-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DepositType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_deposittype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_deposittype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_deposittype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 8 categories of deposit transactions, distinguishing real deposits from internal credits and fee adjustments. Source: etoro.Dictionary.DepositType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_deposittype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DepositType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_deposittype ALTER COLUMN DepositTypeID COMMENT 'Primary key identifying the deposit category. See Deposit Type. (Dictionary.DepositType) (Tier 1 - upstream wiki, etoro.Dictionary.DepositType)';
ALTER TABLE main.general.bronze_etoro_dictionary_deposittype ALTER COLUMN DepositType COMMENT 'Short code name for the deposit category. Used in code branching and API classification. (Tier 1 - upstream wiki, etoro.Dictionary.DepositType)';
ALTER TABLE main.general.bronze_etoro_dictionary_deposittype ALTER COLUMN Description COMMENT 'Human-readable description. Displayed in back-office deposit management and reporting. (Tier 1 - upstream wiki, etoro.Dictionary.DepositType)';
ALTER TABLE main.general.bronze_etoro_dictionary_deposittype ALTER COLUMN ApplyFtd COMMENT 'Whether this deposit type counts toward First Time Deposit. 1=real external deposit, 0=internal/promotional credit. Drives marketing attribution, partner commission calculations, and onboarding milestone tracking. (Tier 1 - upstream wiki, etoro.Dictionary.DepositType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
