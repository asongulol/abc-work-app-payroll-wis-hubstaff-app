# Appendix 03 — Hiring & Onboarding admin, agreements, documents, tools, admins

> Granular build spec with `app/index.html` line anchors. Master overview: [../FEATURES.md](../FEATURES.md). Edge handlers referenced inline.

## 0. Constants & helpers
- `ONB_AGR_LABEL` (10568): `{ic_agreement:"IC Agreement", non_compete:"Non-Compete", confidentiality_nda:"NDA", baa:"BAA"}`
- `ONB_DOC_LABEL` (10569): `{resume:"Resume / CV", diploma:"Diploma / TOR", nbi_clearance:"NBI Clearance", gov_id:"Gov ID / Passport"}`
- `ONB_STAGE_LABEL` (10570): `{stage1_sign:"Signing", stage2_profile:"Profile", stage3_docs:"Documents", complete:"Complete"}`
- `ONB_DOC_KINDS` (10571), `ONB_AGR_KINDS` (10600 = ic_agreement, non_compete, confidentiality_nda, baa)
- `SIG_METHOD_OPTS` (11315): `[["both","Typed or drawn"],["typed","Typed only"],["drawn","Drawn only"]]`
- Helpers: `onbPct(p)` (10591, 0/33/67/100), `onbStatus(p,pending)` (10592 → Action needed amber / Complete green / Stalled red / In progress blue), `mergeAgreement` (10613), `monthlyFromPeriod` (10608, ×2 semi-monthly).
- The standalone **Documents tab** (`Documents` 7343) is a legacy expiry tracker (`DOC_KINDS` 7339 = IC/W-8BEN/Gov ID/Other), NOT onboarding review. All onboarding doc review is in `OnboardingDrilldown`.

## 1. OnboardingAdmin (11579-11654)
`OnboardingAdmin({client,companyId,consolidated,active,onContractorChanged})`.
- Queries: `progs` (11583) onboarding_progress ⨝ workers; `pendDocs` (11586) documents in ONB_DOC_KINDS; `coName` (11582).
- Pending/deferred counted on the **latest** doc per `worker|kind|side` (11588). `needReview`, `orphanReview` (pending w/ no onboarding row), `needFollowup`.
- Row `_name/_email/_pending/_deferred/_pct` (11597). Visible if `showDone || !completed_at || _pending>0 || _deferred>0` (11600).
- Header: **+ Hire new contractor** (disabled consolidated), **Show completed**, **📄 Agreement templates**, **⚙ Onboarding config**, **Refresh**; `HireDraftBanner` (11627); Alerts (11631) for needReview/needFollowup.
- Table (11636): **Contractor** (+⚠️ name_mismatch + email), **Stage**, **Progress** (60×6 bar), **Status** (Badge + pending count + 📌 follow-up), **Updated**, **Review** → `OnboardingDrilldown`.

## 2. OnboardingDrilldown (10970-11221)
Queries (10972): workers (long field list), worker_companies (incl. weekly_hours, for ProfileModal row), onboarding_signatures, documents (ONB_DOC_KINDS), onboarding_progress.

### Stage overrides (11117-11132) via `applyProg(patch,label,warn,onOk)` (11074)
`window.confirm` + update onboarding_progress + log `onboarding_override`.
- **↺ Stage 1/2/3** → `reopenTo(stage)` (11084) — set stage, clear downstream flags + completed_at. Warn re-locks pay access.
- **✓ Mark complete** → `markComplete()` (11091) — all flags + complete + completed_at; warn unlocks pay access; onOk auto-opens ToolsProvisionModal if tools requested & unprovisioned.
- **🔑 Tool access** → ToolsProvisionModal; **↺ Reset** → `revoke()` (11094) back to stage1.

### Hire-management row (11108-11115)
- **✎ Edit details** (11110) → ProfileModal with synthesized row `{w:{id,...w}, workers, company_id, companies:{name}, contract||"FT", role, weekly_hours, hubstaff_name, status:"active"}` (11137); onSaved → reloadW+reloadWc+onChange.
- **✉ Update login & resend** (11111) → modal (11144): Login email prefilled, **Update & resend** (`submitResend` 11037 → `portal-admin update_login_and_resend`) → done panel showing fresh temp password + Copy + status banner. Edge `portal-admin/index.ts:383`.
- **⊘ Withdraw offer** (11113, amber) → `withdrawOffer()` (11000): `confirmDanger({title:"Withdraw {name}'s offer?", consequence:"They can no longer sign in. This does NOT delete their record — use Delete hire for that.", confirmWord:"WITHDRAW"})` → `portal-admin withdraw_offer`. Edge `:435`.
- **🗑 Delete hire** (11114, red) → `deleteHire()` (11015): count signatures+documents → `confirmDanger({title:"Delete {name}?", consequence:"Blocked automatically if they have any payroll history.", confirmWord:"DELETE"})` → `portal-admin delete_contractor force`. Edge `:518`.

### Sections
**1 · Agreements** (11169): signatures table (Agreement/Signed name/When/IP/Ver) + `<AgreementsPanel>`. **2 · Profile** (11184): read-only `FIELDS` grid (11097) incl. education_level "Highest Degree Attained", course "Degree and Major", Wise Tag + `profile_extras` line. **3 · Documents** (11190): review — see §5.

## 3. AgreementsPanel (10702-10896)
`load()` (10708): onboarding_agreements (f_* per kind), agreement_templates (kind,body), admin_users (user_id,email,name,can_countersign), workers (ph_address→waddr, hire_date→whire), worker_companies (coName), portal_settings.onboarding_config → cfgAgr + csMethod.

**Auto-fill from IC** (10738): `icRow`, `effF(r,field)` (own || IC fallback), `effStart`, `effCs`. Summary shows "auto-filled from setup" (blue) for inherited non-IC rows.

**Prepare/Edit form** (`startEdit` 10742; button "Prepare"/"Edit prefill" 10882):
1. **Position / Role** text (`f_position`)
2. **Rate** text "e.g. ₱350/hr" (`f_rate`)
3. **Start date** date (`f_start_date`)
4. **Engagement (shown in the agreement)** `<select>` (`f_employment_type`): — not set — / **Full-time (40 hrs/week)** `full_time` / **Part-time (20 hrs/week)** `part_time`
5. **Expected hours / week** `number 1-60 step.5` (`f_hours_per_week`)
6. **Shift / schedule (shown in the agreement)** text "e.g. 09:00–18:00 (PHT), Mon–Fri" (`f_schedule`)
7. **Countersigner** `<select>` (`countersigner_user_id`): — select admin — + `admins.filter(can_countersign!==false)` as `{name} ({email})`; sets `countersigner_name`
8. **Countersigner name (shown on the document)** text
9. **IC addendum (appended)** — IC only `<select>`: No addendum / **Scope of Work** `scope_of_work` / **Other** `other` + textarea

`savePrep(k)` (10744): upsert onboarding_agreements on conflict `(worker_id,agreement_kind)`. Badges Signed/Awaiting + Countersigned. Edit signed date (10834) → `portal-review set_signed_date` (edge `:120`). Countersign (10883): **Countersign** button if no assigned countersigner OR me is assigned → `CountersignModal` (10644, typed/drawn) → `doCountersign` (10763) → `portal-countersign`.

### mergeAgreement (10613-10639)
Tokens `{{key}}`: contractor_name, rate (`________`), monthly_rate, company_name, client_name (=company), employer_name (default **"Aaron Anderson E.H.S. LLC"**), start_date, position, contractor_address, countersigner_name, today, employment_type, hours_per_week, schedule, addendum.
- `employment_type` → "Full-time"/"Part-time" + ` (${hours}/week)` (explicit hours_per_week else 40/20).
- Addendum auto-append (10628) if `{{addendum}}` absent.
- **Engagement clause + DST note** auto-append (10631) when no `{{employment_type|hours_per_week|schedule}}` token and engagement/schedule set: "Engagement: {phrase}. Work schedule: {schedule}. This schedule is stated in U.S. Eastern Time, which observes U.S. daylight saving time. Because the Philippines does not change its clocks, the equivalent local Philippine start and end times shift by one hour when the U.S. springs forward (mid-March) and falls back (early November)."

### printDoc (10787)
Merged body → new window: logo + `<pre>` + two-column signature block (Contractor / "For ABC Kids NY — {countersigner_name}"). **XSS-safe** `safeSigImg` (10798): only emits `<img>` for `data:image/(png|jpe?g|webp);base64,…`, else escaped cursive name. Print disabled when no template body.

## 4. AgreementTemplatesModal (11261-11304)
`agreement_templates` (kind,title,version,body). Kind buttons via ONB_AGR_LABEL; monospace `<textarea>`; `save()` (11273) updates body; logs `agreement_template_saved`. Merge-field legend (11289): Parties (`{{employer_name}}` "Aaron Anderson E.H.S. LLC", `{{client_name}}`/`{{company_name}}`, `{{contractor_name}}`, `{{countersigner_name}}`) + Engagement (`{{position}} {{rate}} {{monthly_rate}} {{start_date}} {{contractor_address}} {{employment_type}} {{hours_per_week}} {{schedule}} {{today}} {{addendum}}`) + auto-append note.

## 5. Document review (11190-11215)
Grouped by `kind|side`; latest = list[0]. Badge: approved green / waived slate / deferred amber / needs_replacement amber / pending blue. NBI freshness `isNbiStale` (11068, 6mo). Actions via `review(d,action,reason,override)` (11058 → `portal-review`):
- **View** (11205) → `view(d)` (11051) 120s signed URL (`contractor-docs`).
- **Approve** / **Approve anyway** (override stale NBI).
- **Needs replacement** → `ReasonPicker` (11225): presets Blurry/Expired/Wrong document/Incomplete/Name doesn't match/Photo of a screen + Other; "Send back to contractor".
- **Waive** (confirm) / **Defer**. Statuses pending|approved|waived|deferred|needs_replacement. Edge `portal-review/index.ts`.

## 6. ToolsProvisionModal (10913-10968)
`TOOL_FIELDS` (10901): gmail [address,password], providersoft [username,password], hubstaff [username,password], zoom [number]; `others` → textarea. Save (10919): build `creds` → `client.rpc("set_worker_tools",{p_worker_id,p_creds})` (encrypted at rest) → `portal-admin send_tools_email` (decrypts via `decrypt_worker_tools` server-side) → log `tools_provisioned`. RPCs: `set_worker_tools`, `get_tools_status` (11046), `set_tools_requested` (hire wizard), `decrypt_worker_tools`.

## 7. AdminsModal — owner-only (1284-1452)
`load()` (1294): admin_users (user_id,email,role,name,can_countersign,added_at), pending_admins, companies, admin_companies. All mutations via `call(action,extra)` (1336 → `admin-manage`).
- **Add admin** (1382): EmailInput pin `["abckidsny.com","abbilabs.com"]`; role `<select>` Admin/Owner; **Add** → `add_admin` (sign-in-first → pending_admins if not signed in); invite-time company chips for admins.
- **Per-admin row** (1409): email + role pill; Make owner/admin (`set_role`); Remove (`remove_admin`); **Name** input (blur/Enter → `update_admin {name}`, "Full name — shown on agreements"); **Can countersign agreements** checkbox (→ `update_admin {can_countersign}`); company scoping chips (`companyPicker` 1319 → toggle `admin_companies`).
- **Pending invites** (1437): email + role pill + Remove + company picker.
Edge `admin-manage/index.ts`: add_admin (65), set_role (120), update_admin (141), remove_admin (161).

## 8. OnboardingConfigModal (11319-11578)
Edits `portal_settings.onboarding_config` (id=1); form + raw-JSON (preserves unknown keys e.g. `editable_fields`, `profile_tabs`).
- **Onboarding enabled** (11420).
- **📄 Documents to collect** (11433): rows (title, ↑/↓, ✕, Required, Front&back → sides, Expires after N months) + Add + Reset (`ONB_DEFAULT_DOCS` 11310).
- **✍️ Agreements to sign** (11460): rows (title, Required, order=sign order) + Add.
- **🖊️ Signature methods** (11483): Contractor + Countersigner `<select>` SIG_METHOD_OPTS.
- **📧 Onboarding emails** (11502): auto-send toggle, Portal link, Wise referral link; **1·Welcome** ({{name}}{{wise_referral_url}}{{portal_url}}{{email}}{{password}}), **2·Tool access** ({{name}}{{tools_block}}), collapsible **Password-reset** (credentials) + Reset wording. (Withdrawal email is server-side only.)
- **🔔 Document-review reminders** (11545): enable, include-deferred, **Frequency** `<select>` Daily/Weekdays only/Weekly (Mondays), recipients (comma/newline). Consumed by `hiring-docs-review-check`.
- **Advanced — raw JSON** (11563): for `editable_fields` etc.

### Edge / RPC / table index
`portal-admin`: create_login(250), revoke_login(321), reset_password(333), resend_hire_emails(363), update_login_and_resend(383), withdraw_offer(435), send_tools_email(489→decrypt_worker_tools 495), delete_contractor(518), {{tools_block}} renderer(123). `admin-manage`: add_admin(65)/set_role(120)/update_admin(141)/remove_admin(161). `portal-review`: set_signed_date(120), needs_replacement(154), waive/defer(175), approve+NBI 422(192). `portal-countersign`: countersign. RPCs: set_worker_tools/get_tools_status/set_tools_requested/decrypt_worker_tools. Tables: onboarding_progress, onboarding_agreements, onboarding_signatures, documents, agreement_templates, admin_users, pending_admins, admin_companies, portal_settings. Bucket: contractor-docs (120s signed URLs).
