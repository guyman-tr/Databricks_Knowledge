-- =============================================================================
-- Databricks ALTER Script: bronze RiskClassification.dbo.V_RiskClassificationDataLake
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake SET TBLPROPERTIES (
    'comment' = 'BI/data lake oriented view that enriches T_RiskClassification with regulation names, risk explanations, and previous risk scores, with column names sanitized (spaces removed) for data lake compatibility. Source: RiskClassification.dbo.V_RiskClassificationDataLake on the RiskClassification production database, ingested via the Generic Pipeline (Override strategy, 10080-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/dbo/Views/dbo.V_RiskClassificationDataLake.md).'
);

ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RiskClassification',
    'source_schema' = 'dbo',
    'source_table' = 'V_RiskClassificationDataLake',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '10080'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RiskScore_Explanation COMMENT 'Same as V_RiskClassification. Comma-separated non-zero parameter names. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN Regulation COMMENT 'Regulation name from Dictionary.Regulation. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RiskScoreName COMMENT 'Named risk level from Dictionary.RiskClassificationRegulation. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN GCID COMMENT 'Global Customer ID. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN CID COMMENT 'Customer ID. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RegulationID COMMENT 'Regulation ID. See Regulation. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RiskScore COMMENT 'Final aggregate risk score. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN RiskScore_Value COMMENT 'Score formula in N*Score format. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN BeginTime COMMENT 'Temporal row start. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN EndTime COMMENT 'Temporal row end. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN `_RiskScore / _Value (sanitized names)` COMMENT 'All parameter score and value columns with sanitized aliases. E.g., CountryofResidenceOnboarding_RiskScore, AgeofCustomer_Value. Same data as T_RiskClassification. PEP Check and Place of Birth columns excluded (commented out). (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN PreviousRisk COMMENT 'Previous risk score from history CTE. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
ALTER TABLE main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake ALTER COLUMN PreviousRiskUpdateDate COMMENT 'When previous risk score was set. (Tier 1 - upstream wiki, RiskClassification.dbo.V_RiskClassificationDataLake)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:38:55 UTC
-- Bronze deploy: RiskClassification batch 1
-- ====================
