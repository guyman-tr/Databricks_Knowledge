-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RiskScore_Explanation COMMENT 'Same as V_RiskClassification. Comma-separated non-zero parameter names.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN Regulation COMMENT 'Regulation name from Dictionary.Regulation.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RiskScoreName COMMENT 'Named risk level from Dictionary.RiskClassificationRegulation.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN GCID COMMENT 'Global Customer ID.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN CID COMMENT 'Customer ID.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RegulationID COMMENT 'Regulation ID. See [Regulation](_glossary.md#regulation).';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RiskScore COMMENT 'Final aggregate risk score.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RiskScore_Value COMMENT 'Score formula in N*Score format.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN BeginTime COMMENT 'Temporal row start.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN EndTime COMMENT 'Temporal row end.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN PreviousRisk COMMENT 'Previous risk score from history CTE.';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN PreviousRiskUpdateDate COMMENT 'When previous risk score was set.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:18:09 UTC
-- Statements: 12/12 succeeded
-- ====================
