-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_failtype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FailType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_failtype SET TBLPROPERTIES (
    'comment' = 'A lookup table classifying the types of trading operation failures - what went wrong when a position open, close, edit, redeem, or mirror detach operation failed. Trading operations can fail at various stages for different reasons. This table categorizes failures so they can be logged in `History.HedgeFail` and `History.MMLog`, tracked for operational monitoring, and analyzed for patterns. The categorization drives alerting, retry logic, and operational dashboards. Referenced by `History.HedgeFail.FailTypeID` and `History.MMLog` for failure classification. Set by trading procedures including `Trade.HedgeOpen`, `Trade.HedgeClose`, `Trade.PositionCloseRequestAdd`, `Trade.DetachPositionsFromMirror`, and several others during error handling paths.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_failtype ALTER COLUMN FailTypeID COMMENT 'Primary key. Failure category identifier (1-17).';
ALTER TABLE main.general.bronze_etoro_dictionary_failtype ALTER COLUMN Name COMMENT 'Failure description. Indexed (non-unique) for name-based lookups.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:11 UTC
-- Statements: 3/3 succeeded
-- ====================
