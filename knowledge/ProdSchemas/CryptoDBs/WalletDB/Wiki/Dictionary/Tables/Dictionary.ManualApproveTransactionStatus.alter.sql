-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.ManualApproveTransactionStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ManualApproveTransactionStatus.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_manualapprovetransactionstatus
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_manualapprovetransactionstatus (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_manualapprovetransactionstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the lifecycle statuses for transactions requiring manual compliance approval before execution. Source: WalletDB.Dictionary.ManualApproveTransactionStatus on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ManualApproveTransactionStatus.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_manualapprovetransactionstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'ManualApproveTransactionStatus',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_manualapprovetransactionstatus ALTER COLUMN Id COMMENT 'Unique identifier for the approval status. Values: 1=Pending, 2=Approved, 3=Rejected, 4=Sent. FK target for Wallet.ManualApproveTransactionStatuses. (Tier 1 - upstream wiki, WalletDB.Dictionary.ManualApproveTransactionStatus)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_manualapprovetransactionstatus ALTER COLUMN Name COMMENT 'Short label for the status. Notably uses varchar(24) - smaller than typical Dictionary tables (varchar(64)) - suggesting this was designed for compact status display. (Tier 1 - upstream wiki, WalletDB.Dictionary.ManualApproveTransactionStatus)';

