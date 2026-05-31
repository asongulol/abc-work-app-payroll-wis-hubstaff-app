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

    const agreement_kind = String(body.agreement_kind || "");
    const doc_version = String(body.doc_version || "").trim();
    const signed_legal_name = String(body.signed_legal_name || "").trim();
    const signature_method = String(body.signature_method || "");
    if (!AGREEMENT_ORDER.includes(agreement_kind)) return json({ error: "unknown agreement_kind" }, 400);
    if (!doc_version) return json({ error: "doc_version required" }, 400);
    if (!signed_legal_name) return json({ error: "signed_legal_name required" }, 400);
    if (signature_method !== "typed" && signature_method !== "drawn") return json({ error: "signature_method must be typed|drawn" }, 400);
    if (body.scrolled_to_end !== true) return json({ error: "you must read to the end of the document before signing" }, 422);

    // ensure a progress row exists (new hire's first action), then read state
    await fetch(`${SB}/rest/v1/onboarding_progress`, {
      method: "POST",
      headers: { ...svc, Prefer: "resolution=ignore-duplicates,return=minimal" },
      body: JSON.stringify({ worker_id, current_stage: "stage1_sign" }),
    });

    // enforce signing ORDER: every required agreement BEFORE this one must
    // already be signed. (Re-signing the same kind is allowed — idempotent.)
    const sigRes = await fetch(`${SB}/rest/v1/onboarding_signatures?worker_id=eq.${worker_id}&status=eq.signed&select=agreement_kind`, { headers: svc });
    const sigRows = await sigRes.json();
    const signedSet = new Set((Array.isArray(sigRows) ? sigRows : []).map((r: any) => r.agreement_kind));
    const idx = AGREEMENT_ORDER.indexOf(agreement_kind);
    for (let i = 0; i < idx; i++) {
      if (!signedSet.has(AGREEMENT_ORDER[i])) {
        return json({ error: `sign the agreements in order — "${AGREEMENT_ORDER[i]}" must be signed first`, code: "out_of_order" }, 409);
      }
    }

    // soft legal-name mismatch (does NOT block signing — design §6.4)
    const wRes = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}&select=first_name,middle_name,last_name`, { headers: svc });
    const wRows = await wRes.json();
    const w = (Array.isArray(wRows) && wRows[0]) || {};
    const profileName = [w.first_name, w.middle_name, w.last_name].filter(Boolean).join(" ");
    const name_mismatch = !!profileName && norm(profileName) !== norm(signed_legal_name);

    // capture the signature (idempotent on (worker_id, agreement_kind, doc_version))
    const insRes = await fetch(`${SB}/rest/v1/onboarding_signatures`, {
      method: "POST",
      headers: { ...svc, Prefer: "resolution=merge-duplicates,return=minimal" },
      body: JSON.stringify({
        worker_id,
        agreement_kind,
        doc_version,
        doc_sha256: body.doc_sha256 ?? null,
        signed_legal_name,
        signature_method,
        signature_data: body.signature_data ?? null,
        scrolled_to_end: true,
        ip_address: clientIp(req),
        user_agent: req.headers.get("user-agent"),
        device_fingerprint: body.device_fingerprint ?? null,
        status: "signed",
      }),
    });
    if (!insRes.ok) return json({ error: `could not record signature: ${await insRes.text()}` }, 500);

    // re-evaluate stage 1: complete when all required agreements are signed
    signedSet.add(agreement_kind);
    const stage1_complete = AGREEMENT_ORDER.every((k) => signedSet.has(k));
    const current_stage = stage1_complete ? "stage2_profile" : "stage1_sign";
    const patch: Record<string, unknown> = {
      stage1_last_kind: agreement_kind,
      stage1_complete,
      current_stage,
      updated_at: new Date().toISOString(),
    };
    if (name_mismatch) patch.name_mismatch_flag = true;
    await fetch(`${SB}/rest/v1/onboarding_progress?worker_id=eq.${worker_id}`, {
      method: "PATCH",
      headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify(patch),
    });

    // audit
    await fetch(`${SB}/rest/v1/audit_log`, {
      method: "POST",
      headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify({
        action: "agreement.signed",
        entity: `${profileName || worker_id} · ${agreement_kind} v${doc_version}`,
        detail: { worker_id, agreement_kind, doc_version, signature_method, name_mismatch },
      }),
    });

    return json({ ok: true, signed: agreement_kind, stage1_complete, current_stage, name_mismatch });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
