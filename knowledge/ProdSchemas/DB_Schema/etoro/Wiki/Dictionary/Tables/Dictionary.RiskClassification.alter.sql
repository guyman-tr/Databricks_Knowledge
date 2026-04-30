-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RiskClassification
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskClassification.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_riskclassification
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_riskclassification (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_riskclassification SET TBLPROPERTIES (
    'comment' = 'Lookup table defining overall risk classification levels for customer accounts. Each level has a numeric RiskScore enabling quantitative risk comparison and regulatory-driven trading restrictions. Source: etoro.Dictionary.RiskClassification on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskClassification.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_riskclassification SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RiskClassification',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_riskclassification ALTER COLUMN RiskClassificationID COMMENT 'Primary key identifying the risk classification level. 0=High, 1=Medium, 2=Low, 3=Unacceptable, 4=Medium High, 5=Medium Low. Referenced by BackOffice.Customer (RiskClassificationID, OnboardingRiskClassificationID), History.BackOfficeCustomer. Used by RiskCalculation.SetRiskClassificationForCySec, BackOffice.CustomerSetRiskClassification. (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassification)';
ALTER TABLE main.general.bronze_etoro_dictionary_riskclassification ALTER COLUMN Name COMMENT 'Human-readable label for the classification. Used for reporting, UI display, and audit logs. Values: High, Medium, Low, Unacceptable, Medium High, Medium Low. (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassification)';
ALTER TABLE main.general.bronze_etoro_dictionary_riskclassification ALTER COLUMN RiskScore COMMENT 'Numeric score enabling quantitative risk comparison. Higher = higher risk. Range 0–200 in live data. Used for sorting, thresholds, and regulatory reporting. (Tier 1 - upstream wiki, etoro.Dictionary.RiskClassification)';

