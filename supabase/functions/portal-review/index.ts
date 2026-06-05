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

// Day-accurate freshness: add N months (UTC) and compare, so issue day matters.
function addMonths(d: Date, n: number): Date { const r = new Date(d); r.setUTCMonth(r.getUTCMonth() + n); return r; }
function isStale(issuedISO: string, months: number, now: Date): boolean {
  const issued = new Date(issuedISO + "T00:00:00Z");
  if (isNaN(issued.getTime())) return false;          // unparseable -> don't hard-fail (HR decides)
  return addMonths(issued, months).getTime() < now.getTime();
}

// Recompute Stage-3 completion from the AUTHORITATIVE approved-doc state and
// reconcile onboarding_progress. Used by BOTH approve and needs_replacement so
// completion is a pure function of current approvals (a rejection flips
// stage3_complete back to false). completed_at is MONOTONIC here: set once fully
// onboarded, never CLEARED by a review — a later rejection surfaces as
// "action needed" for HR but does not silently revoke a contractor's portal
// access; an admin re-locks explicitly via reopen_stage (M1 step 5).
//
// gov_id sides: for a kind that declares `sides` (e.g. front+back), completion
// requires an approved row for EACH configured side (matched on documents.side),
// not just N approved rows — two approved "front" uploads must NOT satisfy it.
// Non-sided kinds just need one approved row.
async function reEvalStage3(SB: string, svc: any, worker_id: string, cfg: any, now: Date) {
  const reqDocs: any[] = (Array.isArray(cfg.documents) && cfg.documents.length
    ? cfg.documents
    : [{ kind: "resume" }, { kind: "diploma" }, { kind: "nbi_clearance" }, { kind: "gov_id", sides: ["front", "back"] }]
  ).filter((d: any) => d.required !== false);          // honor optional docs

  // "cleared" = approved OR waived OR deferred. waive/defer clear the whole-kind
  // requirement (contractor isn't blocked); approved still needs each side.
  const apRes = await fetch(`${SB}/rest/v1/documents?worker_id=eq.${worker_id}&review_status=in.(approved,waived,deferred)&select=id,kind,side,storage_path,review_status`, { headers: svc });
  const apRows = (await apRes.json()) || [];
  const evidence: Record<string, Set<string>> = {};    // non-sided kinds: distinct storage_path/id
  const sidesSeen: Record<string, Set<string>> = {};   // sided kinds: distinct approved `side`
  const cleared: Record<string, boolean> = {};         // waived/deferred -> kind satisfied outright
  for (const r of apRows) {
    if (r.review_status === "waived" || r.review_status === "deferred") { cleared[r.kind] = true; continue; }
    (evidence[r.kind] ||= new Set()).add(r.storage_path || r.id);
    if (r.side) (sidesSeen[r.kind] ||= new Set()).add(r.side);
  }
  const stage3_complete = reqDocs.every((d: any) => {
    if (cleared[d.kind]) return true;
    if (Array.isArray(d.sides) && d.sides.length) {
      const have = sidesSeen[d.kind] || new Set<string>();
      return d.sides.every((s: string) => have.has(s));   // every configured side approved
    }
    return (evidence[d.kind]?.size || 0) >= 1;
  });

  const opRes = await fetch(`${SB}/rest/v1/onboarding_progress?worker_id=eq.${worker_id}&select=stage1_complete,stage2_complete,completed_at,current_stage`, { headers: svc });
  const op = (await opRes.json())?.[0] || {};
  const fully = !!(op.stage1_complete && op.stage2_complete && stage3_complete);
  const onboarding_complete = fully && !op.completed_at;

  const patch: Record<string, unknown> = { stage3_complete, updated_at: now.toISOString() };
  if (fully) {
    patch.completed_at = op.completed_at || now.toISOString();   // set once; coalesce existing
    patch.current_stage = "complete";
  } else if (!op.completed_at && op.stage1_complete && op.stage2_complete) {
    patch.current_stage = "stage3_docs";                         // only when genuinely in stage 3
  }                                                              // else: leave stage/completed_at untouched (no regression)
  await fetch(`${SB}/rest/v1/onboarding_progress?worker_id=eq.${worker_id}`, {
    method: "PATCH", headers: { ...svc, Prefer: "return=minimal" },
    body: JSON.stringify(patch),
  });
  return { stage3_complete, onboarding_complete };
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

    // ---- set_signed_date (admin correction of the editable "date signed") ----
    // Operates on a SIGNATURE, not a document, so it runs before the document_id
    // gate. Patches ONLY signed_date — the immutable evidence (signed_at, IP,
    // signature_data, signed_legal_name, doc hash) is never touched.
    if (action === "set_signed_date") {
      const sd = String(body.signed_date || "").trim();
      if (!/^\d{4}-\d{2}-\d{2}$/.test(sd)) return json({ error: "signed_date must be YYYY-MM-DD" }, 422);
      const wid = String(body.worker_id || "").trim();
      const ak = String(body.agreement_kind || "").trim();
      if (!wid || !ak) return json({ error: "worker_id and agreement_kind are required" }, 400);
      const upd = await fetch(`${SB}/rest/v1/onboarding_signatures?worker_id=eq.${wid}&agreement_kind=eq.${ak}&status=eq.signed`, {
        method: "PATCH", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ signed_date: sd }),
      });
      if (!upd.ok) return json({ error: `update failed: ${await upd.text()}` }, 500);
      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "signature.signed_date_set", actor: caller.email ?? null, entity: `${ak} · ${wid}`, detail: { worker_id: wid, agreement_kind: ak, signed_date: sd } }),
      });
      return json({ ok: true, signed_date: sd });
    }

    if (!["approve", "needs_replacement", "waive", "defer"].includes(action)) return json({ error: "unknown action" }, 400);
    if (!document_id) return json({ error: "document_id required" }, 400);

    // load the document under review
    const dRes = await fetch(`${SB}/rest/v1/documents?id=eq.${document_id}&select=id,worker_id,kind,issued_on,review_status`, { headers: svc });
    const dRows = await dRes.json();
    const doc = (Array.isArray(dRows) && dRows[0]) || null;
    if (!doc) return json({ error: "document not found" }, 404);
    const worker_id = doc.worker_id;
    const now = new Date();

    // onboarding_config drives required docs, sides, and NBI freshness window
    const psRes = await fetch(`${SB}/rest/v1/portal_settings?id=eq.1&select=onboarding_config`, { headers: svc });
    const cfg = ((await psRes.json())?.[0]?.onboarding_config) || {};

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
        body: JSON.stringify({ action: "document.needs_replacement", actor: caller.email ?? null, entity: `${doc.kind} · ${worker_id}`, detail: { document_id, kind: doc.kind, reason } }),
      });
      // recompute so a rejected doc flips stage3_complete back to false for HR
      const re = await reEvalStage3(SB, svc, worker_id, cfg, now);
      return json({ ok: true, review_status: "needs_replacement", stage3_complete: re.stage3_complete });
    }

    // ---- waive (drop the requirement) / defer (collect later) ----
    // Both clear the requirement so the contractor isn't blocked. "deferred" rows
    // surface in the Hiring & Onboarding tab as follow-ups; "waived" are done.
    if (action === "waive" || action === "defer") {
      const status = action === "waive" ? "waived" : "deferred";
      const reason = String(body.reason || "").trim() || null;
      const upd = await fetch(`${SB}/rest/v1/documents?id=eq.${document_id}`, {
        method: "PATCH", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ review_status: status, review_reason: reason, reviewed_by: caller.id, reviewed_at: now.toISOString() }),
      });
      if (!upd.ok) return json({ error: `update failed: ${await upd.text()}` }, 500);
      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: `document.${status}`, actor: caller.email ?? null, entity: `${doc.kind} · ${worker_id}`, detail: { document_id, kind: doc.kind, reason } }),
      });
      const re = await reEvalStage3(SB, svc, worker_id, cfg, now);
      return json({ ok: true, review_status: status, stage3_complete: re.stage3_complete, onboarding_complete: re.onboarding_complete });
    }

    // ---- approve ----
    // NBI freshness guard: day-accurate, using the configured freshness window.
    // The reviewing admin may override (they're looking at the actual document);
    // the override is recorded in the audit log below.
    if (doc.kind === "nbi_clearance" && doc.issued_on && !body.override) {
      const months = Number((cfg.documents || []).find((d: any) => d.kind === "nbi_clearance")?.freshness_months) || 6;
      if (isStale(doc.issued_on, months, now)) {
        return json({ error: `NBI clearance is older than ${months} months — request a replacement, or use “Approve anyway” to override`, code: "nbi_stale" }, 422);
      }
    }
    const upd = await fetch(`${SB}/rest/v1/documents?id=eq.${document_id}`, {
      method: "PATCH",
      headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify({ review_status: "approved", review_reason: null, reviewed_by: caller.id, reviewed_at: now.toISOString() }),
    });
    if (!upd.ok) return json({ error: `update failed: ${await upd.text()}` }, 500);
    await fetch(`${SB}/rest/v1/audit_log`, {
      method: "POST", headers: { ...svc, Prefer: "return=minimal" },
      body: JSON.stringify({ action: "document.approved", actor: caller.email ?? null, entity: `${doc.kind} · ${worker_id}`, detail: { document_id, kind: doc.kind, freshness_override: !!body.override } }),
    });

    const re = await reEvalStage3(SB, svc, worker_id, cfg, now);
    if (re.onboarding_complete) {
      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "onboarding.completed", actor: caller.email ?? null, entity: `${worker_id}`, detail: { worker_id } }),
      });
    }
    return json({ ok: true, review_status: "approved", stage3_complete: re.stage3_complete, onboarding_complete: re.onboarding_complete });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
