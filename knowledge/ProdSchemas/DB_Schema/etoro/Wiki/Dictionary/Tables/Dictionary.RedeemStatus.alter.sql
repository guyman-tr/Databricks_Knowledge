-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_redeemstatus  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RedeemStatus.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus ALTER COLUMN RedeemStatusID COMMENT 'Primary key identifying the redeem lifecycle state. See [Redeem Status](_glossary.md#redeem-status). (Dictionary.RedeemStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus ALTER COLUMN Name COMMENT 'Internal code name used in procedures and API responses.';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus ALTER COLUMN DisplayName COMMENT 'User-facing display label. More readable than the internal Name. Shown in copy-trading UI and notifications.';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemstatus ALTER COLUMN IsCancelable COMMENT 'Whether the user can still cancel the redeem request at this stage. 1=cancellable (Pending), 0=committed (InProcess, Completed, Failed). The cancel boundary is the point when positions start closing.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:38 UTC
-- Statements: 4/4 succeeded
-- ====================
