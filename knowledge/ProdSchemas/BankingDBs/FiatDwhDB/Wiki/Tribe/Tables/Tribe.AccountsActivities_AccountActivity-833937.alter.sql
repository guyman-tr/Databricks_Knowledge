-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsActivities_AccountActivity-833937.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 SET TBLPROPERTIES (
    'comment' = 'Child data table containing detailed account activity (transaction) records from Tribe, with 100+ columns covering all transaction fields including amounts, currencies, merchant info, risk data, and payment details. Source: FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937 on the FiatDwhDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Tribe/Tables/Tribe.AccountsActivities_AccountActivity-833937.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Tribe',
    'source_table' = 'AccountsActivities_AccountActivity-833937',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN @Created COMMENT 'DWH insertion timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN @Id COMMENT 'Unique record identifier. PK. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN @AccountsActivities@Id-862157 COMMENT 'FK to parent table Tribe.AccountsActivities-862157.@Id. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN HolderId COMMENT 'Tribe holder (customer) identifier. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN AccountId COMMENT 'Tribe account identifier. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN TransactionCode COMMENT 'Transaction type code from Tribe. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN TransactionAmount COMMENT 'Transaction amount (as string). (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN TransactionCurrencyAlpha COMMENT 'Transaction currency ISO alpha code. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN HolderAmount COMMENT 'Amount in holder''s currency (as string). (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN HolderCurrencyAlpha COMMENT 'Holder currency ISO alpha code. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN Suspicious COMMENT 'Risk flag: whether transaction was flagged as suspicious. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN RiskRuleCodes COMMENT 'Comma-separated risk rule codes that fired. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity-833937 ALTER COLUMN Created COMMENT 'Source system timestamp. (Tier 1 - upstream wiki, FiatDwhDB.Tribe.AccountsActivities_AccountActivity-833937)';

