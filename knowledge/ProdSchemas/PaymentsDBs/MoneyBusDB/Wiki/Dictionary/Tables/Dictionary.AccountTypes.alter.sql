-- =============================================================================
-- Databricks ALTER Script: bronze MoneyBusDB.Dictionary.AccountTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_moneybusdb_dictionary_accounttypes
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_moneybusdb_dictionary_accounttypes (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_moneybusdb_dictionary_accounttypes SET TBLPROPERTIES (
    'comment' = 'Lookup table that classifies the types of financial accounts involved in money transfer transactions and withdrawals within the MoneyBus payment system. Source: MoneyBusDB.Dictionary.AccountTypes on the MoneyBusDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md).'
);

ALTER TABLE main.bi_db.bronze_moneybusdb_dictionary_accounttypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'MoneyBusDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'AccountTypes',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_moneybusdb_dictionary_accounttypes ALTER COLUMN ID COMMENT 'Primary key and unique identifier for each account type. Referenced as CreditorTypeID, DebitorTypeID (MoneyBus.Transactions), AccountTypeID (MoneyBus.Withdrawals), DebitAccountTypeID/CreditAccountTypeID (MoneyBus.TransferLimits), and InitiatorAccountTypeId (MoneyBus.TransactionsGroup). Values: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See Account Type for full business definitions. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.AccountTypes)';
ALTER TABLE main.bi_db.bronze_moneybusdb_dictionary_accounttypes ALTER COLUMN Name COMMENT 'Human-readable label for the account type. Used in alert reporting (ALERT_ConsecutiveTransactionFailuresAlert JOINs this column to display creditor/debitor type names). Unique business names that map to platform product verticals. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.AccountTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:41:14 UTC
-- Bronze deploy: MoneyBusDB batch 1
-- ====================
