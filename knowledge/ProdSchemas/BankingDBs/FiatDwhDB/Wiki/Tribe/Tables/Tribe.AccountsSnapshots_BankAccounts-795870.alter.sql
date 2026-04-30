-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.AccountsSnapshots_BankAccounts-795870
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsSnapshots_BankAccounts-795870.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 SET TBLPROPERTIES (
    'comment' = 'Child table storing bank accounts collection from Tribe account snapshots (plural form - the collection container for bank accounts). Source: FiatDwhDB.Tribe.AccountsSnapshots_BankAccounts-795870 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsSnapshots_BankAccounts-795870.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'AccountsSnapshots_BankAccounts-795870',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 ALTER COLUMN @Created COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsSnapshots_BankAccounts-795870)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 ALTER COLUMN @Id COMMENT 'PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsSnapshots_BankAccounts-795870)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 ALTER COLUMN @AccountsSnapshots@Id-509416 COMMENT 'FK to parent. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsSnapshots_BankAccounts-795870)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccounts-795870 ALTER COLUMN Created COMMENT 'Source timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsSnapshots_BankAccounts-795870)';

