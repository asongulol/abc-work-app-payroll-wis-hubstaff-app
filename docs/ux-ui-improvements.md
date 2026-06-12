# UX / UI Improvements — what's shipped so far

A catalog of the user-experience and interface work applied to the two apps to date (admin `app/index.html`, portal `portal/index.html`). Organized by theme; the last section is a rough chronological timeline. File references point at where each mechanism lives today. "Both" = present in admin and portal.

This is paired with the design philosophy in [`ux-ui-guidelines.md`](ux-ui-guidelines.md) — that doc is the *why*; this one is the *what shipped*.

---

## The redesign program (phased & reversible)

The admin app was redesigned in numbered, individually-reversible phases behind a kill-switch, so any phase could be rolled back without a revert war:

| Phase | What it delivered |
|-------|-------------------|
| **0 — Safety net** | Frozen `app/legacy.html` + runtime kill-switch (`FORCE_CLASSIC`, `?ui=classic` / `?ui=new`) — instant rollback to the old UI |
| **1 — Foundation** | AA-contrast color pass, semantic landmarks (`<header>`/`<nav>`/`<main>`), skip-to-content link |
| **2 — Loading** | Loading skeletons + a step-checklist component (no more blank screens / layout shift) |
| **3 — Forms** | Form conventions: visible invalid state, required vs. optional markers, inline errors |
| **4 — Provenance** | Recognition-over-recall tooltips + provenance hints; typed-confirm on money actions |
| **5 — Attention-first Home** | New Overview dashboard surfacing what needs action |
| **6 — Robustness/a11y** | Top-level error boundary, full modal a11y (focus-trap / Escape / aria), motion tokens |
| **7 — Navigation** | Replaced the horizontal tab strip with a grouped sidebar |

The contractor portal got its own mobile redesign (navigation & app shell → tables-to-cards → forms & modals → dashboard) plus the "fun Home" pass.

---

## 1. Design system & branding

- **Navy/gold design tokens.** A single CSS custom-property system — `--navy #1F3A68`, `--gold #D4A24C`, semantic `--good/--warn/--bad`, radii (`7/11/16px`), shadows, focus ring, and **motion tokens** (`--dur:.16s`, `--ease`) that respect `prefers-reduced-motion`. Re-skinnable from `:root`. (`app/index.html:42-63`, `portal/index.html:22-23`; both)
- **Unified brand.** Dark-navy topbar with a gold top-accent and the Aaron Anderson E.H.S. LLC mark (boxless white+gold) across both apps; matching favicons and agreement letterhead. (`app/index.html:12580+`, `portal/index.html:1500+`; both)
- **No table/chart libraries.** Sparklines, the activity chart, and progress bars are hand-rolled SVG/CSS — keeps the apps CSP-safe and dependency-free.

## 2. Navigation & information architecture

- **Grouped sidebar nav** replacing the old horizontal tab strip — groups *Home · Manage Team · Run payroll · Review · Configuration*, collapsible to an icon rail. (`app/index.html:12560-12610`)
- **Workflow-ordered tabs**, not alphabetical: Time & Approval → Calculate → Process and Pay mirrors the real payroll pass. Several renames for honesty/clarity ("Sync" → "Import Time", "Setup" → "Manage Team", "Onboarding" → "Hiring & Onboarding", Company → Client filter).
- **Active tab persists across refresh** (`localStorage eis_tab`), and **tabs lazy-mount then stay mounted** — first visit fires the query, later switches are instant and preserve scroll/filters. (`app/index.html:12398-12412`)
- **Quick-find command palette** (⌘K / Ctrl-K) — jump to any contractor, pay period, or section. (`app/index.html:11781-11859`)
- **Cross-tab "drill" navigation** with guardrails: approving time jumps straight to Calculate with the batch loaded; unlocking a period jumps to Calculate to edit; a contractor row opens its profile from anywhere. (`openContractor` / `openPeriodForEdit` / `go`)
- **Mobile**: bottom tab bar (4 key tabs) + a "More" sheet that mirrors the sidebar groups. (`app/index.html:12642-12656`)

## 3. Accessibility

- **Skip link + semantic landmarks** for keyboard/screen-reader users. (`app/index.html:74-76,12576`)
- **Modal a11y helper** `useModalA11y` — focus trap, focus restore on close, optional Escape-to-close, `role="dialog"`/`aria-modal`, and a modal stack so only the topmost dialog handles keys. Wired into ~25 modals. (`app/index.html:11407-11440`)
- **Top-level error boundary** with a recovery screen ("Reload" / "Switch to classic view") so a render crash never shows a white page. (`app/index.html:12665-12687`)
- **AA-contrast** color pass and visible focus rings throughout.

## 4. Feedback & state

- **Loading skeletons** that reserve layout space (no content jump), shimmer disabled under reduced-motion. (`app/index.html:709-718`)
- **Toast + tab-scoped alert system** — `notify()` for transient toasts, `<Alert>` for persistent warnings that stay visible regardless of scroll, all rendered by a singleton `<Toaster>`. Onboarding/expiring/billing-prompt banners were converted to these. (`app/index.html:730-770`)
- **Stale-while-revalidate** on the Overview dashboard and the Calculate batch list — paint cached data instantly from `sessionStorage`, refresh in the background. (`app/index.html:11556`, batch list SWR)
- **Unsaved-changes navigation guard** — `useUnsavedGuard` registers dirty surfaces; tab switch / sign-out / browser-unload pops a styled Save / Discard / Stay modal (not `window.confirm`). (`app/index.html:1560-1576`, `portal/index.html:451-474`; both)
- **Draft autosave** — the Add-Contractor wizard, bulk-import roster, and announcements composer auto-save to `localStorage` and restore on reopen with a "Start fresh" option. (`useAutoDraft`/`DraftNotice`, `app/index.html:1532-1544`)

## 5. Forms & reusable inputs

- **Form conventions**: `aria-invalid` red-border invalid state, required-asterisk styling, inline per-field errors. (`app/index.html:98-100`)
- **`PhoneInput`** — country-code picker with **US + Philippines pinned** atop the full country list; progressive formatting (US `(212) 555-0100`, PH `917-123-4567`), graceful for other countries; round-trips on reload. (`app/index.html:940-987`, `portal/index.html:357-379`; both)
- **`EmailInput`** — native-datalist domain autocomplete ordered by global mailbox share; **work-email fields pin the company domains** (`123babytalks.com`, `abckidsny.com`) to the front. (`app/index.html:990-1003`, `portal/index.html:405-416`; both)
- **Dropdowns over free text** for Relationship, Marital status, Year graduated, Degree, etc.; "Same as current" mirror for permanent address; an 8–5 ET shift default everywhere.

## 6. Money-safety UX

- **Typed-confirm on destructive/financial actions** — you type the exact word/amount to enable the confirm button (e.g. "DELETE" a batch). (`confirmDanger`, `app/index.html:11343-11397`)
- **Billing-dirty gate** — editing a rate / payout method / Wise recipient records a change; before Calculate / Lock / Reconcile the app shows the list and asks you to confirm, so stale billing never silently flows into a pay run. (`app/index.html:12451-12515`)
- **Honest payment flow** — "drafts only, you fund in Wise" messaging, double-send guards, lock/unlock with audit reasons, and reconciliation that won't unlock already-sent rows even when Wise status lags.
- **Reconciliation overview** — list all periods, "reconcile all", and a Paid·Wise-OK state, with auto-scroll to the period detail.

## 7. Admin discoverability & dashboards

- **Attention-first Overview** — pay-cycle pipeline (Time → Calc → Lock → Sent → Settled), net-pay sparkline, and tiles for pending time, drafts, failures, docs-to-review, and incomplete onboarding. (`app/index.html:11478+`)
- **Reports** — per-contractor pay & hours history with daily drill-down, Year/Month multi-select, and a USD reference total.
- **Recognition-over-recall tooltips** (~120 `title=` hints) explaining columns, states, and "why is this disabled" cases (e.g. "No payout method set — can't be paid until set"). (`app/index.html` throughout)
- **Configuration hub** consolidating companies/clients, admins, portal fields, agreement templates, onboarding config, and Wise reconciliation.

## 8. Mobile & responsive

- **Tables-to-cards**: on ≤768px, data tables become stacked label/value cards via CSS only (`data-label` ::before), with per-table opt-out. (`app/index.html:267-317`)
- **App shell**: responsive topbar, bottom nav, and a slide-up "More" sheet; card-action buttons no longer inflate the viewport.
- **Portal desktop layout**: a sidebar + dashboard grid that reflows to mobile with no horizontal scroll, capped/centered content width. (`portal/index.html:167-225`)

## 9. Performance-as-UX

- **Lazy-mounted tabs**, concurrent batch-list fetches (was sequential), and an optional **JSX precompile** (`tools/build-apps.mjs`) that drops the ~2.8 MB in-browser Babel runtime for faster time-to-interactive.
- **No-stale deploys**: `Cache-Control: no-cache` on the shells + a self-update check against `version.txt` so a normal refresh always lands on the latest build; a visible "Build … · sha" footer makes the live version legible.

## 10. Contractor portal — the delightful layer

- **Animated "From New York" sky hero** — a live NY-time gradient (dawn / day / golden-hour / dusk / night) with a weather-reactive backdrop (open-meteo: clear / cloud / fog / rain / snow / storm), an animated lit skyline, the Statue of Liberty torch, and **Milo the bodega cat** narrating a daily NYC trivia fact. Dual PHT/NYT clocks. (`portal/index.html:1206-1251`)
- **Elevated pay card** — Last pay + Next pay, with a **sun-to-payday progress bar** sliding across the semi-monthly period; PHP-only (USD reference removed for contractors); "Total received since <date>". (`portal/index.html:1430-1455`)
- **Activity chart** — 18-day trailing Hubstaff activity %, color-coded (red/blue/green) with a 3-day trend line, scrollable on mobile. (`portal/index.html:1255+`)
- **Shift-anchored mood check-ins** — a 1–5 emoji pop-up near shift start/end (de-duped per shift, not every refresh), logged to `mood_checkins`. (`portal/index.html:1353-1405`)
- **Outstanding-docs handling** — deferred / sent-back documents surface at the top of Home and after the mood check, with inline upload to the correct bucket, a Docs-tab badge, and a "needs replacement" reason. (`portal/index.html:1131-1152,1387-1396`)
- **"From New York" announcements** ("Word from your Mother") posted by admins; **quick-links toolkit** (Hubstaff / Gmail / Providersoft / Wise) with real favicons; personalized "*<First name>*'s Workspace" header and nickname greeting.

---

## Rough timeline

- **Late May** — Process-&-Pay / Calculate / Time workflow redesigns; honest labels; Misc-column popup; audit-log filters + CSV; Google sign-in gate; built-in connection (Connect screen removed).
- **End May** — Contractor portal launches (self-service, richer pay slips, profile self-edit, doc upload, welcome page); 201 personal-info capture; profile tabs; mobile redesign (nav shell → cards → forms → dashboard).
- **Early June** — Onboarding (sign → profile → docs) + HR review console; guided Add-Contractor wizard; desktop navy/gold brand unify; the phased admin redesign (0–7); typed-confirm money actions; modal a11y; sidebar nav; portal "fun Home" with NY sky, Milo, activity chart.
- **Mid June** — Security hardening (edge-function authz, enforced CSP, Turnstile, payments-lock); admin↔company scoping; portal desktop layout; Calculate perf (SWR + concurrent fetch); employer/client model + multi-client invoicing; reusable `PhoneInput` (country picker) and `EmailInput` (domain autocomplete); hiring-doc review alerts + new-hire emails; full country list with US+PH pinned.

> Sourced from the commit history (`git log`) and confirmed against the current code. For the underlying design rationale see [`ux-ui-guidelines.md`](ux-ui-guidelines.md); for architecture see [`code-map.md`](code-map.md).
