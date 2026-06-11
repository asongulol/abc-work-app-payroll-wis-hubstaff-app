// Supabase Edge Function: hiring-docs-review-check
// ---------------------------------------------------------------------------
// Finds NEW-HIRE onboarding documents (Resume, Diploma/TOR, NBI Clearance,
// Gov ID) that a contractor has uploaded and that are WAITING FOR HR REVIEW
// (documents.review_status = 'pending') — plus, optionally, documents that were
// 'deferred' and still need follow-up. When there's anything to act on it emails
// a digest to the configured recipients via Gmail SMTP.
//
// Email transport: Gmail / Google Workspace SMTP (smtp.gmail.com:465) using an
// app password. Credentials are read from env first, then the app_secrets table
// (so they can be set with plain SQL — no CLI). Keys:
//   gmail_user           the sending mailbox (also the SMTP username)
//   gmail_app_password    a Google app password (account needs 2FA)
//   email_from            optional "Name <addr>" From; defaults to gmail_user
// Without those, the function still computes and returns JSON (email_configured:false).
//
// Configuration: portal_settings.onboarding_config.review_notify
//   { enabled, recipients[], frequency: daily|weekdays|weekly, include_deferred }
// Cron fires daily; `frequency` decides which days actually send.
// Body: { today?:'YYYY-MM-DD', dry_run?:bool, force?:bool }
// ---------------------------------------------------------------------------

import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SB_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const restHdr = { apikey: SB_KEY, Authorization: `Bearer ${SB_KEY}`, "Content-Type": "application/json" };

const ONB_DOC_KINDS = ["resume", "diploma", "nbi_clearance", "gov_id"];
const KIND_LABEL: Record<string, string> = {
  resume: "Resume / CV", diploma: "Diploma / TOR", nbi_clearance: "NBI Clearance", gov_id: "Gov ID / Passport",
};
function docLabel(kind: string, side: string | null): string {
  const base = KIND_LABEL[kind] ?? kind;
  return side ? `${base} (${side})` : base;
}
function isEmail(s: unknown): boolean {
  return typeof s === "string" && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s.trim());
}
// HTML-escape contractor-supplied values before they go into the digest HTML.
function esc(x: unknown): string {
  return String(x ?? "").replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string));
}

// app_secrets lookup (service-role read) — fallback for transport credentials.
async function secretVal(key: string): Promise<string> {
  try {
    const r = await fetch(`${SB_URL}/rest/v1/app_secrets?key=eq.${key}&select=value`, { headers: restHdr });
    const j = await r.json().catch(() => []);
    return (Array.isArray(j) && j[0]?.value) || "";
  } catch { return ""; }
}

// Send one email via Gmail SMTP. Fresh connection per message (low volume) so a
// hiccup on one send never poisons another. Never throws.
async function smtpSend(
  user: string, pass: string, from: string, to: string[], subject: string, html: string,
): Promise<{ ok: boolean; error?: string }> {
  let client: SMTPClient | undefined;
  try {
    client = new SMTPClient({
      connection: { hostname: "smtp.gmail.com", port: 465, tls: true, auth: { username: user, password: pass } },
    });
    await client.send({ from, to, subject, html });
    return { ok: true };
  } catch (e) {
    return { ok: false, error: String((e as any)?.message ?? e) };
  } finally {
    try { if (client) await client.close(); } catch { /* ignore */ }
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    if (!SB_URL || !SB_KEY) return json({ error: "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set" }, 500);
    const body = await req.json().catch(() => ({}));
    const dryRun = body.dry_run === true;
    const force = body.force === true;

    // --- caller authorization (cron secret OR admin JWT; never bare anon) ------
    {
      let authed = false;
      const cronSecret = req.headers.get("x-cron-secret");
      if (cronSecret) {
        const expected = await secretVal("cron_secret");
        if (!expected || cronSecret !== expected) return json({ error: "invalid cron secret" }, 401);
        authed = true;
      }
      if (!authed) {
        const bearer = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
        if (!bearer) return json({ error: "missing auth" }, 401);
        const uRes = await fetch(`${SB_URL}/auth/v1/user`, { headers: { Authorization: `Bearer ${bearer}`, apikey: SB_KEY } });
        if (!uRes.ok) return json({ error: "invalid session" }, 401);
        const caller = await uRes.json().catch(() => null);
        if (!caller?.id) return json({ error: "invalid session" }, 401);
        const aRes = await fetch(`${SB_URL}/rest/v1/admin_users?user_id=eq.${caller.id}&select=user_id`, { headers: restHdr });
        const admins = await aRes.json().catch(() => []);
        if (!Array.isArray(admins) || !admins.length) return json({ error: "not authorized — admins only" }, 403);
      }
    }

    // --- in-app configuration (recipients, cadence, on/off) -------------------
    const cfgRes = await fetch(`${SB_URL}/rest/v1/portal_settings?id=eq.1&select=onboarding_config`, { headers: restHdr });
    const cfgRows = await cfgRes.json().catch(() => []);
    const notify = (Array.isArray(cfgRows) && cfgRows[0]?.onboarding_config?.review_notify) || {};
    const enabled = notify.enabled !== false;
    const includeDeferred = notify.include_deferred !== false;
    const frequency = ["daily", "weekdays", "weekly"].includes(notify.frequency) ? notify.frequency : "daily";
    let recipients: string[] = Array.isArray(notify.recipients) ? notify.recipients.filter(isEmail) : [];
    if (!recipients.length) {
      const fb = Deno.env.get("DOC_REMINDER_EMAIL_TO") || (await secretVal("review_email_to"));
      if (isEmail(fb)) recipients = [fb];
    }
    recipients = Array.from(new Set(recipients.map((r) => r.trim())));

    // --- cadence gate ---------------------------------------------------------
    const todayStr = typeof body.today === "string" && /^\d{4}-\d{2}-\d{2}$/.test(body.today)
      ? body.today : new Date().toISOString().slice(0, 10);
    const dow = new Date(todayStr + "T00:00:00Z").getUTCDay();
    const scheduleAllows = force || frequency === "daily"
      || (frequency === "weekdays" && dow >= 1 && dow <= 5)
      || (frequency === "weekly" && dow === 1);

    // --- onboarding-kind documents + contractor/company names -----------------
    const qs = new URLSearchParams();
    qs.set("select",
      "id,kind,side,review_status,created_at,worker_id," +
      "workers(first_name,middle_name,last_name,status,email)," +
      "companies(name)");
    qs.set("kind", `in.(${ONB_DOC_KINDS.join(",")})`);
    qs.set("order", "created_at.desc");
    const r = await fetch(`${SB_URL}/rest/v1/documents?${qs}`, { headers: restHdr });
    if (!r.ok) return json({ error: `documents fetch ${r.status}: ${await r.text()}` }, 500);
    const docs: any[] = await r.json();

    const fullName = (w: any) =>
      [w?.first_name, w?.middle_name, w?.last_name].filter(Boolean).join(" ").trim() || "(unknown)";

    // Latest doc per (worker,kind,side) — mirrors the app's _latestDoc logic.
    const latest: Record<string, any> = {};
    for (const d of docs) {
      if (d.workers?.status && d.workers.status !== "active") continue;
      const k = `${d.worker_id}|${d.kind}|${d.side ?? ""}`;
      const at = d.created_at || "";
      if (!latest[k] || at > (latest[k].created_at || "")) latest[k] = d;
    }

    const byWorker: Record<string, any> = {};
    for (const d of Object.values(latest)) {
      const bucket = d.review_status === "pending" ? "pending"
        : d.review_status === "deferred" ? "deferred" : null;
      if (!bucket) continue;
      if (bucket === "deferred" && !includeDeferred) continue;
      const wid = d.worker_id;
      (byWorker[wid] ||= {
        worker: fullName(d.workers), company: d.companies?.name ?? "",
        email: d.workers?.email ?? "", pending: [], deferred: [],
      })[bucket].push(docLabel(d.kind, d.side));
    }

    const contractors = Object.values(byWorker).sort((a: any, b: any) => a.worker.localeCompare(b.worker));
    const pendingContractors = contractors.filter((c: any) => c.pending.length);
    const deferredContractors = contractors.filter((c: any) => c.deferred.length);
    const pendingDocs = pendingContractors.reduce((n: number, c: any) => n + c.pending.length, 0);
    const deferredDocs = deferredContractors.reduce((n: number, c: any) => n + c.deferred.length, 0);

    const summary = {
      ok: true,
      pending_contractors: pendingContractors.length, pending_docs: pendingDocs,
      deferred_contractors: deferredContractors.length, deferred_docs: deferredDocs,
      contractors, recipients, enabled, frequency, schedule_allows: scheduleAllows,
    };

    if (!pendingDocs && !deferredDocs) {
      return json({ ...summary, emailed: false, note: "nothing waiting for review" });
    }

    // --- transport (Gmail SMTP) ----------------------------------------------
    const GMAIL_USER = Deno.env.get("GMAIL_USER") || (await secretVal("gmail_user"));
    const GMAIL_PASS = Deno.env.get("GMAIL_APP_PASSWORD") || (await secretVal("gmail_app_password"));
    const FROM = Deno.env.get("HIRING_REVIEW_EMAIL_FROM") || (await secretVal("email_from")) || (GMAIL_USER ? `ABC Kids NY <${GMAIL_USER}>` : "");
    const email_configured = !!(GMAIL_USER && GMAIL_PASS);
    const would_email = enabled && !dryRun && scheduleAllows && recipients.length > 0 && email_configured;

    let emailed = false;
    let email_error: string | undefined;
    if (would_email) {
      const liItems = (arr: string[]) => arr.map((x) => `<li>${esc(x)}</li>`).join("");
      const section = (title: string, list: any[], key: "pending" | "deferred", color: string) =>
        !list.length ? "" :
        `<h3 style="color:${color}">${title}</h3><ul style="margin:0 0 12px">` +
        list.map((c: any) =>
          `<li><b>${esc(c.worker)}</b>${c.company ? ` <span style="color:#666">(${esc(c.company)})</span>` : ""}` +
          `<ul>${liItems(c[key])}</ul></li>`).join("") + `</ul>`;
      const html =
        `<h2>Hiring documents need review</h2>` +
        `<p>${pendingDocs} document(s) from ${pendingContractors.length} contractor(s) are waiting for HR review.</p>` +
        section(`Waiting for review (${pendingDocs})`, pendingContractors, "pending", "#b45309") +
        (deferredDocs ? section(`Deferred — follow up (${deferredDocs})`, deferredContractors, "deferred", "#3730a3") : "") +
        `<p style="color:#666;font-size:12px">Open the HR &amp; Payroll app → Hiring &amp; Onboarding to review (Approve / Needs replacement / Waive / Defer).</p>`;
      const subject = `Hiring docs to review: ${pendingDocs} waiting${deferredDocs ? `, ${deferredDocs} follow-up` : ""}`;
      const res = await smtpSend(GMAIL_USER, GMAIL_PASS, FROM, recipients, subject, html);
      emailed = res.ok;
      if (!res.ok) email_error = res.error;
    }

    return json({ ...summary, dry_run: dryRun, email_configured, would_email, emailed, email_error });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
