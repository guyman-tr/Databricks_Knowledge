-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.ConversionStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ConversionStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_conversionstatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_conversionstatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_conversionstatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the lifecycle statuses of cryptocurrency conversion (swap) operations within the wallet system. Source: WalletDB.Dictionary.ConversionStatuses on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ConversionStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_conversionstatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'ConversionStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_conversionstatuses ALTER COLUMN Id COMMENT 'Unique identifier for the conversion status. Values: 1=Pending, 2=Failed, 3=Completed. FK target for Wallet.ConversionStatuses and referenced in conversion transaction queries. (Tier 1 - upstream wiki, WalletDB.Dictionary.ConversionStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_conversionstatuses ALTER COLUMN Name COMMENT 'Human-readable status label. Displayed in customer transaction history and used in operational monitoring dashboards. (Tier 1 - upstream wiki, WalletDB.Dictionary.ConversionStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
