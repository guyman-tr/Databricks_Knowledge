-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.AddressOwnershipProofOption
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.AddressOwnershipProofOption.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_dictionary_addressownershipproofoption
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_dictionary_addressownershipproofoption (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_addressownershipproofoption SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the available options for proving ownership of a cryptocurrency wallet address, used in compliance and travel rule workflows. Source: WalletDB.Dictionary.AddressOwnershipProofOption on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.AddressOwnershipProofOption.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_dictionary_addressownershipproofoption SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'AddressOwnershipProofOption',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_addressownershipproofoption ALTER COLUMN Id COMMENT 'Unique identifier for the proof option. Values: 0=None, 1=Blocked, 2=Declaration, 3=ProofOfOwnership. Used as FK target by address-related tables in the Wallet schema. (Tier 1 - upstream wiki, WalletDB.Dictionary.AddressOwnershipProofOption)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_addressownershipproofoption ALTER COLUMN Name COMMENT 'Human-readable label for the proof option. Serves as the display name in application UIs and audit logs. (Tier 1 - upstream wiki, WalletDB.Dictionary.AddressOwnershipProofOption)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
