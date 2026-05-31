-- ============================================================================
-- Onboarding M0 · A3 — onboarding_signatures (Stage-1 eSign ledger).
-- INERT: written only by the portal-sign edge fn (M1). Append-only / immutable
-- by design — a dispute adds a status change via service role, never a delete
-- (design §6.3). Idempotent. APPLY TO PROD. Depends on: A1 enums.
--
-- WRITE MODEL: service-role only (capture must record IP/User-Agent server-side
-- and verify sign order). No contractor INSERT policy; SELECT-own + admin only.
-- ============================================================================
create table if not exists onboarding_signatures (
  id                 uuid primary key default gen_random_uuid(),
  worker_id          uuid not null references workers(id) on delete cascade,
  agreement_kind     agreement_kind not null,
  doc_version        text not null,             -- version of the agreement text signed
  doc_sha256         text,                      -- hash of the exact bytes shown (tamper-evidence)
  signed_legal_name  text not null,             -- name the contractor typed at signing
  signature_method   signature_method not null, -- typed | drawn
  signature_data     text,                      -- typed string, or storage path/data-url for drawn glyph
  scrolled_to_end    boolean not null default false,
  ip_address         inet,                      -- captured server-side (x-forwarded-for)
  user_agent         text,                      -- captured server-side
  device_fingerprint text,                      -- best-effort from client; null never fails (§6.8)
  status             signature_status not null default 'signed',
  signed_at          timestamptz not null default now(),
  created_at         timestamptz not null default now(),
  -- one active signature per (worker, agreement, version); re-sign of a NEW
  -- version is a new row, the old one flipped to 'superseded' by the edge fn.
  unique (worker_id, agreement_kind, doc_version)
);

create index if not exists onboarding_signatures_worker_idx on onboarding_signatures (worker_id);

alter table onboarding_signatures enable row level security;

-- Read-only for the owning contractor and admins. No INSERT/UPDATE/DELETE policy.
drop policy if exists onboarding_signatures_read on onboarding_signatures;
create policy onboarding_signatures_read on onboarding_signatures
  for select to authenticated
  using ( worker_id = my_worker_id() or is_admin() );

-- VERIFY:
--   select count(*) from onboarding_signatures;          -- expect 0
--   select policyname, cmd from pg_policies where tablename='onboarding_signatures';
