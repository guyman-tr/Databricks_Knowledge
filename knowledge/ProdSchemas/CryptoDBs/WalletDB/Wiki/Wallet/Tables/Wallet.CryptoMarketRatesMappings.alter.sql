-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.CryptoMarketRatesMappings
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoMarketRatesMappings.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_cryptomarketratesmappings
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_cryptomarketratesmappings (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptomarketratesmappings SET TBLPROPERTIES (
    'comment' = 'Maps each cryptocurrency to its market rate feed symbol, enabling the system to fetch real-time USD prices for balance display, conversion calculations, and portfolio valuation. Source: WalletDB.Wallet.CryptoMarketRatesMappings on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoMarketRatesMappings.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptomarketratesmappings SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'CryptoMarketRatesMappings',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptomarketratesmappings ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoMarketRatesMappings)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptomarketratesmappings ALTER COLUMN CryptoId COMMENT 'The cryptocurrency this mapping applies to. FK to Wallet.CryptoTypes.CryptoID. Unique constraint ensures one rate mapping per crypto. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoMarketRatesMappings)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptomarketratesmappings ALTER COLUMN MarketRatesCurrencySymbol COMMENT 'Symbol used to query the market rate feed for this crypto''s USD price. Usually matches the crypto ticker (BTC, ETH, USDT) but may differ for versioned tokens (KNC2, AXSV2, GALAV2). Unique constraint prevents duplicate symbols. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoMarketRatesMappings)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_cryptomarketratesmappings ALTER COLUMN Occurred COMMENT 'Timestamp when this mapping was created. Original mappings share 2019-11-26. Newer cryptos have later dates tracking their rate feed integration. (Tier 1 - upstream wiki, WalletDB.Wallet.CryptoMarketRatesMappings)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
