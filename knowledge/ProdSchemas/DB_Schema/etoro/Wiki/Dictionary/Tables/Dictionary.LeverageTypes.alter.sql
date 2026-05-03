-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.LeverageTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.LeverageTypes.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_leveragetypes
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_leveragetypes (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_leveragetypes SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 2 leverage policy types (Proportional, Fixed) used to determine how leverage is applied to positions. Source: etoro.Dictionary.LeverageTypes on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.LeverageTypes.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_leveragetypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'LeverageTypes',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_leveragetypes ALTER COLUMN LeverageTypeID COMMENT 'Primary key (auto-increment). 1=Proportional, 2=Fixed. NOT FOR REPLICATION prevents identity conflicts in replicated environments. See Leverage Types. (Dictionary.LeverageTypes) (Tier 1 - upstream wiki, etoro.Dictionary.LeverageTypes)';
ALTER TABLE main.general.bronze_etoro_dictionary_leveragetypes ALTER COLUMN LeverageTypeName COMMENT 'Leverage application method name. NULL allowed. (Tier 1 - upstream wiki, etoro.Dictionary.LeverageTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
