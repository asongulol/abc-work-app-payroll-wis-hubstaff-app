// Supabase Edge Function: admin-manage
// ---------------------------------------------------------------------------
// OWNER-ONLY. Manages the admin allowlist (public.admin_users). admin_users has
// NO client write policy, so every add/remove/role-change goes through here. The
// caller MUST be an 'owner' (verified server-side). Reads (listing admins) are
// done by the frontend directly via RLS (admin_users SELECT = is_admin()).
//
// Deploy:  supabase functions deploy admin-manage --no-verify-jwt
//
// Actions (POST body):
//   { action: "add_admin", email, role? }   role = "admin" (default) | "owner"
//        -> { ok, user_id, email, role, provisioned }   provisioned=true if a new auth user was pre-created
//   { action: "set_role", user_id, role }
//        -> { ok }
//   { action: "remove_admin", user_id }
//        -> { ok }
// ---------------------------------------------------------------------------

// Admins must use a work-domain email (guards against typos / adding a personal
// account). Add explicit exceptions here if ever needed.
const ALLOWED_DOMAINS = ["abckidsny.com", "abbilabs.com"];
const ALLOWED_EXCEPTIONS: string[] = [];

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}
function emailOk(email: string): boolean {
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return false;
  if (ALLOWED_EXCEPTIONS.includes(email)) return true;
  const domain = email.split("@")[1] || "";
  return ALLOWED_DOMAINS.includes(domain);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const SB = Deno.env.get("SUPABASE_URL");
    const SR = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!SB || !SR) return json({ error: "server missing SUPABASE_URL / SERVICE_ROLE_KEY" }, 500);
    const svc = { apikey: SR, Authorization: `Bearer ${SR}`, "Content-Type": "application/json" };

    // --- identify caller + require OWNER ---
    const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "missing auth" }, 401);
    const uRes = await fetch(`${SB}/auth/v1/user`, { headers: { Authorization: `Bearer ${token}`, apikey: SR } });
    if (!uRes.ok) return json({ error: "invalid session" }, 401);
    const caller = await uRes.json();
    if (!caller?.id) return json({ error: "invalid session" }, 401);
    const meRes = await fetch(`${SB}/rest/v1/admin_users?user_id=eq.${caller.id}&select=role`, { headers: svc });
    const me = await meRes.json();
    if (!Array.isArray(me) || !me.length || me[0].role !== "owner")
      return json({ error: "not authorized — owners only" }, 403);

    const body = await req.json().catch(() => ({}));

    // ---- add_admin (sign-in-first) ----
    // The person must have signed in with Google ONCE (creating their auth user);
    // we then grant admin. Robust — no dependence on OAuth identity auto-linking.
    if (body.action === "add_admin") {
      const email = String(body.email || "").trim().toLowerCase();
      const role = body.role === "owner" ? "owner" : "admin";
      if (!email) return json({ error: "email required" }, 400);
      if (!emailOk(email)) return json({ error: `email must be on an allowed work domain (${ALLOWED_DOMAINS.join(", ")})` }, 422);

      // don't turn a contractor's portal login into an admin (match by email — covers active/revoked)
      const clRes = await fetch(`${SB}/rest/v1/contractor_logins?email=eq.${encodeURIComponent(email)}&select=worker_id`, { headers: svc });
      const cl = await clRes.json().catch(() => null);
      if (Array.isArray(cl) && cl.length)
        return json({ error: "that email is a contractor portal login — use a different address for an admin" }, 409);

      // find the existing auth user (service-role-only RPC)
      const lkRes = await fetch(`${SB}/rest/v1/rpc/admin_lookup_auth_user`, {
        method: "POST", headers: svc, body: JSON.stringify({ p_email: email }),
      });
      if (!lkRes.ok) return json({ error: `lookup failed: ${await lkRes.text()}` }, 500);
      const user_id = await lkRes.json();   // expect a uuid string or null
      const validUuid = user_id && typeof user_id === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user_id);

      // Hasn't signed in yet → pre-add to pending_admins. A trigger on auth.users
      // promotes them to a real admin with this role the moment they first sign in.
      if (!validUuid) {
        const pRes = await fetch(`${SB}/rest/v1/pending_admins`, {
          method: "POST", headers: { ...svc, Prefer: "resolution=merge-duplicates,return=minimal" },
          body: JSON.stringify({ email, role, added_by: caller.id }),
        });
        if (!pRes.ok) return json({ error: `couldn't pre-add: ${await pRes.text()}` }, 500);
        await fetch(`${SB}/rest/v1/audit_log`, {
          method: "POST", headers: { ...svc, Prefer: "return=minimal" },
          body: JSON.stringify({ action: "admin.pre_added", actor: caller.email ?? null, entity: email, detail: { role } }),
        });
        return json({ ok: true, email, role, pending: true });
      }

      // already an admin? don't silently change their role here
      const exRes = await fetch(`${SB}/rest/v1/admin_users?user_id=eq.${user_id}&select=role`, { headers: svc });
      const ex = await exRes.json().catch(() => null);
      if (Array.isArray(ex) && ex.length)
        return json({ error: `${email} is already an ${ex[0].role}. Use the role control to change it.`, code: "already_admin" }, 409);

      const insRes = await fetch(`${SB}/rest/v1/admin_users`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ user_id, email, role, added_by: caller.id }),
      });
      if (!insRes.ok) return json({ error: `couldn't add admin: ${await insRes.text()}` }, 500);

      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "admin.added", actor: caller.email ?? null, entity: email, detail: { user_id, role } }),
      });
      return json({ ok: true, user_id, email, role, pending: false });
    }

    // ---- set_role (promote/demote) ----
    if (body.action === "set_role") {
      const user_id = String(body.user_id || "").trim();
      const role = body.role === "owner" ? "owner" : "admin";
      if (!user_id) return json({ error: "user_id required" }, 400);
      // the DB trigger blocks demoting the last owner; surface its message cleanly
      const upd = await fetch(`${SB}/rest/v1/admin_users?user_id=eq.${user_id}`, {
        method: "PATCH", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ role }),
      });
      if (!upd.ok) {
        const t = await upd.text();
        return json({ error: /last owner/i.test(t) ? "You can't demote the last owner." : `couldn't change role: ${t}` }, 409);
      }
      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "admin.role_changed", actor: caller.email ?? null, entity: user_id, detail: { user_id, role } }),
      });
      return json({ ok: true });
    }

    // ---- remove_admin (revoke admin rights / cancel a pending invite) ----
    if (body.action === "remove_admin") {
      const user_id = String(body.user_id || "").trim();
      const pendingEmail = String(body.email || "").trim().toLowerCase();
      if (!user_id && !pendingEmail) return json({ error: "user_id or email required" }, 400);

      if (!user_id) {
        // cancel a pending invite (not yet a real admin)
        const del = await fetch(`${SB}/rest/v1/pending_admins?email=eq.${encodeURIComponent(pendingEmail)}`, {
          method: "DELETE", headers: { ...svc, Prefer: "return=minimal" },
        });
        if (!del.ok) return json({ error: `couldn't remove invite: ${await del.text()}` }, 500);
        await fetch(`${SB}/rest/v1/audit_log`, {
          method: "POST", headers: { ...svc, Prefer: "return=minimal" },
          body: JSON.stringify({ action: "admin.invite_removed", actor: caller.email ?? null, entity: pendingEmail, detail: { email: pendingEmail } }),
        });
        return json({ ok: true });
      }

      const del = await fetch(`${SB}/rest/v1/admin_users?user_id=eq.${user_id}`, {
        method: "DELETE", headers: { ...svc, Prefer: "return=minimal" },
      });
      if (!del.ok) {
        const t = await del.text();
        return json({ error: /last owner/i.test(t) ? "You can't remove the last owner." : `couldn't remove admin: ${t}` }, 409);
      }
      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "admin.removed", actor: caller.email ?? null, entity: user_id, detail: { user_id } }),
      });
      return json({ ok: true });
    }

    return json({ error: "unknown action" }, 400);
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
