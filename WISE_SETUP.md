# Wise API setup — connect Wise and pull recipients

This connects the app to your Wise account so it can (a) draft payout batches and
(b) **pull your saved recipients and match them to contractors**. ~15 minutes.

**Security first — read this:**
- Your Wise API token is a **secret**. It lives ONLY server-side, as a Supabase
  *secret* read by the `wise-payouts` edge function. It is never stored in the app,
  the database, or the browser.
- **You** create and paste the token (in your own terminal). Nobody else should
  enter it for you, and it should never be pasted into a web form, a chat, a doc,
  or committed to git.
- The recipient pull is **read-only** and the payout actions only ever create
  **drafts** — the app never moves money. Funding is always done by you in Wise.

Your Supabase project ref: `cgsidolrauzsowqlllsz`

---

## 0. What you'll end up with

```
Wise account                     Supabase (server)                 the app
┌──────────────────┐   token    ┌────────────────────────┐        ┌──────────────┐
│ API token (secret)│──────────►│ secret: WISE_API_TOKEN  │        │ index.html   │
│ recipients,       │           │ edge fn: wise-payouts   │◄──────►│ Wise payouts │
│ transfers         │◄──────────│ (calls Wise with token) │  HTTPS │ screen       │
└──────────────────┘           └────────────────────────┘        └──────────────┘
```

The browser never sees the token. It calls the edge function; the function calls Wise.

---

## 1. Get a Wise API token

Wise calls these **personal API tokens** (they work for business profiles you can
access too). Decide first whether you want **live** or **sandbox**:

- **Live** (`https://api.wise.com`) — your real Wise account and real recipients.
- **Sandbox** (`https://api.sandbox.transferwise.tech`) — a test account with fake
  data. Good for trying the pull without touching production. Sign up separately at
  https://sandbox.transferwise.tech if you want this.

### Steps (live)

1. Log in to **https://wise.com** with the account that holds your business profile.
2. Go to **Settings** (your profile, top-right) → look for **"API tokens"** /
   **"Integrations and tools" → "API tokens"**. (Direct link to try:
   https://wise.com/settings/api-tokens — if it doesn't open, search "API" in Settings.)
3. Click **Create / Add new token**.
   - **Name**: something memorable, e.g. `hr-payroll-readonly`.
   - **Permission / scope**: choose **Read-only** if Wise offers a scope choice and
     you only want the recipient pull + status checks. (Drafting payout batches needs
     **full / read-write**; only choose that if you also want the batch-draft feature.
     You can start read-only and upgrade later.)
4. Click **Create**. Wise shows the token **once** — copy it now and keep it somewhere
   safe (a password manager). You won't be able to see it again; if you lose it, you
   delete it and make a new one.

> Note: some Wise business accounts require API access to be **enabled** or may show
> the token under the *business* profile rather than the personal one. If you don't
> see "API tokens," check that you're on the business profile, or contact Wise support
> to enable API access.

---

## 2. Install & log in to the Supabase CLI (one-time)

You set the secret and deploy the function with the Supabase CLI. If you already use
it (you deployed `hubstaff-sync` / `wise-payouts` before), skip to step 3.

1. **Install** (pick your OS):
   - macOS (Homebrew): `brew install supabase/tap/supabase`
   - Windows (Scoop): `scoop bucket add supabase https://github.com/supabase/scoop-bucket.git && scoop install supabase`
   - npm (any OS): `npm install -g supabase`
   - Verify: `supabase --version`
2. **Log in**: `supabase login` → it opens a browser to authorize, then returns to the terminal.
3. **Link this project** (run from the repo folder that contains the `supabase/` directory):
   ```
   supabase link --project-ref cgsidolrauzsowqlllsz
   ```
   It may ask for your database password (the one you set when creating the project).

---

## 3. Set the Wise token as a server secret

In your terminal, paste **your** token (replace the placeholder). This stores it in
Supabase, server-side — not in the app or git.

```
supabase secrets set WISE_API_TOKEN="paste-your-wise-token-here"
```

If you're using **sandbox** instead of live, also set the base URL:

```
supabase secrets set WISE_API_BASE="https://api.sandbox.transferwise.tech"
```

(For live you can omit `WISE_API_BASE`; it defaults to `https://api.wise.com`.)

Confirm it's set (shows the *name* only, never the value):

```
supabase secrets list
```

---

## 4. Deploy the wise-payouts function

From the repo folder:

```
supabase functions deploy wise-payouts --no-verify-jwt
```

You should see a success message with the function URL. This deploy includes the new
read-only **`recipients`** action used by the pull.

Quick sanity check that the connection works (returns your business profile id):

```
curl -s -X POST "https://cgsidolrauzsowqlllsz.functions.supabase.co/wise-payouts" \
  -H "Content-Type: application/json" \
  -d '{"action":"profile"}'
```

- A JSON like `{"profile_id":1234567}` → token + deploy are good.
- `{"error":"WISE_API_TOKEN not set ..."}` → re-do step 3.
- An auth/401 from Wise → the token is wrong, expired, or lacks access; make a new one.

---

## 5. Pull recipients in the app

1. Open the app (`app/index.html`) and sign in.
2. Pick a **single company** in the top-left switcher (not "All companies").
3. Go to **Process and Pay → Wise payouts**.
4. In the **"Pull recipients from Wise"** panel, click **Pull from Wise**.
5. Review the preview table. Each Wise recipient shows as:
   - **already linked** — that recipient ID is already on a contractor (nothing to do),
   - **will link** — matched to a contractor; its ID will be saved on Save,
   - **unmatched** — no contractor matched (left untouched).
6. Click **Save N matched ID(s)** to store the Wise recipient IDs on the matched
   contractors. Unmatched recipients are never auto-created — for those, set the Wise
   recipient on the contractor's profile manually (Contractors → Edit → Wise recipients).

### How matching works (ID-first)
The pull matches each Wise recipient to a contractor by **stored Wise recipient ID
first** (immune to name changes), then a strict normalized name, then a loose
first+last name. Once an ID is saved, future pulls match by ID — so even if the
recipient's name in Wise differs from the contractor's name, they still match.

---

## 6. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| "WISE_API_TOKEN not set on the server" | Step 3 didn't take, or you deployed before setting it. Set the secret, redeploy. |
| 401 / "Unauthorized" from Wise | Token wrong/expired/insufficient scope. Create a new token (step 1), re-set (step 3). |
| `accounts 4xx` error on pull | Your Wise account may return recipients under a different shape/endpoint. Tell me the error text and I'll adjust the field mapping in the edge function. |
| Pull returns 0 recipients | You may have no saved recipients on that profile, or you're on the wrong profile (live vs sandbox). |
| "Pick a single company first" | Switch out of consolidated/"All companies" mode in the top-left switcher. |
| Recipients matched to the wrong person | Names collided. Clear the bad `wise_recipient_id` on that contractor's profile and set the correct recipient manually; the stored ID then wins on future pulls. |

---

## Notes
- **No money moves** from any app action: the recipient pull is read-only, and payout
  actions only create drafts. You complete and fund batches in Wise yourself.
- The token can be **rotated** anytime: create a new one in Wise, `supabase secrets set
  WISE_API_TOKEN="..."` again, then delete the old one in Wise. No redeploy needed.
- Account numbers are **never** stored or shown in full — the pull shows a masked
  hint (last 4) only.

---

## Two recipient identifiers — and why we use the numeric one

Wise has **two** identifiers for the same recipient account, and they are NOT
interchangeable:

| Identifier | Looks like | Used by |
|---|---|---|
| **Numeric account id** | `1372559053` | the **API** (recipient pull, transfer/batch `targetAccount`) — what this app stores in `wise_recipient_id` |
| **UUID** | `33e5a91a-cb38-...` | the **manual Batch Payments CSV** template (`recipientId` column) in Wise's web UI |

**The API does not expose the UUID.** Verified (May 2026) against this account's token:
`v1/accounts`, `v2/accounts` both return the **numeric id only** — no UUID field —
and `…/recipients` paths 404. The UUID is minted by Wise's batch-upload product and
is not retrievable via the personal-token API.

**Consequence:** the app **cannot generate the manual Batch Payments CSV** with valid
`recipientId` values. Don't try to build that — it would produce a file Wise rejects.

**What to use instead:** the app's built-in **"Create Wise batch" (API batch)** path
(`wise-payouts` action `batch`). It creates a Wise batch group and adds one transfer
per contractor via the API using the **numeric** id — the same end result as the manual
CSV upload, without the file. You still review, complete, and **fund** the batch in Wise.
The numeric defaults were validated against a real batch (all paid accounts matched).

> If Wise later enables a **Batch Payments API** for this account (which uses UUIDs and
> is separate from the recipient/transfer endpoints), revisit this — but as of the last
> check it was not available via the API.

---

## Reconcile a paid batch & poll Wise for status

After Wise processes the batch you uploaded, the **app's database doesn't yet
know** which Wise transfer IDs map to which contractors — that information only
appears on Wise's side. To close the loop, the app has two new pieces:

### 1. "Reconcile with Wise" card (Process Payroll → after Summary)

- In Wise, open the processed batch and click **Download** to get the processed
  CSV. It has your original upload columns plus a `transferId` column.
- In the app, on the same locked/paid period, click **Import processed Wise CSV**
  and pick that file.
- The app does three things in one pass:
  1. Matches rows by `recipientId` (the stable Wise recipient UUID) and writes
     the `transferId` back into `payments.wise_transfer_id`. **Idempotent** —
     re-importing the same file is a no-op for rows already on file.
  2. Compares the amount Wise actually transferred against the DB's recorded
     amount and shows any variances (DB ≠ Wise = ₱ delta).
  3. Calls the **poll** action to ask Wise for the current status of every
     transfer in the period and marks payments `sent` once Wise reports
     `outgoing_payment_sent` / `completed` / `sent`. In-flight states like
     `processing` and `funds_converted` are surfaced but do **not** mark paid.

You can also click **Poll Wise now** to skip the import and just re-check status
once transfer IDs are already on file.

### 2. Manual / scheduled poll endpoint

The `wise-payouts` edge function gained a `poll` action so you can run the same
reconcile from a script or any scheduler:

```bash
curl -X POST https://<your-project-ref>.functions.supabase.co/wise-payouts \
  -H "Authorization: Bearer <SUPABASE_ANON_KEY_OR_SERVICE_ROLE>" \
  -H "Content-Type: application/json" \
  -d '{"action":"poll","only_drafts":true}'
# Optional: scope to a single period
#   "pay_period_id": "<uuid-of-the-pay-period>"
```

Response:

```json
{ "checked": 13, "marked_paid": 13, "in_flight": 0, "unknown": 0, "results": [...] }
```

The endpoint:

- Reads payments with `wise_transfer_id is not null` (and `status = draft` by
  default — pass `"only_drafts": false` to re-check sent rows too).
- Asks Wise for each transfer's status.
- Writes `status = 'sent'` and `paid_at = now()` for terminal-success states.
  In-flight and unknown states are counted in the response but not written.

To run on a schedule, point any cron-style trigger at the URL (Cloudflare Cron
Triggers, GitHub Actions cron, cron-job.org, etc.). The endpoint is safe to call
repeatedly — it does nothing when there's nothing to update.

**No env-var setup needed.** Supabase auto-injects `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY` into every edge function as default secrets, so the
poll handler can read them with `Deno.env.get(...)` without any
`supabase secrets set` step. (In fact the CLI rejects any secret name that
starts with `SUPABASE_` for exactly this reason — those names are reserved.)

The service-role key is used **inside the function only** to write back to the
`payments` table when Wise reports a transfer is sent. It never leaves the
server. Just deploy and you're done:

```bash
supabase functions deploy wise-payouts --no-verify-jwt
```

See: <https://supabase.com/docs/guides/functions/secrets#default-secrets>

---

## History matcher & one-time backfill

The **matcher** is for paid periods that have no `wise_transfer_id` stored on
the payment rows. That covers:

- Historical periods imported retroactively (you paid in Wise first and reconstructed the period in the app afterwards).
- Periods you paid by uploading the manual Wise batch CSV (Wise generates transfer IDs server-side and never returns them to the app).

The matcher pulls Wise's recent transfer history and links each unmatched
DB payment to its actual Wise transfer by **recipient UUID + amount + pay-date
window (±14 days)**. It writes the transfer ID and nothing else — amounts are
never changed.

### Per-period (Process and Pay → Reconcile with Wise → "Match from Wise history")

Run this on a single period when you want to fix just that period. The result
panel shows four outcomes:

- **Matched cleanly** — exactly one Wise transfer matches recipient AND amount in the window. Transfer ID was written. Status polling now works.
- **Matched with variance** — exactly one transfer matches recipient + date but the amount Wise sent differs from the DB. Transfer ID was written anyway (so polling works) but the variance is surfaced for human review. The DB amount is NOT changed automatically.
- **Ambiguous** — multiple transfers match recipient + amount + window. Nothing was written; you'll need to pick the right one or wait for the next status check.
- **Unmatched** — no Wise transfer fits. Common causes: worker has no `wise_recipient_uuid`, paid via BPI not Wise, transfer happened outside ±14 days, or funded from a different Wise account.

### Global one-time backfill (Reports → Wise reconciliation → "Backfill all paid periods")

Scans every paid Wise payment without a `wise_transfer_id` across **all
periods**. Idempotent — running it again only touches new unmatched rows.
Inline-confirm before it runs. Use this once to clean up the historical
backlog, then rely on the per-period button going forward.

### Operational notes

- The matcher uses one Wise API call (paged) plus one DB write per match. It is safe to call repeatedly — already-matched rows are skipped.
- After a successful match, the next poll (or the next "Check Wise status" click on Process and Pay) will pick up the real Wise status and flip the row to `sent`.
- The matcher does **not** move money and does **not** modify amounts. It only writes `wise_transfer_id`.

---

## Test the Wise API draft flow in sandbox (recommended before relying on it)

Card #3 on Process and Pay ("Automatic Wise API draft") creates Wise transfers
via the API instead of via the manual CSV upload. It's been built but never
verified end-to-end on this Wise account. Before relying on it for a real
batch, test in Wise's sandbox.

### One-time sandbox setup (you do this)

1. **Create a Wise sandbox account.** Go to
   <https://sandbox.transferwise.tech/register> and sign up with any email
   address. The sandbox is completely separate from production — no real money,
   no real recipients.
2. **Generate a sandbox API token.** In the sandbox dashboard:
   Settings → API tokens → Create new token → name it `wise-payouts-sandbox`,
   give it **Full access**, copy the token.
3. **Add a couple of fake recipients in the sandbox** (Recipients → Add). One
   PHP recipient is enough to test a batch.
4. **Point the edge function at sandbox** by setting two secrets in your terminal:

   ```bash
   cd hr_payroll_app
   supabase secrets set \
     WISE_API_BASE="https://api.sandbox.transferwise.tech" \
     WISE_API_TOKEN="<your sandbox token from step 2>"
   ```

   No redeploy needed — secrets take effect immediately.

5. **Run the sandbox test:** in the app, on a locked period with at least one
   Wise-method contractor, go to Process and Pay → card #3 → "Pull recipients
   from Wise" (this will show your sandbox recipients), match them, then create
   a Wise batch.
6. **Check what happened in the sandbox dashboard:** Batch payments should show
   the drafted batch. If it does, **Path B works on your account.** If you get
   an error like "batch-groups not enabled for this profile", Path B isn't
   available for your real account either — fall back to manual CSV uploads
   plus the matcher.

### Switch back to production after testing

Replace the sandbox secrets with the production ones — same command, different values:

```bash
supabase secrets set \
  WISE_API_BASE="https://api.wise.com" \
  WISE_API_TOKEN="<your production token>"
```

Or, if you'd rather just remove the override (and let the default
`https://api.wise.com` apply), unset it:

```bash
supabase secrets unset WISE_API_BASE
supabase secrets set WISE_API_TOKEN="<production token>"
```

**Important:** the sandbox token is useless against production and vice versa.
Don't mix them. If you ever see "Bearer token invalid" errors after switching,
you probably forgot to swap the token along with the base URL.

---

## External-source drift checks (Wise + Hubstaff)

Two read-only checks help keep DB / Wise / Hubstaff in sync without
auto-overwriting anything:

### Per-contractor (Contractors → Edit → "External sources")

When you open a contractor's profile, an **External sources** section lazy-loads:
- **Wise:** what the linked recipient looks like (name, email if present, masked
  account hint). Mismatches with the DB show a ⚠️.
- **Hubstaff:** what the linked user has (name, email). Mismatches show a ⚠️ and
  expose a **Push to Hubstaff…** button — click, type a reason, confirm, and
  the DB value is pushed to Hubstaff via the new `update_user` edge function.

**Wise side is read-only.** The Wise API does not allow editing existing
recipients (KYC reasons). Fix Wise drift either in Wise's web UI or by
correcting the DB to match.

**Hubstaff push is strictly limited to `name` and `email`.** The edge function
hardcodes the allowlist — any attempt to push role / status / rate / anything
else is silently dropped. This is belt-and-suspenders against UI bugs or
misuse: only safe identity fields can ever be written.

### Bulk drift summary (Reports → Wise reconciliation → "Cross-system drift")

Click **Scan all** to scan every linked contractor in the current company
against both Wise and Hubstaff. Reports counts plus a click-to-expand list of
who differs and on what fields. Doesn't fix anything — points you at each
profile to do the fix.

### Hubstaff write scope

The `update_user` action requires the Hubstaff personal access token to
include the `hubstaff:write` scope. Check at
<https://app.hubstaff.com/account/personal_access_tokens> — if you see only
`*:read` scopes, regenerate the token with write scope added before this
feature works.

---

## Hubstaff writes: not supported by Hubstaff's public API

We probed 11 candidate endpoints + HTTP method combinations for updating a
Hubstaff user's name/email. None worked:

- `PATCH/POST /v2/users/{id}` → **405 Not Allowed** (path is read-only)
- `POST /v2/users/{id}/update` → **404 Not Found**
- `PUT/PATCH /v1/users/{id}`, `/v2/users/{id}/profile`,
  `/v2/organizations/{org}/members/{user}`,
  `/v1/organizations/{org}/members/{user}`,
  `/v2/organizations/{org}/members/{user}/edit` → all **422** with
  `{"alert":"Your session has expired. Reloading.."}` — Hubstaff's web-UI
  internal error, meaning these endpoints exist but expect cookie-based
  browser session auth, not Bearer tokens. They are NOT public REST API.

**Conclusion:** the `hubstaff:write` scope covers projects / tasks / time
entries but NOT user-profile updates. The app therefore:

- Reads Hubstaff user names/emails (works fine) and surfaces drift against
  the DB in the contractor profile's "External sources" section.
- Does **not** offer a "Push to Hubstaff" button — when Hubstaff drifts from
  the DB, the only fix is in Hubstaff's own web UI (a "Fix in Hubstaff" link
  is shown on each drift row).
- The `update_user` action and the diagnostic `debug_user_endpoints` action
  have been removed from `hubstaff-sync`. The function only does `list_orgs`,
  `get_user`, and the default activities pull.
