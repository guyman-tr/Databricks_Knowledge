-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.SentTransactionReplaces
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionReplaces.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_senttransactionreplaces
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_senttransactionreplaces (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionreplaces SET TBLPROPERTIES (
    'comment' = 'Tracks Replace-By-Fee (RBF) events where a stuck blockchain transaction is replaced with a new one at a higher fee, recording the old and new transaction hashes. Source: WalletDB.Wallet.SentTransactionReplaces on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionReplaces.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionreplaces SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'SentTransactionReplaces',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionreplaces ALTER COLUMN Id COMMENT 'Auto-incrementing primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionReplaces)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionreplaces ALTER COLUMN SentTransactionId COMMENT 'The sent transaction being replaced. FK to Wallet.SentTransactions.Id. Stays constant across replacements. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionReplaces)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionreplaces ALTER COLUMN OldBlockchainTransactionId COMMENT 'The blockchain hash of the transaction being replaced (the stuck one). (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionReplaces)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionreplaces ALTER COLUMN NewBlockchainTransactionId COMMENT 'The blockchain hash of the replacement transaction (with higher fee). This becomes the new active hash. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionReplaces)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionreplaces ALTER COLUMN Occurred COMMENT 'Timestamp of the replacement event. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionReplaces)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
