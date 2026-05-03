-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.SettlementsTransactions-333243
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.SettlementsTransactions-333243.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions-333243
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions-333243 (business_group=emoney) ----
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243` SET TBLPROPERTIES (
    'comment' = 'Parent container table for Tribe SettlementsTransactions data files containing settlement/clearing transaction records from the provider. Source: FiatDwhDB.Tribe.SettlementsTransactions-333243 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.SettlementsTransactions-333243.md).'
);

ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243` SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'SettlementsTransactions-333243',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243` ALTER COLUMN `@Created` COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.SettlementsTransactions-333243)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243` ALTER COLUMN `@Id` COMMENT 'Unique file identifier. PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.SettlementsTransactions-333243)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243` ALTER COLUMN `@FileName` COMMENT 'Source file name. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.SettlementsTransactions-333243)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_settlementstransactions-333243` ALTER COLUMN Created COMMENT 'Source system timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.SettlementsTransactions-333243)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:09:36 UTC
-- Bronze deploy: FiatDwhDB batch 2
-- ====================
