-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.ConversionTransactions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionTransactions.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_conversiontransactions
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_conversiontransactions (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions SET TBLPROPERTIES (
    'comment' = 'Stores the per-leg transaction details of crypto-to-crypto conversions, recording the exchange rate, destination address, amounts, and fees for each side of the swap. Source: WalletDB.Wallet.ConversionTransactions on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionTransactions.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'ConversionTransactions',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN Id COMMENT 'Auto-incrementing primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN ConversionId COMMENT 'Parent conversion. FK to Wallet.Conversions.Id. Part of unique constraint. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN WalletId COMMENT 'The wallet for this conversion leg. FK to Wallet.Wallets.WalletId. Part of unique constraint. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN CryptoRateUsd COMMENT 'USD exchange rate of this crypto at execution time. Used for valuation and fee calculation. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN ToAddress COMMENT 'Destination blockchain address for this conversion leg. NULL when the transfer is internal. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN Amount COMMENT 'Amount of crypto for this conversion leg in native units. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN EtoroFeePercentage COMMENT 'eToro fee percentage applied to this leg. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN EtoroFeeCalculated COMMENT 'Calculated eToro fee amount in the crypto''s native units. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN EstimatedBlockChainFee COMMENT 'Estimated blockchain network fee for this leg. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN Occurred COMMENT 'Timestamp of this transaction record creation. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversiontransactions ALTER COLUMN CryptoId COMMENT 'The cryptocurrency for this leg. FK to Wallet.CryptoTypes.CryptoID. Part of unique constraint. (Tier 1 - upstream wiki, WalletDB.Wallet.ConversionTransactions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
