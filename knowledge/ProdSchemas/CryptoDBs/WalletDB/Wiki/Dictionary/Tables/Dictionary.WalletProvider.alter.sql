-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.WalletProvider
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.WalletProvider.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_walletprovider
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_walletprovider (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_walletprovider SET TBLPROPERTIES (
    'comment' = 'Lookup table of blockchain custody providers that manage wallet key generation, transaction signing, and blockchain interaction for the eToro crypto platform. Source: WalletDB.Dictionary.WalletProvider on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.WalletProvider.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_walletprovider SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'WalletProvider',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_walletprovider ALTER COLUMN Id COMMENT 'Unique identifier. Values: 1=Bitgo, 2=CUG, 3=None. FK target for WalletPool, BlockchainCryptoProviders, TransactionsSyncRuns, WebhookTransactions, and 40+ SPs. The most referenced column in WalletDB after RequestStatuses.Id. (Tier 1 - upstream wiki, WalletDB.Dictionary.WalletProvider)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_walletprovider ALTER COLUMN Name COMMENT 'Provider name. Used throughout the application for routing blockchain operations to the correct custody infrastructure. (Tier 1 - upstream wiki, WalletDB.Dictionary.WalletProvider)';

