-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.CardsSnapshots_Account-513255
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_Account-513255.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 SET TBLPROPERTIES (
    'comment' = 'Child table storing individual account details from Tribe card snapshot files (singular account per card snapshot). Source: FiatDwhDB.Tribe.CardsSnapshots_Account-513255 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_Account-513255.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'CardsSnapshots_Account-513255',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 ALTER COLUMN @Created COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_Account-513255)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 ALTER COLUMN @Id COMMENT 'PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_Account-513255)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 ALTER COLUMN @CardsSnapshots@Id-890718 COMMENT 'FK to parent. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_Account-513255)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 ALTER COLUMN Created COMMENT 'Source timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_Account-513255)';

