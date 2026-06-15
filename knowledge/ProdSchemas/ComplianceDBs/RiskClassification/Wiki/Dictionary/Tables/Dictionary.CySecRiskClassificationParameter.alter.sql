-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter ALTER COLUMN ParameterID COMMENT 'Parameter identifier. PK. Same ID space as Dictionary.RiskClassificationParameter (2-21, 1001-1025, 9999). FK target for RiskClassification.CySecRiskClassificationParameter.';
ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter ALTER COLUMN Name COMMENT 'Parameter name. Identical to Dictionary.RiskClassificationParameter.Name for the same ID.';
ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter ALTER COLUMN Description COMMENT 'Parameter description. Same content as the main dictionary.';
ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter ALTER COLUMN Source COMMENT 'External data source. Same as main dictionary.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:08 UTC
-- Statements: 4/4 succeeded
-- ====================
