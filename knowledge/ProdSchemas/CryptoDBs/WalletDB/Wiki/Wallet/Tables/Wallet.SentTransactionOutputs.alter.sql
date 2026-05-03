-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.SentTransactionOutputs
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_senttransactionoutputs
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_senttransactionoutputs (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs SET TBLPROPERTIES (
    'comment' = 'Stores the output details (destination addresses, amounts, fees) for each sent blockchain transaction, supporting multi-output transactions like Bitcoin''s UTXO model. Source: WalletDB.Wallet.SentTransactionOutputs on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'SentTransactionOutputs',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN Id COMMENT 'Auto-incrementing key starting at 0. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN SentTransactionId COMMENT 'Parent sent transaction. FK to Wallet.SentTransactions.Id. Multiple outputs per transaction possible. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN ToAddress COMMENT 'Destination blockchain address for this output. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN Amount COMMENT 'Amount of crypto sent to this output address. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN EtoroFees COMMENT 'eToro service fee allocated to this output. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN BlockchainFees COMMENT 'Network fee allocated to this output. NULL when fee is at transaction level. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN SourceId COMMENT 'Business entity ID this output originated from. For redemptions, this is the PositionId. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN SourceIdType COMMENT 'Type of SourceId: 0=PositionId. See Transaction Output Source ID Type. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN Occurred COMMENT 'Timestamp of this output record creation. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN IsEtoroFee COMMENT 'Whether this output represents an eToro fee payment rather than a value transfer. 1=fee output, 0/NULL=value output. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_senttransactionoutputs ALTER COLUMN NormalizedToAddress COMMENT 'Computed PERSISTED column stripping protocol prefix and query parameters from ToAddress. (Tier 1 - upstream wiki, WalletDB.Wallet.SentTransactionOutputs)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
