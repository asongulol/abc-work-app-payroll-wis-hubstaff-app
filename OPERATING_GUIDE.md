# Operating guide — running payroll each period

The routine, start to finish. Each pay period is one pass through these steps.
Pay schedule is **semi-monthly**: work 1–15 is paid end of that month; work 16–end
is paid the 15th of the next month. Contractors are **paid in PHP**.

---

## Each pay period — the 6 steps

### 1. Pick the company
Use the **company switcher** (top right). Everything below is scoped to it.

### 2. Bring in the time — *Time & Approval tab*
Either:
- **Option A — CSV**: export the daily report from Hubstaff, drop the file in.
- **Option B — API**: click *List my orgs* → pick org → set the dates → *Sync*.

The preview shows matched vs unmatched contractors and flags anyone inactive.
If it warns about overlapping dates, choose **Overwrite**, **Skip overlapping**,
or **Cancel**. Anyone unmatched needs their *Hubstaff name* set on their profile.

### 3. Approve the time — *same tab, below*
Review the staged hours, then **Approve all pending** (or approve/reject per
person). Only approved time becomes payable. Once approved, the rows clear and
move to *"previously approved periods"* — the screen is ready for the next import.

### 4. Calculate & lock — *Payroll tab*
The period + pay date auto-fill from the imported dates. Check the **Expected
hours** line (working days minus holidays). Click **Calculate**. Review the pay
statements — yellow rows have no rate (fix before locking); you can override any
Gross or add PDD Lunch inline. When it's right, **Lock period & save statements**.
(The calculation auto-saves as a draft, so you won't lose it if you navigate away.)

### 5. Pay people — *Process Payroll tab*
Pick the locked period. You get a summary (Wise vs BPI split) and three options:
- **Wise batch CSV** — download it, upload to Wise → Batch payments, fund it there.
- **Payments CSV** — full per-contractor list (incl. BPI) for manual payments/records.
- **Wise API draft** — select contractors (Select all available), create one Wise
  batch draft. *Drafts only — you complete and fund the batch in Wise.*

A "already downloaded" warning guards against exporting (and paying) a batch twice.

### 6. Mark paid & print — *Process Payroll, the Pay list*
After you've sent payments: **Check Wise status** (auto-marks Wise transfers paid
when Wise reports them sent), and **Mark paid** for BPI/manual ones. Once every
payment is marked paid, the period auto-advances to **paid**. Hit **Print** for a
clean record of the pay run.

---

## Occasional / as-needed

- **A contractor joins**: add them in the Contractors tab; set contract (FT/PT),
  hire date, payout method, and (for Wise) their Wise recipient ID on the profile.
- **A contractor leaves** (e.g. removed from Hubstaff): Contractors tab →
  **Deactivate**. They drop from active lists; their history stays. Their time can
  still be imported for a final period (you'll get an "inactive" warning).
- **Rates change**: edit the rate on the contractor — effective-dated, so history
  is preserved.
- **Health Allowance**: ₱20k/yr, auto-applied in the period containing each
  person's hire anniversary (6 months after hire to start). Toggle on the Payroll tab.
- **13th-month**: optional accrual toggle on the Payroll tab.
- **Holidays**: edit the observed-holiday list via the link on the Payroll tab;
  movable holidays (Good Friday, Thanksgiving, etc.) auto-compute per year.
- **Fix a bad import**: *Imports tab* — view or delete a specific import batch, or
  delete by date range.

---

## Reports — *Reports tab*
Payout by period (PHP + USD reference), contractor utilization, unpaid amounts.
Per-company, or switch to consolidated for an all-company view.

## Money safety reminders
- Contractors are paid in **PHP**; the USD figure is reference only.
- The app **never sends money** — it drafts/prepares; you fund in Wise (or pay BPI).
- Locked statements are the source of truth; if you edit an amount after locking,
  that's flagged.
