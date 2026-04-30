-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsSnapshots_AccountSnapshot-956050.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 SET TBLPROPERTIES (
    'comment' = 'Child table storing account snapshot details from Tribe, containing point-in-time account state (status, balance, program info) as raw nvarchar data. Source: FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsSnapshots_AccountSnapshot-956050.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'AccountsSnapshots_AccountSnapshot-956050',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 ALTER COLUMN @Created COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 ALTER COLUMN @Id COMMENT 'Unique record identifier. PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 ALTER COLUMN @AccountsSnapshots@Id-509416 COMMENT 'FK to parent Tribe.AccountsSnapshots-509416. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 ALTER COLUMN Created COMMENT 'Source system timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050)';

