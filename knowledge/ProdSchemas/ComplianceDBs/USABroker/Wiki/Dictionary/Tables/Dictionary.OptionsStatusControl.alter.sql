-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_usabroker_dictionary_optionsstatuscontrol
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.OptionsStatusControl.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_usabroker_dictionary_optionsstatuscontrol SET TBLPROPERTIES (
    'comment' = '`Dictionary.OptionsStatusControl` is a static reference table that encodes the administrative control state layered on top of a user''s options application status. While `Dictionary.OptionsStatus` captures where the user''s application stands in the approval workflow, `OptionsStatusControl` captures whether a separate system-level or compliance-level gate is blocking or permitting options activity regardless of the application state. This separation of concerns allows the platform to place a hold on a user''s options access (`Blocked`) even if their application is otherwise `Approved`, without needing to change the application status itself. Conversely, `Allowed` signals that no administrative override is active and the application status alone governs access. `None` is the uninitialised sentinel.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_usabroker_dictionary_optionsstatuscontrol ALTER COLUMN OptionsStatusControlID COMMENT 'Numeric identifier for the administrative control state; 0 is the sentinel for not set.';
ALTER TABLE main.general.bronze_usabroker_dictionary_optionsstatuscontrol ALTER COLUMN Name COMMENT 'Label representing the control state; used by access-control logic and compliance tooling.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:30 UTC
-- Statements: 3/3 succeeded
-- ====================
