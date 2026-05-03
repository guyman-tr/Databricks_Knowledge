-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_Accounts-350640.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640 (business_group=emoney) ----
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640` SET TBLPROPERTIES (
    'comment' = 'Child collection table for accounts array in Tribe card snapshot files. Parent: CardsSnapshots-890718. Source: FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_Accounts-350640.md).'
);

ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640` SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'CardsSnapshots_Accounts-350640',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640` ALTER COLUMN `@Created` COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640` ALTER COLUMN `@Id` COMMENT 'PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640` ALTER COLUMN `@CardsSnapshots@Id-890718` COMMENT 'FK to parent. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640` ALTER COLUMN Created COMMENT 'Source timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:09:36 UTC
-- Bronze deploy: FiatDwhDB batch 2
-- ====================
