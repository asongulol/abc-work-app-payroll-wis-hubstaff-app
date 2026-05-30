// Supabase Edge Function: portal-self
// ---------------------------------------------------------------------------
// CONTRACTOR-facing. Lets a signed-in contractor update a WHITELISTED set of
// their OWN profile fields. The whitelist is enforced here (server side):
//   allowed = portal_settings.editable_fields  ∩  SAFE_FIELDS
// so contractors can never write payout destination, benefits, rate, status,
// etc. — even if the client is tampered with. No direct write RLS on workers.
//
// Deploy:  supabase functions deploy portal-self --no-verify-jwt
//
// Action (POST body):
//   { action: "update_profile", fields: { mobile, ph_address, ... } }
//     -> { ok, updated: [field, ...] }
// ---------------------------------------------------------------------------

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

// Hard cap of what a contractor may EVER edit, regardless of config. Excludes
// payout destination (wise_recipient_*), payout_method, benefits eligibility,
// rate, status, email (login-tied), hire_date.
const SAFE_FIELDS = new Set([
  "first_name", "middle_name", "last_name",
  "mobile", "ph_address", "date_of_birth",
  "gcash", "paymaya", "paypal", "wise_tag",
  // 201 personal info (safe for self-edit; gov IDs/payout stay out)
  "emergency_name", "emergency_relationship", "emergency_mobile",
  "permanent_address", "address_landmark", "postal_code",
  "marital_status", "education_level", "course", "year_graduated", "school",
]);

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

    // map the caller -> their worker_id via an ACTIVE contractor login
    const clRes = await fetch(`${SB}/rest/v1/contractor_logins?auth_user_id=eq.${caller.id}&status=eq.active&select=worker_id`, { headers: svc });
    const cl = await clRes.json();
    const worker_id = (Array.isArray(cl) && cl[0]?.worker_id) || null;
    if (!worker_id) return json({ error: "no active contractor profile for this login" }, 403);

    const body = await req.json().catch(() => ({}));
    if (body.action !== "update_profile") return json({ error: "unknown action" }, 400);

    // allowed = admin's editable_fields ∩ SAFE_FIELDS
    const psRes = await fetch(`${SB}/rest/v1/portal_settings?id=eq.1&select=editable_fields`, { headers: svc });
    const ps = await psRes.json();
    const adminAllowed: string[] = (Array.isArray(ps) && Array.isArray(ps[0]?.editable_fields)) ? ps[0].editable_fields : [];
    const allowed = new Set(adminAllowed.filter((f) => SAFE_FIELDS.has(f)));

    const inFields = (body.fields && typeof body.fields === "object") ? body.fields : {};
    const patch: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(inFields)) {
      if (!allowed.has(k)) continue;                       // silently drop disallowed fields
      patch[k] = (typeof v === "string" && v.trim() === "") ? null : v;
    }
    if (!Object.keys(patch).length) return json({ error: "no editable fields in request (check the admin's portal settings)" }, 400);

    const upd = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}`, {
      method: "PATCH",
      headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify(patch),
    });
    if (!upd.ok) return json({ error: `update failed: ${await upd.text()}` }, 500);

    return json({ ok: true, updated: Object.keys(patch) });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
