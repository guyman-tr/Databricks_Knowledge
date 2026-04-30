-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.SuitabilityTestStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.SuitabilityTestStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_suitabilityteststatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_suitabilityteststatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_suitabilityteststatus SET TBLPROPERTIES (
    'comment' = 'Classifies the outcome of MiFID II suitability assessments for customer trading eligibility. Source: etoro.Dictionary.SuitabilityTestStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.SuitabilityTestStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_suitabilityteststatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'SuitabilityTestStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_suitabilityteststatus ALTER COLUMN SuitabilityTestStatusID COMMENT 'Primary key identifying the suitability outcome. 1=Suitable, 2=NotSuitableXp, 3=NotSuitableObjectives. Referenced by BackOffice.Customer and BackOffice.Suitability. (Tier 1 - upstream wiki, etoro.Dictionary.SuitabilityTestStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_suitabilityteststatus ALTER COLUMN Name COMMENT 'Assessment outcome label. Used in BackOffice UI and regulatory reporting. (Tier 1 - upstream wiki, etoro.Dictionary.SuitabilityTestStatus)';

