-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.ChecksumTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ChecksumTypes.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_checksumtypes
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_checksumtypes (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_checksumtypes SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the categories of objects that have checksums computed for data integrity verification across the wallet system. Source: WalletDB.Dictionary.ChecksumTypes on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ChecksumTypes.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_checksumtypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'ChecksumTypes',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_checksumtypes ALTER COLUMN Id COMMENT 'Unique identifier for the checksum type. Values: 1=WalletPool, 2=Wallet, 3=StakingAddress, 4=EtoroExternalAddress. FK target for Wallet.Checksums.ChecksumTypeId. (Tier 1 - upstream wiki, WalletDB.Dictionary.ChecksumTypes)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_checksumtypes ALTER COLUMN Name COMMENT 'Unique human-readable label identifying the scope of checksum monitoring. Used in integrity verification procedures and security monitoring alerts. (Tier 1 - upstream wiki, WalletDB.Dictionary.ChecksumTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
