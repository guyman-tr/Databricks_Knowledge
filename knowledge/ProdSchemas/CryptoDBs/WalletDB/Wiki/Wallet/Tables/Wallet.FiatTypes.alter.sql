-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Wallet.FiatTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_wallet_fiattypes
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_wallet_fiattypes (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes SET TBLPROPERTIES (
    'comment' = 'Reference table of supported fiat currencies for crypto-to-fiat conversions and payment operations within the eToro wallet platform. Source: WalletDB.Wallet.FiatTypes on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.FiatTypes.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Wallet',
    'source_table' = 'FiatTypes',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes ALTER COLUMN Id COMMENT 'Auto-incrementing surrogate primary key within WalletDB. Used as FK target by Wallet.Payments. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes ALTER COLUMN FiatId COMMENT 'Business identifier for the fiat currency used across eToro platform systems. Unique constraint (UQ_Wallet_FiatTypes_FiatId). Values: 1=USD, 2=EUR, 3=GBP, 5=AUD. Referenced by Wallet.FiatMarketRatesMappings as FK. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes ALTER COLUMN FiatName COMMENT 'ISO 4217 three-letter currency code (e.g., USD, EUR, GBP, AUD). Unique constraint enforced. Used for display and API parameter matching. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes ALTER COLUMN IsActive COMMENT 'Whether this fiat currency is currently available for crypto operations. All current entries are active (1). Setting to 0 would disable conversions and payments in this currency. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes ALTER COLUMN AvatarUrl COMMENT 'URL to the currency''s display icon hosted on S3. Used in the eToro wallet UI for visual identification of fiat currencies. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes ALTER COLUMN Precision COMMENT 'Number of decimal places used when displaying and calculating amounts in this currency. All current currencies use 5 decimal places for precision in conversion calculations. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes ALTER COLUMN InstrumentId COMMENT 'Links to the eToro trading platform instrument representing the exchange rate for this fiat vs USD. NULL for USD (base currency). EUR=1, GBP=2, AUD=7. Used to fetch real-time exchange rates for crypto-to-fiat conversions. Implicit reference to Wallet.Instruments. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatTypes)';
ALTER TABLE main.wallet.bronze_walletdb_wallet_fiattypes ALTER COLUMN NumericCode COMMENT 'ISO 4217 numeric currency code (e.g., 840=USD, 978=EUR, 826=GBP, 36=AUD). Used for standardized integrations with payment providers and regulatory reporting. (Tier 1 - upstream wiki, WalletDB.Wallet.FiatTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
