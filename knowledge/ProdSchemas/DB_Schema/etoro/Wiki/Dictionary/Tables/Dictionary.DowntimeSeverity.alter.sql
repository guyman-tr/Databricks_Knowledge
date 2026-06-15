-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_downtimeseverity
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DowntimeSeverity.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimeseverity SET TBLPROPERTIES (
    'comment' = 'A lookup table defining severity levels for downtime incidents, used to prioritize incident response in the BackOffice incident management system. Severity classification drives incident prioritization and escalation. When a downtime is reported, the severity level communicates the business impact and urgency of the issue. Referenced by `BackOffice.Downtime.DowntimeSeverityID` (explicit FK). Assigned when a downtime incident is created via `BackOffice.DowntimeAdd` and can be modified via `BackOffice.DowntimeEdit`.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimeseverity ALTER COLUMN DowntimeSeverityID COMMENT 'Primary key. Severity level (1=Critical, 2=High, 3=Medium, 4=Low). Lower value = higher severity.';
ALTER TABLE main.general.bronze_etoro_dictionary_downtimeseverity ALTER COLUMN Name COMMENT 'Severity label. Unique index ensures no duplicate names.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:54 UTC
-- Statements: 3/3 succeeded
-- ====================
