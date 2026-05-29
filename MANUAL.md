# HR & Payroll — Instruction Manual

The complete operator's guide to the contractor payroll app. This is the
**reference manual** (every tab, every feature); for the quick start-to-finish
routine you run each pay period, see **[OPERATING_GUIDE.md](OPERATING_GUIDE.md)**.

- **What it is:** a single-page web app for paying PH-based independent
  contractors. Time comes from **Hubstaff**, money goes out via **Wise** (in
  **PHP**), and everything is stored in Supabase.
- **What it never does:** send money on its own. The app *prepares* payments
  (CSV batches or Wise API drafts); **you** fund them in Wise (or pay BPI
  manually). Nothing leaves an account without you completing it in Wise.

---

## 1. Key concepts (read once)

1. **Companies.** Every screen is scoped to the company chosen in the **company
   switcher** in the top bar. Most actions (import, calculate, pay) require a
   **single** company. Choosing *"— All companies (consolidated) —"* gives a
   read-only cross-company view and disables per-company actions.
2. **Pay periods are semi-monthly** (24 per year):
   - Work on the **1st–15th** → period `1–15`, **paid at the end of that month**.
   - Work on the **16th–end** → period `16–last`, **paid on the 15th of the next month**.
3. **Period lifecycle:** `open (draft)` → `locked (ready to pay)` → `paid`.
   - *Open* = a draft calculation you can still edit.
   - *Locked* = statements are frozen and the batch is ready to pay. Editing a
     locked amount is flagged in the audit log.
   - *Paid* = every payment in the batch is marked paid.
4. **Contractors are paid in PHP.** Any USD figure shown is a **reference only**.
5. **ID-first matching.** Whenever the app pulls people or recipients from an
   external system (Hubstaff, Wise), it matches to existing records by the
   provider's **stable ID first**, then falls back to name. It stores the ID on
   first match so future syncs are immune to name changes. It never creates a
   duplicate without first checking for a match.
6. **Time approval gate.** Imported/entered hours are staged as **pending** and
   are **not payable** until you approve them.

---

## 2. Getting in

1. Open the app (the single `app/index.html` page, served from wherever it's
   hosted). First run shows the **Connect** screen.
2. Enter the Supabase URL and anon key (one-time; stored in your browser).
   See **[SETUP.md](SETUP.md)** for where these come from.
3. Pick a company in the top-bar switcher. You're ready.

> First-time environment setup (Supabase, Wise token, Hubstaff token, edge
> functions) lives in **[SETUP.md](SETUP.md)** and **[WISE_SETUP.md](WISE_SETUP.md)**.
> This manual assumes that's already done.

---

## 3. The tabs, in workflow order

The tab bar is grouped to read like the real process:

| Group | Tab | What you do there |
|---|---|---|
| **Setup** | Contractors | Add/maintain people, rates, payout details |
| **Setup** | Documents | Track IC agreements, W-8BEN, expiries |
| **Run payroll** | Time & Approval | Import / enter hours, then approve them |
| **Run payroll** | Calculate | Turn approved time into pay statements, then lock |
| **Run payroll** | Process and Pay | Pay the locked batch (Wise / BPI), mark paid |
| **Review** | Review & Recon Batches | Inspect a batch; reconcile against Wise |
| **Review** | Reports | Payout, utilization, per-contractor summaries |
| **Review** | Imports | View / delete time-import batches |
| **Review** | Audit Log | Who did what, when (filter + export) |

---

## 4. Contractors (Setup)

The roster for the selected company. Click any row (or **Edit**) to open the
full profile. Three action buttons sit in the header:

### 4.1 + Add contractor
Creates a new contractor in the current company and opens their profile so you
can fill in details, rate, and payout method. Use this for **one** person.

### 4.2 ⇪ Bulk import
Import or update **many** contractors at once. Opens a modal with a
parse → preview → commit flow.

1. **Input.** Paste rows straight from a spreadsheet (tab-separated) **or**
   upload a CSV. A header row is required; column names are flexible.
2. **⬇ Download CSV template** gives you a ready-made header row plus an example
   line to fill in.
3. **Matching is Wise-first**, per the ID-first rule:
   `Wise recipient id → Wise UUID → Hubstaff user id → name (strict) → name (loose)`.
   - **Matched** rows are **updated in place**. Blank cells never wipe existing
     values — an empty column leaves that field untouched.
   - **Unmatched** rows are **created** (only after the match check).
4. **Prefer the Wise account name** (checkbox, on by default): for any row with a
   numeric Wise recipient id, the preview fetches the **Wise account-holder name**
   and uses it as the contractor's name — so the stored name matches exactly what
   payouts and reconciliation see. Falls back to the sheet name when Wise can't
   return one (Wisetag / balance recipients). Wise-named rows are tagged in the
   preview. *(This makes live, read-only Wise calls during preview — untick it
   for a no-API dry run.)*
5. **Preview** tags every row **CREATE / UPDATE / SKIP**, shows what it matched
   on, the Wise id/UUID, the rate, and a per-field `from→to` change summary.
   Error rows (e.g. no name and no Wise match) are excluded.
6. **Commit.** Click *Import N contractor(s)*. You get a result summary and, if
   anything failed, a per-row error table. Every row is audit-logged.

**Accepted columns:** Name (or First/Last name), Wise recipient id, Wise UUID,
Payout method (wise/bpi/gcash/paymaya/paypal), Rate, Rate effective (YYYY-MM-DD),
Email, Mobile, Role, Contract (FT/PT), Hubstaff user id, Hubstaff name, Hire
date, Date of birth, PH address, GCash, PayMaya, PayPal, Health allowance
(yes/no), 13th month (yes/no), Status (active/ended), Started on, Ended on.

### 4.3 ⤓ Pull IDs from Wise
Opens a read-only modal that lists your saved Wise recipients and matches each to
a contractor (by stored Wise ID first, then name), then stores the numeric
**recipient ID** on the matched contractor. It does **not** pull bank details or
the batch-CSV UUID, and **no money moves**. Review the match table, then **Save
matched IDs**; unmatched recipients are left untouched.

### 4.4 The contractor profile
- **Details:** name, email, mobile, PH address, hire date, date of birth,
  Health-Allowance and 13th-month eligibility.
- **Rate:** effective-dated PHP amount (per semi-monthly period). Setting a new
  rate closes the prior one — **history is preserved**, so old periods keep their
  old rate.
- **Payout method & Wise recipient:** choose the channel; store the Wise
  recipient ID (numeric, for the API) and/or UUID (for the manual batch CSV).
  Pull these from Wise here, or type them.
- **Deactivate / Reactivate:** deactivating drops a contractor from active lists
  but keeps all history; their time can still be imported for a final period
  (you'll get an "inactive" warning at lock time).

> **Billing-change prompts:** changing a rate or payout detail flags the roster
> as "changed", so the next Calculate / Lock / Pay action asks you to acknowledge
> before acting on a roster that just moved.

---

## 5. Documents (Setup)

Track each contractor's compliance documents (IC agreement, W-8BEN, etc.) with
signed/expiry dates. Expiring documents are flagged. A nightly **document-expiry**
edge function can email a reminder when something is within 30 days of expiry.

---

## 6. Time & Approval (Run payroll)

Two parts: bring time in, then approve it.

### 6.1 Hubstaff time import
- **Option A — Upload CSV:** export the daily report from Hubstaff and drop the
  file in.
- **Option B — Sync from Hubstaff API:** *List my orgs* → pick the organization →
  set **Start** (Stop auto-fills to the semi-monthly period end) → **Import Time**.

Contractors are matched by **Hubstaff user id first, then Hubstaff name**. The
result shows matched vs unmatched and flags anyone **inactive**. If dates overlap
an existing import you'll be asked to **Overwrite**, **Skip overlapping**, or
**Cancel**. Anyone unmatched needs their *Hubstaff name* set on their profile (or
add them from the unmatched row).

### 6.2 Create Manual Time Entry / Enter Manual Time
The **Create Manual Time Entry** button opens the same grid used for review — this
is where you add hours **by hand** for a contractor (with a period picker), for
people who aren't in Hubstaff or for adjustments. (After an import, this grid
opens automatically for review.)

### 6.3 Approve
Imported/entered hours stage as **pending**. Review the grid, then **Approve all
pending** (or approve/reject per person). **Only approved time becomes payable.**
Time review is per-company — switch out of consolidated to approve.

---

## 7. Calculate (Run payroll)

Turns approved time into pay statements, then locks the batch.

1. **Batch list.** The tab shows the pay periods ready to calculate (approved time
   grouped by period). The actionable ones surface first.
2. **Calculate.** Pick a period (dates + pay date auto-fill). Check the
   **Expected hours** line (working days minus observed holidays). Click
   **Calculate**.
3. **Review the statements.** Yellow rows have **no rate** — fix on the profile
   before locking. You can override a **Gross** or add **Misc** items (Lunch,
   Bonus, Deductions, Other Earns/Hours, Health Allowance, 13th month) inline via
   the per-row **Misc** popup.
   - **Recalculate** re-derives from time and **wipes manual overrides / Misc
     entries** — the warning lists what will be lost.
4. **Auto-save.** The calculation saves as a **draft** continuously, so you won't
   lose work by navigating away.
5. **Lock period & save statements.** Freezes the batch and moves it to *Process
   and Pay*. Inactive contractors with approved time are flagged in red — confirm
   before including them.
6. **Unlock.** A locked period can be unlocked to edit, then re-locked.
7. **Clean up empty drafts.** If a *Clean up N empty draft(s)* button appears, it
   means there are phantom **open** periods with no payments and no approved time
   (leftovers from a deleted batch/import). One click lists and removes them
   safely — it can't touch a real draft, a locked/paid batch, or anything with
   hours behind it.

**Health Allowance** (₱20k/yr) auto-applies around each person's hire anniversary;
**13th-month** is an optional accrual. Both are toggles here. **Holidays** are
edited via the observed-holiday list on this tab — each holiday in a period
reduces Expected hours by one day (8h FT / 4h PT); movable holidays auto-compute
per year.

---

## 8. Process and Pay (Run payroll)

Lists **only locked batches that haven't been fully paid**. (If it says it's
waiting on upstream batches, those are real drafts still on the Calculate tab —
lock them there.) Pick a batch to get a payout summary (Wise vs BPI split) and:

1. **Wise batch CSV** — download it, upload to **Wise → Batch payments**, and
   **fund it in Wise**. Uses each contractor's stored recipient UUID.
2. **Payments CSV** — the full per-contractor list (including BPI) for manual
   payments and your records.
3. **Wise API draft** — select contractors and create one Wise batch **draft**
   via the API. **Drafts only — you complete and fund the batch in Wise.** (Wise
   Tag / balance recipients are excluded from the API draft; pay those via the
   Manual CSV.)

An **"already downloaded"** warning guards against exporting — and paying — the
same batch twice.

### 8.1 Mark paid & finish
After you've sent payments:
- **Check Wise status** auto-marks Wise transfers paid once Wise reports them sent.
- **Mark paid** the BPI/manual ones yourself.
- When **every** payment is marked paid, the period auto-advances to **paid**.
- **Print** for a clean record of the pay run.

---

## 9. Review & Recon Batches (Review)

Pick any **locked or paid** batch from the dropdown to inspect it and
**reconcile** it against Wise — confirming what Wise actually sent matches what
you locked.

- **Reconcile** keys on the Wise recipient UUID/ID. When a CSV row's UUID is
  missing, it falls back to a strict **name + amount + date** match and surfaces
  the candidate for one-click accept.
- **Orphan transfers** (a Wise transfer with no obvious local match — e.g. after
  a contractor changed banks) are surfaced with candidate contractors. When the
  amount+date is unique, it's offered to one row; when ambiguous, you must pick
  and confirm. A post-link sanity probe compares the linked recipient's name to
  the contractor.
- If Reconcile auto-corrects a locked amount, the original is preserved on the
  payment row.

---

## 10. Reports (Review)

- **Payout by period** — PHP totals with a USD reference column.
- **Per-contractor summary** — totals across a date range (gross, net, periods,
  PTO) for annual statements / visa / mortgage requests.
- **Utilization** — worked hours vs expected.
- **Unpaid amounts** — what's still outstanding.

Works per-company, or consolidated for an all-company view.

---

## 11. Imports (Review)

View or delete time-import batches when an import was wrong.

- **Delete a specific batch**, or **delete by date range** (with a typed `DELETE`
  confirmation for overlapping ranges).
- Deleting an import also clears its (open) pay batch, so you don't leave a
  phantom draft behind.

---

## 12. Audit Log (Review)

A record of every significant action (imports, approvals, locks, rate changes,
payments, contractor edits, bulk imports). Filter by **date range** (the date
filter drives the query, so you can look back beyond the recent-500 default) and
**export to CSV**. Rate/recipient/method changes record the prior value too, so a
change is replayable in a dispute.

---

## 13. End-to-end checklist (each pay period)

1. **Pick the company** (top-bar switcher).
2. **Bring in time** — *Time & Approval* → CSV upload or API sync.
3. **Approve time** — same tab → *Approve all pending*.
4. **Calculate & lock** — *Calculate* → Calculate → review → *Lock period & save*.
5. **Pay** — *Process and Pay* → Wise batch CSV / Payments CSV / Wise API draft →
   fund in Wise (and pay BPI manually).
6. **Mark paid & print** — *Process and Pay* → Check Wise status, Mark paid, Print.
7. **Reconcile** — *Review & Recon Batches* → confirm Wise matches the locked batch.

---

## 14. Common occasional tasks

- **A contractor joins:** *Contractors* → + Add contractor (or include them in a
  bulk import). Set contract, hire date, payout method, and Wise recipient ID.
- **Several join at once:** *Contractors* → ⇪ Bulk import (download the template
  first).
- **A contractor leaves:** *Contractors* → open profile → **Deactivate**. History
  stays; final-period time can still be imported.
- **Rate changes:** edit the rate on the profile — it's effective-dated.
- **A contractor changed banks (Wise):** update their Wise recipient ID/UUID on
  the profile (or *Pull IDs from Wise*); reconcile will then match, and any
  orphan transfer can be linked in *Review & Recon Batches*.
- **Fix a bad import:** *Imports* → delete the batch or date range.

---

## 15. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| A contractor isn't in Calculate | Their time isn't **approved** yet (Time & Approval), or the period was never calculated. |
| "Waiting upstream: N batches not yet locked" | Real drafts on the Calculate tab — lock them. |
| Empty/phantom open periods | Use **Clean up empty draft(s)** on the Calculate tab. |
| Unmatched contractor on import | Set their **Hubstaff name** on the profile, or add them from the unmatched row. |
| Wise recipient warning / missing UUID | Set the Wise recipient ID/UUID on the profile, or use *Pull IDs from Wise*. |
| Wise API draft rejects a Wise Tag person | Pay Wise Tag / balance recipients via the **Manual CSV**, not the API draft. |
| Changes don't show after editing | Hard-refresh the browser (Ctrl/Cmd+Shift+R). |
| Bulk import "name from Wise" is slow | Each Wise-id row makes a read-only Wise call — untick *Prefer Wise account name* for a no-API run. |

---

## 16. Money-safety reminders

1. Contractors are paid in **PHP**; the USD figure is reference only.
2. The app **never sends money** — it drafts/prepares batches; **you fund in
   Wise** (or pay BPI manually).
3. **Locked statements are the source of truth.** Editing an amount after locking
   is flagged in the audit log.
4. Reconcile every paid batch so the app's record matches what Wise actually sent.

---

*This manual reflects the current app. Setup details: [SETUP.md](SETUP.md),
[WISE_SETUP.md](WISE_SETUP.md), [FINISH_SETUP.md](FINISH_SETUP.md). Quick
per-period routine: [OPERATING_GUIDE.md](OPERATING_GUIDE.md).*
