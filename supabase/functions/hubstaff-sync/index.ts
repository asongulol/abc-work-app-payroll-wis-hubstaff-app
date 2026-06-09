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

    // --- caller authorization (read actions) ----------------------------------
    // list_orgs / get_user / the default rollup proxy the org's Hubstaff data via
    // the server-held token, so require an authenticated admin (or the cron
    // secret). cron_ingest / activity_backfill keep their own x-cron-secret gate
    // below and are exempt here. Runs BEFORE getAccessToken so an unauthorized
    // caller never triggers a Hubstaff token read/refresh.
    {
      const SECRET_GATED = new Set(["cron_ingest", "activity_backfill"]);
      if (!SECRET_GATED.has(body.action)) {
        let authed = false;
        const cronSecret = req.headers.get("x-cron-secret");
        if (cronSecret) {
          const sRes = await fetch(`${SB_URL}/rest/v1/app_secrets?key=eq.cron_secret&select=value`, { headers: tokHdr });
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
          const aRes = await fetch(`${SB_URL}/rest/v1/admin_users?user_id=eq.${caller.id}&select=user_id`, { headers: tokHdr });
          const admins = await aRes.json().catch(() => []);
          if (!Array.isArray(admins) || !admins.length) return json({ error: "not authorized — admins only" }, 403);
        }
      }
    }
    // --------------------------------------------------------------------------

    const token = await getAccessToken();   // reads stored token, persists rotated one

    // action: list organizations the token can see
    if (body.action === "list_orgs") {
      const orgs = await pageAll(`${API}/organizations`, token, "organizations");
      return json({ organizations: orgs.map((o: any) => ({ id: o.id, name: o.name })) });
    }

    // action: list an org's projects — used to map Hubstaff projects → client
    // companies for per-client hour attribution. READ ONLY.
    if (body.action === "list_projects") {
      const orgId = Number(body.org_id);
      if (!Number.isFinite(orgId) || orgId <= 0) return json({ error: "need org_id (positive integer)" }, 400);
      const projects = await pageAll(`${API}/organizations/${orgId}/projects`, token, "projects");
      return json({ projects: projects.map((p: any) => ({ id: p.id, name: p.name, status: p.status ?? null })) });
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

    // ---- CRON INGEST (server-side daily write; secret-gated) ----------------
    // Pulls Hubstaff daily activity for a recent window and UPSERTs time_entries
    // for ONE company. Mirrors the app's importer EXACTLY: ID-first match on
    // hubstaff_user_id, name fallback (strict sorted-token key, then loose
    // first+last), persisting the id on first name-match. MATCH-BEFORE-CREATE:
    // unmatched members are REPORTED, never inserted (an automated job must not
    // auto-create workers). Never overwrites a row a human already decided
    // (approval != 'pending'). Populates activity_pct = round(overall/tracked*100)
    // — the field the browser API-sync leaves null. The whole action is gated by
    // a shared secret stored in public.app_secrets (RLS-locked; readable only by
    // the service role this function runs as), so it is NOT publicly invocable.
    // cron_ingest (secret-gated daily job, fixed company) and sync_ingest
    // (admin-gated manual browser sync) share the per-client ingest below.
    // sync_ingest supports CONSOLIDATED mode: omit company_id and only
    // project-mapped time is attributed; unmapped project time + PTO are reported.
    if (body.action === "cron_ingest" || body.action === "sync_ingest") {
      const isSync = body.action === "sync_ingest";
      if (!isSync) {
        const provided = req.headers.get("x-cron-secret") ?? body.secret ?? "";
        const sRes = await fetch(`${SB_URL}/rest/v1/app_secrets?key=eq.cron_secret&select=value`, { headers: tokHdr });
        const expected = sRes.ok ? (await sRes.json())?.[0]?.value : null;
        if (!expected || provided !== expected) return json({ error: "unauthorized" }, 401);
      }
      // (sync_ingest is gated by the admin-bearer check at the top of the handler.)

      const orgId = Number(body.org_id);
      const companyId = String(body.company_id ?? "").trim();   // "" allowed for sync_ingest (consolidated)
      if (!Number.isFinite(orgId) || orgId <= 0) return json({ error: "need org_id" }, 400);
      if (!isSync && !companyId) return json({ error: "need org_id and company_id" }, 400);

      // Window: sync_ingest passes explicit start/stop; cron_ingest uses a lookback
      // ending at `today` (deterministic — the cron passes the date).
      let start: string, stop: string, startMs: number, stopMs: number;
      if (isSync && /^\d{4}-\d{2}-\d{2}$/.test(String(body.start ?? "")) && /^\d{4}-\d{2}-\d{2}$/.test(String(body.stop ?? ""))) {
        start = String(body.start); stop = String(body.stop);
        startMs = new Date(`${start}T00:00:00Z`).getTime();
        stopMs = new Date(`${stop}T23:59:59Z`).getTime();
      } else {
        const lookback = Math.max(0, Math.min(31, Number(body.lookback_days ?? 3)));
        const today = /^\d{4}-\d{2}-\d{2}$/.test(String(body.today ?? ""))
          ? String(body.today) : new Date().toISOString().slice(0, 10);
        startMs = new Date(`${today}T00:00:00Z`).getTime() - lookback * 86400000;
        stopMs = new Date(`${today}T23:59:59Z`).getTime();
        start = new Date(startMs).toISOString().slice(0, 10);
        stop = today;
      }

      // name normalization — MIRRORS app/index.html nameTokens/nameKey/looseKey
      const nameTokens = (raw: any): string[] => {
        if (!raw) return [];
        const s = String(raw).normalize("NFD").replace(/[̀-ͯ]/g, "")
          .replace(/[.,]/g, " ").replace(/\bMa\b/ig, "Maria")
          .replace(/\b(jr|sr|ii|iii|iv|n)\b/ig, " ");
        return s.split(/\s+/).filter(Boolean).map((x) => x.toLowerCase());
      };
      const nameKey = (raw: any): string => { const t = nameTokens(raw); return t.length ? [...t].sort().join(" ") : ""; };
      const looseKey = (raw: any): string => { const t = nameTokens(raw); if (!t.length) return ""; return t.length === 1 ? t[0] : `${t[0]} ${t[t.length - 1]}`; };

      const auth = { headers: { Authorization: `Bearer ${token}` } };

      // members -> names
      const members = await pageAll(`${API}/organizations/${orgId}/members`, token, "members");
      const userIds = [...new Set(members.map((m: any) => m.user_id ?? m.id).filter(Boolean))];
      const nameById: Record<number, string> = {};
      for (let i = 0; i < userIds.length; i += 50) {
        const qs = userIds.slice(i, i + 50).map((id) => `id%5B%5D=${id}`).join("&");
        const r = await fetch(`${API}/users?${qs}`, auth);
        if (!r.ok) break;
        const data = await r.json();
        for (const u of (data.users ?? [])) nameById[u.id] = u.name ?? `user ${u.id}`;
      }
      for (const id of userIds.filter((id) => !(id in nameById))) {
        const r = await fetch(`${API}/users/${id}`, auth);
        if (!r.ok) continue;
        const d = await r.json(); const u = d.user ?? d;
        nameById[id] = u?.name ?? `user ${id}`;
      }

      // Phase B — per-client attribution: map each Hubstaff project to a client
      // company. EMPTY map (or unmapped project) => time falls to the passed
      // company_id, i.e. byte-identical to the previous single-company behavior.
      const projMap: Record<number, string> = {};
      {
        const pr = await fetch(`${SB_URL}/rest/v1/hubstaff_projects?select=hubstaff_project_id,company_id`, { headers: tokHdr });
        if (pr.ok) for (const r of (await pr.json() as any[])) projMap[r.hubstaff_project_id] = r.company_id;
      }
      const coOf = (projectId: any): string | null => (projectId != null && projMap[projectId]) || (companyId || null);

      // daily activities: tracked + overall (active) seconds per user per CLIENT per day
      // (activities/daily returns one row per user per PROJECT per day, so we route
      // each project's seconds to the client it maps to).
      const acts = await pageAll(
        `${API}/organizations/${orgId}/activities/daily?date%5Bstart%5D=${start}&date%5Bstop%5D=${stop}`,
        token, "daily_activities",
      );
      const trackedDay: Record<number, Record<string, Record<string, number>>> = {};
      const overallDay: Record<number, Record<string, Record<string, number>>> = {};
      let unmappedSecs = 0;
      for (const a of acts) {
        const uid = a.user_id, day = a.date;
        if (!uid || !day) continue;
        const co = coOf(a.project_id);
        if (!co) { unmappedSecs += (a.tracked ?? 0); continue; }   // consolidated + unmapped project: report, don't guess a client
        ((trackedDay[uid] ??= {})[co] ??= {})[day] = (trackedDay[uid][co][day] ?? 0) + (a.tracked ?? 0);
        ((overallDay[uid] ??= {})[co] ??= {})[day] = (overallDay[uid][co][day] ?? 0) + (a.overall ?? 0);
      }

      // PTO per user per CLIENT per day (approved; per-day amounts inside the window).
      // PTO is org-level leave with no project, so it is attributed to the default
      // company_id passed by the cron (the contractor's primary client).
      const ptoDay: Record<number, Record<string, Record<string, number>>> = {};
      try {
        const ptoReqs = await pageAll(`${API}/organizations/${orgId}/time_off_requests`, token, "time_off_requests");
        for (const r2 of (ptoReqs as any[])) {
          if (r2?.status !== "approved") continue;
          const uid = r2?.user_id; if (!uid) continue;
          for (const d of (Array.isArray(r2?.time_off_request_days) ? r2.time_off_request_days : [])) {
            const date = d?.date;
            if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) continue;
            const dMs = new Date(`${date}T00:00:00Z`).getTime();
            if (dMs < startMs || dMs > stopMs) continue;
            const secs = Number(d?.amount_used ?? 0);
            if (!Number.isFinite(secs) || secs <= 0) continue;
            if (companyId) ((ptoDay[uid] ??= {})[companyId] ??= {})[date] = (ptoDay[uid][companyId][date] ?? 0) + secs;
          }
        }
      } catch (_) { /* PTO optional — continue tracked-only */ }

      // Target client companies = the default + every client a mapped project routes
      // to. Worker matching, canonical labels, and the decided-row guard are all done
      // PER company (a worker is only attributed to a client they're linked to).
      const targetCompanies = [...new Set([...(companyId ? [companyId] : []), ...Object.values(projMap)])];
      if (targetCompanies.length === 0) {
        // consolidated sync with no project→client mappings yet — nothing to attribute to
        return json({
          ok: true, window: { start, stop }, company_id: null, clients_attributed: 0, projects_mapped: 0,
          members_seen: userIds.length, rows_written: 0, ids_persisted: 0, skipped_decided: 0,
          unmatched: [], unmapped_seconds: unmappedSecs,
          note: "No client companies to attribute to — map Hubstaff projects to clients first (Configuration → Hubstaff Projects → Clients).",
        });
      }
      const inCos = targetCompanies.map((c) => `"${c}"`).join(",");

      // worker links for all target companies -> per-company match index (id/strict/loose)
      const wcRes = await fetch(
        `${SB_URL}/rest/v1/worker_companies?company_id=in.(${inCos})` +
        `&select=company_id,worker_id,hubstaff_name,hubstaff_user_id,status,workers(first_name,last_name,status)`,
        { headers: tokHdr });
      const links: any[] = wcRes.ok ? await wcRes.json() : [];
      type Idx = { byId: Record<number, any>; strict: Record<string, any>; loose: Record<string, any> };
      const idx: Record<string, Idx> = {};
      for (const co of targetCompanies) idx[co] = { byId: {}, strict: {}, loose: {} };
      for (const l of links) {
        const ix = idx[l.company_id]; if (!ix) continue;
        const val = { worker_id: l.worker_id };
        if (l.hubstaff_user_id != null && !(l.hubstaff_user_id in ix.byId)) ix.byId[l.hubstaff_user_id] = val;
        const realName = `${l.workers?.first_name ?? ""} ${l.workers?.last_name ?? ""}`;
        for (const src of [l.hubstaff_name, realName].filter(Boolean)) {
          const sk = nameKey(src), lk = looseKey(src);
          if (sk && !(sk in ix.strict)) ix.strict[sk] = val;
          if (lk && !(lk in ix.loose)) ix.loose[lk] = val;
        }
      }
      const matchIn = (co: string, uid: number, nm: string) => {
        const ix = idx[co]; if (!ix) return null;
        return (uid != null && ix.byId[uid]) || ix.strict[nameKey(nm)] || ix.loose[looseKey(nm)] || null;
      };

      // canonical source_name per (company, worker): reuse the label already on their
      // rows so we UPDATE the same row instead of inserting a second under a new
      // spelling (unique key is company_id+source_name+work_date).
      const allWorkerIds = [...new Set(links.map((l: any) => l.worker_id).filter(Boolean))];
      const canonical: Record<string, string> = {};   // "company_id|worker_id" -> source_name
      if (allWorkerIds.length) {
        const inList = allWorkerIds.map((w) => `"${w}"`).join(",");
        const cRes = await fetch(
          `${SB_URL}/rest/v1/time_entries?company_id=in.(${inCos})&worker_id=in.(${inList})` +
          `&select=company_id,worker_id,source_name,work_date&order=work_date.desc`,
          { headers: tokHdr });
        if (cRes.ok) for (const row of await cRes.json()) {
          const k = `${row.company_id}|${row.worker_id}`;
          if (row.worker_id && !(k in canonical)) canonical[k] = row.source_name;
        }
      }

      // human-DECIDED rows (approval != 'pending') are protected — keyed by
      // company|source|day AND company|worker|day so a relabeled row stays shielded.
      const exRes = await fetch(
        `${SB_URL}/rest/v1/time_entries?company_id=in.(${inCos})` +
        `&work_date=gte.${start}&work_date=lte.${stop}&select=company_id,worker_id,source_name,work_date,approval`,
        { headers: tokHdr });
      const decidedSrc = new Set<string>(), decidedWrk = new Set<string>();
      if (exRes.ok) for (const row of await exRes.json()) {
        if (row.approval && row.approval !== "pending") {
          decidedSrc.add(`${row.company_id}|${row.source_name}|${row.work_date}`);
          if (row.worker_id) decidedWrk.add(`${row.company_id}|${row.worker_id}|${row.work_date}`);
        }
      }

      const days: string[] = [];
      for (let t = new Date(`${start}T00:00:00Z`).getTime(); t <= stopMs; t += 86400000) {
        days.push(new Date(t).toISOString().slice(0, 10));
      }

      const rows: any[] = [];
      const unmatched = new Set<string>();
      const persistIds: Array<{ company_id: string; worker_id: string; uid: number }> = [];
      let skippedDecided = 0;

      for (const uid of userIds) {
        const nm = nameById[uid] ?? `user ${uid}`;
        // every client this member logged tracked time / PTO against
        const cos = new Set<string>([
          ...Object.keys(trackedDay[uid] ?? {}),
          ...Object.keys(ptoDay[uid] ?? {}),
        ]);
        for (const co of cos) {
          const hit = matchIn(co, uid, nm);
          if (!hit) {
            // member logged time on a client they're not assigned to — report it
            // (assign them to that client to capture the hours) rather than mis-attribute.
            unmatched.add(targetCompanies.length > 1 ? `${nm} (not assigned to the client for some tracked time)` : nm);
            continue;
          }
          const wId = hit.worker_id;
          const src = canonical[`${co}|${wId}`] ?? nm;
          const link = links.find((l: any) => l.company_id === co && l.worker_id === wId);
          if (uid != null && link && link.hubstaff_user_id == null) persistIds.push({ company_id: co, worker_id: wId, uid });
          for (const day of days) {
            const tracked = trackedDay[uid]?.[co]?.[day] ?? 0;
            const pto = ptoDay[uid]?.[co]?.[day] ?? 0;
            if (tracked === 0 && pto === 0) continue;   // don't write empty days
            if (decidedSrc.has(`${co}|${src}|${day}`) || decidedWrk.has(`${co}|${wId}|${day}`)) { skippedDecided++; continue; }
            const ov = overallDay[uid]?.[co]?.[day] ?? 0;
            const activity = tracked > 0 ? Math.round((ov / tracked) * 100) : null;
            rows.push({
              company_id: co, worker_id: wId, source_name: src, work_date: day,
              tracked_seconds: tracked, pto_seconds: pto,
              activity_pct: activity, approval: "pending",
            });
          }
        }
      }

      // Upsert. merge-duplicates updates ONLY the columns in the payload, so
      // pay_period_id / import_batch_id / approved_* on an existing row are
      // preserved; decided rows were filtered out above so approval is never
      // clobbered from a human decision back to 'pending'.
      let written = 0;
      if (rows.length) {
        const up = await fetch(
          `${SB_URL}/rest/v1/time_entries?on_conflict=company_id,source_name,work_date`,
          { method: "POST",
            headers: { ...tokHdr, Prefer: "resolution=merge-duplicates,return=minimal" },
            body: JSON.stringify(rows) });
        if (!up.ok) return json({ error: `upsert failed (${up.status}): ${await up.text()}` }, 500);
        written = rows.length;
      }
      // persist the stable Hubstaff id on links that matched by name (id-first next run)
      for (const p of persistIds) {
        await fetch(
          `${SB_URL}/rest/v1/worker_companies?company_id=eq.${p.company_id}&worker_id=eq.${p.worker_id}&hubstaff_user_id=is.null`,
          { method: "PATCH", headers: { ...tokHdr, Prefer: "return=minimal" },
            body: JSON.stringify({ hubstaff_user_id: p.uid }) });
      }

      return json({
        ok: true, window: { start, stop }, company_id: companyId || null,
        clients_attributed: targetCompanies.length, projects_mapped: Object.keys(projMap).length,
        unmapped_seconds: unmappedSecs,
        members_seen: userIds.length, rows_written: written,
        ids_persisted: persistIds.length, skipped_decided: skippedDecided,
        unmatched: [...unmatched],
      });
    }

    // ---- activity_backfill ----
    // Fill activity_pct on EXISTING time_entries from Hubstaff daily activity,
    // WITHOUT touching tracked hours, approval, pay_period, or anything else — so
    // it is safe even on approved/locked rows (activity is informational, never
    // pay-affecting). It UPDATEs by primary key only: never inserts a row, never
    // changes a human decision. Window: explicit {start,stop} or {lookback_days}
    // (cap 366). By default only fills rows whose activity_pct is null; pass
    // overwrite:true to refresh all. Secret-gated like cron_ingest.
    if (body.action === "activity_backfill") {
      const provided = req.headers.get("x-cron-secret") ?? body.secret ?? "";
      const sRes = await fetch(`${SB_URL}/rest/v1/app_secrets?key=eq.cron_secret&select=value`, { headers: tokHdr });
      const expected = sRes.ok ? (await sRes.json())?.[0]?.value : null;
      if (!expected || provided !== expected) return json({ error: "unauthorized" }, 401);

      const orgId = Number(body.org_id);
      const companyId = String(body.company_id ?? "").trim();
      if (!Number.isFinite(orgId) || orgId <= 0 || !companyId) return json({ error: "need org_id and company_id" }, 400);

      const overwrite = body.overwrite === true;
      let start: string, stop: string;
      if (/^\d{4}-\d{2}-\d{2}$/.test(String(body.start ?? "")) && /^\d{4}-\d{2}-\d{2}$/.test(String(body.stop ?? ""))) {
        start = String(body.start); stop = String(body.stop);
      } else {
        const lookback = Math.max(1, Math.min(366, Number(body.lookback_days ?? 90)));
        const today = /^\d{4}-\d{2}-\d{2}$/.test(String(body.today ?? "")) ? String(body.today) : new Date().toISOString().slice(0, 10);
        start = new Date(new Date(`${today}T00:00:00Z`).getTime() - lookback * 86400000).toISOString().slice(0, 10);
        stop = today;
      }

      const nameTokens = (raw: any): string[] => { if (!raw) return []; const s = String(raw).normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[.,]/g, " ").replace(/\bMa\b/ig, "Maria").replace(/\b(jr|sr|ii|iii|iv|n)\b/ig, " "); return s.split(/\s+/).filter(Boolean).map((x) => x.toLowerCase()); };
      const nameKey = (raw: any) => { const t = nameTokens(raw); return t.length ? [...t].sort().join(" ") : ""; };
      const looseKey = (raw: any) => { const t = nameTokens(raw); if (!t.length) return ""; return t.length === 1 ? t[0] : `${t[0]} ${t[t.length - 1]}`; };
      const auth = { headers: { Authorization: `Bearer ${token}` } };

      const members = await pageAll(`${API}/organizations/${orgId}/members`, token, "members");
      const userIds = [...new Set(members.map((m: any) => m.user_id ?? m.id).filter(Boolean))];
      const nameById: Record<number, string> = {};
      for (let i = 0; i < userIds.length; i += 50) { const qs = userIds.slice(i, i + 50).map((id) => `id%5B%5D=${id}`).join("&"); const r = await fetch(`${API}/users?${qs}`, auth); if (!r.ok) break; const d = await r.json(); for (const u of (d.users ?? [])) nameById[u.id] = u.name ?? `user ${u.id}`; }
      for (const id of userIds.filter((id) => !(id in nameById))) { const r = await fetch(`${API}/users/${id}`, auth); if (!r.ok) continue; const d = await r.json(); const u = d.user ?? d; nameById[id] = u?.name ?? `user ${id}`; }

      // Hubstaff's activities/daily rejects ranges > 31 days, so fetch in ≤31-day
      // chunks and accumulate across the whole requested window.
      const trackedDay: Record<number, Record<string, number>> = {}, overallDay: Record<number, Record<string, number>> = {};
      const stopMsAll = new Date(`${stop}T00:00:00Z`).getTime();
      for (let cs = new Date(`${start}T00:00:00Z`).getTime(); cs <= stopMsAll; cs += 31 * 86400000) {
        const ceMs = Math.min(cs + 30 * 86400000, stopMsAll);
        const cStart = new Date(cs).toISOString().slice(0, 10);
        const cStop = new Date(ceMs).toISOString().slice(0, 10);
        const acts = await pageAll(`${API}/organizations/${orgId}/activities/daily?date%5Bstart%5D=${cStart}&date%5Bstop%5D=${cStop}`, token, "daily_activities");
        for (const a of acts) { const uid = a.user_id, day = a.date; if (!uid || !day) continue; (trackedDay[uid] ??= {})[day] = (trackedDay[uid][day] ?? 0) + (a.tracked ?? 0); (overallDay[uid] ??= {})[day] = (overallDay[uid][day] ?? 0) + (a.overall ?? 0); }
      }

      const wcRes = await fetch(`${SB_URL}/rest/v1/worker_companies?company_id=eq.${companyId}&select=worker_id,hubstaff_name,hubstaff_user_id,workers(first_name,last_name)`, { headers: tokHdr });
      const links: any[] = wcRes.ok ? await wcRes.json() : [];
      const byId: Record<number, any> = {}, strict: Record<string, any> = {}, loose: Record<string, any> = {};
      for (const l of links) { const val = { worker_id: l.worker_id }; if (l.hubstaff_user_id != null && !(l.hubstaff_user_id in byId)) byId[l.hubstaff_user_id] = val; const realName = `${l.workers?.first_name ?? ""} ${l.workers?.last_name ?? ""}`; for (const src of [l.hubstaff_name, realName].filter(Boolean)) { const sk = nameKey(src), lk = looseKey(src); if (sk && !(sk in strict)) strict[sk] = val; if (lk && !(lk in loose)) loose[lk] = val; } }
      const matchMember = (uid: number, nm: string) => (uid != null && byId[uid]) || strict[nameKey(nm)] || loose[looseKey(nm)] || null;

      // activity map: worker_id|day -> activity_pct (only where tracked > 0)
      const actMap: Record<string, number> = {};
      const unmatched = new Set<string>();
      for (const uid of userIds) {
        const nm = nameById[uid] ?? `user ${uid}`;
        const hit = matchMember(uid, nm);
        if (!hit) { if (trackedDay[uid]) unmatched.add(nm); continue; }
        for (const day of Object.keys(trackedDay[uid] ?? {})) {
          const tracked = trackedDay[uid][day] ?? 0;
          if (tracked <= 0) continue;
          const ov = overallDay[uid]?.[day] ?? 0;
          actMap[`${hit.worker_id}|${day}`] = Math.round((ov / tracked) * 100);
        }
      }

      // For each EXISTING row in the window, set activity_pct from the map. Update
      // by PK id, so nothing else on the row (hours/approval/pay) is touched and no
      // new row is ever created.
      // Paginate — PostgREST caps a response at ~1000 rows; a wide window has more.
      const existing: any[] = [];
      for (let off = 0; ; off += 1000) {
        const exRes = await fetch(`${SB_URL}/rest/v1/time_entries?company_id=eq.${companyId}&work_date=gte.${start}&work_date=lte.${stop}&select=id,worker_id,work_date,activity_pct&order=id&limit=1000&offset=${off}`, { headers: tokHdr });
        if (!exRes.ok) return json({ error: `read rows failed (${exRes.status}): ${await exRes.text()}` }, 500);
        const batch = await exRes.json();
        if (!Array.isArray(batch) || batch.length === 0) break;
        existing.push(...batch);
        if (batch.length < 1000) break;
      }
      const updates: any[] = [];
      for (const row of existing) {
        if (!row.worker_id) continue;
        const v = actMap[`${row.worker_id}|${row.work_date}`];
        if (v == null) continue;
        if (!overwrite && row.activity_pct != null) continue;   // only fill gaps unless overwrite
        if (row.activity_pct === v) continue;                   // no-op
        updates.push({ id: row.id, activity_pct: v });
      }

      let updated = 0;
      if (updates.length) {
        // Bulk UPDATE-by-id via a service-role RPC: sets ONLY activity_pct, never
        // inserts, never touches hours/approval/pay. (A PostgREST upsert can't do
        // this — its INSERT branch would violate NOT NULL on the omitted columns.)
        const up = await fetch(`${SB_URL}/rest/v1/rpc/set_time_entry_activity`, {
          method: "POST",
          headers: { ...tokHdr, "Content-Type": "application/json" },
          body: JSON.stringify({ p: updates }),
        });
        if (!up.ok) return json({ error: `update failed (${up.status}): ${await up.text()}` }, 500);
        updated = Number(await up.json()) || updates.length;
      }

      return json({
        ok: true, action: "activity_backfill", window: { start, stop }, company_id: companyId,
        members_seen: userIds.length, rows_in_window: existing.length, rows_updated: updated,
        overwrite, unmatched: [...unmatched],
      });
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
