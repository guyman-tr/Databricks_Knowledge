-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.RequestStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.RequestStatuses.md
-- Layer: bronze
-- UC Target: main.wallet.bronze_walletdb_dictionary_requeststatuses
-- =============================================================================

-- ---- UC Target: main.wallet.bronze_walletdb_dictionary_requeststatuses (business_group=Wallet) ----
ALTER TABLE main.wallet.bronze_walletdb_dictionary_requeststatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the comprehensive lifecycle statuses for wallet operation requests, the central state machine driving all crypto transaction processing from initiation through blockchain confirmation. Source: WalletDB.Dictionary.RequestStatuses on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.RequestStatuses.md).'
);

ALTER TABLE main.wallet.bronze_walletdb_dictionary_requeststatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'RequestStatuses',
    'business_group' = 'Wallet',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.wallet.bronze_walletdb_dictionary_requeststatuses ALTER COLUMN Id COMMENT 'Unique status identifier. Non-sequential IDs (gaps at 10-15, 17-24) reflect organic growth as new flows were added. FK target for Wallet.RequestStatuses. The most referenced column in the entire WalletDB Dictionary schema. (Tier 1 - upstream wiki, WalletDB.Dictionary.RequestStatuses)';
ALTER TABLE main.wallet.bronze_walletdb_dictionary_requeststatuses ALTER COLUMN Name COMMENT 'PascalCase status label. Maps to C# enum values in application code. Used across 36+ stored procedures and functions for status filtering and transitions. (Tier 1 - upstream wiki, WalletDB.Dictionary.RequestStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
