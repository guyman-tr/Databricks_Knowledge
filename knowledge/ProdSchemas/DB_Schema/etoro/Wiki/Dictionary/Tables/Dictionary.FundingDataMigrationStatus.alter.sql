-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.FundingDataMigrationStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundingDataMigrationStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_fundingdatamigrationstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_fundingdatamigrationstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_fundingdatamigrationstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the six states of the funding data encryption migration pipeline — from initial staging through XML update success or failure in Billing.Funding. Source: etoro.Dictionary.FundingDataMigrationStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundingDataMigrationStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_fundingdatamigrationstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'FundingDataMigrationStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_fundingdatamigrationstatus ALTER COLUMN ID COMMENT 'Primary key identifying the migration status. 0=New, 1=Encryption succeeded in staging, 2=Encryption failed in staging, 3=XML modified in production (success), 4=Runtime error during production update, 5=Silent update failure. Used to track each funding record''s progress through the encryption migration pipeline. (Tier 1 - upstream wiki, etoro.Dictionary.FundingDataMigrationStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundingdatamigrationstatus ALTER COLUMN StatusDesc COMMENT 'Human-readable description of the migration state. Provides enough detail for operations staff to understand what happened at each step — particularly useful for distinguishing between different failure modes (runtime error vs silent failure). (Tier 1 - upstream wiki, etoro.Dictionary.FundingDataMigrationStatus)';

