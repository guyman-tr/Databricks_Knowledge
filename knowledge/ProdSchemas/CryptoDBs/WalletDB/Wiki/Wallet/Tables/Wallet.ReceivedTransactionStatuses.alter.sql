-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.ReceivedTransactionStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history for received blockchain transactions, tracking each processing step from detection through AML screening to final acknowledgment. Source: WalletDB.Wallet.ReceivedTransactionStatuses on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'ReceivedTransactionStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing event identifier. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses ALTER COLUMN ReceivedTransactionId COMMENT 'The received transaction this status belongs to. FK to Wallet.ReceivedTransactions.Id. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses ALTER COLUMN StatusId COMMENT 'Processing status. Uses the same Dictionary.TransactionStatus values as sent transactions but in the context of receive processing (0=Pending processing, 1=Confirmed/credited, etc.). (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses ALTER COLUMN Occurred COMMENT 'Timestamp of this processing step. (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses ALTER COLUMN DetailsJson COMMENT 'JSON payload with step-specific context (AML results, error details, processing metadata). (Tier 1 - upstream wiki, WalletDB.Wallet.ReceivedTransactionStatuses)';

