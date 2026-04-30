-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.FiatMarketRatesMappings
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatMarketRatesMappings.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_fiatmarketratesmappings
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_fiatmarketratesmappings (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiatmarketratesmappings SET TBLPROPERTIES (
    'comment' = 'Maps fiat currencies to their market rate feed symbols, enabling the system to fetch real-time exchange rates for crypto-to-fiat conversion calculations. Source: WalletDB.Wallet.FiatMarketRatesMappings on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatMarketRatesMappings.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_fiatmarketratesmappings SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'FiatMarketRatesMappings',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiatmarketratesmappings ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatMarketRatesMappings)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiatmarketratesmappings ALTER COLUMN FiatId COMMENT 'References the fiat currency being mapped. FK to Wallet.FiatTypes.FiatId. Unique constraint ensures each fiat has exactly one rate mapping. Values: 1=USD, 2=EUR, 3=GBP, 5=AUD. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatMarketRatesMappings)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiatmarketratesmappings ALTER COLUMN MarketRatesCurrencySymbol COMMENT 'The symbol used to query the market rate feed for this fiat currency. Typically matches the ISO 4217 code (USD, EUR, GBP, AUD). Unique constraint ensures no duplicate symbols. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatMarketRatesMappings)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiatmarketratesmappings ALTER COLUMN Occurred COMMENT 'Timestamp when this mapping was created. Original 3 currencies share 2019-11-26; AUD added 2025-11-09. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatMarketRatesMappings)';

