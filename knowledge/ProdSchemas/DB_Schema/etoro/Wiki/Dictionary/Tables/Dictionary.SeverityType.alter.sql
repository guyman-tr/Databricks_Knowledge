-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_severitytype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.SeverityType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_severitytype SET TBLPROPERTIES (
    'comment' = 'A lookup table defining log severity levels for the platform''s server-side error logging system. Classifies logged events from Fatal (most severe) to Verbose (least severe) following standard logging severity conventions. eToro''s trading platform generates error and diagnostic logs that are stored in `History.ErrorLog`. Each log entry has a severity level from this table, enabling monitoring systems to filter, alert, and prioritize issues. Fatal and Error entries trigger immediate alerts; Warning and below are informational. When a server-side event is logged to `History.ErrorLog`, the `SeverityTypeID` is set from this table. The ErrorLog has an explicit FK constraint to this table. Monitoring dashboards and alerting rules filter on severity level - typically alerting on Fatal/Error and suppressing Verbose/Informatory noise.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_severitytype ALTER COLUMN SeverityTypeID COMMENT 'Primary key. Severity level: 1=Fatal, 2=Error, 3=Warning, 4=Informatory, 5=Verbose. Lower ID = higher severity.';
ALTER TABLE main.general.bronze_etoro_dictionary_severitytype ALTER COLUMN Name COMMENT 'Unique severity label. Enforced unique by index `DSEV_NAME`. Follows standard logging conventions (note: "Informatory" not "Information").';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:24 UTC
-- Statements: 3/3 succeeded
-- ====================
