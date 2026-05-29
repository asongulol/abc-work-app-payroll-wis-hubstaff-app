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

async function getBusinessProfileId(token: string): Promise<number> {
  const r = await fetch(`${BASE}/v2/profiles`, { headers: authHeaders(token) });
  if (!r.ok) throw new Error(`profiles ${r.status}: ${await r.text()}`);
  const profiles = await r.json();
  const biz = profiles.find((p: any) => p.type === "business") ?? profiles[0];
  if (!biz) throw new Error("no Wise profile found");
  return biz.id;
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
  if (!tRes.ok) return { worker_id: item.worker_id, status: "failed", error: `transfer ${tRes.status}: ${await tRes.text()}` };
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
          if (!tRes.ok) { results.push({ worker_id: item.worker_id, status: "failed", error: `transfer ${tRes.status}: ${await tRes.text()}` }); continue; }
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
      const statuses = [];
      for (const id of ids) {
        const r = await fetch(`${BASE}/v1/transfers/${id}`, { headers: authHeaders(token) });
        statuses.push(r.ok ? { id, status: (await r.json()).status } : { id, status: "unknown" });
      }
      return json({ statuses });
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
          active: a.active !== false,
        };
      });
      return json({ profile_id: profileId, recipients });
    }

    return json({ error: "unknown action" }, 400);
  } catch (e) {
    const msg = String(e?.message ?? e);
    console.error("wise-payouts error:", msg);
    return json({ error: msg }, 500);
  }
});
