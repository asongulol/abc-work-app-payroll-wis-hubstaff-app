-- ============================================================================
-- Onboarding · Stage-1 agreements upgrade: merge-field TEMPLATES + per-contractor
-- PREFILL + assigned ADMIN COUNTERSIGNATURE + printable.
-- ----------------------------------------------------------------------------
-- Two new tables:
--   agreement_templates    — the standard agreement text (one per kind), with
--                            {{contractor_name}} {{rate}} {{start_date}}
--                            {{position}} {{countersigner_name}} {{today}}
--                            placeholders. Admin-editable; contractors may READ
--                            (needed to render the doc they are signing).
--   onboarding_agreements  — per (worker, kind) prepared instance: the prefill
--                            values + the assigned countersigner + the captured
--                            admin countersignature.
-- Contractor signature itself stays in onboarding_signatures (unchanged).
-- Idempotent. Depends on: agreement_kind enum, is_admin(), my_worker_id().
-- ============================================================================

-- ---- standard templates -----------------------------------------------------
create table if not exists agreement_templates (
  kind        agreement_kind primary key,
  title       text not null,
  version     text not null default '1.0',
  body        text not null default '',
  updated_by  uuid,
  updated_at  timestamptz not null default now()
);
alter table agreement_templates enable row level security;

drop policy if exists agreement_templates_admin_all on agreement_templates;
create policy agreement_templates_admin_all on agreement_templates
  for all to authenticated using (is_admin()) with check (is_admin());

-- contractors render the template they sign, so they may read it (text only)
drop policy if exists agreement_templates_read on agreement_templates;
create policy agreement_templates_read on agreement_templates
  for select to authenticated using (true);

-- ---- per-contractor prepared instance --------------------------------------
create table if not exists onboarding_agreements (
  worker_id             uuid not null references workers(id) on delete cascade,
  agreement_kind        agreement_kind not null,
  -- prefill values filled by the preparer (contractor_name derives from workers)
  f_rate                text,
  f_start_date          date,
  f_position            text,
  prepared_by           uuid,
  prepared_at           timestamptz,
  -- assigned admin countersigner (id + denormalized display name so the
  -- contractor can render {{countersigner_name}} without reading admin tables)
  countersigner_user_id uuid,
  countersigner_name    text,
  countersigned_by      uuid,
  countersigned_name    text,
  countersign_method    text,           -- typed | drawn
  countersign_data      text,
  countersigned_at      timestamptz,
  countersign_ip        text,
  updated_at            timestamptz not null default now(),
  primary key (worker_id, agreement_kind)
);
alter table onboarding_agreements enable row level security;

drop policy if exists onboarding_agreements_admin_all on onboarding_agreements;
create policy onboarding_agreements_admin_all on onboarding_agreements
  for all to authenticated using (is_admin()) with check (is_admin());

-- contractor reads their own prepared instance (to render prefilled values);
-- they never write it — preparation + countersignature are admin/service-role.
drop policy if exists onboarding_agreements_read_own on onboarding_agreements;
create policy onboarding_agreements_read_own on onboarding_agreements
  for select to authenticated using (worker_id = my_worker_id());

-- ---- seed the four standard templates (merge-field versions of the existing
--      placeholder bodies). Admin edits these in the template editor. ON CONFLICT
--      DO NOTHING so re-running never clobbers edited text. ----------------------
insert into agreement_templates (kind, title, version, body) values
('ic_agreement', 'Independent Contractor Agreement', '1.0',
$body$INDEPENDENT CONTRACTOR AGREEMENT

This Independent Contractor Agreement is entered into between ABC Kids NY ("Company") and {{contractor_name}} ("Contractor").

  Position / Role:  {{position}}
  Compensation:     {{rate}}
  Start date:       {{start_date}}

[PLACEHOLDER — replace with the executed Independent Contractor Agreement text. Edit this template in the admin Agreement Templates editor.]

1. ENGAGEMENT. The Contractor is engaged as an independent contractor and not as an employee. Nothing in this Agreement creates an employment, partnership, or agency relationship.

2. SERVICES. The Contractor will perform the services for the role of {{position}}, exercising independent professional judgment as to the manner and means of performance.

3. COMPENSATION. The Contractor will be paid {{rate}}, in PHP via the chosen payout method, beginning {{start_date}}. The Contractor is responsible for their own taxes and statutory contributions.

4. INDEPENDENT STATUS. The Contractor controls their own schedule, tools, and methods, and may provide services to others, subject to the separate Non-Compete and Confidentiality terms.

5. TERM & TERMINATION. Either party may end the engagement on written notice. Accrued amounts for work performed remain payable.

6. MISCELLANEOUS. This Agreement is governed by the applicable laws of the State of New York, USA. The parties agree to electronic signature.

Signed:

  {{contractor_name}} — Contractor
  {{countersigner_name}} — for ABC Kids NY
$body$),
('non_compete', 'Non-Compete Agreement', '1.0',
$body$NON-COMPETE AGREEMENT

This Non-Compete Agreement is entered into between ABC Kids NY ("Company") and {{contractor_name}} ("Contractor"), in connection with the Contractor's engagement as {{position}} beginning {{start_date}}.

[PLACEHOLDER — replace with the executed Non-Compete Agreement text.]

1. SCOPE. During the engagement and for the agreed period afterward, the Contractor will not directly compete with the Company's specific clients on matters they worked on, to the extent permitted by law.

2. NON-SOLICITATION. The Contractor will not solicit the Company's clients or contractors for a competing purpose during the restricted period.

3. REASONABLENESS. The restrictions are limited in time, scope, and geography to what is reasonable to protect legitimate business interests.

4. SEVERABILITY. If any restriction is found unenforceable, it will be reduced to the maximum enforceable extent rather than voided.

Signed:

  {{contractor_name}} — Contractor
  {{countersigner_name}} — for ABC Kids NY
$body$),
('confidentiality_nda', 'Confidentiality / Non-Disclosure Agreement', '1.0',
$body$CONFIDENTIALITY / NON-DISCLOSURE AGREEMENT

This Agreement is entered into between ABC Kids NY ("Company") and {{contractor_name}} ("Contractor").

[PLACEHOLDER — replace with the executed NDA text.]

1. CONFIDENTIAL INFORMATION. The Contractor will receive confidential information including client data, business processes, and personal information of third parties.

2. OBLIGATIONS. The Contractor will keep all confidential information strictly private, use it only for the engagement, and not disclose it to anyone without authorization.

3. PERSONAL DATA. The Contractor will handle any personal data in accordance with applicable privacy laws, including the Philippine Data Privacy Act of 2012.

4. RETURN. On request or at the end of the engagement, the Contractor will return or securely destroy all confidential information.

5. SURVIVAL. These obligations survive the end of the engagement.

Signed:

  {{contractor_name}} — Contractor
  {{countersigner_name}} — for ABC Kids NY
$body$),
('baa', 'Business Associate Agreement (BAA)', '1.0',
$body$BUSINESS ASSOCIATE AGREEMENT (BAA)

This Business Associate Agreement is entered into between ABC Kids NY ("Company") and {{contractor_name}} ("Contractor").

[PLACEHOLDER — replace with the executed BAA text.]

1. PURPOSE. To the extent the Contractor handles protected health information (PHI) on behalf of the Company, this BAA sets out the required safeguards.

2. PERMITTED USES. The Contractor will use or disclose PHI only as permitted by the engagement and applicable law.

3. SAFEGUARDS. The Contractor will implement reasonable administrative, physical, and technical safeguards to protect PHI.

4. INCIDENTS. The Contractor will report any suspected unauthorized use or disclosure promptly.

5. RETURN OR DESTRUCTION. On termination, the Contractor will return or destroy all PHI where feasible.

Signed:

  {{contractor_name}} — Contractor
  {{countersigner_name}} — for ABC Kids NY
$body$)
on conflict (kind) do nothing;

-- ============================================================================
-- ROLLBACK:
--   drop table if exists onboarding_agreements;
--   drop table if exists agreement_templates;
-- ============================================================================
