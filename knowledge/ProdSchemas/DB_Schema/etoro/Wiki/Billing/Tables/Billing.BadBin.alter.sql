-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_billing_badbin  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_billing_badbin ALTER COLUMN BinFrom COMMENT 'Start of the blocked BIN range (inclusive). Part of the composite PK. For single-BIN blocks, equals BinTo. Represents the first 6 or 8 digits of the card number.';
ALTER TABLE main.billing.bronze_etoro_billing_badbin ALTER COLUMN BinTo COMMENT 'End of the blocked BIN range (inclusive). Part of the composite PK. For single-BIN blocks, equals BinFrom. Any card whose BIN prefix falls in [BinFrom, BinTo] is considered blocked.';
ALTER TABLE main.billing.bronze_etoro_billing_badbin ALTER COLUMN BlockReasonID COMMENT 'Optional block reason code. NULL = blocked without a specific coded reason (the overwhelming majority of rows). Non-NULL values reference a reason catalog (only BlockReasonID=1 observed in live data, applied to 2 rows at BIN 40380600-40380601). No FK constraint defined.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:41 UTC
-- Statements: 3/3 succeeded
-- ====================
