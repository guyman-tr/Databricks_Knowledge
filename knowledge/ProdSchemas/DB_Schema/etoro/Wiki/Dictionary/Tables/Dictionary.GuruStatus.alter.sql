-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.GuruStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GuruStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_gurustatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_gurustatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_gurustatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 9 Popular Investor (Guru) program states — from non-participant through Cadet, Rising Star, Champion, Elite, and Elite Pro tiers, plus Removed and Rejected terminal states. Source: etoro.Dictionary.GuruStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GuruStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_gurustatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'GuruStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_gurustatus ALTER COLUMN GuruStatusID COMMENT 'Primary key identifying the PI program state. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. Referenced by BackOffice.Customer (FK), Billing.GuruStatusToCashoutFeeGroup (FK). Filtered as IN (2,3,4,5) for active PIs or IN (2,3,4,5,6) including Elite Pro. (Tier 1 - upstream wiki, etoro.Dictionary.GuruStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_gurustatus ALTER COLUMN Name COMMENT 'Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Note: "Rejected" has trailing space in production data. (Tier 1 - upstream wiki, etoro.Dictionary.GuruStatus)';

