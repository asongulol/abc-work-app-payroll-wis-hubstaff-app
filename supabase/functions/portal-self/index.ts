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
  // "Culture" / fun facts — routed into the profile_extras jsonb (see EXTRA_KEYS)
  "favorite_color", "favorite_food", "motto",
]);

// These live as keys inside the workers.profile_extras jsonb, not as flat
// columns. We merge them into the existing object so a partial edit never
// clobbers the other culture fields. Keep in sync with the admin reader.
const EXTRA_KEYS = new Set(["favorite_color", "favorite_food", "motto"]);

// ---- Stage-2 onboarding: tab -> fields, and server-side validation ----
const STAGE2_SELECT = "first_name,middle_name,last_name,mobile,ph_address,permanent_address,address_landmark,postal_code,date_of_birth,emergency_name,emergency_relationship,emergency_mobile,marital_status,education_level,course,year_graduated,school,gcash,paymaya,paypal,wise_tag,profile_extras";
const TAB_FIELDS: Record<string, true> = { contact: true, personal: true, payout: true, about: true };
const PH_MOBILE = /^(\+63|0)9\d{9}$/;
const nonEmpty = (v: unknown) => v != null && String(v).trim() !== "";

// Validate one Stage-2 tab against the (flattened) worker row. Returns [] when
// the tab's required fields are satisfied. Mirrors the client-side hints, but
// THIS is the authority (the client can't mark a tab complete on its own).
function validateTab(tab: string, w: Record<string, any>): Array<{ field: string; msg: string }> {
  const e: Array<{ field: string; msg: string }> = [];
  const req = (f: string, msg: string) => { if (!nonEmpty(w[f])) e.push({ field: f, msg }); };
  const mobile = (f: string, msg: string) => {
    if (!nonEmpty(w[f])) { e.push({ field: f, msg: msg + " is required" }); return; }
    if (!PH_MOBILE.test(String(w[f]).replace(/\s/g, ""))) e.push({ field: f, msg: "Use 09XXXXXXXXX or +639XXXXXXXXX" });
  };
  if (tab === "contact") {
    req("first_name", "First name is required");
    req("last_name", "Last name is required");
    req("ph_address", "Current PH address is required");
    mobile("mobile", "Mobile");
    if (nonEmpty(w.postal_code) && !/^\d{4}$/.test(String(w.postal_code).trim())) e.push({ field: "postal_code", msg: "PH postal code is 4 digits" });
    if (!nonEmpty(w.date_of_birth)) e.push({ field: "date_of_birth", msg: "Date of birth is required" });
    else {
      const dob = new Date(String(w.date_of_birth));
      if (isNaN(dob.getTime())) e.push({ field: "date_of_birth", msg: "Invalid date" });
      else {
        const now = new Date();
        let age = now.getUTCFullYear() - dob.getUTCFullYear();
        const m = now.getUTCMonth() - dob.getUTCMonth();
        if (m < 0 || (m === 0 && now.getUTCDate() < dob.getUTCDate())) age--;
        if (age < 18) e.push({ field: "date_of_birth", msg: "You must be at least 18" });
      }
    }
  } else if (tab === "personal") {
    req("emergency_name", "Emergency contact name is required");
    req("emergency_relationship", "Emergency contact relationship is required");
    mobile("emergency_mobile", "Emergency contact mobile");
    req("marital_status", "Marital status is required");
  } else if (tab === "payout") {
    if (!["gcash", "paymaya", "paypal", "wise_tag"].some((f) => nonEmpty(w[f]))) {
      e.push({ field: "payout", msg: "Add at least one payout method" });
    }
  }
  // "about" has no required fields
  return e;
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

    // map the caller -> their worker_id via an ACTIVE contractor login
    const clRes = await fetch(`${SB}/rest/v1/contractor_logins?auth_user_id=eq.${caller.id}&status=eq.active&select=worker_id`, { headers: svc });
    const cl = await clRes.json();
    const worker_id = (Array.isArray(cl) && cl[0]?.worker_id) || null;
    if (!worker_id) return json({ error: "no active contractor profile for this login" }, 403);

    const body = await req.json().catch(() => ({}));
    const action = body.action;
    if (action !== "update_profile" && action !== "complete_tab") return json({ error: "unknown action" }, 400);

    // shared: turn input fields into {patch, extra} limited to an allowed set
    const buildPatch = (inFields: any, allowed: Set<string>) => {
      const patch: Record<string, unknown> = {};
      const extra: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(inFields || {})) {
        if (!allowed.has(k)) continue;                     // silently drop disallowed
        const val = (typeof v === "string" && v.trim() === "") ? null : v;
        if (EXTRA_KEYS.has(k)) extra[k] = val; else patch[k] = val;
      }
      return { patch, extra };
    };
    // merge culture keys into the existing profile_extras jsonb (don't clobber)
    const applyExtra = async (patch: Record<string, unknown>, extra: Record<string, unknown>) => {
      if (!Object.keys(extra).length) return;
      const wRes = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}&select=profile_extras`, { headers: svc });
      const wRows = await wRes.json();
      const cur = (Array.isArray(wRows) && wRows[0]?.profile_extras && typeof wRows[0].profile_extras === "object") ? wRows[0].profile_extras : {};
      const merged: Record<string, unknown> = { ...cur };
      for (const [k, v] of Object.entries(extra)) { if (v === null) delete merged[k]; else merged[k] = v; }
      patch.profile_extras = merged;
    };

    // ---- update_profile (existing self-service): admin's editable_fields ∩ SAFE_FIELDS ----
    if (action === "update_profile") {
      const psRes = await fetch(`${SB}/rest/v1/portal_settings?id=eq.1&select=editable_fields`, { headers: svc });
      const ps = await psRes.json();
      const adminAllowed: string[] = (Array.isArray(ps) && Array.isArray(ps[0]?.editable_fields)) ? ps[0].editable_fields : [];
      const allowed = new Set(adminAllowed.filter((f) => SAFE_FIELDS.has(f)));
      const { patch, extra } = buildPatch(body.fields, allowed);
      await applyExtra(patch, extra);
      if (!Object.keys(patch).length) return json({ error: "no editable fields in request (check the admin's portal settings)" }, 400);
      const upd = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}`, { method: "PATCH", headers: { ...svc, Prefer: "return=minimal" }, body: JSON.stringify(patch) });
      if (!upd.ok) return json({ error: `update failed: ${await upd.text()}` }, 500);
      return json({ ok: true, updated: Object.keys(patch) });
    }

    // ---- complete_tab (onboarding Stage 2) ----
    const tab = String(body.tab || "");
    if (!TAB_FIELDS[tab]) return json({ error: "unknown tab" }, 400);

    // sequencing: Stage 1 must be done first
    const opRes = await fetch(`${SB}/rest/v1/onboarding_progress?worker_id=eq.${worker_id}&select=stage1_complete,completed_at,current_stage`, { headers: svc });
    const op = (await opRes.json())?.[0];
    if (!op || !op.stage1_complete) return json({ error: "finish signing your agreements first", code: "stage_out_of_order" }, 409);

    // During onboarding a contractor may edit ANY SAFE_FIELD (not gated by the
    // admin editable_fields picker) so required fields can always be filled.
    // SAFE_FIELDS still hard-excludes payout_method / work_* / email / rate / status.
    const { patch, extra } = buildPatch(body.fields, SAFE_FIELDS);
    await applyExtra(patch, extra);
    if (Object.keys(patch).length) {
      const upd = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}`, { method: "PATCH", headers: { ...svc, Prefer: "return=minimal" }, body: JSON.stringify(patch) });
      if (!upd.ok) return json({ error: `update failed: ${await upd.text()}` }, 500);
    }

    // re-read the authoritative worker row and validate
    const wRes = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}&select=${STAGE2_SELECT}`, { headers: svc });
    const w0 = ((await wRes.json()) || [])[0] || {};
    const ex0 = (w0.profile_extras && typeof w0.profile_extras === "object") ? w0.profile_extras : {};
    const wv = { ...w0, ...ex0 };                          // flatten profile_extras for lookups
    const field_errors = validateTab(tab, wv);

    // Stage 2 is complete when the three REQUIRED tabs validate (about is optional)
    const stage2_complete = ["contact", "personal", "payout"].every((tt) => validateTab(tt, wv).length === 0);

    // advance progress monotonically; never regress stage or clear completion
    const RANK: Record<string, number> = { stage1_sign: 0, stage2_profile: 1, stage3_docs: 2, complete: 3 };
    const curStage = op.current_stage || "stage2_profile";
    const next_stage = op.completed_at ? curStage
      : (stage2_complete && RANK["stage3_docs"] > RANK[curStage] ? "stage3_docs" : curStage);
    await fetch(`${SB}/rest/v1/onboarding_progress?worker_id=eq.${worker_id}`, {
      method: "PATCH", headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify({ stage2_last_tab: tab, stage2_complete, current_stage: next_stage, updated_at: new Date().toISOString() }),
    });

    return json({ ok: true, tab, tab_complete: field_errors.length === 0, field_errors, stage2_complete });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
