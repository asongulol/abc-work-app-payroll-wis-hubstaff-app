-- 2026-05-28 — preserve pre-Wise DB amount when matcher auto-overrides variance
--
-- Background:
--   Yesterday's investigation surfaced cases like Ferdinand/Melissa/Mery where
--   the DB stored amount differs from what Wise actually sent — usually
--   because the disbursement was adjusted between calculation and payment,
--   and the override never made it back to the DB. Until now the matcher
--   surfaced these as "matched_with_variance" but didn't change the amount,
--   so the DB silently kept lying about what was paid.
--
-- Fix:
--   When the matcher finds an unambiguous variance (exactly one Wise transfer
--   matches recipient+window, amount differs), it now auto-overrides
--   payments.net_php to the amount Wise actually sent, and preserves the
--   old DB amount in payments.original_net_php so the audit trail is intact.
--
-- Safety:
--   Nullable column, no default. Old rows stay NULL (unchanged). Only the
--   matcher writes this column, and only when there's a single candidate
--   transfer (no tiebreaker ambiguity). The UI shows a ⚠️ next to overridden
--   amounts with the original value in the tooltip.

alter table payments add column if not exists original_net_php numeric(12,2);

-- Verify:
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name   = 'payments'
  and column_name  = 'original_net_php';
