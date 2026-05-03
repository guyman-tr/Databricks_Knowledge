-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.AccountsActivities_862157
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Views/Tribe.AccountsActivities_862157.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_862157
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_862157 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_862157 SET TBLPROPERTIES (
    'comment' = 'Simple view wrapper over the Tribe.AccountsActivities-862157 table, providing a clean view name without the hyphen that some tools struggle with. Source: FiatDwhDB.Tribe.AccountsActivities_862157 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Views/Tribe.AccountsActivities_862157.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_862157 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'AccountsActivities_862157',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_862157 ALTER COLUMN `@Created` COMMENT 'DWH insertion timestamp. From base table. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_862157)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_862157 ALTER COLUMN `@Id` COMMENT 'File GUID. From base table. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_862157)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_862157 ALTER COLUMN `@FileName` COMMENT 'Source file name. From base table. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_862157)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_862157 ALTER COLUMN Created COMMENT 'Source timestamp. From base table. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_862157)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
