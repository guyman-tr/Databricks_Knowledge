-- =============================================================================
-- Databricks ALTER Script: bronze RiskClassification.RiskClassification.CySecRiskClassificationParameter
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter SET TBLPROPERTIES (
    'comment' = 'CySEC-specific risk scoring rules configuration table that maps input values to risk scores for each parameter under CySEC regulation, with temporal versioning for audit of rule changes. Source: RiskClassification.RiskClassification.CySecRiskClassificationParameter on the RiskClassification production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md).'
);

ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RiskClassification',
    'source_schema' = 'RiskClassification',
    'source_table' = 'CySecRiskClassificationParameter',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN RegulationID COMMENT 'Regulation this rule applies to. Part of composite PK. Currently CySEC-focused. See Regulation. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN ParameterID COMMENT 'Risk parameter being configured. Part of composite PK. FK to Dictionary.CySecRiskClassificationParameter. See Risk Classification Parameter. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN ID COMMENT 'Option/row ID within the parameter+regulation combination. Part of composite PK. 0 = default/fallback rule, 1+ = specific matching rules. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN Value COMMENT 'Input value matching criteria. NULL for default rules. Contains country tier codes ("0","1","2,3"), screening status codes, or other matching patterns. Comma-separated values match any of the listed values. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN RiskClassificationID COMMENT 'Resulting risk score when this rule matches. 0=Low, 50=Medium, 100=High. Looked up in Dictionary.RiskClassificationRegulation for named level. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN ValidationText COMMENT 'Human-readable description of the rule. "Default" for fallback rules, NULL for specific matching rules. May also contain descriptions like "Sanction Match\Risk Match". (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN BeginTime COMMENT 'Temporal row start. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter ALTER COLUMN EndTime COMMENT 'Temporal row end. GENERATED ALWAYS AS ROW END. (Tier 1 - upstream wiki, RiskClassification.RiskClassification.CySecRiskClassificationParameter)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:38:55 UTC
-- Bronze deploy: RiskClassification batch 1
-- ====================
