# Appendix 01 — Design system, app shell, navigation & global UX

> Granular build spec with `app/index.html` line anchors. Master overview: [../FEATURES.md](../FEATURES.md).

**Source:** `app/index.html` (single file, ~13,013 lines, React 18 UMD + in-browser Babel + `@supabase/supabase-js` via esm.sh).

---

## 1. Visual design / theme

### 1.1 Where the CSS lives
One main `<style>` block at **lines 41–584** holds the entire app theme (CSS custom properties + component classes). Two other tiny `<style>` strings exist only inside printable HTML generated for an agreement preview (`10811`) and an invoice (`12540`).

### 1.2 Color palette — CSS custom properties (`:root`, lines 42–63)

| Variable | Value | Role |
|---|---|---|
| `--navy` | `#1F3A68` | Primary brand / topbar / active nav / buttons |
| `--navy-700` | `#162a4d` | Button hover, topbar bottom border |
| `--navy-50` | `#eef2f8` | Hover wash on nav/rows |
| `--gold` | `#D4A24C` | Accent: topbar top border (3px), brand subtitle |
| `--gold-soft` | `#f7edd8` | soft gold |
| `--bg` | `#f4f6f9` | Page background |
| `--card` | `#ffffff` | Card / panel / sidebar surface |
| `--surface-2` | `#f8fafc` | Secondary surface |
| `--border` | `#e4e8ee` | Default hairline border |
| `--border-strong` | `#ccd3dd` | Input borders, header bottom border |
| `--text` | `#15233b` | Body text |
| `--muted` | `#5c6677` | Secondary text |
| `--subtle` | `#677083` | Tertiary text (darkened to hit WCAG AA 4.5:1) |
| `--good` / `--good-soft` | `#0a7d3c` / `#dcfce7` | Success |
| `--warn` / `--warn-soft` | `#b45309` / `#fef3c7` | Warning |
| `--bad` / `--bad-soft` | `#b91c1c` / `#fee2e2` | Danger / error |
| `--accent` / `--accent-soft` | → `var(--navy)` / `var(--navy-50)` | **Re-skin hook** (legacy classNames use `--accent`) |

### 1.3 Radius, shadow, ring, motion (lines 53–62)
- Radius: `--radius-sm:7px`, `--radius:11px`, `--radius-lg:16px`
- Shadows: `--shadow-sm:0 1px 2px rgba(15,28,51,.05)`, `--shadow:0 4px 14px -5px rgba(15,28,51,.14)`, `--shadow-lg:0 16px 40px -12px rgba(15,28,51,.28)`
- Focus ring: `--ring:0 0 0 3px rgba(31,58,104,.22)`
- Motion: `--dur:.16s`, `--ease:cubic-bezier(.2,.6,.2,1)`. **All motion disabled under `prefers-reduced-motion`** (lines 580–583).

### 1.4 Typography (lines 65–68)
- Body: `Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif`; base `14px/1.5`; antialiased.
- Money tables use `font-variant-numeric:tabular-nums`.
- `h2` 19px/700/`-.01em`; `h3` 15px; `.brand` 16px/800; table `th` 11px uppercase letter-spacing `.04em` color `--subtle`.

### 1.5 Brand / logo assets
- Favicon: inline SVG data-URI (line 31) — navy rounded square + gold "mountain/A" triangles + arc; PNG fallback `favicon.png`.
- Topbar mark: `mark-light.png` 38px (`onError` hides). Auth screens: `logo.png`. Assets in `app/`: `favicon.png`, `logo.png`, `mark-light.png`, `legacy.html`, `version.txt`.

### 1.6 Card styling
`.card` (152): white, 1px `--border`, radius 11, padding 20, margin-bottom 16, `--shadow-sm`. `.card.primary` = navy border + bigger shadow. Heading pattern `<h2>` + `.sub`.

---

## 2. Application shell

### 2.1 Top header bar `.topbar` (CSS 77–92; JSX 12902–12914)
Sticky `top:0 z-index:10`, navy, **3px gold top border**, white text, safe-area inset. Contents:
1. `<h1 className="brand">` `mark-light.png` + **"HR & Payroll"** + `<small>`"PH independent contractors" (gold).
2. **Quick find** `🔎 Find` `title="Quick find (⌘K / Ctrl-K)"` → CommandPalette.
3. `.company-switcher` → `<EmployerSwitcher>`.
4. User email span (when session).
5. **Admins** (owner-only) → AdminsModal.
6. **Sign out** — runs the unsaved guard then `sb.signOut()`.

### 2.2 Left sidebar `.sidebar` (CSS 115–141; JSX 12915–12934)
Width `--side-w:212px` (collapsed 60). Sticky `top:var(--topbar-h)` (measured at runtime, default 65). Section labels `.side-group-label` (10px uppercase). Items `.side-item` (13.5/600 muted; hover `--navy-50`; `.active` solid navy bg/white, `aria-current="page"`). `NAV_ICON` (12891) + `tabGroups` (12882–12888) — full list:

| Group | Tab | Label | Icon |
|---|---|---|---|
| HOME | overview | Overview | 🏠 |
| MANAGE TEAM | contractors | Contractors | 👥 |
| | onboarding | Hiring & Onboarding | 🧭 |
| | documents | Documents | 📄 |
| RUN PAYROLL | time | Time & Approval | ⏱ |
| | payroll | Calculate | 🧮 |
| | process | Process and Pay | 💸 |
| REVIEW | batches | Review & Recon Batches | 📦 |
| | reports | Reports | 📊 |
| | invoicing | Invoicing | 🧾 |
| | imports | Imports | 🗂 |
| | audit | Audit Log | 📝 |
| CONFIGURATION | configuration | Configuration | ⚙ |

`.side-collapse` toggle (icon `«`/`»`, persisted `localStorage["eis_sidebar"]`).

### 2.3 Routing (tab state)
Single `tab` string in `App` (12720), restored/validated from `localStorage["eis_tab"]`, persisted on change. `go(id)` (12889): runs unsaved guard, sets tab, scrolls `.wrap` to top. Cross-tab: `openContractor(workerId)` (12793), `openPeriodForEdit({start,end})` (12808). **Render:** `overview`+`configuration` conditionally mounted (each in its own `ErrorBoundary`); all other tabs lazy-mount on first visit then stay mounted hidden via `display:none` (`seenTabs`, 12731), `useQuery` gated by `enabled`/`active`. All tabs pinned to `employerId`.

### 2.4 Mobile nav (≤768px)
Bottom tab bar `.bottom-nav` (CSS 453–472; JSX 12965–12977): `bottomPrimary` = `[overview Home, time Time, payroll Calc, process Pay]` + **More** (`☰`). `MoreSheet` (12073–12095) = slide-up dialog with full grouped nav.

### 2.5 Build footer
`Build {BUILD}` (12961) — `BUILD` (596) = `"<date> · <sha>"`, stamped by `tools/stamp-build.mjs`, matched in `version.txt`.

---

## 3. Global reusable components

- **Buttons** (CSS 162–175): `.btn` navy/white (hover navy-700, active translateY1, focus ring, disabled .5); `.btn.ghost` white/navy outline; `.btn.danger` red; `.btn.danger-outline`; `.btn.sm`. Mobile ≤640: `min-height:44px`.
- **Modals** (CSS 355–359, 484–528): `.modal-bg` fixed, backdrop `rgba(15,28,51,.45)`, `z-index:20` (50 on mobile), `modalFade`. `.modal` white radius-16 padding-24 max-680, `modalRise`. **≤640px → bottom sheet** (full-width, 92dvh, rounded top, `sheetUp`, sticky `.actions` bar, 16px fonts). Pattern: `<div className="modal-bg" onClick={onClose}><div className="modal" ref={mref} role="dialog" aria-modal="true" aria-labelledby="…" onClick={e=>e.stopPropagation()}>…`.
- **Tables** (CSS 156–161, 264–323): base + `.table-scroll`. **Responsive cards ≤767px**: `.table-scroll:not(.keep-table)` → `thead` hidden, each `<tr>` a card, each `<td>` a `[data-label][value]` row (`::before content:attr(data-label)`). Cell classes `.card-title`, `.card-action`, `.card-skip`; opt out `.keep-table`. Canonical example: Contractors table 2768–2808.
- **Pill** `.pill` (176–183): variants `.ft` navy, `.pt` pink `#fce7f3`/`#9d174d`, `.active` green, `.inactive` gray, `.warn`, `.bad`, `.info`. Usually + `codeHint` title.
- **Badge** `Badge({s})` (10598): `{color,bg,txt}` span.
- **Banner/Alert** (CSS 336–352; 772/830/835): `.banner` (warn-soft, 5px accent border, auto icon) + `.success`/`.error`/`.info` (info blue, not green). `<Banner msg/>` auto-detects tone via `bannerTone`. `<Alert show type tab>` = persistent tab-scoped toast.
- **Skeleton** `Skeleton({rows})` (740) shimmer bars; `<ProgressSteps>` (805) checklist + elapsed timer.
- **Empty/stub** `.empty` (335), `.stub` (376).
- **FilterBox** (1127): one input bound to q/setQ.
- **Tooltips** `.tip-wrap`/`.tip-body` (438–447): inline pattern with multiline bubble; coded values use `title=codeHint(...)`.
- **Toasts** `.toaster` (570–578) fixed top-center.
- **CommandPalette (⌘K)** (12103): opened by Cmd/Ctrl-K (12738) or 🔎 Find. Loads workers + last 60 periods on open; result set = Sections + Contractors (👤, cap 8) + Periods (📅, cap 8), total cap 14; ↑/↓/↵/Esc; routes via `go`/`openContractor`/`openPeriodForEdit`; `role=listbox`/`option`.

---

## 4. Data-entry helpers

- **`EmailInput`** (1019) `{value,onChange,work,pin,style,placeholder}`: `<input type=email>` + `<datalist>`. `EMAIL_DOMAINS` (1001) gmail/yahoo/hotmail/outlook/icloud/aol/proton.me/gmx/yandex/live/msn/mail.com. `WORK_EMAIL_DOMAINS` (1005) `123babytalks.com`,`abckidsny.com`. `emailSuggestions` (1008) narrows by typed local/domain, cap 8.
- **`PhoneInput`** (969) `{value,onChange,defaultCountry="US",…}`: country `<select>` + `type=tel`; raw while typing, formats on blur. `PHONE_COUNTRIES` (853–911) US+PH pinned then A–Z, flags from ISO codepoints. Helpers `phoneCountry`/`groupNational` (US `(AAA) BBB-CCCC`, PH `AAA-BBB-CCCC`)/`buildPhone`/`parsePhone`/`formatPhone`.
- **`ContractorPicker`** (7443) `{options:[{id,name}],value:Set,onChange,placeholder}`: `.cpick` ghost button + popover (search, Select all (N), Clear, checkbox list); closes outside-click/Esc.
- **Date/time**: native inputs styled globally (CSS 94–96; mobile min-height 44). `ShiftEditor` (624) two `type=time` PHT + ET↔PHT helpers `etToPhtHHMM` (665), `phtToEtHHMM` (674), `fmt12` (681).
- **Money/name**: `money(n,cur)` (5806) `"$"`/`"PHP "` 2dp null→"—"; `fullName(w)` (843); `methodLabel(m)` (717); `Avatar` (1034) + `fileToAvatarDataUri` (1044) 256px JPEG data-URI.
- **`codeHint(kind,val)`** (725): tooltips for contract/status/method/pay codes → native `title=`.
- **`useSortFilter(rows,accessors,searchFields)`** (1098) → `{rows, Th, q, setQ}`; `<Th k>` sort (▲/▼/⇅).
- **`useQuery(client,runner,deps,opts)`** (1455) → `{data,error,loading,reload}`; `opts.enabled:false` defers (gates hidden tabs).
- **`pageAll(countQuery,rangeQuery,1000)`** (1483): count + concurrent `range()` pages (1000-row-cap fix).

---

## 5. Cross-cutting UX systems

### 5.1 Unsaved-changes guard (1613–1693)
`_guards` Map. `useUnsavedGuard({dirty,label,save,discard})` (1627). `confirmUnsaved()` (1635) → Promise<bool>; only `_savableDirty` (1625) blocks; opens single `UnsavedChangesModal` (1661, mounted at root). Choke points: `go()`, `openContractor`/`openPeriodForEdit`, Sign out, `beforeunload`. `UnsavedDialog` (1668): **Save / Discard / Stay** (1685–1689); keeps open if a Save fails. `guardedClose(onClose)` (1657).

### 5.2 Draft autosave (1571–1611)
`draftSave(key,value)` (1579, sync) / `draftLoad` (1574) / `draftClear` (1575). `useAutoDraft(key,value,hasContent,doneRef)` (1580) debounced 500ms. Resume: `<DraftNotice show onFresh>` (1587), `<HireDraftBanner companyId refreshKey onResume>` (1595) on Contractors (2810).

### 5.3 confirmDanger / DangerConfirm (11663–11719)
`confirmDanger({title,message,consequence,confirmWord,confirmLabel})` (11665) → Promise<bool>; `DangerConfirm` (11674) mounted via App (12899), `zIndex:1000`. `confirmWord` → typed-confirm input, Confirm disabled until match (case-insensitive). ~15 call sites (delete/lock/recalc/withdraw/billing-dirty).

### 5.4 useModalA11y (11729)
`useModalA11y(onClose,opts)` → ref. `opts.escClose` (off for forms), `opts.dep`. `_modalStack` (only top handles keys), focus first control, trap Tab/Shift-Tab, restore focus on close. Verified by `tools/modal-a11y-check.mjs`.

### 5.5 notify / Toaster (749–799)
`notify(content,{type,ms,persistent,actions})` (759), `dismissToast` (766). `<Toaster/>` (781) mounted at root; merges persistent tab-scoped Alerts + transient toasts; `role=alert`/`status`.

### 5.6 Kill switch + self-update (7–28, 597–621)
Head `<script>`: `?ui=classic|new`, `var FORCE_CLASSIC=false` (17), `localStorage["eis_ui"]`. Classic → `location.replace("/legacy.html"…)`. `#ui-switch` pill outside `#root`. Self-update: `BUILD` (596) vs `version.txt?_=<ts>` `no-store` on load + visibility/focus (619–620); reload to `?_v=<latest>` (loop-safe 612; skips OAuth callbacks 604).

### 5.7 ErrorBoundary (12987)
Wraps App + each conditionally-mounted tab → recovery card ("Something went wrong / Your data is safe", Reload, "Switch to classic view", error `<pre>`).

### 5.8 Auth/connection gating (12860–12879)
`ConnectScreen` (1201, only if creds absent) → "Loading…" (supabase-js from esm.sh, ~10s poll) → `SignInScreen` (Google OAuth, 1221) → "Checking access…" → `AccessErrorScreen` (1268, fail-closed) / `NotAuthorizedScreen` (1251). `isOwner` drives owner-only UI. Built-in URL/anon key (1139–1140) auto-connect; localStorage override for staging.

### Root render (13009)
`ReactDOM.createRoot(...).render(<><ErrorBoundary><App/></ErrorBoundary><Toaster/><UnsavedChangesModal/></>)` — three always-mounted hosts (`DangerConfirm` mounted inside App at 12899).
