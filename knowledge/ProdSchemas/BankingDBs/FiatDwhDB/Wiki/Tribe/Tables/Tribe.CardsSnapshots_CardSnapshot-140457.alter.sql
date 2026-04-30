-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_CardSnapshot-140457.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 SET TBLPROPERTIES (
    'comment' = 'Primary child table storing detailed card snapshot records from Tribe, including card status, program, holder details, limits, and activation dates. Source: FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_CardSnapshot-140457.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'CardsSnapshots_CardSnapshot-140457',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 ALTER COLUMN @Created COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 ALTER COLUMN @Id COMMENT 'PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 ALTER COLUMN @CardsSnapshots@Id-890718 COMMENT 'FK to parent. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 ALTER COLUMN HolderId COMMENT 'Tribe holder ID. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 ALTER COLUMN CardStatusCode COMMENT 'Card status code from Tribe. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 ALTER COLUMN CardStatusCodeDescription COMMENT 'Human-readable status description. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 ALTER COLUMN IsVirtual COMMENT 'Whether virtual card. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_cardsnapshot-140457 ALTER COLUMN Created COMMENT 'Source timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457)';

