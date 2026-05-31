// Supabase Edge Function: portal-admin
// ---------------------------------------------------------------------------
// ADMIN-ONLY. Creates a contractor's self-service portal login (email+password)
// and links it to a worker in contractor_logins. Creating an auth user needs
// the service-role key, so it can't be done from the browser — hence this
// function. The caller MUST be an allowlisted admin (verified below).
//
// Deploy:  supabase functions deploy portal-admin --no-verify-jwt
//
// Actions (POST body):
//   { action: "create_login", worker_id, email, password? }
//        -> { ok, email, password }   (password = the temp password to share)
//   { action: "revoke_login", worker_id }
//        -> { ok }                    (sets status='revoked'; blocks portal access)
// ---------------------------------------------------------------------------

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const SB = Deno.env.get("SUPABASE_URL");
    const SR = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!SB || !SR) return json({ error: "server missing SUPABASE_URL / SERVICE_ROLE_KEY" }, 500);
    const svc = { apikey: SR, Authorization: `Bearer ${SR}`, "Content-Type": "application/json" };

    // --- verify the caller is an allowlisted admin ---
    const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "missing auth" }, 401);
    const uRes = await fetch(`${SB}/auth/v1/user`, { headers: { Authorization: `Bearer ${token}`, apikey: SR } });
    if (!uRes.ok) return json({ error: "invalid session" }, 401);
    const caller = await uRes.json();
    if (!caller?.id) return json({ error: "invalid session" }, 401);
    const aRes = await fetch(`${SB}/rest/v1/admin_users?user_id=eq.${caller.id}&select=user_id`, { headers: svc });
    const admins = await aRes.json();
    if (!Array.isArray(admins) || !admins.length) return json({ error: "not authorized — admins only" }, 403);

    const body = await req.json().catch(() => ({}));

    if (body.action === "create_login") {
      const worker_id = body.worker_id;
      const email = String(body.email || "").trim().toLowerCase();
      if (!worker_id || !email) return json({ error: "need worker_id and a contractor email" }, 400);

      // already linked?
      const exRes = await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}&select=worker_id,email,status`, { headers: svc });
      const ex = await exRes.json();
      if (Array.isArray(ex) && ex.length) {
        return json({ error: `This contractor already has a portal login (${ex[0].email || "set"}, ${ex[0].status}).` }, 409);
      }

      // temp password (the contractor changes it on first login via reset)
      const pw = String(body.password || "").trim() ||
        ("Abc-" + Math.random().toString(36).slice(2, 8) + "-" + Math.floor(Math.random() * 9000 + 1000));

      // create the auth user (email pre-confirmed so they can sign in immediately)
      const cRes = await fetch(`${SB}/auth/v1/admin/users`, {
        method: "POST", headers: svc,
        body: JSON.stringify({ email, password: pw, email_confirm: true }),
      });
      const cTxt = await cRes.text(); let cJson: any = null; try { cJson = JSON.parse(cTxt); } catch { /* */ }
      if (!cRes.ok) {
        return json({ error: `couldn't create login: ${cJson?.msg ?? cJson?.error_description ?? cTxt}` }, cRes.status);
      }
      const auth_user_id = cJson?.id ?? cJson?.user?.id;

      // link worker -> login
      const lRes = await fetch(`${SB}/rest/v1/contractor_logins`, {
        method: "POST",
        headers: { ...svc, Prefer: "resolution=merge-duplicates,return=minimal" },
        body: JSON.stringify({ worker_id, auth_user_id, email, status: "active" }),
      });
      if (!lRes.ok) return json({ error: `login created but linking failed: ${await lRes.text()}` }, 500);

      return json({ ok: true, email, password: pw });
    }

    if (body.action === "revoke_login") {
      const worker_id = body.worker_id;
      if (!worker_id) return json({ error: "need worker_id" }, 400);
      const r = await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}`, {
        method: "PATCH", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ status: "revoked" }),
      });
      if (!r.ok) return json({ error: `revoke failed: ${await r.text()}` }, 500);
      return json({ ok: true });
    }

    // Permanently delete a contractor — ONLY if they have NO payroll history.
    // Payroll records (payments / time entries) must be retained, so a worker
    // with any is refused here (the UI offers Deactivate instead). The guard is
    // server-side so it can't be bypassed. Also cleans up the things the admin
    // client cannot: the contractor's Storage files and their auth login.
    if (body.action === "delete_contractor") {
      const worker_id = body.worker_id;
      if (!worker_id) return json({ error: "need worker_id" }, 400);

      // GUARD: block if any payroll history exists.
      const payRes = await fetch(`${SB}/rest/v1/payments?worker_id=eq.${worker_id}&select=id&limit=1`, { headers: svc });
      const pays = await payRes.json();
      const teRes = await fetch(`${SB}/rest/v1/time_entries?worker_id=eq.${worker_id}&select=work_date&limit=1`, { headers: svc });
      const tes = await teRes.json();
      if ((Array.isArray(pays) && pays.length) || (Array.isArray(tes) && tes.length)) {
        return json({ error: "This contractor has payroll history (payments or time entries) and can't be deleted — deactivate them instead.", code: "has_history" }, 409);
      }

      // Gather storage files + auth login BEFORE the cascade removes those rows.
      const docRes = await fetch(`${SB}/rest/v1/documents?worker_id=eq.${worker_id}&select=storage_path`, { headers: svc });
      const docs = await docRes.json();
      const paths = (Array.isArray(docs) ? docs : []).map((d: any) => d.storage_path).filter(Boolean);
      const clRes = await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}&select=auth_user_id`, { headers: svc });
      const cl = await clRes.json();
      const auth_user_id = (Array.isArray(cl) && cl[0]?.auth_user_id) || null;

      // Remove storage objects (best-effort; never block the delete on these).
      if (paths.length) {
        await fetch(`${SB}/storage/v1/object/contractor-docs`, {
          method: "DELETE", headers: svc, body: JSON.stringify({ prefixes: paths }),
        }).catch(() => {});
      }
      // Remove the auth login (best-effort).
      if (auth_user_id) {
        await fetch(`${SB}/auth/v1/admin/users/${auth_user_id}`, { method: "DELETE", headers: svc }).catch(() => {});
      }
      // Delete the worker — FK ON DELETE CASCADE removes worker_companies, rates,
      // documents, onboarding_progress, onboarding_signatures, contractor_logins.
      const delRes = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}`, {
        method: "DELETE", headers: { ...svc, Prefer: "return=minimal" },
      });
      if (!delRes.ok) return json({ error: `delete failed: ${await delRes.text()}` }, 500);

      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "delete_contractor", actor: caller.email ?? null, entity: worker_id, detail: { worker_id, files_removed: paths.length, login_removed: !!auth_user_id } }),
      });
      return json({ ok: true, files_removed: paths.length, login_removed: !!auth_user_id });
    }

    return json({ error: "unknown action" }, 400);
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
