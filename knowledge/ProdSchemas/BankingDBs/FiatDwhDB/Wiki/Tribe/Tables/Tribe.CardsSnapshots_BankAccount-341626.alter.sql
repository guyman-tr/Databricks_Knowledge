-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.CardsSnapshots_BankAccount-341626
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_BankAccount-341626.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 SET TBLPROPERTIES (
    'comment' = 'Grandchild table storing individual bank account details from Tribe card snapshot files. References CardsSnapshots_BankAccounts collection. Source: FiatDwhDB.Tribe.CardsSnapshots_BankAccount-341626 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.CardsSnapshots_BankAccount-341626.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'CardsSnapshots_BankAccount-341626',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 ALTER COLUMN @Id COMMENT 'Record identifier. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_BankAccount-341626)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 ALTER COLUMN @CardsSnapshots_BankAccounts@Id-83854 COMMENT 'FK to collection parent. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_BankAccount-341626)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccount-341626 ALTER COLUMN Created COMMENT 'Source timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.CardsSnapshots_BankAccount-341626)';

