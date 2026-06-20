// Supabase Edge Function: wise-payouts  (v1)
// ---------------------------------------------------------------------------
// DRAFTS Wise transfers for a locked payroll batch and returns the locked FX
// rate + transfer IDs. It DOES NOT fund (move money). Funding is done by the
// user in Wise directly. The Wise API token lives ONLY here (server secret).
//
// Safety: this function only creates QUOTES and DRAFT TRANSFERS. It never calls
// the funding endpoint (POST .../transfers/{id}/payments). Money does not move.
//
// Deploy:
//   supabase functions deploy wise-payouts --no-verify-jwt
//   supabase secrets set WISE_API_TOKEN="...personal API token..."
//   (optional) supabase secrets set WISE_API_BASE="https://api.wise.com"   // sandbox: https://api.sandbox.transferwise.tech
//
// Actions (POST body):
//   { action: "profile" }                          -> { profile_id }
//   { action: "draft", items: [ { worker_id, name, recipient_id, amount_php } ] }
//        -> { results: [ { worker_id, transfer_id?, fx_rate?, status, error? } ] }
//   { action: "batch", name, items: [ {worker_id, recipient_id, amount_php} ] }
//        -> { batch_group_id, results: [...] }   (group created + transfers added;
//            NOT completed, NOT funded — you complete & fund in Wise)
//   { action: "status", transfer_ids: [..] }       -> { statuses: [ {id, status} ] }
//   { action: "rates",  transfer_ids: [..] }        -> { rates: [ {id, rate, status, sourceValue, targetValue, ...} ] }  (read-only GET; no money moves)
//   { action: "poll", pay_period_id?: uuid, only_drafts?: boolean }
//        -> { checked, marked_paid, in_flight, unknown, results: [...] }
//        Server-side reconcile: pulls every payment with a wise_transfer_id
//        (optionally scoped to one period, optionally restricted to status='draft'),
//        queries Wise, and updates payments.status to 'sent' for terminal-success
//        states. Idempotent. Safe to call on a schedule. Requires SUPABASE_URL +
//        SUPABASE_SERVICE_ROLE_KEY env vars so it can write to the DB directly.
//   { action: "match", pay_period_id?: uuid, window_days?: number, refresh?: boolean }
//        -> { scanned, matched, variances, ambiguous, unmatched, results }
//        BACKFILL MATCHER. For payments missing a wise_transfer_id, pulls Wise's
//        transfer history for the relevant window and matches by recipient UUID
//        + amount + date. Writes wise_transfer_id back where the match is
//        unambiguous. NEVER changes amounts — variances are surfaced for review.
//        Idempotent — already-matched rows are skipped by default. Pass pay_period_id
//        to scope to one period, omit it to scan all paid periods with missing IDs.
//        window_days defaults to 7 — half the biweekly payroll cadence so no
//        two consecutive batches can both fall in one period's window. When
//        amount + recipient match more than one transfer in the window, the
//        matcher picks the transfer whose `created` date is closest to the
//        period's pay_date (no more "ambiguous" stand-offs in the common case).
//        Pass refresh:true to ALSO re-fetch already-matched rows — useful for
//        backfilling new fields like wise_dates onto rows that were matched
//        before the column existed.
//   { action: "recipients" }                        -> { profile_id, recipients: [
//        { id, name, currency, account } ] }  (READ-ONLY list of saved recipients)
// ---------------------------------------------------------------------------

const BASE = Deno.env.get("WISE_API_BASE") ?? "https://api.wise.com";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

function authHeaders(token: string) {
  return { Authorization: `Bearer ${token}`, "Content-Type": "application/json" };
}

// --- Wise SCA (Strong Customer Authentication / "2FA") ----------------------
// Sensitive endpoints — funding a transfer from balance — require SCA. The
// first call returns HTTP 403 with an `x-2fa-approval` one-time token (OTT);
// we sign that token with our registered private key (RSA, SHA-256, PKCS#1
// v1.5) and retry the SAME request with `x-2fa-approval` + `X-Signature`.
// Key setup (generate keypair, register the PUBLIC key in Wise, set the
// PRIVATE key as WISE_PRIVATE_KEY): see WISE_SCA_SETUP.md.
function pemToDer(pem: string): Uint8Array {
  const b64 = pem.replace(/-----BEGIN [^-]+-----/g, "")
                 .replace(/-----END [^-]+-----/g, "")
                 .replace(/\s+/g, "");
  const bin = atob(b64);
  const der = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) der[i] = bin.charCodeAt(i);
  return der;
}
let _scaKey: CryptoKey | null = null;
async function getScaKey(): Promise<CryptoKey | null> {
  if (_scaKey) return _scaKey;
  const pem = Deno.env.get("WISE_PRIVATE_KEY");
  if (!pem) return null;
  _scaKey = await crypto.subtle.importKey(
    "pkcs8", pemToDer(pem) as BufferSource,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false, ["sign"],
  );
  return _scaKey;
}
async function signOtt(ott: string): Promise<string> {
  const key = await getScaKey();
  if (!key) throw new Error("WISE_PRIVATE_KEY not set — required to fund via API (Wise SCA). See WISE_SCA_SETUP.md");
  const sig = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" }, key, new TextEncoder().encode(ott));
  let bin = ""; const bytes = new Uint8Array(sig);
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin);   // base64 signature for the X-Signature header
}
// Perform a request that may require SCA. On 403 + x-2fa-approval, sign the OTT
// and retry once with the approval + signature headers. Anything else passes
// through unchanged (no-op when SCA isn't required, e.g. non-EEA accounts).
async function fetchWithSca(url: string, init: RequestInit, _token: string): Promise<Response> {
  const res = await fetch(url, init);
  const ott = res.headers.get("x-2fa-approval");
  if (res.status === 403 && ott) {
    const signature = await signOtt(ott);
    const headers = { ...(init.headers as Record<string, string>),
      "x-2fa-approval": ott, "X-Signature": signature };
    return await fetch(url, { ...init, headers });
  }
  return res;
}

// Run async `fn` over `items` with bounded concurrency, preserving input order.
// Used to parallelize the per-transfer Wise GET loops (status / rates / poll)
// without hammering the Wise API; cap kept modest for rate-limit safety.
async function mapLimit<T, R>(items: T[], limit: number, fn: (item: T, i: number) => Promise<R>): Promise<R[]> {
  const out: R[] = new Array(items.length);
  let next = 0;
  const workers = Array.from({ length: Math.max(1, Math.min(limit, items.length)) }, async () => {
    while (true) {
      const i = next++;
      if (i >= items.length) break;
      out[i] = await fn(items[i], i);
    }
  });
  await Promise.all(workers);
  return out;
}

// The Wise business profile id is constant for the account, so memoize it at
// module scope — warm isolates skip the redundant GET /v2/profiles round-trip.
// Only the resolved value is cached; a thrown fetch never poisons the cache.
let cachedProfileId: number | null = null;
async function getBusinessProfileId(token: string): Promise<number> {
  if (cachedProfileId != null) return cachedProfileId;
  const r = await fetch(`${BASE}/v2/profiles`, { headers: authHeaders(token) });
  if (!r.ok) throw new Error(`profiles ${r.status}: ${await r.text()}`);
  const profiles = await r.json();
  const biz = profiles.find((p: any) => p.type === "business") ?? profiles[0];
  if (!biz) throw new Error("no Wise profile found");
  cachedProfileId = biz.id;
  return cachedProfileId;
}

// Pull a single transfer's full detail to capture the dateFunded / dateSent
// timestamps that the list endpoint omits. Falls back to whatever was already
// on the list row if the detail fetch fails. Returns ISO strings so the DB
// can store them in jsonb without further conversion.
// Wise sometimes returns space-separated "YYYY-MM-DD HH:MM:SS" (UTC), sometimes
// ISO. Normalise both into a real ISO string (or null).
function toIsoWise(v: any): string | null {
  if (!v) return null;
  const s = String(v).trim();
  const iso = s.includes("T") ? s : s.replace(" ", "T") + "Z";
  const d = new Date(iso);
  return isNaN(d.getTime()) ? null : d.toISOString();
}

// Pure: derive the created/dateFunded/dateSent triple from a FULL transfer
// detail object (GET /v1/transfers/{id}) — no network. Use this when you already
// have the detail row in hand (e.g. the poll loop) to avoid a second GET.
function wiseDatesFromRow(row: any): Record<string, string | null> {
  return {
    created: toIsoWise(row.created ?? row.createdAt),
    dateFunded: toIsoWise(row.dateFunded ?? row.fundedDate ?? null),
    dateSent: toIsoWise(row.dateSent ?? row.sentDate ?? null),
  };
}

// Pull a single transfer's full detail to capture dateFunded / dateSent that the
// LIST endpoint omits. Falls back to the list row's created if the detail fetch
// fails. Use only when you have a list row (not the full detail) — the poll loop
// already has the detail and should use wiseDatesFromRow() instead.
async function fetchWiseDates(token: string, listRow: any): Promise<Record<string, string | null>> {
  const dates: Record<string, string | null> = {
    created: toIsoWise(listRow.created ?? listRow.createdAt),
    dateFunded: null,
    dateSent: null,
  };
  try {
    const r = await fetch(`${BASE}/v1/transfers/${listRow.id}`, { headers: authHeaders(token) });
    if (r.ok) {
      const d = wiseDatesFromRow(await r.json());
      dates.dateFunded = d.dateFunded;
      dates.dateSent   = d.dateSent;
      if (!dates.created) dates.created = d.created;
    }
  } catch (_e) { /* best effort — keep created at minimum */ }
  return dates;
}

// Draft one transfer: quote (PHP->PHP) -> transfer. NO funding.
async function draftOne(token: string, profileId: number, item: any) {
  // 1. quote
  const qRes = await fetch(`${BASE}/v3/profiles/${profileId}/quotes`, {
    method: "POST", headers: authHeaders(token),
    body: JSON.stringify({
      sourceCurrency: "PHP", targetCurrency: "PHP",
      targetAmount: Number(item.amount_php),
      payOut: "BALANCE",
    }),
  });
  if (!qRes.ok) return { worker_id: item.worker_id, status: "failed", error: `quote ${qRes.status}: ${await qRes.text()}` };
  const quote = await qRes.json();
  const fx = quote.rate ?? 1;

  // 2. transfer (references an EXISTING recipient by id; no bank details here)
  const tRes = await fetch(`${BASE}/v1/transfers`, {
    method: "POST", headers: authHeaders(token),
    body: JSON.stringify({
      targetAccount: item.recipient_id,
      quoteUuid: quote.id,
      customerTransactionId: crypto.randomUUID(),
      details: { reference: "Payroll", transferPurpose: "verification.transfers.purpose.pay.bills" },
    }),
  });
  if (!tRes.ok) {
    const errText = await tRes.text();
    // C5 — Wisetag / non-bank-account recipient detection. When the stored
    // recipient_id is a Wisetag (balance) contact rather than a bank-account
    // recipient, /v1/transfers rejects it (typically 422/403 referencing the
    // target account / recipient type). Surface a SPECIFIC, actionable status
    // instead of a raw error so the UI can say "pay via Manual CSV" rather
    // than leaving a half-drafted row that would fail at funding.
    const looksWisetag = (tRes.status === 422 || tRes.status === 403) &&
      /target.?account|recipient|not.*(bank|active)|balance/i.test(errText);
    if (looksWisetag) {
      return { worker_id: item.worker_id, status: "wisetag_unsupported",
        error: "Recipient is a Wisetag / Wise-balance contact, not a bank-account recipient — "+
               "the API draft path can't use it. Pay this contractor via the Manual Wise batch CSV.",
        recipient_id: item.recipient_id };
    }
    return { worker_id: item.worker_id, status: "failed", error: `transfer ${tRes.status}: ${errText}` };
  }
  const transfer = await tRes.json();

  // IMPORTANT: we stop here. No POST .../payments. Money has NOT moved.
  return { worker_id: item.worker_id, transfer_id: transfer.id, fx_rate: fx, status: "drafted" };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const token = Deno.env.get("WISE_API_TOKEN");
    if (!token) return json({ error: "WISE_API_TOKEN not set on the server" }, 500);
    const body = await req.json().catch(() => ({}));

    // --- caller authorization -------------------------------------------------
    // This function wields the company Wise token AND the service-role key, so
    // EVERY action requires an authenticated admin (the public anon key alone is
    // not enough). Money-moving actions (draft / batch / fund) require the OWNER
    // role — fund actually disburses from the Wise balance, so it is owner-only.
    // The machine reconcile actions (poll / match) may alternatively present the
    // cron secret, so a scheduled job can run them without a user session. This
    // is the same in-function gate portal-admin / admin-manage use; the function
    // stays --no-verify-jwt like its siblings (the in-code gate is the control).
    {
      const SB = Deno.env.get("SUPABASE_URL");
      const SR = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      if (!SB || !SR) return json({ error: "server missing SUPABASE_URL / SERVICE_ROLE_KEY" }, 500);
      const svc = { apikey: SR, Authorization: `Bearer ${SR}`, "Content-Type": "application/json" };
      const action = body.action;
      const OWNER_ACTIONS = new Set(["draft", "batch", "fund"]);
      const CRON_ACTIONS = new Set(["poll", "match"]);

      let authed = false;
      // machine path: a scheduled reconcile may authenticate with the cron secret.
      if (CRON_ACTIONS.has(action)) {
        const cronSecret = req.headers.get("x-cron-secret");
        if (cronSecret) {
          const sRes = await fetch(`${SB}/rest/v1/app_secrets?key=eq.cron_secret&select=value`, { headers: svc });
          const secrets = await sRes.json().catch(() => []);
          const expected = Array.isArray(secrets) && secrets[0]?.value;
          if (!expected || cronSecret !== expected) return json({ error: "invalid cron secret" }, 401);
          authed = true;
        }
      }
      // user path: validate the bearer JWT and require an admin (owner for staging).
      if (!authed) {
        const bearer = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
        if (!bearer) return json({ error: "missing auth" }, 401);
        const uRes = await fetch(`${SB}/auth/v1/user`, { headers: { Authorization: `Bearer ${bearer}`, apikey: SR } });
        if (!uRes.ok) return json({ error: "invalid session" }, 401);
        const caller = await uRes.json().catch(() => null);
        if (!caller?.id) return json({ error: "invalid session" }, 401);
        const aRes = await fetch(`${SB}/rest/v1/admin_users?user_id=eq.${caller.id}&select=role`, { headers: svc });
        const admins = await aRes.json().catch(() => []);
        const me = Array.isArray(admins) && admins[0];
        if (!me) return json({ error: "not authorized — admins only" }, 403);
        if (OWNER_ACTIONS.has(action) && me.role !== "owner")
          return json({ error: "not authorized — owner only for staging transfers" }, 403);
      }
    }
    // --------------------------------------------------------------------------

    if (body.action === "profile") {
      return json({ profile_id: await getBusinessProfileId(token) });
    }

    if (body.action === "draft") {
      const items = body.items ?? [];
      if (!items.length) return json({ error: "no items to draft" }, 400);
      const profileId = body.profile_id ?? await getBusinessProfileId(token);
      const results = [];
      for (const item of items) {
        if (!item.recipient_id) { results.push({ worker_id: item.worker_id, status: "skipped", error: "no Wise recipient" }); continue; }
        if (!item.amount_php || item.amount_php <= 0) { results.push({ worker_id: item.worker_id, status: "skipped", error: "no amount" }); continue; }
        try { results.push(await draftOne(token, profileId, item)); }
        catch (e) { results.push({ worker_id: item.worker_id, status: "failed", error: String(e?.message ?? e) }); }
      }
      return json({ profile_id: profileId, results });
    }

    // FUND a single drafted transfer — calls Wise's funding endpoint
    // (POST /v3/profiles/{id}/transfers/{transferId}/payments) which is what
    // actually moves money from the business Wise balance. Independent of
    // the `draft` action so the UI can fund per-row and surface per-row
    // outcomes. Owner-gated above (OWNER_ACTIONS) AND gated client-side on
    // companies.api_payouts_enabled; this function additionally enforces
    // idempotency (refuse to refund a row that already has funded_at).
    //
    // Body: { action: "fund",
    //         transfer_id: <string|number>,   // required: Wise transfer id
    //         payment_id?: <uuid>,            // optional: DB payment row for
    //                                         //   idempotency check + audit update
    //         actor?: <string> }              // optional: admin email/id for
    //                                         //   funded_by column
    //
    // Returns:
    //   ok=true   → { ok: true, funded_at, wise_status, already_funded? }
    //   ok=false  → { ok: false, error, http_status?, fund_error_stored? }
    if (body.action === "fund") {
      const transferId = body.transfer_id;
      const paymentId  = body.payment_id;
      const actor      = body.actor ?? null;
      if (transferId == null || String(transferId).trim() === "") {
        return json({ ok: false, error: "need transfer_id" }, 400);
      }
      const supaUrl = Deno.env.get("SUPABASE_URL");
      const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      if (!supaUrl || !serviceKey) {
        return json({ ok: false, error: "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set on the server" }, 500);
      }
      const restHeaders = {
        "apikey": serviceKey,
        "Authorization": `Bearer ${serviceKey}`,
        "Content-Type": "application/json",
      };

      // 1. Defensive idempotency: if the DB row already has funded_at, refuse
      //    to call Wise a second time. Wise rejects double-funding too, but
      //    avoiding the API call entirely is faster and surfaces the prior
      //    funded_at to the UI without another roundtrip.
      let priorFundedAt: string | null = null;
      if (paymentId) {
        const pq = new URLSearchParams({
          "select": "funded_at,wise_transfer_id",
          "id": `eq.${paymentId}`,
        });
        const pr = await fetch(`${supaUrl}/rest/v1/payments?${pq}`, { headers: restHeaders });
        if (pr.ok) {
          const rows = await pr.json();
          if (Array.isArray(rows) && rows[0]) {
            priorFundedAt = rows[0].funded_at ?? null;
            const dbTransfer = String(rows[0].wise_transfer_id ?? "");
            if (dbTransfer && dbTransfer !== String(transferId)) {
              return json({ ok: false, error:
                `transfer_id mismatch: DB has ${dbTransfer}, request has ${transferId}` }, 400);
            }
          }
        }
        if (priorFundedAt) {
          return json({ ok: true, already_funded: true, funded_at: priorFundedAt });
        }
      }

      // 2. Call Wise's funding endpoint. This is SCA-protected: fetchWithSca
      //    transparently signs the x-2fa-approval challenge and retries. If
      //    SCA is required but WISE_PRIVATE_KEY isn't configured, signing
      //    throws — surface it as a normal ok:false (and store fund_error) so
      //    the UI shows a clear reason instead of a 500.
      const profileId = body.profile_id ?? await getBusinessProfileId(token);
      let fRes: Response;
      try {
        fRes = await fetchWithSca(
          `${BASE}/v3/profiles/${profileId}/transfers/${transferId}/payments`,
          { method: "POST", headers: authHeaders(token), body: JSON.stringify({ type: "BALANCE" }) },
          token,
        );
      } catch (scaErr) {
        const errMsg = String((scaErr as any)?.message ?? scaErr);
        if (paymentId) {
          await fetch(`${supaUrl}/rest/v1/payments?id=eq.${paymentId}`, {
            method: "PATCH",
            headers: { ...restHeaders, "Prefer": "return=minimal" },
            body: JSON.stringify({ fund_error: errMsg.slice(0, 500) }),
          });
        }
        return json({ ok: false, error: errMsg.slice(0, 500), fund_error_stored: !!paymentId }, 500);
      }
      const fText = await fRes.text();
      let fJson: any = null;
      try { fJson = fText ? JSON.parse(fText) : null; } catch { /* ignore */ }

      // 3a. Failure path. Store fund_error so the UI can render the reason.
      if (!fRes.ok) {
        const errMsg = (fJson?.errors?.[0]?.message)
                    ?? (fJson?.message)
                    ?? fText
                    ?? `Wise fund ${fRes.status}`;
        if (paymentId) {
          await fetch(`${supaUrl}/rest/v1/payments?id=eq.${paymentId}`, {
            method: "PATCH",
            headers: { ...restHeaders, "Prefer": "return=minimal" },
            body: JSON.stringify({ fund_error: String(errMsg).slice(0, 500) }),
          });
        }
        return json({
          ok: false,
          error: String(errMsg).slice(0, 500),
          http_status: fRes.status,
          fund_error_stored: !!paymentId,
        }, fRes.status === 422 ? 422 : 500);
      }

      // 3b. Success path. Store funded_at + funded_by; clear any prior
      //     fund_error.
      const fundedAt = new Date().toISOString();
      const patch: Record<string, unknown> = {
        funded_at: fundedAt,
        funded_by: actor,
        fund_error: null,
      };

      // H8 — auto-reconcile after fund: immediately re-read the transfer's
      // status so the UI doesn't lag in "drafted" until a separate Reconcile
      // pass runs. If Wise already reports a terminal-sent state, set
      // paid_at (to the real sent/funded date) + status='sent' in the SAME
      // write. Best-effort: a probe failure just leaves the row funded (the
      // normal Reconcile will catch up later).
      let wiseStatus = fJson?.status ?? null;
      let autoSent = false;
      try {
        const dates = await fetchWiseDates(token, { id: transferId });
        const sRes = await fetch(`${BASE}/v1/transfers/${transferId}`, { headers: authHeaders(token) });
        if (sRes.ok) {
          const tdetail = await sRes.json();
          wiseStatus = tdetail.status ?? wiseStatus;
          const sentStates = new Set(["outgoing_payment_sent", "completed", "sent"]);
          const sentIso = dates.dateSent || dates.dateFunded || dates.created || null;
          if (wiseStatus && sentStates.has(wiseStatus) && sentIso) {
            patch.paid_at = sentIso;
            patch.status = "sent";
            patch.wise_dates = dates;
            autoSent = true;
          }
        }
      } catch (_e) { /* best-effort; leave row funded for the next Reconcile */ }

      let dbWriteOk = true;
      if (paymentId) {
        const u = await fetch(`${supaUrl}/rest/v1/payments?id=eq.${paymentId}`, {
          method: "PATCH",
          headers: { ...restHeaders, "Prefer": "return=minimal" },
          body: JSON.stringify(patch),
        });
        dbWriteOk = u.ok;
      }
      return json({
        ok: true,
        funded_at: fundedAt,
        wise_status: wiseStatus,
        wise_type:   fJson?.type   ?? null,
        auto_sent:   autoSent,
        db_write_ok: dbWriteOk,
      });
    }

    if (body.action === "batch") {
      const items = (body.items ?? []).filter((i: any) => i.recipient_id && i.amount_php > 0);
      if (!items.length) return json({ error: "no fundable items" }, 400);
      const profileId = body.profile_id ?? await getBusinessProfileId(token);
      // 1. create the batch group (PHP source)
      const gRes = await fetch(`${BASE}/v3/profiles/${profileId}/batch-groups`, {
        method: "POST", headers: authHeaders(token),
        body: JSON.stringify({ name: body.name ?? `Payroll ${new Date().toISOString().slice(0,10)}`, sourceCurrency: "PHP" }),
      });
      if (!gRes.ok) return json({ error: `batch-group ${gRes.status}: ${await gRes.text()}` }, 500);
      const group = await gRes.json();
      // 2. add a transfer per item (quote + transfer inside the group)
      const results = [];
      for (const item of items) {
        try {
          const qRes = await fetch(`${BASE}/v3/profiles/${profileId}/quotes`, {
            method: "POST", headers: authHeaders(token),
            body: JSON.stringify({ sourceCurrency: "PHP", targetCurrency: "PHP", targetAmount: Number(item.amount_php), payOut: "BALANCE" }),
          });
          if (!qRes.ok) { results.push({ worker_id: item.worker_id, status: "failed", error: `quote ${qRes.status}` }); continue; }
          const quote = await qRes.json();
          const tRes = await fetch(`${BASE}/v3/profiles/${profileId}/batch-groups/${group.id}/transfers`, {
            method: "POST", headers: authHeaders(token),
            body: JSON.stringify({ targetAccount: item.recipient_id, quoteUuid: quote.id,
              customerTransactionId: crypto.randomUUID(),
              details: { reference: "Payroll", transferPurpose: "verification.transfers.purpose.pay.bills" } }),
          });
          if (!tRes.ok) {
            const errText = await tRes.text();
            // C5 — Wisetag / non-bank-account recipient (see draftOne).
            const looksWisetag = (tRes.status === 422 || tRes.status === 403) &&
              /target.?account|recipient|not.*(bank|active)|balance/i.test(errText);
            results.push(looksWisetag
              ? { worker_id: item.worker_id, status: "wisetag_unsupported", recipient_id: item.recipient_id,
                  error: "Wisetag / Wise-balance recipient — can't API-draft; pay via Manual CSV." }
              : { worker_id: item.worker_id, status: "failed", error: `transfer ${tRes.status}: ${errText}` });
            continue;
          }
          const t = await tRes.json();
          results.push({ worker_id: item.worker_id, transfer_id: t.id, fx_rate: quote.rate ?? 1, status: "drafted" });
        } catch (e) { results.push({ worker_id: item.worker_id, status: "failed", error: String(e?.message ?? e) }); }
      }
      // NOTE: we deliberately do NOT complete or fund the group. You review,
      // complete, and fund it in Wise. Money has NOT moved.
      return json({ batch_group_id: group.id, profile_id: profileId, results });
    }

    if (body.action === "status") {
      const ids = body.transfer_ids ?? [];
      const statuses = await mapLimit(ids, 8, async (id: any) => {
        const r = await fetch(`${BASE}/v1/transfers/${id}`, { headers: authHeaders(token) });
        return r.ok ? { id, status: (await r.json()).status } : { id, status: "unknown" };
      });
      return json({ statuses });
    }

    // READ-ONLY rate lookup. Given transfer_ids, returns each transfer's
    // authoritative LOCKED quote rate (the `rate` Wise locked at draft time)
    // plus source/target amounts and status. No quote, no draft, no funding —
    // a plain GET /v1/transfers/{id}. Use this to verify/disambiguate the
    // fx_rate stored on payments.
    if (body.action === "rates") {
      const ids = body.transfer_ids ?? [];
      const rates = await mapLimit(ids, 8, async (id: any) => {
        const r = await fetch(`${BASE}/v1/transfers/${id}`, { headers: authHeaders(token) });
        if (!r.ok) return { id, error: `wise ${r.status}` };
        const t = await r.json();
        return {
          id,
          rate: t.rate ?? null,
          status: t.status ?? null,
          sourceCurrency: t.sourceCurrency ?? null,
          targetCurrency: t.targetCurrency ?? null,
          sourceValue: t.sourceValue ?? null,
          targetValue: t.targetValue ?? null,
          targetAccount: t.targetAccount ?? null,
          reference: t.details?.reference ?? null,
          created: t.created ?? null,
        };
      });
      return json({ rates });
    }

    // SERVER-SIDE RECONCILE. Pulls every payment with a wise_transfer_id
    // (optionally scoped to one period, optionally restricted to status='draft'),
    // asks Wise for the current state, and updates payments.status to 'sent'
    // for terminal-success states only. Idempotent — safe to call manually or
    // on a schedule. Same paid-state policy as the front-end check.
    if (body.action === "poll") {
      const supaUrl = Deno.env.get("SUPABASE_URL");
      const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      if (!supaUrl || !serviceKey) {
        return json({ error: "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set on the server" }, 500);
      }
      // Default: only check payments still in 'draft' (idempotent / cheap).
      // Pass only_drafts=false to re-check 'sent' rows too.
      const onlyDrafts = body.only_drafts !== false;
      const restHeaders = {
        "apikey": serviceKey,
        "Authorization": `Bearer ${serviceKey}`,
        "Content-Type": "application/json",
      };
      // 1. fetch candidate payments via PostgREST
      const qs = new URLSearchParams();
      qs.set("select", "id,worker_id,pay_period_id,wise_transfer_id,status,net_php");
      qs.set("wise_transfer_id", "not.is.null");
      if (onlyDrafts) qs.set("status", "eq.draft");
      if (body.pay_period_id) qs.set("pay_period_id", `eq.${body.pay_period_id}`);
      const pRes = await fetch(`${supaUrl}/rest/v1/payments?${qs}`, { headers: restHeaders });
      if (!pRes.ok) return json({ error: `payments fetch ${pRes.status}: ${await pRes.text()}` }, 500);
      const payments: any[] = await pRes.json();
      if (!payments.length) {
        return json({ checked: 0, marked_paid: 0, in_flight: 0, unknown: 0, results: [] });
      }
      // 2. ask Wise for each transfer's status, then update where terminal-success
      const paidStates = new Set(["outgoing_payment_sent", "completed", "sent"]);
      const inFlightStates = new Set([
        "processing", "funds_converted",
        "incoming_payment_waiting", "waiting_recipient_input_to_proceed",
      ]);
      const results = [];
      let marked = 0, inFlight = 0, unknown = 0;
      const nowIso = new Date().toISOString();
      // Fetch every transfer's full detail in parallel (bounded), then apply the
      // per-row DB updates. Each transfer GET already returns the full detail, so
      // we derive wise_dates from it directly (no second GET via fetchWiseDates).
      const fetched = await mapLimit(payments, 8, async (p: any) => {
        const id = p.wise_transfer_id;
        const r = await fetch(`${BASE}/v1/transfers/${id}`, { headers: authHeaders(token) });
        return r.ok ? { p, id, ok: true as const, wiseRow: await r.json() }
                    : { p, id, ok: false as const, httpStatus: r.status };
      });
      for (const f of fetched) {
        const { p, id } = f;
        if (!f.ok) {
          unknown++;
          results.push({ payment_id: p.id, transfer_id: id, status: "unknown", error: `wise ${f.httpStatus}` });
          continue;
        }
        const wiseRow = f.wiseRow;
        const st = wiseRow.status;
        if (paidStates.has(st)) {
          // PATCH the single payment row to 'sent', using Wise's REAL sent date
          // (or dateFunded / created as fallbacks) instead of now(). Also
          // captures the full wise_dates triple for the UI tooltip.
          const dates = wiseDatesFromRow(wiseRow);
          const realSent = dates.dateSent || dates.dateFunded || dates.created || nowIso;
          const uRes = await fetch(
            `${supaUrl}/rest/v1/payments?id=eq.${p.id}`,
            { method: "PATCH", headers: { ...restHeaders, "Prefer": "return=minimal" },
              body: JSON.stringify({
                status: "sent",
                paid_at: realSent,
                wise_dates: dates,
                wise_locked_at: nowIso,   // auto-lock once Wise confirms terminal-success
              }) },
          );
          if (uRes.ok) { marked++; results.push({ payment_id: p.id, transfer_id: id, status: st, marked_paid: true, paid_at: realSent }); }
          else        { results.push({ payment_id: p.id, transfer_id: id, status: st, error: `db ${uRes.status}` }); }
        } else if (inFlightStates.has(st)) {
          inFlight++;
          results.push({ payment_id: p.id, transfer_id: id, status: st, in_flight: true });
        } else {
          // cancelled / funds_refunded / bounced_back / etc — surface but don't change DB
          results.push({ payment_id: p.id, transfer_id: id, status: st });
        }
      }
      return json({ checked: payments.length, marked_paid: marked, in_flight: inFlight, unknown, results });
    }

    // BACKFILL MATCHER. For payments that don't have a wise_transfer_id yet,
    // pull Wise's transfer history for the relevant window and try to match
    // each unmatched payment to exactly one Wise transfer by:
    //    targetAccount == workers.wise_recipient_uuid
    //    AND |targetValue - payments.net_php| <= 1.00  (peso-level rounding tolerance)
    //    AND created within [pay_date - window, pay_date + window]
    // Writes wise_transfer_id back only on UNAMBIGUOUS matches. Amount
    // variances are surfaced for human review — never auto-fixed.
    if (body.action === "match") {
      const supaUrl = Deno.env.get("SUPABASE_URL");
      const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      if (!supaUrl || !serviceKey) {
        return json({ error: "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set on the server" }, 500);
      }
      // Default window: ±7 days. Half the biweekly payroll cadence — narrow
      // enough that two consecutive batches can't both fall in one period's
      // window (which is what the original ±14 was causing — see the ambiguous
      // pairs Oliver hit on 2026-05-28).
      const windowDays = Number(body.window_days ?? 7);
      const restHeaders = {
        "apikey": serviceKey,
        "Authorization": `Bearer ${serviceKey}`,
        "Content-Type": "application/json",
      };

      // 1. Fetch payments to match.
      //    Default: rows with no wise_transfer_id yet (true "unmatched" cleanup).
      //    refresh=true: rows that ARE already matched, to re-fetch wise_dates
      //    or any other field that didn't exist when the original match ran.
      //    We pull numeric wise_recipient_id (LAST-USED default), the newer
      //    wise_recipient_uuid, AND the full wise_recipients array (every saved
      //    recipient for this worker, including historical ones from a prior
      //    bank). Historical periods may have been paid via an older recipient
      //    id that's no longer the default — without the full list we'd miss
      //    those transfers and report "no_wise_transfer".
      const refresh = body.refresh === true;
      const qs = new URLSearchParams();
      qs.set("select",
        "id,worker_id,pay_period_id,wise_transfer_id,status,net_php,original_net_php,payout_method," +
        "workers(first_name,middle_name,last_name,wise_recipient_id,wise_recipient_uuid,wise_recipients,payout_method)," +
        "pay_periods(pay_date,period_start,period_end,state)");
      if (refresh) qs.set("wise_transfer_id", "not.is.null");
      else         qs.set("wise_transfer_id", "is.null");
      qs.set("payout_method", "eq.wise");
      if (body.pay_period_id) qs.set("pay_period_id", `eq.${body.pay_period_id}`);
      const pRes = await fetch(`${supaUrl}/rest/v1/payments?${qs}`, { headers: restHeaders });
      if (!pRes.ok) return json({ error: `payments fetch ${pRes.status}: ${await pRes.text()}` }, 500);
      const payments: any[] = await pRes.json();
      if (!payments.length) {
        return json({ scanned: 0, matched: 0, variances: 0, ambiguous: 0, unmatched: 0, results: [] });
      }

      // 2. Compute the union date window across all candidate payments so we
      //    only need to pull Wise transfers once. (Pulling per-payment would
      //    be N API calls; pulling the union is 1 + paging.)
      const dateMs = (p: any) => {
        const d = p.pay_periods?.pay_date || p.pay_periods?.period_end;
        return d ? new Date(d).getTime() : Date.now();
      };
      let minTs = Infinity, maxTs = -Infinity;
      for (const p of payments) {
        const t = dateMs(p);
        if (t < minTs) minTs = t;
        if (t > maxTs) maxTs = t;
      }
      const dayMs = 86_400_000;
      // For the Wise API pull, use a generous window so historical periods
      // (where the DB pay_date may be weeks before the real Wise transfer
      // date) still surface their transfers. The per-row matching logic
      // applies the tight windowDays filter afterward — this is just the
      // coarse "what transfers exist at all" pull.
      const pullPaddingDays = Math.max(windowDays, 45);
      const fromIso = new Date(minTs - pullPaddingDays * dayMs).toISOString();
      const toIso   = new Date(maxTs + pullPaddingDays * dayMs).toISOString();

      // 3. Pull Wise transfer history for the union window. Page until we have
      //    all of them. Wise caps page size at 100, so we may need several pages.
      const profileId = await getBusinessProfileId(token);
      const wiseTransfers: any[] = [];
      let offset = 0; const pageSize = 100;
      // Safety: cap at 50 pages = 5,000 transfers. More than enough for ~2 years.
      for (let i = 0; i < 50; i++) {
        const tqs = new URLSearchParams();
        tqs.set("profile", String(profileId));
        tqs.set("limit", String(pageSize));
        tqs.set("offset", String(offset));
        tqs.set("createdDateStart", fromIso);
        tqs.set("createdDateEnd", toIso);
        const tRes = await fetch(`${BASE}/v1/transfers?${tqs}`, { headers: authHeaders(token) });
        if (!tRes.ok) {
          return json({ error: `wise transfer list ${tRes.status}: ${await tRes.text()}` }, 500);
        }
        const page = await tRes.json();
        if (!Array.isArray(page) || page.length === 0) break;
        wiseTransfers.push(...page);
        if (page.length < pageSize) break;
        offset += pageSize;
      }

      // 4. Filter out cancelled transfers BEFORE indexing. Wise's batch CSV
      //    upload flow creates draft "shadow" transfers in the API that get
      //    cancelled when the actual funded transfer is created — leaving the
      //    history with both a `cancelled` ghost AND the real `outgoing_payment_sent`
      //    transfer for the same recipient+amount. Including the ghosts would
      //    make every row look "ambiguous" (2 candidates per recipient).
      //    Confirmed via live API probe on the May 2026 batch: 13 sent + 12 cancelled.
      const liveTransfers = wiseTransfers.filter(t => t.status !== "cancelled");

      // 5. Index live Wise transfers by targetAccount. `targetAccount` in
      //    /v1/transfers is the recipient's NUMERIC id (confirmed by probe),
      //    so we match against `workers.wise_recipient_id`. We ALSO index by
      //    UUID if Wise ever returns one (e.g. on newer recipient formats),
      //    so a future format shift doesn't silently break the matcher.
      const byRecipient = new Map<string, any[]>();
      for (const t of liveTransfers) {
        // primary: numeric targetAccount
        const numKey = String(t.targetAccount ?? "");
        if (numKey) {
          const arr = byRecipient.get(numKey) || [];
          arr.push(t);
          byRecipient.set(numKey, arr);
        }
        // secondary: any UUID-looking field Wise might add later
        const uuidKey = String(t.recipientId ?? "");
        if (uuidKey && uuidKey !== numKey) {
          const arr = byRecipient.get(uuidKey) || [];
          arr.push(t);
          byRecipient.set(uuidKey, arr);
        }
      }

      // 5b. For refresh mode, build a second index by transfer ID so we can
      //     look up already-matched rows directly without re-running recipient
      //     + window discovery. Important for historical periods where the DB
      //     pay_date doesn't match when Wise actually paid (the ±windowDays
      //     filter would reject the legitimate transfer otherwise).
      const byTransferId = new Map<string, any>();
      for (const t of liveTransfers) {
        if (t.id != null) byTransferId.set(String(t.id), t);
      }

      // 6. Match each payment.
      const results: any[] = [];
      let matched = 0, variances = 0, ambiguous = 0, unmatched = 0;
      for (const p of payments) {
        // REFRESH FAST PATH: row already has a transfer_id — trust it. Look
        // the transfer up directly, re-check amount, apply variance override
        // if needed. Skip recipient + window matching entirely so historical
        // pay_date mismatches don't hide the row's real transfer.
        if (refresh && p.wise_transfer_id) {
          const t = byTransferId.get(String(p.wise_transfer_id));
          if (!t) {
            // Transfer ID is stored on the row but isn't in the pulled
            // history (most likely the pull window didn't reach back far
            // enough). Leave the row alone — don't try to re-match it.
            unmatched++;
            results.push({ payment_id: p.id, worker_id: p.worker_id,
              outcome: "refresh_transfer_not_in_history",
              transfer_id: String(p.wise_transfer_id),
              reason: "Stored transfer_id not found in the pulled Wise history window" });
            continue;
          }
          const dbAmt = Number(p.net_php || 0);
          const wiseAmt = Number(t.targetValue ?? t.targetAmount ?? 0);
          const isMatch = Math.abs(wiseAmt - dbAmt) <= 1.00;
          const dates = await fetchWiseDates(token, t);
          const patch: Record<string, unknown> = {
            wise_dates: dates,
          };
          const sentIso = dates.dateSent || dates.dateFunded || dates.created || null;
          const wiseTerminal = t.status === "outgoing_payment_sent" || t.status === "completed" || t.status === "sent";
          if (sentIso && wiseTerminal) {
            patch.paid_at = sentIso;
            patch.status = "sent";
            patch.wise_locked_at = new Date().toISOString();
          } else if (p.status === "sent") {
            // The row was ALREADY recorded as sent (CSV import / manual / a prior
            // poll) and we've re-found its non-cancelled transfer in Wise. Lock it
            // even though the live API status isn't terminal: some batch-uploaded
            // transfers keep reporting a non-terminal status long after the money
            // actually went out (e.g. the 2026-05-29 batch showed "in progress"
            // though the payroll was paid). We trust the recorded 'sent' here;
            // first-time matching (below) still requires a terminal status.
            patch.wise_locked_at = new Date().toISOString();
          }
          // Variance auto-override: refresh path always treats the existing
          // link as unambiguous (we're not re-discovering), so apply the
          // override if amount differs and we haven't already overridden.
          if (!isMatch && p.original_net_php == null) {
            patch.original_net_php = dbAmt;
            patch.net_php = wiseAmt;
          }
          const uRes = await fetch(
            `${supaUrl}/rest/v1/payments?id=eq.${p.id}`,
            { method: "PATCH", headers: { ...restHeaders, "Prefer": "return=minimal" },
              body: JSON.stringify(patch) });
          if (uRes.ok) {
            if (isMatch) {
              matched++;
              results.push({ payment_id: p.id, worker_id: p.worker_id,
                outcome: "refreshed_clean", transfer_id: String(t.id),
                amount: dbAmt, wise_status: t.status, wise_dates: dates });
            } else {
              variances++;
              results.push({ payment_id: p.id, worker_id: p.worker_id,
                outcome: "matched_with_variance_overridden",
                transfer_id: String(t.id),
                db_amount: dbAmt, wise_amount: wiseAmt,
                delta: wiseAmt - dbAmt, wise_status: t.status,
                wise_dates: dates,
                amount_overridden: p.original_net_php == null });
            }
          } else {
            results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "db_write_failed",
              error: `db ${uRes.status}` });
          }
          continue;
        }
        // DISCOVERY PATH (first-time match): use recipient + window matching.
        // Try numeric id first (the format Wise's transfer API uses), then UUID,
        // then every historical recipient id saved in wise_recipients. The last
        // bit matters when a contractor changes bank: the LAST-USED default
        // (wise_recipient_id) is the NEW bank's id, but historical pay periods
        // were paid via the OLD recipient id that's still listed in
        // wise_recipients. Without unioning, those historical matches return
        // "no_wise_transfer" — even though Wise still has the transfer.
        const numId  = String(p.workers?.wise_recipient_id   ?? "").trim();
        const uuidId = String(p.workers?.wise_recipient_uuid ?? "").trim();
        const historicIds = (Array.isArray(p.workers?.wise_recipients) ? p.workers.wise_recipients : [])
          .map((x: any) => String(x?.id ?? "").trim())
          .filter((s: string) => !!s);
        // Distinct lookup keys in priority order: current default, UUID, then historicals.
        const keys: string[] = [];
        const pushKey = (k: string) => { if (k && !keys.includes(k)) keys.push(k); };
        pushKey(numId); pushKey(uuidId); historicIds.forEach(pushKey);
        if (!keys.length) {
          unmatched++;
          results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "no_recipient",
            reason: "Worker has no wise_recipient_id, wise_recipient_uuid, or wise_recipients entries stored" });
          continue;
        }
        // Union candidate transfers across every known recipient id for this worker.
        // Dedupe by transfer id since the index keys (numeric + UUID) can map to
        // the same transfer.
        const seenTransfers = new Set<string>();
        const candidates: any[] = [];
        let matchedViaKey = "";
        for (const k of keys) {
          for (const t of (byRecipient.get(k) || [])) {
            const id = String(t.id ?? "");
            if (id && !seenTransfers.has(id)) {
              seenTransfers.add(id);
              candidates.push(t);
              if (!matchedViaKey) matchedViaKey = k;
            }
          }
        }
        if (!candidates.length) {
          unmatched++;
          const tried = keys.length === 1 ? "this recipient" : `${keys.length} known recipient ids`;
          results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "no_wise_transfer",
            reason: `No Wise transfer in the union window for ${tried} (${keys.join(", ")})`,
            recipient_keys_tried: keys });
          continue;
        }
        // Filter by date window per-payment (the union window was the coarse net).
        const payTs = dateMs(p);
        const inWindow = candidates.filter(t => {
          const tt = new Date(t.created || t.createdAt || 0).getTime();
          return Math.abs(tt - payTs) <= windowDays * dayMs;
        });
        if (!inWindow.length) {
          unmatched++;
          const tried = keys.length === 1 ? "this recipient" : `${keys.length} known recipient ids`;
          results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "no_wise_transfer_in_window",
            reason: `Wise has transfers to ${tried} but none within ±${windowDays} days of pay_date`,
            recipient_keys_tried: keys });
          continue;
        }
        // Look for an exact amount match (within ₱1.00) first. Tolerance is
        // ±1 peso, not ±0.01, because Wise batch uploads often round to the
        // nearest peso (or are typed by hand) — a true match for a calculated
        // ₱31,229.70 might be sent as ₱31,230 without any real override
        // happening. Differences bigger than ₱1 are treated as real variances.
        const dbAmt = Number(p.net_php || 0);
        const exact = inWindow.filter(t => {
          const a = Number(t.targetValue ?? t.targetAmount ?? 0);
          return Math.abs(a - dbAmt) <= 1.00;
        });
        if (exact.length === 1) {
          // Unambiguous exact match — write the transfer ID + Wise dates.
          const t = exact[0];
          const dates = await fetchWiseDates(token, t);
          const patch: Record<string, unknown> = {
            wise_transfer_id: String(t.id),
            wise_dates: dates,
          };
          // If Wise reports the money has been sent, also set paid_at to the
          // REAL sent date (not now()), AND auto-lock the row so it can't be
          // accidentally re-calculated or edited. Falls back to dateFunded /
          // created if dateSent is missing.
          const sentIso = dates.dateSent || dates.dateFunded || dates.created || null;
          if (sentIso && (t.status === "outgoing_payment_sent" || t.status === "completed" || t.status === "sent")) {
            patch.paid_at = sentIso;
            patch.status = "sent";
            patch.wise_locked_at = new Date().toISOString();
          }
          const uRes = await fetch(
            `${supaUrl}/rest/v1/payments?id=eq.${p.id}`,
            { method: "PATCH", headers: { ...restHeaders, "Prefer": "return=minimal" },
              body: JSON.stringify(patch) });
          if (uRes.ok) {
            matched++;
            results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "matched_exact",
              transfer_id: String(t.id), amount: dbAmt, wise_status: t.status,
              wise_dates: dates });
          } else {
            results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "db_write_failed",
              error: `db ${uRes.status}` });
          }
          continue;
        }
        if (exact.length > 1) {
          // Multiple transfers match recipient + amount in the window. Resolve
          // by picking the one whose `created` date is closest to the period's
          // pay_date — biweekly payrolls are 14 days apart, so the correct
          // transfer for THIS period is the one closest to its own pay_date,
          // and the others belong to neighbouring periods. Only declare
          // ambiguity if two transfers are equally close (true tie).
          const rankedByDate = exact.slice().sort((a, b) => {
            const ta = new Date(a.created || a.createdAt || 0).getTime();
            const tb = new Date(b.created || b.createdAt || 0).getTime();
            return Math.abs(ta - payTs) - Math.abs(tb - payTs);
          });
          const closestMs   = Math.abs(new Date(rankedByDate[0].created || rankedByDate[0].createdAt || 0).getTime() - payTs);
          const runnerUpMs  = Math.abs(new Date(rankedByDate[1].created || rankedByDate[1].createdAt || 0).getTime() - payTs);
          // Only call it a true tie if the two closest are within a day of each
          // other relative to pay_date — that's a genuine "can't tell" case.
          // Otherwise the closer transfer wins.
          const isTrueTie = Math.abs(closestMs - runnerUpMs) < dayMs;
          if (isTrueTie) {
            ambiguous++;
            results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "ambiguous_exact",
              reason: `${exact.length} Wise transfers match recipient + amount equally close to pay_date — can't pick automatically`,
              candidate_transfer_ids: exact.map(t => String(t.id)) });
            continue;
          }
          // Closest-pay-date wins. Treat as an exact match — same write path.
          const t = rankedByDate[0];
          const dates = await fetchWiseDates(token, t);
          const patch: Record<string, unknown> = {
            wise_transfer_id: String(t.id),
            wise_dates: dates,
          };
          const sentIso = dates.dateSent || dates.dateFunded || dates.created || null;
          if (sentIso && (t.status === "outgoing_payment_sent" || t.status === "completed" || t.status === "sent")) {
            patch.paid_at = sentIso;
            patch.status = "sent";
            patch.wise_locked_at = new Date().toISOString();
          }
          const uRes = await fetch(
            `${supaUrl}/rest/v1/payments?id=eq.${p.id}`,
            { method: "PATCH", headers: { ...restHeaders, "Prefer": "return=minimal" },
              body: JSON.stringify(patch) });
          if (uRes.ok) {
            matched++;
            results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "matched_closest_date",
              transfer_id: String(t.id), amount: dbAmt, wise_status: t.status,
              wise_dates: dates,
              also_considered: rankedByDate.slice(1).map(x => String(x.id)) });
          } else {
            results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "db_write_failed",
              error: `db ${uRes.status}` });
          }
          continue;
        }
        // No exact amount match — recipient matches but amount doesn't. The
        // path forks on how many candidates we have:
        //   - inWindow.length === 1 → UNAMBIGUOUS variance. The recipient +
        //     window picked exactly one transfer. The amount difference is
        //     almost certainly a manual disbursement override (Ferdinand /
        //     Melissa / Mery case). Auto-override net_php to Wise's value
        //     and preserve the original in original_net_php.
        //   - inWindow.length > 1  → AMBIGUOUS variance. Multiple transfers
        //     to the same recipient in the window. Closest-amount wins as
        //     before but we DON'T override the amount automatically — too
        //     risky to pick the wrong one and silently mutate the DB.
        const ranked = inWindow.slice().sort((a, b) => {
          const da = Math.abs(Number(a.targetValue ?? a.targetAmount ?? 0) - dbAmt);
          const db = Math.abs(Number(b.targetValue ?? b.targetAmount ?? 0) - dbAmt);
          return da - db;
        });
        const t = ranked[0];
        const wiseAmt = Number(t.targetValue ?? t.targetAmount ?? 0);
        const vDates = await fetchWiseDates(token, t);
        const isUnambiguous = inWindow.length === 1;
        const vPatch: Record<string, unknown> = {
          wise_transfer_id: String(t.id),
          wise_dates: vDates,
        };
        // ONLY auto-override the amount when this is unambiguous AND the row
        // doesn't already have an override stored (don't overwrite a previous
        // original_net_php on a re-run).
        if (isUnambiguous && p.original_net_php == null) {
          vPatch.original_net_php = dbAmt;       // preserve pre-Wise value
          vPatch.net_php = wiseAmt;              // adopt Wise's value
        }
        const vSentIso = vDates.dateSent || vDates.dateFunded || vDates.created || null;
        if (vSentIso && (t.status === "outgoing_payment_sent" || t.status === "completed" || t.status === "sent")) {
          vPatch.paid_at = vSentIso;
          vPatch.status = "sent";
          vPatch.wise_locked_at = new Date().toISOString();
        }
        const uRes = await fetch(
          `${supaUrl}/rest/v1/payments?id=eq.${p.id}`,
          { method: "PATCH", headers: { ...restHeaders, "Prefer": "return=minimal" },
            body: JSON.stringify(vPatch) });
        if (uRes.ok) {
          variances++;
          results.push({
            payment_id: p.id, worker_id: p.worker_id,
            outcome: isUnambiguous ? "matched_with_variance_overridden" : "matched_with_variance",
            transfer_id: String(t.id),
            db_amount: dbAmt, wise_amount: wiseAmt,
            delta: wiseAmt - dbAmt, wise_status: t.status,
            wise_dates: vDates,
            other_candidates: ranked.length - 1,
            amount_overridden: isUnambiguous && p.original_net_php == null,
          });
        } else {
          results.push({ payment_id: p.id, worker_id: p.worker_id, outcome: "db_write_failed",
            error: `db ${uRes.status}` });
        }
      }

      // Orphan-transfer diagnostic: for any payment that returned
      // no_wise_transfer / no_wise_transfer_in_window, scan transfers that
      // DIDN'T claim any DB row for ones whose amount and date fit. A single
      // orphan match strongly suggests the payment was paid via a historical
      // recipient id that's missing from the worker's wise_recipients list
      // (typical of bank-change cases). Surfaced so the UI can offer a
      // one-click "Link this recipient" action against the worker.
      const claimedTransferIds = new Set<string>(
        results.filter((r: any) => r.transfer_id).map((r: any) => String(r.transfer_id))
      );
      const orphans = liveTransfers.filter(t => !claimedTransferIds.has(String(t.id)));
      if (orphans.length) {
        const byPaymentId: Record<string, any> = {};
        for (const p of payments) byPaymentId[String(p.id)] = p;
        const unmatchedResults = results.filter((r: any) =>
          r.outcome === "no_wise_transfer" || r.outcome === "no_wise_transfer_in_window");

        // Does orphan transfer t fit unmatched payment p (amount + window)?
        const fitsPayment = (t: any, p: any) => {
          const tt = new Date(t.created || t.createdAt || 0).getTime();
          if (Math.abs(tt - dateMs(p)) > windowDays * dayMs) return false;
          const a = Number(t.targetValue ?? t.targetAmount ?? 0);
          return Math.abs(a - Number(p.net_php || 0)) <= 1.00;
        };

        // EXCLUSIVE ASSIGNMENT: count how many unmatched payments each orphan
        // fits. An orphan that fits exactly one payment is a confident
        // candidate (UI offers one-click link). An orphan that fits multiple
        // payments (e.g. two contractors with the same amount in the window) is
        // AMBIGUOUS — we still surface it, but flagged, so the UI forces an
        // explicit pick + confirmation instead of a blind one-click link that
        // could wire the transfer to the wrong contractor.
        const orphanFitCount = new Map<string, number>();
        for (const t of orphans) {
          let n = 0;
          for (const r of unmatchedResults) {
            const p = byPaymentId[String(r.payment_id)];
            if (p && fitsPayment(t, p)) n++;
          }
          orphanFitCount.set(String(t.id), n);
        }

        for (const r of unmatchedResults) {
          const p = byPaymentId[String(r.payment_id)];
          if (!p) continue;
          const fits = orphans.filter(t => fitsPayment(t, p)).slice(0, 5);
          if (fits.length) {
            r.candidate_orphan_transfers = fits.map(t => {
              const sharedCount = orphanFitCount.get(String(t.id)) || 1;
              return {
                transfer_id: String(t.id),
                target_account: String(t.targetAccount ?? ""),
                target_value: Number(t.targetValue ?? t.targetAmount ?? 0),
                created: t.created || t.createdAt || null,
                wise_status: t.status || null,
                // shared_with_n_payments > 1 ⇒ ambiguous; UI must require an
                // explicit confirmation before linking.
                shared_with_n_payments: sharedCount,
                ambiguous: sharedCount > 1,
              };
            });
          }
        }
      }

      return json({ scanned: payments.length, matched, variances, ambiguous, unmatched,
        wise_transfers_pulled: wiseTransfers.length,
        wise_transfers_live: liveTransfers.length,
        wise_transfers_cancelled: wiseTransfers.length - liveTransfers.length,
        window: { from: fromIso, to: toIso, days: windowDays },
        mode: refresh ? "refresh" : "match",
        results });
    }

    // READ-ONLY: list saved recipients for the business profile. Returns the
    // stable recipient id, holder name, currency, and a masked account summary.
    // No bank/account numbers are returned in full. Money never moves here.
    if (body.action === "recipients") {
      const profileId = body.profile_id ?? await getBusinessProfileId(token);
      const r = await fetch(`${BASE}/v1/accounts?profile=${profileId}`, { headers: authHeaders(token) });
      if (!r.ok) return json({ error: `accounts ${r.status}: ${await r.text()}` }, 500);
      const accounts = await r.json();
      const recipients = (Array.isArray(accounts) ? accounts : []).map((a: any) => {
        // build a short, non-sensitive account hint (last 4 / masked) for display
        const d = a.details ?? {};
        const hint = d.accountNumber ?? d.iban ?? d.email ?? "";
        const masked = hint ? `••••${String(hint).slice(-4)}` : "";
        return {
          id: a.id,
          name: a.accountHolderName ?? a.name ?? "",
          currency: a.currency ?? d.currency ?? "",
          account: masked,            // masked only — never the full number
          email: d.email ?? null,     // when Wise stores an email on the recipient — used by the email cross-check
          active: a.active !== false,
        };
      });
      return json({ profile_id: profileId, recipients });
    }

    // READ-ONLY: search Wise contacts by Wisetag / name / partial string.
    // Uses /v1/profiles/{profileId}/contacts?searchTerm=X which we verified
    // works on this account type. Returns up to ~6 results per Wise's default
    // (we don't paginate — searches with too many results aren't useful UX).
    //
    // IMPORTANT shape note: this returns Wise *contacts* (people you've
    // interacted with), not bank-account *recipients*. Each contact has a
    // `balanceRecipientId` which is a usable recipient ID for paying via the
    // contact's Wise balance — but is DIFFERENT from a bank-account recipient
    // ID. Most PH contractors are paid via bank-account recipients, so this
    // lookup is a narrow use case.
    if (body.action === "search_contacts") {
      const term = String(body.search_term ?? "").trim();
      if (!term) return json({ error: "need search_term" }, 400);
      const profileId = body.profile_id ?? await getBusinessProfileId(token);
      const url = `${BASE}/v1/profiles/${profileId}/contacts?searchTerm=${encodeURIComponent(term)}`;
      const r = await fetch(url, { headers: authHeaders(token) });
      if (!r.ok) return json({ error: `wise contacts search ${r.status}: ${await r.text()}` }, 500);
      const contacts = await r.json();
      const list = (Array.isArray(contacts) ? contacts : []).map((c: any) => ({
        id: c.id,
        name: c.name ?? c.accountHolderName ?? "",
        account_holder_name: c.accountHolderName ?? "",
        profile_id: c.profileId,
        balance_recipient_id: c.balanceRecipientId,
        avatar: c.avatar ?? null,
        hidden: !!c.hidden,
      }));
      return json({ profile_id: profileId, search_term: term, contacts: list });
    }

    // READ-ONLY: fetch a single recipient by id. Used by the per-profile
    // drift check so we don't have to pull the full account list every time
    // a profile is opened.
    if (body.action === "get_recipient") {
      const id = body.recipient_id;
      if (id == null || String(id).trim() === "") return json({ error: "need recipient_id" }, 400);
      const r = await fetch(`${BASE}/v1/accounts/${id}`, { headers: authHeaders(token) });
      if (!r.ok) return json({ error: `wise GET accounts/${id} ${r.status}: ${await r.text()}` }, r.status === 404 ? 404 : 500);
      const a = await r.json();
      const d = a.details ?? {};
      const hint = d.accountNumber ?? d.iban ?? d.email ?? "";
      const masked = hint ? `••••${String(hint).slice(-4)}` : "";
      return json({
        recipient: {
          id: a.id,
          name: a.accountHolderName ?? a.name ?? "",
          currency: a.currency ?? d.currency ?? "",
          account: masked,           // masked only — never full
          email: d.email ?? null,
          active: a.active !== false,
        },
      });
    }

    // Diagnostic: find all Wise transfers to a specific recipient in a date window.
    // Used to investigate "why doesn't X reconcile" — answers definitively whether
    // a Wise transfer even exists for that recipient.
    //
    // Body: { action: "find_transfers_by_recipient",
    //         recipient_id: <numeric>,
    //         from_iso?: <YYYY-MM-DD>,  // default: 90 days ago
    //         to_iso?:   <YYYY-MM-DD> } // default: today
    if (body.action === "find_transfers_by_recipient") {
      const recipientId = body.recipient_id;
      if (recipientId == null) return json({ error: "need recipient_id" }, 400);
      const dayMs = 86_400_000;
      const toIso = body.to_iso
        ? new Date(body.to_iso).toISOString()
        : new Date().toISOString();
      const fromIso = body.from_iso
        ? new Date(body.from_iso).toISOString()
        : new Date(Date.now() - 90 * dayMs).toISOString();
      const profileId = await getBusinessProfileId(token);
      const all: any[] = [];
      let offset = 0; const pageSize = 100;
      for (let i = 0; i < 50; i++) {
        const qs = new URLSearchParams();
        qs.set("profile", String(profileId));
        qs.set("limit", String(pageSize));
        qs.set("offset", String(offset));
        qs.set("createdDateStart", fromIso);
        qs.set("createdDateEnd", toIso);
        const r = await fetch(`${BASE}/v1/transfers?${qs}`, { headers: authHeaders(token) });
        if (!r.ok) return json({ error: `wise transfers ${r.status}: ${await r.text()}` }, 500);
        const page = await r.json();
        if (!Array.isArray(page) || page.length === 0) break;
        all.push(...page);
        if (page.length < pageSize) break;
        offset += pageSize;
      }
      const matches = all.filter(t => String(t.targetAccount) === String(recipientId));
      return json({
        recipient_id: recipientId,
        window: { from: fromIso, to: toIso },
        total_transfers_in_window: all.length,
        matches_for_recipient: matches.length,
        matches: matches.map(t => ({
          id: t.id,
          status: t.status,
          targetAccount: t.targetAccount,
          targetValue: t.targetValue,
          targetCurrency: t.targetCurrency,
          created: t.created,
          reference: t.reference,
        })),
      });
    }

    return json({ error: "unknown action" }, 400);
  } catch (e) {
    const msg = String(e?.message ?? e);
    console.error("wise-payouts error:", msg);
    return json({ error: msg }, 500);
  }
});
