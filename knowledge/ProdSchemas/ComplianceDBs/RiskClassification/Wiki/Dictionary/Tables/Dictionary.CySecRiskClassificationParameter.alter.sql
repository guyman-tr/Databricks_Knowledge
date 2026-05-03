-- =============================================================================
-- Databricks ALTER Script: bronze RiskClassification.Dictionary.CySecRiskClassificationParameter
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter SET TBLPROPERTIES (
    'comment' = 'CySEC-specific version of the risk classification parameter dictionary, mirroring Dictionary.RiskClassificationParameter with identical parameter definitions and weight percentages for CySEC regulatory context. Source: RiskClassification.Dictionary.CySecRiskClassificationParameter on the RiskClassification production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md).'
);

ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RiskClassification',
    'source_schema' = 'Dictionary',
    'source_table' = 'CySecRiskClassificationParameter',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter ALTER COLUMN ParameterID COMMENT 'Parameter identifier. PK. Same ID space as Dictionary.RiskClassificationParameter (2-21, 1001-1025, 9999). FK target for RiskClassification.CySecRiskClassificationParameter. (Tier 1 - upstream wiki, RiskClassification.Dictionary.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter ALTER COLUMN Name COMMENT 'Parameter name. Identical to Dictionary.RiskClassificationParameter.Name for the same ID. (Tier 1 - upstream wiki, RiskClassification.Dictionary.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter ALTER COLUMN Description COMMENT 'Parameter description. Same content as the main dictionary. (Tier 1 - upstream wiki, RiskClassification.Dictionary.CySecRiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter ALTER COLUMN Source COMMENT 'External data source. Same as main dictionary. (Tier 1 - upstream wiki, RiskClassification.Dictionary.CySecRiskClassificationParameter)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:38:55 UTC
-- Bronze deploy: RiskClassification batch 1
-- ====================
