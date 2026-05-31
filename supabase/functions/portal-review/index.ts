// Supabase Edge Function: portal-review
// ---------------------------------------------------------------------------
// ADMIN-ONLY. HR reviews a Stage-3 uploaded document: approve it or mark it
// "needs replacement" with a required reason. reviewed_by is resolved from the
// admin's own session (never client-supplied). On approval it re-evaluates the
// contractor's Stage-3 completion and, when every required document is
// approved, finalizes onboarding (sets onboarding_progress.completed_at).
//
// Deploy:  supabase functions deploy portal-review --no-verify-jwt
//
// Actions (POST body):
//   { action: "approve", document_id }
//      -> { ok, review_status, stage3_complete, onboarding_complete }
//   { action: "needs_replacement", document_id, reason }
//      -> { ok, review_status }
// ---------------------------------------------------------------------------

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

function monthsBetween(fromISO: string, to: Date): number {
  const f = new Date(fromISO);
  return (to.getFullYear() - f.getFullYear()) * 12 + (to.getMonth() - f.getMonth());
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const SB = Deno.env.get("SUPABASE_URL");
    const SR = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!SB || !SR) return json({ error: "server missing SUPABASE_URL / SERVICE_ROLE_KEY" }, 500);
    const svc = { apikey: SR, Authorization: `Bearer ${SR}`, "Content-Type": "application/json" };

    // --- verify caller is an allowlisted admin ---
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
    const action = body.action;
    const document_id = body.document_id;
    if (action !== "approve" && action !== "needs_replacement") return json({ error: "unknown action" }, 400);
    if (!document_id) return json({ error: "document_id required" }, 400);

    // load the document under review
    const dRes = await fetch(`${SB}/rest/v1/documents?id=eq.${document_id}&select=id,worker_id,kind,issued_on,review_status`, { headers: svc });
    const dRows = await dRes.json();
    const doc = (Array.isArray(dRows) && dRows[0]) || null;
    if (!doc) return json({ error: "document not found" }, 404);
    const worker_id = doc.worker_id;
    const now = new Date();

    // ---- needs_replacement ----
    if (action === "needs_replacement") {
      const reason = String(body.reason || "").trim();
      if (!reason) return json({ error: "a reason is required when requesting a replacement" }, 422);
      const upd = await fetch(`${SB}/rest/v1/documents?id=eq.${document_id}`, {
        method: "PATCH",
        headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ review_status: "needs_replacement", review_reason: reason, reviewed_by: caller.id, reviewed_at: now.toISOString() }),
      });
      if (!upd.ok) return json({ error: `update failed: ${await upd.text()}` }, 500);
      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "document.needs_replacement", entity: `${doc.kind} · ${worker_id}`, detail: { document_id, kind: doc.kind, reason } }),
      });
      return json({ ok: true, review_status: "needs_replacement" });
    }

    // ---- approve ----
    // NBI freshness guard: refuse approval if issued_on is set and older than 6 months.
    if (doc.kind === "nbi_clearance" && doc.issued_on && monthsBetween(doc.issued_on, now) > 6) {
      return json({ error: "NBI clearance is older than 6 months — request a replacement instead", code: "nbi_stale" }, 422);
    }
    const upd = await fetch(`${SB}/rest/v1/documents?id=eq.${document_id}`, {
      method: "PATCH",
      headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify({ review_status: "approved", review_reason: null, reviewed_by: caller.id, reviewed_at: now.toISOString() }),
    });
    if (!upd.ok) return json({ error: `update failed: ${await upd.text()}` }, 500);
    await fetch(`${SB}/rest/v1/audit_log`, {
      method: "POST", headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify({ action: "document.approved", entity: `${doc.kind} · ${worker_id}`, detail: { document_id, kind: doc.kind } }),
    });

    // ---- re-evaluate Stage 3 for this worker ----
    // Required docs come from portal_settings.onboarding_config (fallback default).
    const psRes = await fetch(`${SB}/rest/v1/portal_settings?id=eq.1&select=onboarding_config`, { headers: svc });
    const ps = await psRes.json();
    const cfg = (Array.isArray(ps) && ps[0]?.onboarding_config) || {};
    const reqDocs: any[] = Array.isArray(cfg.documents) && cfg.documents.length
      ? cfg.documents
      : [{ kind: "resume" }, { kind: "diploma" }, { kind: "nbi_clearance" }, { kind: "gov_id", sides: ["front", "back"] }];

    // approved docs for this worker, grouped by kind
    const apRes = await fetch(`${SB}/rest/v1/documents?worker_id=eq.${worker_id}&review_status=eq.approved&select=kind`, { headers: svc });
    const apRows = await apRes.json();
    const approvedCount: Record<string, number> = {};
    for (const r of (Array.isArray(apRows) ? apRows : [])) approvedCount[r.kind] = (approvedCount[r.kind] || 0) + 1;

    const stage3_complete = reqDocs.every((d) => {
      const need = Array.isArray(d.sides) ? d.sides.length : 1;   // gov_id needs front+back
      return (approvedCount[d.kind] || 0) >= need;
    });

    let onboarding_complete = false;
    if (stage3_complete) {
      // only finalize if stages 1 & 2 are already complete
      const opRes = await fetch(`${SB}/rest/v1/onboarding_progress?worker_id=eq.${worker_id}&select=stage1_complete,stage2_complete,completed_at`, { headers: svc });
      const op = (await opRes.json())?.[0] || {};
      const finalize = op.stage1_complete && op.stage2_complete;
      onboarding_complete = !!finalize && !op.completed_at;
      await fetch(`${SB}/rest/v1/onboarding_progress?worker_id=eq.${worker_id}`, {
        method: "PATCH", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({
          stage3_complete: true,
          current_stage: finalize ? "complete" : "stage3_docs",
          completed_at: finalize ? (op.completed_at || now.toISOString()) : null,
          updated_at: now.toISOString(),
        }),
      });
      if (onboarding_complete) {
        await fetch(`${SB}/rest/v1/audit_log`, {
          method: "POST", headers: { ...svc, Prefer: "return=minimal" },
          body: JSON.stringify({ action: "onboarding.completed", entity: `${worker_id}`, detail: { worker_id } }),
        });
      }
    }

    return json({ ok: true, review_status: "approved", stage3_complete, onboarding_complete });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
