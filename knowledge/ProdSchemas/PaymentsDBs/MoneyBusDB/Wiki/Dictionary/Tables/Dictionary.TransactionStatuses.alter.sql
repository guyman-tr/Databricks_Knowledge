-- =============================================================================
-- Databricks ALTER Script: bronze MoneyBusDB.Dictionary.TransactionStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatuses.md
-- Layer: bronze
-- UC Target: main.billing.bronze_moneybusdb_dictionary_transactionstatuses
-- =============================================================================

-- ---- UC Target: main.billing.bronze_moneybusdb_dictionary_transactionstatuses (business_group=billing) ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the top-level lifecycle states of money transfer transactions in the MoneyBus payment system. Source: MoneyBusDB.Dictionary.TransactionStatuses on the MoneyBusDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatuses.md).'
);

ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'MoneyBusDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TransactionStatuses',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatuses ALTER COLUMN ID COMMENT 'Primary key identifying each transaction status. Explicitly assigned (not IDENTITY). Referenced as StatusID in MoneyBus.Transactions and as TransactionStatusID in Dictionary.TransactionStatusReasons. Values: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. See Transaction Status for full business definitions. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.TransactionStatuses)';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_transactionstatuses ALTER COLUMN Name COMMENT 'Human-readable status label. JOINed by ALERT_ConsecutiveTransactionFailuresAlert to display status names in alert output. Used for reporting and debugging visibility. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.TransactionStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:41:14 UTC
-- Bronze deploy: MoneyBusDB batch 1
-- ====================
