// Supabase Edge Function: hubstaff-sync  (v6 — caches access token; refresh only when expired)
// ---------------------------------------------------------------------------
// Pulls Hubstaff daily activities for a date range and returns per-member daily
// hours to the browser. The Hubstaff REFRESH TOKEN lives ONLY here (server-side
// secret) — it is never sent to or stored in the frontend.
//
// Deploy:
//   supabase functions deploy hubstaff-sync
//   supabase secrets set HUBSTAFF_REFRESH_TOKEN="...your refresh token..."
//
// Call from the app (browser) with the anon key as Authorization, body:
//   { "org_id": 123456, "start": "2026-04-16", "stop": "2026-04-30" }
// Returns:
//   { members: [{ user_id, name, days: { "2026-04-16": seconds, ... }, total }] }
// ---------------------------------------------------------------------------

const TOKEN_URL = "https://account.hubstaff.com/access_tokens";
const API = "https://api.hubstaff.com/v2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status, headers: { ...cors, "Content-Type": "application/json" },
  });
}

// --- persisted refresh token (Hubstaff ROTATES it on every exchange) ---------
// We keep the current token in the api_tokens table and write the new one back
// after each exchange. The function reaches Supabase with the service-role key
// it gets automatically as an env var.
const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SB_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const tokRow = `${SB_URL}/rest/v1/api_tokens?provider=eq.hubstaff`;
const tokHdr = { apikey: SB_KEY, Authorization: `Bearer ${SB_KEY}`, "Content-Type": "application/json" };

async function getStored(): Promise<any | null> {
  try {
    const r = await fetch(`${tokRow}&select=refresh_token,access_token,access_expires_at`, { headers: tokHdr });
    if (!r.ok) return null;
    const rows = await r.json();
    return rows?.[0] ?? null;
  } catch { return null; }
}
async function saveTokens(fields: Record<string, unknown>): Promise<void> {
  await fetch(`${SB_URL}/rest/v1/api_tokens`, {
    method: "POST",
    headers: { ...tokHdr, Prefer: "resolution=merge-duplicates" },
    body: JSON.stringify({ provider: "hubstaff", updated_at: new Date().toISOString(), ...fields }),
  });
}

// Returns a valid access token. CACHES it and only does a refresh EXCHANGE when
// the cached access token is missing/expired — Hubstaff rate-limits refreshes,
// so we must NOT refresh on every call. Access tokens are valid ~24-72h.
async function getAccessToken(): Promise<string> {
  const row = await getStored();
  // reuse the cached access token if it's still good (>5 min of life left)
  if (row?.access_token && row?.access_expires_at) {
    const msLeft = new Date(row.access_expires_at).getTime() - Date.now();
    if (msLeft > 5 * 60 * 1000) return row.access_token;
  }
  // otherwise exchange the refresh token for a new access token
  const refresh = row?.refresh_token ?? Deno.env.get("HUBSTAFF_REFRESH_TOKEN");
  if (!refresh) throw new Error("no Hubstaff refresh token (seed api_tokens, or set HUBSTAFF_REFRESH_TOKEN)");
  const r = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "refresh_token", refresh_token: refresh }),
  });
  if (!r.ok) throw new Error(`token exchange failed (${r.status}): ${await r.text()}`);
  const data = await r.json();
  const expiresIn = Number(data.expires_in || 3600); // seconds
  await saveTokens({
    refresh_token: data.refresh_token ?? refresh,     // Hubstaff rotates it — keep the new one
    access_token: data.access_token,
    access_expires_at: new Date(Date.now() + expiresIn * 1000).toISOString(),
  });
  return data.access_token;
}

async function pageAll(url: string, token: string, key: string): Promise<any[]> {
  const out: any[] = [];
  let pageStart: string | null = null;
  for (let i = 0; i < 50; i++) { // safety cap
    const u = new URL(url);
    if (pageStart) u.searchParams.set("page_start_id", pageStart);
    const r = await fetch(u.toString(), { headers: { Authorization: `Bearer ${token}` } });
    if (!r.ok) throw new Error(`${key} fetch failed (${r.status}): ${await r.text()}`);
    const data = await r.json();
    for (const row of (data[key] ?? [])) out.push(row);
    pageStart = data?.pagination?.next_page_start_id ?? null;
    if (!pageStart) break;
  }
  return out;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const body = await req.json().catch(() => ({}));
    const token = await getAccessToken();   // reads stored token, persists rotated one

    // action: list organizations the token can see
    if (body.action === "list_orgs") {
      const orgs = await pageAll(`${API}/organizations`, token, "organizations");
      return json({ organizations: orgs.map((o: any) => ({ id: o.id, name: o.name })) });
    }

    const { org_id, start, stop } = body;
    if (!org_id || !start || !stop) return json({ error: "need org_id, start, stop" }, 400);

    // members endpoint returns only user_ids; names live on the /users endpoint.
    const members = await pageAll(`${API}/organizations/${org_id}/members`, token, "members");
    const userIds = [...new Set(members.map((m: any) => m.user_id ?? m.id).filter(Boolean))];
    console.error(`members=${members.length} userIds=${userIds.length} sampleMember=${JSON.stringify(members[0] ?? null)}`);

    const nameById: Record<number, string> = {};
    const auth = { headers: { Authorization: `Bearer ${token}` } };

    // Attempt 1: bulk filter  GET /v2/users?id[]=..&id[]=..
    for (let i = 0; i < userIds.length; i += 50) {
      const qs = userIds.slice(i, i + 50).map((id) => `id%5B%5D=${id}`).join("&");
      const r = await fetch(`${API}/users?${qs}`, auth);
      if (!r.ok) { console.error(`bulk users ${r.status}: ${await r.text()}`); break; }
      const data = await r.json();
      console.error(`bulk users sample=${JSON.stringify((data.users ?? [])[0] ?? data)}`);
      for (const u of (data.users ?? [])) nameById[u.id] = u.name ?? `user ${u.id}`;
    }

    // Attempt 2 (fallback): per-user  GET /v2/users/{id}  for any still unnamed
    const missing = userIds.filter((id) => !(id in nameById));
    if (missing.length) {
      console.error(`bulk resolved ${Object.keys(nameById).length}; fetching ${missing.length} individually`);
      for (const id of missing) {
        const r = await fetch(`${API}/users/${id}`, auth);
        if (!r.ok) { console.error(`user ${id} ${r.status}: ${await r.text()}`); continue; }
        const d = await r.json();
        const u = d.user ?? d;
        nameById[id] = u?.name ?? `user ${id}`;
      }
    }

    // daily activities (pre-aggregated per member per day)
    const acts = await pageAll(
      `${API}/organizations/${org_id}/activities/daily?date%5Bstart%5D=${start}&date%5Bstop%5D=${stop}`,
      token, "daily_activities",
    );

    const byUser: Record<number, { days: Record<string, number>; total: number }> = {};
    for (const a of acts) {
      const uid = a.user_id;
      const day = a.date;
      const secs = a.tracked ?? 0;
      const g = byUser[uid] ?? (byUser[uid] = { days: {}, total: 0 });
      g.days[day] = (g.days[day] ?? 0) + secs;
      g.total += secs;
    }

    const result = Object.entries(byUser).map(([uid, g]) => ({
      user_id: Number(uid),
      name: nameById[Number(uid)] ?? `user ${uid}`,
      days: g.days,
      total: g.total,
    })).sort((a, b) => a.name.localeCompare(b.name));

    return json({ start, stop, members: result });
  } catch (e) {
    const msg = String(e?.message ?? e);
    console.error("hubstaff-sync error:", msg);   // shows up in the dashboard logs
    return json({ error: msg }, 500);
  }
});
