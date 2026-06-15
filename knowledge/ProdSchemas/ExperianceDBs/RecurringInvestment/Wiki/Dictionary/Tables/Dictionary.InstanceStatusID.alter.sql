-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.InstanceStatusID.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid ALTER COLUMN ID COMMENT 'Unique numeric identifier for the instance status. 1=Success, 2=Cancelled, 3=Skipped, 4=UserSkipped, 5=InProgress, 6=Technical Issue, 7=Completed without position. See [Instance Status](../../_glossary.md#instance-status).';
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid ALTER COLUMN InstanceStatusID COMMENT 'Human-readable label for the instance lifecycle state. Note: column name matches table name, which is a naming convention anomaly - this is the descriptive label, not a foreign key.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:25 UTC
-- Statements: 2/2 succeeded
-- ====================
