-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.CardsSnapshots-890718
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots-890718.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots-890718
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots-890718 (business_group=emoney) ----
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718` SET TBLPROPERTIES (
    'comment' = 'Parent container table for Tribe CardsSnapshots data files containing point-in-time card state snapshots from the provider. Source: FiatDwhDB.Tribe.CardsSnapshots-890718 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots-890718.md).'
);

ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718` SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'CardsSnapshots-890718',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718` ALTER COLUMN `@Created` COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots-890718)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718` ALTER COLUMN `@Id` COMMENT 'Unique file identifier. PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots-890718)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718` ALTER COLUMN `@FileName` COMMENT 'Source file name. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots-890718)';
ALTER TABLE main.emoney.`bronze_fiatdwhdb_tribe_cardssnapshots-890718` ALTER COLUMN Created COMMENT 'Source system timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots-890718)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:09:36 UTC
-- Bronze deploy: FiatDwhDB batch 2
-- ====================
