-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN RegulationID COMMENT 'Regulation this rule applies to. Part of composite PK. Currently CySEC-focused. See [Regulation](../_glossary.md#regulation).';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN ParameterID COMMENT 'Risk parameter being configured. Part of composite PK. FK to Dictionary.CySecRiskClassificationParameter. See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter).';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN ID COMMENT 'Option/row ID within the parameter+regulation combination. Part of composite PK. 0 = default/fallback rule, 1+ = specific matching rules.';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN Value COMMENT 'Input value matching criteria. NULL for default rules. Contains country tier codes ("0","1","2,3"), screening status codes, or other matching patterns. Comma-separated values match any of the listed values.';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN RiskClassificationID COMMENT 'Resulting risk score when this rule matches. 0=Low, 50=Medium, 100=High. Looked up in Dictionary.RiskClassificationRegulation for named level.';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN ValidationText COMMENT 'Human-readable description of the rule. "Default" for fallback rules, NULL for specific matching rules. May also contain descriptions like "Sanction Match\\Risk Match".';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN BeginTime COMMENT 'Temporal row start. GENERATED ALWAYS AS ROW START.';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN EndTime COMMENT 'Temporal row end. GENERATED ALWAYS AS ROW END.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:27:52 UTC
-- Statements: 8/8 succeeded
-- ====================
