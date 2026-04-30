-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RiskClassificationParameter
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskClassificationParameter.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_riskclassificationparameter
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_riskclassificationparameter (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationparameter SET TBLPROPERTIES (
    'comment' = 'Reference table defining 46 risk classification parameters — customer attributes scored for AML/KYC risk assessment — including country of residence, occupation, income, deposits, and enhanced due diligence indicators. Source: etoro.Dictionary.RiskClassificationParameter on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskClassificationParameter.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationparameter SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RiskClassificationParameter',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationparameter ALTER COLUMN RiskClassificationParameterID COMMENT 'Primary key. Standard params: 2-21, EDD params: 1001-1025, Final: 9999. Referenced by RiskCalculation.ScoresTemporary and dbo.ScoresDaily. (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationparameter ALTER COLUMN Name COMMENT 'Short parameter label (e.g., "Country of Residence, Onboarding", "SectorHighRisk"). Used in reporting and configuration UI. (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationparameter ALTER COLUMN Description COMMENT 'Extended description of what the parameter measures and how it maps to questionnaire answers. Empty for EDD parameters. (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassificationParameter)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_riskclassificationparameter ALTER COLUMN Source COMMENT 'Data source table/view for the parameter value (e.g., "Customer.CustomerStatic", "V_CustomerAnswersNrml"). Empty for EDD and external parameters. (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassificationParameter)';

