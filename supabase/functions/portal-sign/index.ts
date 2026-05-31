// Supabase Edge Function: portal-sign
// ---------------------------------------------------------------------------
// CONTRACTOR-facing. Captures a Stage-1 onboarding e-signature for ONE
// agreement and advances onboarding_progress. The contractor never writes
// onboarding_signatures / onboarding_progress directly (RLS has no contractor
// write policy) — this service-role function is the only path, so it can:
//   - capture IP + User-Agent SERVER-side (can't be spoofed by the client),
//   - enforce the agreement signing ORDER,
//   - enforce scroll-to-bottom,
//   - flag a legal-name mismatch without failing the sign.
//
// Deploy:  supabase functions deploy portal-sign --no-verify-jwt
//
// Action (POST body):
//   { action: "sign", agreement_kind, doc_version, doc_sha256?, signed_legal_name,
//     signature_method: "typed"|"drawn", signature_data?, scrolled_to_end: true,
//     device_fingerprint? }
//     -> { ok, signed: agreement_kind, stage1_complete, current_stage }
// ---------------------------------------------------------------------------

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

// Required agreements, in signing order. Index = order.
const AGREEMENT_ORDER = ["ic_agreement", "non_compete", "confidentiality_nda", "baa"];

// Best-effort client IP from the edge proxy headers (never throws).
function clientIp(req: Request): string | null {
  const xf = req.headers.get("x-forwarded-for") || "";
  const first = xf.split(",")[0]?.trim();
  return first || req.headers.get("x-real-ip") || null;
}

// loose name compare for the soft mismatch flag (case/space/punct-insensitive)
function norm(s: string): string {
  return (s || "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const SB = Deno.env.get("SUPABASE_URL");
    const SR = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!SB || !SR) return json({ error: "server missing SUPABASE_URL / SERVICE_ROLE_KEY" }, 500);
    const svc = { apikey: SR, Authorization: `Bearer ${SR}`, "Content-Type": "application/json" };

    // identify the caller from their session token
    const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "missing auth" }, 401);
    const uRes = await fetch(`${SB}/auth/v1/user`, { headers: { Authorization: `Bearer ${token}`, apikey: SR } });
    if (!uRes.ok) return json({ error: "invalid session" }, 401);
    const caller = await uRes.json();
    if (!caller?.id) return json({ error: "invalid session" }, 401);

    // map caller -> active worker
    const clRes = await fetch(`${SB}/rest/v1/contractor_logins?auth_user_id=eq.${caller.id}&status=eq.active&select=worker_id`, { headers: svc });
    const cl = await clRes.json();
    const worker_id = (Array.isArray(cl) && cl[0]?.worker_id) || null;
    if (!worker_id) return json({ error: "no active contractor profile for this login" }, 403);

    const body = await req.json().catch(() => ({}));
    if (body.action !== "sign") return json({ error: "unknown action" }, 400);

    // Required agreements + signing order come from config (fallback to the
    // constant) so the gate stays in sync with what the portal shows.
    const psRes = await fetch(`${SB}/rest/v1/portal_settings?id=eq.1&select=onboarding_config`, { headers: svc });
    const ps = await psRes.json();
    const cfgAgr = (Array.isArray(ps) && Array.isArray(ps[0]?.onboarding_config?.agreements)) ? ps[0].onboarding_config.agreements : null;
    const order: string[] = (cfgAgr && cfgAgr.length)
      ? cfgAgr.slice().sort((a: any, b: any) => (a.order || 0) - (b.order || 0)).map((a: any) => a.kind)
      : AGREEMENT_ORDER;

    const agreement_kind = String(body.agreement_kind || "");
    const doc_version = String(body.doc_version || "").trim();
    const signed_legal_name = String(body.signed_legal_name || "").trim();
    const signature_method = String(body.signature_method || "");
    if (!order.includes(agreement_kind)) return json({ error: "unknown agreement_kind" }, 400);
    if (!doc_version) return json({ error: "doc_version required" }, 400);
    if (!signed_legal_name) return json({ error: "signed_legal_name required" }, 400);
    if (signature_method !== "typed" && signature_method !== "drawn") return json({ error: "signature_method must be typed|drawn" }, 400);
    if (body.scrolled_to_end !== true) return json({ error: "you must read to the end of the document before signing" }, 422);

    // ensure a progress row exists (new hire's first action) — fail loudly on error
    const opIns = await fetch(`${SB}/rest/v1/onboarding_progress`, {
      method: "POST",
      headers: { ...svc, Prefer: "resolution=ignore-duplicates,return=minimal" },
      body: JSON.stringify({ worker_id, current_stage: "stage1_sign" }),
    });
    if (!opIns.ok) return json({ error: `could not initialize onboarding: ${await opIns.text()}` }, 500);

    // enforce signing ORDER: every required agreement BEFORE this one must be signed.
    const sigRes = await fetch(`${SB}/rest/v1/onboarding_signatures?worker_id=eq.${worker_id}&status=eq.signed&select=agreement_kind`, { headers: svc });
    const preSigned = new Set(((await sigRes.json()) || []).map((r: any) => r.agreement_kind));
    const idx = order.indexOf(agreement_kind);
    for (let i = 0; i < idx; i++) {
      if (!preSigned.has(order[i])) {
        return json({ error: `sign the agreements in order — "${order[i]}" must be signed first`, code: "out_of_order" }, 409);
      }
    }

    // soft legal-name mismatch (does NOT block signing — design §6.4)
    const wRes = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}&select=first_name,middle_name,last_name`, { headers: svc });
    const wRows = await wRes.json();
    const w = (Array.isArray(wRows) && wRows[0]) || {};
    const profileName = [w.first_name, w.middle_name, w.last_name].filter(Boolean).join(" ");
    const name_mismatch = !!profileName && norm(profileName) !== norm(signed_legal_name);

    // capture the signature. IMMUTABLE: ignore-duplicates => ON CONFLICT DO
    // NOTHING, so an existing (worker, kind, version) signature row is NEVER
    // overwritten (it is legal evidence — IP/timestamp/data must not change).
    const insRes = await fetch(`${SB}/rest/v1/onboarding_signatures`, {
      method: "POST",
      headers: { ...svc, Prefer: "resolution=ignore-duplicates,return=minimal" },
      body: JSON.stringify({
        worker_id, agreement_kind, doc_version,
        doc_sha256: body.doc_sha256 ?? null,
        signed_legal_name, signature_method,
        signature_data: body.signature_data ?? null,
        scrolled_to_end: true,
        ip_address: clientIp(req),
        user_agent: req.headers.get("user-agent"),
        device_fingerprint: body.device_fingerprint ?? null,
        status: "signed",
      }),
    });
    if (!insRes.ok) return json({ error: `could not record signature: ${await insRes.text()}` }, 500);

    // re-evaluate stage 1 from AUTHORITATIVE db state (not the pre-insert set) so
    // two concurrent signs can't lose the completion update.
    const postRes = await fetch(`${SB}/rest/v1/onboarding_signatures?worker_id=eq.${worker_id}&status=eq.signed&select=agreement_kind`, { headers: svc });
    const signedNow = new Set(((await postRes.json()) || []).map((r: any) => r.agreement_kind));
    const stage1_complete = order.every((k) => signedNow.has(k));

    // read current progress so we only ADVANCE the stage, never regress it
    // (e.g. re-signing after already reaching stage 2/3, or after completion).
    const curRes = await fetch(`${SB}/rest/v1/onboarding_progress?worker_id=eq.${worker_id}&select=current_stage,completed_at`, { headers: svc });
    const cur = (await curRes.json())?.[0] || {};
    const RANK: Record<string, number> = { stage1_sign: 0, stage2_profile: 1, stage3_docs: 2, complete: 3 };
    const desired = stage1_complete ? "stage2_profile" : "stage1_sign";
    const curStage = cur.current_stage ?? "stage1_sign";
    const next_stage = cur.completed_at ? curStage
      : (RANK[desired] > RANK[curStage] ? desired : curStage);

    const patch: Record<string, unknown> = {
      stage1_last_kind: agreement_kind,
      stage1_complete,
      current_stage: next_stage,
      updated_at: new Date().toISOString(),
    };
    if (name_mismatch) patch.name_mismatch_flag = true;
    const patchRes = await fetch(`${SB}/rest/v1/onboarding_progress?worker_id=eq.${worker_id}`, {
      method: "PATCH",
      headers: { ...svc, Prefer: "return=representation" },
      body: JSON.stringify(patch),
    });
    const patched = patchRes.ok ? await patchRes.json() : null;
    if (!patchRes.ok || !Array.isArray(patched) || !patched.length) {
      return json({ error: "signature recorded but progress update failed — please retry" }, 500);
    }

    // audit (populate the existing audit_log.actor column with the caller email)
    await fetch(`${SB}/rest/v1/audit_log`, {
      method: "POST",
      headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify({
        action: "agreement.signed",
        actor: caller.email ?? null,
        entity: `${profileName || worker_id} · ${agreement_kind} v${doc_version}`,
        detail: { worker_id, agreement_kind, doc_version, signature_method, name_mismatch },
      }),
    });

    return json({ ok: true, signed: agreement_kind, stage1_complete, current_stage: next_stage, name_mismatch });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
