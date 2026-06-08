// Supabase Edge Function: documents-expiry-check
// ---------------------------------------------------------------------------
// Finds tracked documents (IC agreements, W-8BENs, gov IDs) that are expiring
// soon or already overdue, and — if an email provider is configured — emails a
// digest to the admin. Designed to be run on a schedule (daily) via Supabase
// scheduled functions / pg_cron, so the admin gets reminded even when the
// Documents tab isn't open.
//
// Deploy:
//   supabase functions deploy documents-expiry-check --no-verify-jwt
//
// Schedule (Supabase Dashboard → Edge Functions → Schedules, or pg_cron):
//   daily, e.g. cron "0 13 * * *"  (13:00 UTC = 21:00 Manila)
//   POST body: {} (or { "within_days": 30 } to override the window)
//
// Email (optional): set these secrets to enable the digest email. Without them
// the function still runs and RETURNS the expiring list as JSON (so you can
// call it ad hoc, or wire your own notifier):
//   supabase secrets set DOC_REMINDER_EMAIL_TO="otrinidad@abckidsny.com"
//   supabase secrets set RESEND_API_KEY="re_..."          (https://resend.com)
//   supabase secrets set DOC_REMINDER_EMAIL_FROM="payroll@yourdomain.com"
//                         (must be a Resend-verified sender)
//
// Returns:
//   { within_days, overdue: [...], expiring_soon: [...], emailed: bool,
//     email_error?: string }
//   Each doc: { worker, company, kind, title, expires_on, days }
//   (days < 0 = overdue, >= 0 = days until expiry)
// ---------------------------------------------------------------------------

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

const KIND_LABEL: Record<string, string> = {
  ic_agreement: "IC Agreement", w8ben: "W-8BEN", gov_id: "Gov ID", other: "Other",
};

// Whole-day difference between an ISO date (YYYY-MM-DD) and today (UTC).
// Negative = past (overdue), 0 = today, positive = future.
function daysUntil(dateStr: string, today: Date): number {
  const d = new Date(dateStr + "T00:00:00Z").getTime();
  const t = new Date(today.toISOString().slice(0, 10) + "T00:00:00Z").getTime();
  return Math.round((d - t) / 86_400_000);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    if (!SB_URL || !SB_KEY) return json({ error: "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set" }, 500);
    const body = await req.json().catch(() => ({}));

    // --- caller authorization -------------------------------------------------
    // Schedule-driven, service-role read of contractor PII (names + companies +
    // document kinds). Require the cron secret (for the scheduled job) OR a valid
    // admin JWT (for an ad-hoc admin call). Never open to the bare anon key.
    {
      let authed = false;
      const cronSecret = req.headers.get("x-cron-secret");
      if (cronSecret) {
        const sRes = await fetch(`${SB_URL}/rest/v1/app_secrets?key=eq.cron_secret&select=value`, { headers: restHdr });
        const secrets = await sRes.json().catch(() => []);
        const expected = Array.isArray(secrets) && secrets[0]?.value;
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
    // --------------------------------------------------------------------------

    const withinDays = Number(body.within_days ?? 30);
    const today = new Date();

    // Pull docs that have an expiry and join contractor + company names. Bound the
    // query server-side to an upper expiry date (today + window, +1 day of slack so
    // the time-of-day-aware JS filter below is still authoritative) — this keeps all
    // overdue rows and everything in the window while dropping far-future docs, and
    // avoids PostgREST's 1000-row cap silently truncating the result. The explicit
    // date comparison also excludes NULLs, so a separate not-null filter is redundant.
    const upper = new Date(today.getTime() + (withinDays + 1) * 86400000).toISOString().slice(0, 10);
    const qs = new URLSearchParams();
    qs.set("select",
      "id,kind,title,expires_on,worker_id," +
      "workers(first_name,middle_name,last_name,status)," +
      "companies(name)");
    qs.set("expires_on", "lte." + upper);
    qs.set("order", "expires_on.asc");
    const r = await fetch(`${SB_URL}/rest/v1/documents?${qs}`, { headers: restHdr });
    if (!r.ok) return json({ error: `documents fetch ${r.status}: ${await r.text()}` }, 500);
    const docs: any[] = await r.json();

    const fullName = (w: any) =>
      [w?.first_name, w?.middle_name, w?.last_name].filter(Boolean).join(" ").trim() || "(unknown)";

    const overdue: any[] = [];
    const expiringSoon: any[] = [];
    for (const d of docs) {
      // Skip docs for ended/inactive contractors — no point chasing a renewal
      // for someone no longer engaged.
      if (d.workers?.status && d.workers.status !== "active") continue;
      const days = daysUntil(d.expires_on, today);
      const entry = {
        worker: fullName(d.workers), company: d.companies?.name ?? "",
        kind: KIND_LABEL[d.kind] ?? d.kind, title: d.title ?? "",
        expires_on: d.expires_on, days,
      };
      if (days < 0) overdue.push(entry);
      else if (days <= withinDays) expiringSoon.push(entry);
    }

    // Nothing to report → succeed quietly (so a daily cron is silent on clean days).
    if (!overdue.length && !expiringSoon.length) {
      return json({ within_days: withinDays, overdue: [], expiring_soon: [], emailed: false,
        note: "no documents overdue or expiring within the window" });
    }

    // Optional email digest via Resend.
    const RESEND = Deno.env.get("RESEND_API_KEY");
    const TO = Deno.env.get("DOC_REMINDER_EMAIL_TO");
    const FROM = Deno.env.get("DOC_REMINDER_EMAIL_FROM");
    let emailed = false;
    let email_error: string | undefined;

    if (RESEND && TO && FROM) {
      const line = (e: any) =>
        `<li><b>${e.worker}</b>${e.company ? ` (${e.company})` : ""} — ${e.kind}` +
        `${e.title ? ` “${e.title}”` : ""}: ${e.days < 0 ? `overdue ${Math.abs(e.days)}d` : `in ${e.days}d`}` +
        ` (expires ${e.expires_on})</li>`;
      const html =
        `<h2>Document expiry reminder</h2>` +
        (overdue.length ? `<h3>Overdue (${overdue.length})</h3><ul>${overdue.map(line).join("")}</ul>` : "") +
        (expiringSoon.length ? `<h3>Expiring within ${withinDays} days (${expiringSoon.length})</h3><ul>${expiringSoon.map(line).join("")}</ul>` : "") +
        `<p style="color:#666;font-size:12px">Open the HR &amp; Payroll app → Documents tab to renew.</p>`;
      try {
        const er = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: { Authorization: `Bearer ${RESEND}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            from: FROM, to: [TO],
            subject: `Document reminders: ${overdue.length} overdue, ${expiringSoon.length} expiring soon`,
            html,
          }),
        });
        if (er.ok) emailed = true;
        else email_error = `resend ${er.status}: ${await er.text()}`;
      } catch (e) {
        email_error = String((e as any)?.message ?? e);
      }
    }

    return json({ within_days: withinDays, overdue, expiring_soon: expiringSoon, emailed, email_error });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
