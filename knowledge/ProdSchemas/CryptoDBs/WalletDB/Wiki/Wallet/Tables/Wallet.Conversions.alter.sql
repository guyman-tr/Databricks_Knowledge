-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.Conversions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_conversions
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_conversions (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions SET TBLPROPERTIES (
    'comment' = 'Records crypto-to-crypto conversion operations where a user swaps one cryptocurrency for another, tracking the source and destination wallets, amounts, and exchange direction. Source: WalletDB.Wallet.Conversions on the WalletDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Conversions.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'Conversions',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN Id COMMENT 'Auto-incrementing primary key. FK target for Wallet.ConversionStatuses and Wallet.ConversionTransactions. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN FromWalletId COMMENT 'The source wallet from which crypto is sold. FK to Wallet.Wallets.WalletId. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN ToWalletId COMMENT 'The destination wallet into which the purchased crypto arrives. FK to Wallet.Wallets.WalletId. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN ConversionTypeId COMMENT 'Determines pricing direction: 1=FixedFrom (sell amount fixed), 2=FixedTo (buy amount fixed). See Conversion Type. FK to Dictionary.ConversionTypes. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN FromAmount COMMENT 'Amount of source crypto being sold. In native units of FromCryptoId. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN ToAmount COMMENT 'Amount of destination crypto being purchased. In native units of ToCryptoId. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN CorrelationId COMMENT 'Links to the parent request in Wallet.Requests.CorrelationId. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN Occurred COMMENT 'Timestamp when the conversion was initiated. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN FromCryptoId COMMENT 'Source cryptocurrency being sold. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_conversions ALTER COLUMN ToCryptoId COMMENT 'Destination cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 - upstream wiki, WalletDB.Wallet.Conversions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
