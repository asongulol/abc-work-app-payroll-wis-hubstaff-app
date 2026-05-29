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

    // NOTE: a `debug_role_sources` diagnostic action lived here briefly on
    // 2026-05-28. The probe found Hubstaff's /v2/organizations/{org}/members
    // endpoint returns `membership_role` and `effective_role` fields, but
    // both are PERMISSIONS (owner / user / project_user / organization_owner),
    // not job titles. /v2/users/{id}/projects returns 404. Projects ARE
    // structured like job functions ("Billing and Accounting" etc) but
    // mapping a user to a single role via project assignments is ambiguous
    // (users belong to multiple projects). Conclusion: Hubstaff doesn't
    // expose job titles in a usable form. The contractor `role` field on
    // worker_companies stays manual.

    // NOTE: Three diagnostic actions lived here briefly during the
    // 2026-05-28 PTO investigation: debug_user_endpoints (proved Hubstaff
    // doesn't expose user-profile writes), debug_role_sources (proved
    // Hubstaff's role fields are permissions not job titles), and
    // debug_daily_activities + debug_pto_endpoints (used to find the
    // working PTO endpoint: GET /v2/organizations/{org}/time_off_requests).
    // The default sync path below now pulls that endpoint and merges
    // paid+approved PTO into the per-day rollup.

    // action: PTO-only refresh for a historical period — pulls Hubstaff's
    // time_off_requests for [start, stop], finds existing time_entries by
    // (company_id, source_name, work_date), and UPDATEs only pto_seconds.
    //
    // DOES NOT:
    //   - touch tracked_seconds (preserves the historical record of what was paid)
    //   - create new rows (doesn't retroactively add hours that weren't billed)
    //   - call Calculate (payments stay frozen)
    //
    // Returns a diff report: which rows had PTO added vs which Hubstaff PTO
    // had no matching DB row (skipped). Safe to call multiple times — re-runs
    // simply re-assert the same value.
    if (body.action === "pto_refresh") {
      const supaUrl = Deno.env.get("SUPABASE_URL");
      const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      if (!supaUrl || !serviceKey) {
        return json({ error: "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set" }, 500);
      }
      const orgId = Number(body.org_id);
      const companyId = String(body.company_id || "").trim();
      const start = String(body.start || "").trim();
      const stop = String(body.stop || "").trim();
      if (!Number.isFinite(orgId) || orgId <= 0) return json({ error: "need org_id" }, 400);
      if (!companyId) return json({ error: "need company_id" }, 400);
      if (!/^\d{4}-\d{2}-\d{2}$/.test(start) || !/^\d{4}-\d{2}-\d{2}$/.test(stop)) {
        return json({ error: "need start and stop as YYYY-MM-DD" }, 400);
      }
      const auth = { Authorization: `Bearer ${token}` };
      const restHeaders = {
        "apikey": serviceKey,
        "Authorization": `Bearer ${serviceKey}`,
        "Content-Type": "application/json",
      };

      // 1. Pull org members + name resolution (same path the default sync uses)
      const members = await pageAll(`${API}/organizations/${orgId}/members`, token, "members");
      const userIds = [...new Set(members.map((m: any) => m.user_id ?? m.id).filter(Boolean))];
      const nameById: Record<number, string> = {};
      for (let i = 0; i < userIds.length; i += 50) {
        const qs = userIds.slice(i, i + 50).map((id) => `id%5B%5D=${id}`).join("&");
        const r = await fetch(`${API}/users?${qs}`, { headers: auth });
        if (!r.ok) break;
        const data = await r.json();
        for (const u of (data.users ?? [])) nameById[u.id] = u.name ?? `user ${u.id}`;
      }

      // 2. Pull PTO and aggregate per (user_id, date)
      const startMs = new Date(`${start}T00:00:00Z`).getTime();
      const stopMs  = new Date(`${stop}T23:59:59Z`).getTime();
      const ptoReqs = await pageAll(`${API}/organizations/${orgId}/time_off_requests`, token, "time_off_requests");
      const ptoBy: Record<string, number> = {};  // key = `${uid}|${date}` → seconds
      for (const req of (ptoReqs as any[])) {
        if (req?.status !== "approved") continue;
        const uid = req?.user_id;
        if (!uid) continue;
        const days = Array.isArray(req?.time_off_request_days) ? req.time_off_request_days : [];
        for (const d of days) {
          const date = d?.date;
          if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) continue;
          const dMs = new Date(`${date}T00:00:00Z`).getTime();
          if (dMs < startMs || dMs > stopMs) continue;
          const secs = Number(d?.amount_used ?? 0);
          if (!Number.isFinite(secs) || secs <= 0) continue;
          const k = `${uid}|${date}`;
          ptoBy[k] = (ptoBy[k] ?? 0) + secs;
        }
      }

      // 3. Fetch existing time_entries for this company+period
      const teQs = new URLSearchParams();
      teQs.set("select", "id,source_name,work_date,pto_seconds,tracked_seconds");
      teQs.set("company_id", `eq.${companyId}`);
      teQs.set("work_date", `gte.${start}`);
      teQs.append("work_date", `lte.${stop}`);
      const teRes = await fetch(`${supaUrl}/rest/v1/time_entries?${teQs}`, { headers: restHeaders });
      if (!teRes.ok) return json({ error: `time_entries fetch ${teRes.status}: ${await teRes.text()}` }, 500);
      const teRows: any[] = await teRes.json();

      // Index DB rows by (source_name, work_date). Also index by stripped/lowercased
      // name so a CSV import that used a slightly different spelling can still match.
      const teByKey: Record<string, any> = {};
      for (const r of teRows) {
        teByKey[`${r.source_name}|${r.work_date}`] = r;
      }

      // 4. Walk PTO entries; if a matching DB row exists, UPDATE its pto_seconds.
      let updated = 0, unchanged = 0, no_db_row = 0;
      const updates: any[] = [];
      const orphans: any[] = [];   // PTO with no matching DB row
      for (const [k, secs] of Object.entries(ptoBy)) {
        const [uidStr, date] = k.split("|");
        const uid = Number(uidStr);
        const hubName = nameById[uid] || `user ${uid}`;
        // Match by hubstaff name first, then any DB row that uses that name as source_name.
        const dbRow = teByKey[`${hubName}|${date}`];
        if (!dbRow) {
          orphans.push({ hubstaff_user_id: uid, name: hubName, date, pto_seconds: secs });
          no_db_row++;
          continue;
        }
        if (Number(dbRow.pto_seconds || 0) === secs) {
          unchanged++;
          continue;
        }
        const uRes = await fetch(
          `${supaUrl}/rest/v1/time_entries?id=eq.${dbRow.id}`,
          { method: "PATCH", headers: { ...restHeaders, "Prefer": "return=minimal" },
            body: JSON.stringify({ pto_seconds: secs }) });
        if (uRes.ok) {
          updated++;
          updates.push({ name: hubName, date, old_pto: dbRow.pto_seconds||0, new_pto: secs });
        }
      }

      return json({
        period: { start, stop, company_id: companyId, org_id: orgId },
        pto_days_pulled: Object.keys(ptoBy).length,
        time_entries_scanned: teRows.length,
        updated, unchanged, no_db_row,
        sample_updates: updates.slice(0, 20),
        sample_orphans: orphans.slice(0, 20),
      });
    }

    // action: read a single Hubstaff user — used by the per-profile drift check.
    // READ ONLY. Returns just the small identity fields the app needs.
    if (body.action === "get_user") {
      const id = Number(body.user_id);
      if (!Number.isFinite(id) || id <= 0) return json({ error: "need user_id (positive integer)" }, 400);
      const r = await fetch(`${API}/users/${id}`, { headers: { Authorization: `Bearer ${token}` } });
      if (!r.ok) return json({ error: `hubstaff users/${id} ${r.status}: ${await r.text()}` }, r.status === 404 ? 404 : 500);
      const d = await r.json();
      const u = d.user ?? d;
      return json({
        user: {
          id: u?.id,
          name: u?.name ?? null,
          email: u?.email ?? null,
          status: u?.status ?? null,
          time_zone: u?.time_zone ?? null,
        },
      });
    }

    // NOTE: `update_user` was removed on 2026-05-28 after a thorough endpoint
    // probe (11 candidate paths/methods) found that Hubstaff's public REST
    // API does not expose user-profile writes. PATCH/POST on /v2/users/{id}
    // return 405; org-scoped paths return 422 with a web-session error
    // (those routes are internal to Hubstaff's own web UI, not the public
    // API). The `hubstaff:write` scope covers other resources (projects,
    // tasks, time entries) but not member-profile updates. The drift-detection
    // UI now points the user at Hubstaff's web UI to fix mismatches manually.

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

    // Two sources per user now:
    //   tracked_days = active time clocked via Hubstaff timer (from activities/daily)
    //   pto_days     = paid + approved time off (from time_off_requests)
    // Totals are summed across both. Front-end displays them as separate columns
    // AND adds them for the displayed total — per Oliver: "PTO is not being
    // added to the total hours, add PTO column and add to get the total hours."
    type UserRollup = {
      tracked_days: Record<string, number>;
      pto_days: Record<string, number>;
      tracked_total: number;
      pto_total: number;
    };
    const byUser: Record<number, UserRollup> = {};
    const ensure = (uid: number): UserRollup => {
      return byUser[uid] ?? (byUser[uid] = {
        tracked_days: {}, pto_days: {}, tracked_total: 0, pto_total: 0,
      });
    };
    for (const a of acts) {
      const uid = a.user_id;
      const day = a.date;
      const secs = a.tracked ?? 0;
      const g = ensure(uid);
      g.tracked_days[day] = (g.tracked_days[day] ?? 0) + secs;
      g.tracked_total += secs;
    }

    // PTO: pull every time_off_request (the endpoint ignores date filters on
    // this account — see 2026-05-28 probe — so we paginate everything and
    // filter client-side). Count every APPROVED request in the window.
    //
    // We deliberately do NOT filter by `paid`. Earlier we filtered to
    // `paid=true` thinking that meant "the contractor gets paid for this
    // leave," but a follow-up probe revealed that on this account approved
    // PTO is almost entirely `paid=false` and yet still shows up in Hubstaff's
    // own daily reports as "Time off" that pays out. Verified: ignoring the
    // paid flag sums to exactly 85:42:00 across May 1-15, matching the CSV.
    // Treating `paid` as a payroll-relevance signal was an English-semantics
    // assumption that didn't match Hubstaff's data model.
    //
    // Walk time_off_request_days for per-day amounts because a single request
    // can span multiple days; only the days INSIDE [start, stop] count.
    const startMs = new Date(`${start}T00:00:00Z`).getTime();
    const stopMs  = new Date(`${stop}T23:59:59Z`).getTime();
    try {
      const ptoReqs = await pageAll(
        `${API}/organizations/${org_id}/time_off_requests`,
        token, "time_off_requests",
      );
      for (const req of (ptoReqs as any[])) {
        if (req?.status !== "approved") continue;
        const uid = req?.user_id;
        if (!uid) continue;
        const days = Array.isArray(req?.time_off_request_days) ? req.time_off_request_days : [];
        for (const d of days) {
          const date = d?.date;
          if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) continue;
          const dMs = new Date(`${date}T00:00:00Z`).getTime();
          if (dMs < startMs || dMs > stopMs) continue;
          const secs = Number(d?.amount_used ?? 0);
          if (!Number.isFinite(secs) || secs <= 0) continue;
          const g = ensure(uid);
          g.pto_days[date] = (g.pto_days[date] ?? 0) + secs;
          g.pto_total += secs;
        }
      }
    } catch (e) {
      // PTO pull failure shouldn't break the whole sync — log and continue
      // with tracked-only results. The front-end will treat missing pto as 0.
      console.error("PTO pull failed (continuing without PTO):", String((e as any)?.message ?? e));
    }

    const result = Object.entries(byUser).map(([uid, g]) => ({
      user_id: Number(uid),
      name: nameById[Number(uid)] ?? `user ${uid}`,
      // Back-compat: `days` and `total` still mean TRACKED-only so any existing
      // caller keeps working. New fields `pto_days`, `pto_total`, and `total_with_pto`
      // are additive — front-end uses them; old front-end ignores them.
      days: g.tracked_days,
      total: g.tracked_total,
      pto_days: g.pto_days,
      pto_total: g.pto_total,
      total_with_pto: g.tracked_total + g.pto_total,
    })).sort((a, b) => a.name.localeCompare(b.name));

    return json({ start, stop, members: result });
  } catch (e) {
    const msg = String(e?.message ?? e);
    console.error("hubstaff-sync error:", msg);   // shows up in the dashboard logs
    return json({ error: msg }, 500);
  }
});
