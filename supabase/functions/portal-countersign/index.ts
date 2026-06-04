// Supabase Edge Function: portal-countersign
// ---------------------------------------------------------------------------
// ADMIN-facing. Captures an admin COUNTERSIGNATURE on a contractor's Stage-1
// agreement, server-side (parity with portal-sign for the contractor). Only the
// service role writes onboarding_agreements' countersign_* fields, so it can:
//   - verify the caller is an admin (admin_users),
//   - enforce the ASSIGNED countersigner (if one was set at prepare time),
//   - require the CONTRACTOR to have signed first,
//   - capture IP + User-Agent + timestamp SERVER-side (can't be spoofed),
//   - refuse to overwrite an existing countersignature (immutable evidence).
//
// Deploy:  supabase functions deploy portal-countersign --no-verify-jwt
//
// Action (POST body):
//   { action: "countersign", worker_id, agreement_kind,
//     signed_name, signature_method?: "typed"|"drawn", signature_data? }
//     -> { ok, worker_id, agreement_kind, countersigned_at }
// ---------------------------------------------------------------------------

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

const AGREEMENT_KINDS = new Set(["ic_agreement", "non_compete", "confidentiality_nda", "baa"]);

function clientIp(req: Request): string | null {
  const xf = req.headers.get("x-forwarded-for") || "";
  const first = xf.split(",")[0]?.trim();
  return first || req.headers.get("x-real-ip") || null;
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

    // caller must be an admin
    const aRes = await fetch(`${SB}/rest/v1/admin_users?user_id=eq.${caller.id}&select=user_id,email`, { headers: svc });
    const admin = (await aRes.json())?.[0];
    if (!admin) return json({ error: "not authorized — admins only" }, 403);

    const body = await req.json().catch(() => ({}));
    if (body.action !== "countersign") return json({ error: "unknown action" }, 400);

    const worker_id = String(body.worker_id || "");
    const agreement_kind = String(body.agreement_kind || "");
    const signed_name = String(body.signed_name || "").trim();
    const method = body.signature_method === "drawn" ? "drawn" : "typed";
    if (!/^[0-9a-f-]{36}$/i.test(worker_id)) return json({ error: "worker_id required" }, 400);
    if (!AGREEMENT_KINDS.has(agreement_kind)) return json({ error: "unknown agreement_kind" }, 400);
    if (!signed_name) return json({ error: "signed_name required to countersign" }, 400);

    // the CONTRACTOR must have signed this agreement first
    const sRes = await fetch(`${SB}/rest/v1/onboarding_signatures?worker_id=eq.${worker_id}&agreement_kind=eq.${agreement_kind}&status=eq.signed&select=agreement_kind`, { headers: svc });
    const sigs = await sRes.json();
    if (!(Array.isArray(sigs) && sigs.length)) {
      return json({ error: "the contractor has not signed this agreement yet", code: "not_signed" }, 409);
    }

    // existing prepared instance: enforce assignment + immutability
    const iRes = await fetch(`${SB}/rest/v1/onboarding_agreements?worker_id=eq.${worker_id}&agreement_kind=eq.${agreement_kind}&select=*`, { headers: svc });
    const inst = (await iRes.json())?.[0] || null;
    if (inst?.countersigned_at) return json({ error: "this agreement is already countersigned", code: "already_countersigned" }, 409);
    if (inst?.countersigner_user_id && inst.countersigner_user_id !== caller.id) {
      return json({ error: `assigned to ${inst.countersigner_name || "another admin"} — only the assigned countersigner may sign`, code: "not_assigned" }, 403);
    }

    const nowIso = new Date().toISOString();
    const row: Record<string, unknown> = {
      worker_id, agreement_kind,
      // preserve prepared prefill if present
      f_position: inst?.f_position ?? null,
      f_rate: inst?.f_rate ?? null,
      f_start_date: inst?.f_start_date ?? null,
      countersigner_user_id: inst?.countersigner_user_id ?? caller.id,
      countersigner_name: inst?.countersigner_name ?? signed_name,
      countersigned_by: caller.id,
      countersigned_name: signed_name,
      countersign_method: method,
      countersign_data: method === "drawn" ? (body.signature_data ?? null) : signed_name,
      countersigned_at: nowIso,
      countersign_ip: clientIp(req),
      updated_at: nowIso,
    };
    // upsert (contractor may have signed before the admin prepared a row)
    const up = await fetch(`${SB}/rest/v1/onboarding_agreements?on_conflict=worker_id,agreement_kind`, {
      method: "POST",
      headers: { ...svc, Prefer: "resolution=merge-duplicates,return=minimal" },
      body: JSON.stringify(row),
    });
    if (!up.ok) return json({ error: `countersign failed: ${await up.text()}` }, 500);

    // audit
    await fetch(`${SB}/rest/v1/audit_log`, {
      method: "POST",
      headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify({
        action: "agreement.countersigned",
        actor: caller.email ?? null,
        entity: `${worker_id} · ${agreement_kind}`,
        detail: { worker_id, agreement_kind, countersigned_name: signed_name, method },
      }),
    });

    return json({ ok: true, worker_id, agreement_kind, countersigned_at: nowIso });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
