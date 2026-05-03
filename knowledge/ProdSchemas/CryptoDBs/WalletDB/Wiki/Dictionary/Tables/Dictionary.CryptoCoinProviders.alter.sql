-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.CryptoCoinProviders
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.CryptoCoinProviders.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_cryptocoinproviders
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_cryptocoinproviders (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_cryptocoinproviders SET TBLPROPERTIES (
    'comment' = 'Lookup table mapping blockchain-specific provider implementations (e.g., BitGo Bitcoin, BitGo Ethereum) to their parent custody provider (BitGo, CUG). Source: WalletDB.Dictionary.CryptoCoinProviders on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.CryptoCoinProviders.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_cryptocoinproviders SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'CryptoCoinProviders',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_cryptocoinproviders ALTER COLUMN Id COMMENT 'Unique identifier. Values: 1-9 mapping to specific blockchain/provider combinations. FK target for Wallet.BlockchainCryptoProviders and Wallet.BlockchainCryptos. (Tier 1 - upstream wiki, WalletDB.Dictionary.CryptoCoinProviders)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_cryptocoinproviders ALTER COLUMN Name COMMENT 'Unique provider implementation name. Maps to application-layer class names that implement blockchain interaction logic. (Tier 1 - upstream wiki, WalletDB.Dictionary.CryptoCoinProviders)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_cryptocoinproviders ALTER COLUMN WalletProviderId COMMENT 'FK to Dictionary.WalletProvider. Links this blockchain-specific implementation to its parent custody provider. Default is 1 (BitGo), indicating most coin providers are BitGo-managed. (Tier 1 - upstream wiki, WalletDB.Dictionary.CryptoCoinProviders)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
