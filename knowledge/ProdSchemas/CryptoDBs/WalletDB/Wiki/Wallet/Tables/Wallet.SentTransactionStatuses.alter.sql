-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.SentTransactionStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_senttransactionstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_senttransactionstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionstatuses SET TBLPROPERTIES (
    'comment' = 'Event-sourced status history for sent blockchain transactions, tracking each lifecycle transition from pending through confirmation to final verification or error. Source: WalletDB.Wallet.SentTransactionStatuses on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'SentTransactionStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionstatuses ALTER COLUMN Id COMMENT 'Auto-incrementing event identifier. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionstatuses ALTER COLUMN SentTransactionId COMMENT 'The sent transaction this status event belongs to. FK to Wallet.SentTransactions.Id. Multiple rows per transaction. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionstatuses ALTER COLUMN StatusId COMMENT 'Blockchain confirmation status: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. See Transaction Status. FK to Dictionary.TransactionStatus. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionstatuses ALTER COLUMN Occurred COMMENT 'Timestamp of this status transition. Used for confirmation time calculations. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
