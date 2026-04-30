-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.TransactionStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatus.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_transactionstatus
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_transactionstatus (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_transactionstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the lifecycle statuses for blockchain transactions (sent and received), tracking progress from pending through confirmation to verification or error. Source: WalletDB.Dictionary.TransactionStatus on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatus.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_transactionstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TransactionStatus',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_transactionstatus ALTER COLUMN Id COMMENT 'Unique identifier. Values: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. FK target for Dictionary.ErrorMonitoringPolicies.TransactionStatusId and Wallet.LimitExceeds. (Tier 1 - upstream wiki, WalletDB.Dictionary.TransactionStatus)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_transactionstatus ALTER COLUMN Name COMMENT 'Status label used in transaction monitoring dashboards and blockchain tracking UIs. (Tier 1 - upstream wiki, WalletDB.Dictionary.TransactionStatus)';

