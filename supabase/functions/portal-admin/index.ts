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
//   { action: "create_login", worker_id, email, password?, send_emails? }
//        -> { ok, email, password, emailed }
//        On success, best-effort emails the new hire (1) their portal credentials
//        and (2) a Hubstaff welcome — both customizable, both non-fatal.
//   { action: "reset_password", worker_id, send_emails? }
//        -> { ok, email, password, emailed }   (re-emails the new credentials)
//   { action: "resend_hire_emails", worker_id, which?, password? }
//        -> { ok, emailed }   which = "welcome" (default) | "credentials" | "both"
//   { action: "update_login_and_resend", worker_id, email?, password? }
//        -> { ok, email, password, email_changed, emailed }
//        Corrects an in-flight hire: optionally changes the login email, issues a
//        fresh temp password, syncs contractor_logins/workers.email, re-sends welcome.
//   { action: "withdraw_offer", worker_id, send_email? }   -> { ok, email, emailed }
//        Revokes the login, bans the auth user, marks worker/company links "ended",
//        emails a withdrawal notice. Refuses if any payroll history exists.
//   { action: "revoke_login", worker_id }   -> { ok }
//   { action: "delete_contractor", worker_id, force? }   -> { ok, ... }
//
// New-hire emails are customizable in the app (Configuration → Onboarding setup),
// stored at portal_settings.onboarding_config.hire_emails. Transport is Gmail /
// Google Workspace SMTP (smtp.gmail.com:465) with an app password; credentials are
// read from env first, then the app_secrets table (settable via plain SQL):
//   gmail_user, gmail_app_password, email_from (optional From override).
// Without those, every send no-ops ({ email_configured:false }) and hiring is
// unaffected. Contractor-supplied values are HTML-escaped before templating.
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

// HTML-escape a value before it goes into an email body (prevents a contractor's
// name/work-email from injecting markup into the message HR/they receive).
function esc(x: unknown): string {
  return String(x ?? "").replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string));
}

// Default templates — overridable per-tenant via onboarding_config.hire_emails.
const DEFAULT_HIRE_EMAILS = {
  auto_send: true,
  portal_url: "https://portal.abbilabs.com",
  hubstaff_install_url: "https://hubstaff.com/download",
  wise_referral_url: "https://wise.com/invite/dic/olivert410",
  // Email 1 (sent at hire): thank-you + onboarding intro + Wise button + prepare
  // docs + login credentials, all in one. Merge: {{name}} {{wise_referral_url}}
  // {{portal_url}} {{email}} {{password}}.
  welcome: {
    subject: "Welcome to ABC Kids — let's get you onboarded",
    html: [
      "<p>Hi {{name}},</p>",
      "<p>Thank you for joining ABC Kids NY — we're excited to have you on the team! Here's how to get started.</p>",
      "<p><b>Your onboarding, in the portal:</b></p>",
      "<ol><li>Sign your agreements (IC Agreement, Non-Compete, NDA, BAA)</li><li>Complete your profile and billing / payout details</li><li>Upload your documents</li></ol>",
      "<p><b>First, set up Wise.</b> We pay in Philippine Pesos via Wise, so please create your Wise account now — you'll add your payout details during onboarding:</p>",
      "<p><a href=\"{{wise_referral_url}}\" style=\"display:inline-block;padding:11px 20px;background:#1F3A68;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:600\">Create your Wise account</a></p>",
      "<p><b>Please prepare these documents</b> to upload in the portal: Resume / CV, Diploma / TOR, NBI Clearance, and a Gov ID / Passport (front &amp; back).</p>",
      "<p><b>Your portal login</b><br>Portal: <a href=\"{{portal_url}}\">{{portal_url}}</a><br>Username: {{email}}<br>Temporary password: {{password}}</p>",
      "<p>You'll set your own password on first sign-in. Questions? Just reply to this email.</p>",
      "<p>Welcome aboard!<br>— ABC Kids NY</p>",
    ].join("\n"),
  },
  // Login-only email — reused when an admin RE-ISSUES a temp password (reset).
  credentials: {
    subject: "Your ABC Kids contractor portal login",
    html: [
      "<p>Hi {{name}},</p>",
      "<p>Here are your contractor portal sign-in details.</p>",
      "<p><b>Portal:</b> <a href=\"{{portal_url}}\">{{portal_url}}</a><br>",
      "<b>Username:</b> {{email}}<br>",
      "<b>Temporary password:</b> {{password}}</p>",
      "<p>You'll set your own password on first sign-in.</p>",
      "<p>— ABC Kids NY</p>",
    ].join("\n"),
  },
  // Email 2 (sent at onboarding completion): the provisioned tool logins.
  // {{tools_block}} is rendered server-side from the decrypted credentials.
  tools: {
    subject: "Your ABC Kids tool access",
    html: [
      "<p>Hi {{name}},</p>",
      "<p>Your onboarding is complete — here are the tool logins you'll need to get started:</p>",
      "{{tools_block}}",
      "<p>Please keep these secure and, where possible, change any passwords on first sign-in. You can also view them anytime in the portal.</p>",
      "<p>— ABC Kids NY</p>",
    ].join("\n"),
  },
  // Sent when an admin WITHDRAWS an offer / cancels an onboarding before it
  // completes. Polite, brief, no portal links (the login is revoked).
  withdraw: {
    subject: "Update on your ABC Kids offer",
    html: [
      "<p>Hi {{name}},</p>",
      "<p>Thank you for your interest in working with ABC Kids NY and for the time you've invested so far.</p>",
      "<p>After further review we won't be moving forward with onboarding at this time, and your contractor portal access has been deactivated.</p>",
      "<p>We're grateful for the opportunity to have connected, and we wish you all the best. If anything changes on our side, we'll be in touch.</p>",
      "<p>Warm regards,<br>— ABC Kids NY</p>",
    ].join("\n"),
  },
};

// Friendly labels for the provisioned tools.
const TOOL_LABEL: Record<string, string> = {
  gmail: "Company Gmail", providersoft: "Providersoft", hubstaff: "Hubstaff", zoom: "Zoom", others: "Other",
};
// Render the decrypted tool credentials into an HTML block. Generic over whatever
// fields the admin entered; every value is HTML-escaped.
function toolsBlock(creds: any): string {
  if (!creds || typeof creds !== "object") return "";
  return Object.entries(creds).map(([tool, fields]: [string, any]) => {
    const label = TOOL_LABEL[tool] || tool;
    const inner = (fields && typeof fields === "object")
      ? Object.entries(fields).filter(([, v]) => String(v ?? "").trim())
          .map(([k, v]) => `${esc(k)}: ${esc(String(v))}`).join("<br>")
      : esc(String(fields ?? ""));
    return inner ? `<p><b>${esc(label)}</b><br>${inner}</p>` : "";
  }).filter(Boolean).join("");
}

// Resolve the Gmail SMTP transport (env first, then app_secrets).
async function resolveTransport(SB: string, svc: any) {
  const user = Deno.env.get("GMAIL_USER") || (await secretVal(SB, svc, "gmail_user"));
  const pass = Deno.env.get("GMAIL_APP_PASSWORD") || (await secretVal(SB, svc, "gmail_app_password"));
  const from = Deno.env.get("HIRING_REVIEW_EMAIL_FROM") || (await secretVal(SB, svc, "email_from")) || (user ? `ABC Kids NY <${user}>` : "");
  return { user, pass, from, configured: !!(user && pass) };
}

function mergeTpl(s: string, vars: Record<string, string>): string {
  return String(s || "").replace(/\{\{\s*(\w+)\s*\}\}/g, (m, k) => (k in vars ? vars[k] : m));
}

// app_secrets lookup (service-role read) — fallback for transport credentials.
async function secretVal(SB: string, svc: any, key: string): Promise<string> {
  try {
    const r = await fetch(`${SB}/rest/v1/app_secrets?key=eq.${key}&select=value`, { headers: svc });
    const j = await r.json().catch(() => []);
    return (Array.isArray(j) && j[0]?.value) || "";
  } catch { return ""; }
}

// One email via Gmail SMTP, fresh connection per message. Never throws.
async function smtpSend(
  user: string, pass: string, from: string, to: string, subject: string, html: string,
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

async function loadHireCfg(SB: string, svc: any) {
  try {
    const res = await fetch(`${SB}/rest/v1/portal_settings?id=eq.1&select=onboarding_config`, { headers: svc });
    const rows = await res.json().catch(() => []);
    const he = (Array.isArray(rows) && rows[0]?.onboarding_config?.hire_emails) || {};
    return {
      ...DEFAULT_HIRE_EMAILS, ...he,
      credentials: { ...DEFAULT_HIRE_EMAILS.credentials, ...(he.credentials || {}) },
      welcome: { ...DEFAULT_HIRE_EMAILS.welcome, ...(he.welcome || {}) },
      tools: { ...DEFAULT_HIRE_EMAILS.tools, ...(he.tools || {}) },
      withdraw: { ...DEFAULT_HIRE_EMAILS.withdraw, ...(he.withdraw || {}) },
    };
  } catch {
    return DEFAULT_HIRE_EMAILS;
  }
}

// Best-effort: email a new hire their credentials and/or a Hubstaff welcome via
// Gmail SMTP. Never throws — a mail failure must not break hiring.
async function sendHireEmails(
  SB: string, svc: any, worker_id: string, loginEmail: string, password: string | null,
  opts: { credentials: boolean; welcome: boolean; force?: boolean },
) {
  const cfg = await loadHireCfg(SB, svc);
  const user = Deno.env.get("GMAIL_USER") || (await secretVal(SB, svc, "gmail_user"));
  const pass = Deno.env.get("GMAIL_APP_PASSWORD") || (await secretVal(SB, svc, "gmail_app_password"));
  const from = Deno.env.get("HIRING_REVIEW_EMAIL_FROM") || (await secretVal(SB, svc, "email_from")) || (user ? `ABC Kids NY <${user}>` : "");
  const email_configured = !!(user && pass);
  if (cfg.auto_send === false && !opts.force) return { skipped: true, email_configured };
  if (!email_configured) return { email_configured: false, credentials: null, welcome: null };

  const wRes = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}&select=first_name,middle_name,last_name,work_email`, { headers: svc });
  const w = (await wRes.json().catch(() => []))?.[0] || {};
  const name = [w.first_name, w.middle_name, w.last_name].filter(Boolean).join(" ").trim() || "there";
  // Hubstaff name lives on worker_companies and is usually empty for a brand-new
  // hire (set on first sync match) — fall back to the contractor's full name.
  const hcRes = await fetch(`${SB}/rest/v1/worker_companies?worker_id=eq.${worker_id}&hubstaff_name=not.is.null&select=hubstaff_name&limit=1`, { headers: svc });
  const hubstaff_name = ((await hcRes.json().catch(() => []))?.[0]?.hubstaff_name || name);
  const work_email = String(w.work_email || "").trim();
  // Escape contractor-derived values; leave admin-set config (URLs) and the
  // system-generated password as-is so the displayed password stays exact.
  const vars: Record<string, string> = {
    name: esc(name), email: esc(loginEmail), password: password || "",
    portal_url: cfg.portal_url, wise_referral_url: cfg.wise_referral_url || "",
    hubstaff_name: esc(hubstaff_name), hubstaff_install_url: cfg.hubstaff_install_url,
    work_email: esc(work_email), work_email_block: work_email ? `<p><b>Your company email:</b> ${esc(work_email)}</p>` : "",
  };
  const out: any = { email_configured: true };
  if (opts.credentials && password) out.credentials = await smtpSend(user, pass, from, loginEmail, mergeTpl(cfg.credentials.subject, vars), mergeTpl(cfg.credentials.html, vars));
  if (opts.welcome) out.welcome = await smtpSend(user, pass, from, loginEmail, mergeTpl(cfg.welcome.subject, vars), mergeTpl(cfg.welcome.html, vars));
  return out;
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

      const exRes = await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}&select=worker_id,email,status`, { headers: svc });
      const ex = await exRes.json();
      if (Array.isArray(ex) && ex.length) {
        return json({ error: `This contractor already has a portal login (${ex[0].email || "set"}, ${ex[0].status}).` }, 409);
      }

      // Guard: the email must not already belong to ANY auth account (another
      // contractor's login, an admin, or a leftover user). Without this, Supabase
      // Auth can reject the create OR silently return the EXISTING user — leaving a
      // login that can't actually sign in, with no error surfaced. Fail loudly here.
      const lkRes = await fetch(`${SB}/rest/v1/rpc/admin_lookup_auth_user`, {
        method: "POST", headers: svc, body: JSON.stringify({ p_email: email }),
      });
      if (lkRes.ok) {
        const existingId = await lkRes.json().catch(() => null);
        if (existingId && typeof existingId === "string" &&
            /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(existingId)) {
          return json({ error: `That email (${email}) is already in use by another account — use a different email for this contractor, or remove the existing account first.`, code: "email_taken" }, 409);
        }
      }

      const pw = String(body.password || "").trim() ||
        ("Abc-" + Math.random().toString(36).slice(2, 8) + "-" + Math.floor(Math.random() * 9000 + 1000));

      // must_set_password flag: the portal forces a password change on first
      // sign-in (the temp password is emailed in cleartext). Cleared by the
      // contractor's own updateUser() when they set their real password.
      const cRes = await fetch(`${SB}/auth/v1/admin/users`, {
        method: "POST", headers: svc,
        body: JSON.stringify({ email, password: pw, email_confirm: true, user_metadata: { must_set_password: true } }),
      });
      const cTxt = await cRes.text(); let cJson: any = null; try { cJson = JSON.parse(cTxt); } catch { /* */ }
      if (!cRes.ok) {
        return json({ error: `couldn't create login: ${cJson?.msg ?? cJson?.error_description ?? cTxt}` }, cRes.status);
      }
      const auth_user_id = cJson?.id ?? cJson?.user?.id;

      const lRes = await fetch(`${SB}/rest/v1/contractor_logins`, {
        method: "POST",
        headers: { ...svc, Prefer: "resolution=merge-duplicates,return=minimal" },
        body: JSON.stringify({ worker_id, auth_user_id, email, status: "active" }),
      });
      if (!lRes.ok) return json({ error: `login created but linking failed: ${await lRes.text()}` }, 500);

      // Provisioning hook: seed an onboarding row so the new hire is gated from
      // session 1 and shows in the admin Onboarding queue immediately. Idempotent.
      await fetch(`${SB}/rest/v1/onboarding_progress`, {
        method: "POST",
        headers: { ...svc, Prefer: "resolution=ignore-duplicates,return=minimal" },
        body: JSON.stringify({ worker_id, current_stage: "stage1_sign" }),
      }).catch(() => {});

      // Best-effort new-hire emails. send_emails:false suppresses; true forces past
      // the auto_send config toggle; otherwise the in-app setting (default on) decides.
      // One consolidated welcome at hire (credentials are folded into it).
      let emailed: any;
      if (body.send_emails !== false) {
        try {
          emailed = await sendHireEmails(SB, svc, worker_id, email, pw,
            { credentials: false, welcome: true, force: body.send_emails === true });
        } catch (_e) { emailed = { error: "send failed (non-fatal)" }; }
      }

      return json({ ok: true, email, password: pw, emailed });
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

    // Re-issue a temp password for an EXISTING contractor login.
    if (body.action === "reset_password") {
      const worker_id = body.worker_id;
      if (!worker_id) return json({ error: "need worker_id" }, 400);
      const exRes = await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}&select=auth_user_id,email,status`, { headers: svc });
      const ex = await exRes.json();
      const row = Array.isArray(ex) && ex[0];
      if (!row || !row.auth_user_id) return json({ error: "this contractor has no portal login yet — create one first" }, 404);
      const pw = String(body.password || "").trim() ||
        ("Abc-" + Math.random().toString(36).slice(2, 8) + "-" + Math.floor(Math.random() * 9000 + 1000));
      const upd = await fetch(`${SB}/auth/v1/admin/users/${row.auth_user_id}`, {
        method: "PUT", headers: svc, body: JSON.stringify({ password: pw, user_metadata: { must_set_password: true } }),
      });
      if (!upd.ok) return json({ error: `couldn't reset password: ${await upd.text()}` }, upd.status);
      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "portal_login.reset_password", actor: caller.email ?? null, entity: `${row.email || worker_id}`, detail: { worker_id } }),
      });

      let emailed: any;
      if (body.send_emails !== false) {
        try {
          emailed = await sendHireEmails(SB, svc, worker_id, row.email, pw,
            { credentials: true, welcome: false, force: true });
        } catch (_e) { emailed = { error: "send failed (non-fatal)" }; }
      }
      return json({ ok: true, email: row.email, password: pw, emailed });
    }

    // Re-send the new-hire emails from the admin UI. 'credentials'/'both' need a
    // password passed in (not stored); 'welcome' (default) needs none.
    if (body.action === "resend_hire_emails") {
      const worker_id = body.worker_id;
      if (!worker_id) return json({ error: "need worker_id" }, 400);
      const exRes = await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}&select=email,status`, { headers: svc });
      const ex = await exRes.json();
      const row = Array.isArray(ex) && ex[0];
      if (!row?.email) return json({ error: "this contractor has no portal login yet — create one first" }, 404);
      const which = ["welcome", "credentials", "both"].includes(body.which) ? body.which : "welcome";
      const pw = String(body.password || "").trim() || null;
      const emailed = await sendHireEmails(SB, svc, worker_id, row.email, pw, {
        credentials: which !== "welcome", welcome: which !== "credentials", force: true,
      }).catch((_e) => ({ error: "send failed" }));
      return json({ ok: true, email: row.email, emailed });
    }

    // Correct an in-flight hire and re-send the welcome. Optionally changes the
    // portal login email to a fixed address (e.g. a typo'd one), ALWAYS issues a
    // fresh temp password (the prior one may have gone to the wrong inbox), keeps
    // contractor_logins + workers.email in sync, and re-sends the welcome with the
    // corrected details. Pair with editing the hire's profile/contract first.
    if (body.action === "update_login_and_resend") {
      const worker_id = body.worker_id;
      if (!worker_id) return json({ error: "need worker_id" }, 400);
      const newEmail = String(body.email || "").trim().toLowerCase();
      if (newEmail && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(newEmail)) return json({ error: "that doesn't look like a valid email address" }, 400);
      const exRes = await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}&select=auth_user_id,email,status`, { headers: svc });
      const ex = await exRes.json();
      const row = Array.isArray(ex) && ex[0];
      if (!row || !row.auth_user_id) return json({ error: "this contractor has no portal login yet — create one first" }, 404);

      const emailChanged = !!newEmail && newEmail !== String(row.email || "").toLowerCase();
      const pw = String(body.password || "").trim() ||
        ("Abc-" + Math.random().toString(36).slice(2, 8) + "-" + Math.floor(Math.random() * 9000 + 1000));

      // Auth user: new email (if changed) + fresh temp password + re-arm the
      // first-sign-in forced reset.
      const authPatch: any = { password: pw, email_confirm: true, user_metadata: { must_set_password: true } };
      if (emailChanged) authPatch.email = newEmail;
      const upd = await fetch(`${SB}/auth/v1/admin/users/${row.auth_user_id}`, {
        method: "PUT", headers: svc, body: JSON.stringify(authPatch),
      });
      if (!upd.ok) {
        const t = await upd.text();
        const dup = /already.*(registered|exists)|duplicate/i.test(t);
        return json({ error: dup ? "another login already uses that email address" : `couldn't update login: ${t}` }, upd.status);
      }
      const effEmail = emailChanged ? newEmail : row.email;
      if (emailChanged) {
        await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}`, {
          method: "PATCH", headers: { ...svc, Prefer: "return=minimal" }, body: JSON.stringify({ email: newEmail }),
        }).catch(() => {});
        await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}`, {
          method: "PATCH", headers: { ...svc, Prefer: "return=minimal" }, body: JSON.stringify({ email: newEmail }),
        }).catch(() => {});
      }
      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "portal_login.update_resend", actor: caller.email ?? null, entity: effEmail, detail: { worker_id, email_changed: emailChanged } }),
      });

      let emailed: any;
      try {
        emailed = await sendHireEmails(SB, svc, worker_id, effEmail, pw, { credentials: false, welcome: true, force: true });
      } catch (_e) { emailed = { error: "send failed (non-fatal)" }; }
      return json({ ok: true, email: effEmail, password: pw, email_changed: emailChanged, emailed });
    }

    // Withdraw a pending offer / cancel onboarding before completion: revoke the
    // portal login, ban the auth user (blocks sign-in), mark the worker + their
    // company links "ended" (drops them from active rosters), and email the
    // candidate a withdrawal notice. Refuses if any payroll history exists — that
    // is a real engagement, not a pending offer (deactivate on the roster instead).
    if (body.action === "withdraw_offer") {
      const worker_id = body.worker_id;
      if (!worker_id || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(String(worker_id)))
        return json({ error: "valid worker_id (uuid) required" }, 400);

      const probe = async (table: string) => {
        const res = await fetch(`${SB}/rest/v1/${table}?worker_id=eq.${worker_id}&select=worker_id&limit=1`, { headers: svc });
        if (!res.ok) return { ok: false, n: 0 };
        const j = await res.json().catch(() => null);
        return { ok: Array.isArray(j), n: Array.isArray(j) ? j.length : 0 };
      };
      const [pay, te] = await Promise.all([probe("payments"), probe("time_entries")]);
      if (!pay.ok || !te.ok) return json({ error: "couldn't verify payroll history — withdraw aborted, please retry", code: "guard_error" }, 502);
      if (pay.n || te.n) return json({ error: "This contractor has payroll history — an offer can't be withdrawn. Deactivate them on the roster instead.", code: "has_history" }, 409);

      const wRes = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}&select=first_name,middle_name,last_name,email`, { headers: svc });
      const w = (await wRes.json().catch(() => []))?.[0] || {};
      const name = [w.first_name, w.middle_name, w.last_name].filter(Boolean).join(" ").trim() || "there";
      const clRes = await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}&select=auth_user_id,email`, { headers: svc });
      const cl = (await clRes.json().catch(() => []))?.[0] || {};
      const to = String(cl.email || w.email || "").trim();

      await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}`, {
        method: "PATCH", headers: { ...svc, Prefer: "return=minimal" }, body: JSON.stringify({ status: "revoked" }),
      }).catch(() => {});
      if (cl.auth_user_id) await fetch(`${SB}/auth/v1/admin/users/${cl.auth_user_id}`, {
        method: "PUT", headers: svc, body: JSON.stringify({ ban_duration: "876000h" }),
      }).catch(() => {});
      await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}`, {
        method: "PATCH", headers: { ...svc, Prefer: "return=minimal" }, body: JSON.stringify({ status: "ended" }),
      }).catch(() => {});
      await fetch(`${SB}/rest/v1/worker_companies?worker_id=eq.${worker_id}`, {
        method: "PATCH", headers: { ...svc, Prefer: "return=minimal" }, body: JSON.stringify({ status: "ended" }),
      }).catch(() => {});

      let emailed: any = { skipped: true };
      if (body.send_email !== false && to) {
        try {
          const cfg = await loadHireCfg(SB, svc);
          const t = await resolveTransport(SB, svc);
          emailed = t.configured
            ? await smtpSend(t.user, t.pass, t.from, to, mergeTpl(cfg.withdraw.subject, { name: esc(name) }), mergeTpl(cfg.withdraw.html, { name: esc(name) }))
            : { email_configured: false };
        } catch (_e) { emailed = { error: "send failed (non-fatal)" }; }
      }
      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "withdraw_offer", actor: caller.email ?? null, entity: to || worker_id, detail: { worker_id } }),
      });
      return json({ ok: true, email: to, emailed });
    }

    // Email 2: deliver the (decrypted) tool logins after the admin provisions them
    // at onboarding completion. Credentials are decrypted server-side only.
    if (body.action === "send_tools_email") {
      const worker_id = body.worker_id;
      if (!worker_id) return json({ error: "need worker_id" }, 400);
      const exRes = await fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}&select=email`, { headers: svc });
      const row = (await exRes.json().catch(() => []))?.[0];
      if (!row?.email) return json({ error: "this contractor has no portal login yet" }, 404);
      const dRes = await fetch(`${SB}/rest/v1/rpc/decrypt_worker_tools`, {
        method: "POST", headers: svc, body: JSON.stringify({ p_worker_id: worker_id }),
      });
      const creds = await dRes.json().catch(() => null);
      if (!creds || typeof creds !== "object") return json({ error: "no tool credentials stored for this contractor" }, 404);
      const wRes = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}&select=first_name,middle_name,last_name`, { headers: svc });
      const w = (await wRes.json().catch(() => []))?.[0] || {};
      const name = [w.first_name, w.middle_name, w.last_name].filter(Boolean).join(" ").trim() || "there";
      const cfg = await loadHireCfg(SB, svc);
      const t = await resolveTransport(SB, svc);
      if (!t.configured) return json({ ok: true, email: row.email, emailed: { email_configured: false } });
      const vars = { name: esc(name), portal_url: cfg.portal_url, tools_block: toolsBlock(creds) };
      const res = await smtpSend(t.user, t.pass, t.from, row.email, mergeTpl(cfg.tools.subject, vars), mergeTpl(cfg.tools.html, vars));
      return json({ ok: true, email: row.email, emailed: res });
    }

    // Permanently delete a contractor. Two tiers of protection, enforced here
    // (server-side, unbypassable):
    //   - ABSOLUTE block if any payments / time_entries exist (financial records
    //     must be retained — the UI offers Deactivate instead).
    //   - Signed legal records (onboarding_signatures eSign ledger, documents)
    //     are destroyed only with an explicit { force: true } (a stronger UI confirm).
    // Both probes FAIL CLOSED: any non-ok / non-array response aborts the delete.
    if (body.action === "delete_contractor") {
      const worker_id = body.worker_id;
      if (!worker_id || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(String(worker_id)))
        return json({ error: "valid worker_id (uuid) required" }, 400);
      const force = body.force === true;

      const probe = async (table: string, sel: string) => {
        const res = await fetch(`${SB}/rest/v1/${table}?worker_id=eq.${worker_id}&select=${sel}&limit=1`, { headers: svc });
        if (!res.ok) return { ok: false, n: 0 };
        const j = await res.json().catch(() => null);
        if (!Array.isArray(j)) return { ok: false, n: 0 };
        return { ok: true, n: j.length };
      };

      const [pay, te] = await Promise.all([probe("payments", "id"), probe("time_entries", "work_date")]);
      if (!pay.ok || !te.ok) return json({ error: "couldn't verify payroll history — delete aborted, please retry", code: "guard_error" }, 502);
      if (pay.n || te.n) return json({ error: "This contractor has payroll history (payments or time entries) and can't be deleted — deactivate them instead.", code: "has_history" }, 409);

      const [sig, doc] = await Promise.all([probe("onboarding_signatures", "id"), probe("documents", "id")]);
      if (!sig.ok || !doc.ok) return json({ error: "couldn't verify contractor records — delete aborted, please retry", code: "guard_error" }, 502);
      if (!force && (sig.n || doc.n))
        return json({ error: "This contractor has signed agreements / uploaded documents.", code: "has_records", signatures: sig.n, documents: doc.n }, 409);

      const [docRes, clRes] = await Promise.all([
        fetch(`${SB}/rest/v1/documents?worker_id=eq.${worker_id}&select=storage_path`, { headers: svc }),
        fetch(`${SB}/rest/v1/contractor_logins?worker_id=eq.${worker_id}&select=auth_user_id`, { headers: svc }),
      ]);
      const docs = await docRes.json().catch(() => []);
      const paths = (Array.isArray(docs) ? docs : []).map((d: any) => d.storage_path).filter(Boolean);
      const cl = await clRes.json().catch(() => []);
      const auth_user_id = (Array.isArray(cl) && cl[0]?.auth_user_id) || null;

      const delRes = await fetch(`${SB}/rest/v1/workers?id=eq.${worker_id}`, {
        method: "DELETE", headers: { ...svc, Prefer: "return=minimal" },
      });
      if (!delRes.ok) return json({ error: `delete failed: ${await delRes.text()}` }, 500);

      if (paths.length) await fetch(`${SB}/storage/v1/object/contractor-docs`, { method: "DELETE", headers: svc, body: JSON.stringify({ prefixes: paths }) }).catch(() => {});
      if (auth_user_id) await fetch(`${SB}/auth/v1/admin/users/${auth_user_id}`, { method: "DELETE", headers: svc }).catch(() => {});

      await fetch(`${SB}/rest/v1/audit_log`, {
        method: "POST", headers: { ...svc, Prefer: "return=minimal" },
        body: JSON.stringify({ action: "delete_contractor", actor: caller.email ?? null, entity: worker_id, detail: { worker_id, force, signatures: sig.n, documents: doc.n, files_removed: paths.length, login_removed: !!auth_user_id } }),
      });
      return json({ ok: true, files_removed: paths.length, login_removed: !!auth_user_id });
    }

    return json({ error: "unknown action" }, 400);
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
