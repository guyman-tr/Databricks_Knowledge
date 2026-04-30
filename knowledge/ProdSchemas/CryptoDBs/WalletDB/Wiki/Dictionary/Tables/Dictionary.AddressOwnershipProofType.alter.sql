-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.AddressOwnershipProofType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.AddressOwnershipProofType.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_dictionary_addressownershipprooftype
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_dictionary_addressownershipprooftype (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_addressownershipprooftype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the types of evidence accepted for verifying cryptocurrency address ownership under travel rule compliance. Source: WalletDB.Dictionary.AddressOwnershipProofType on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.AddressOwnershipProofType.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_dictionary_addressownershipprooftype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'AddressOwnershipProofType',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_addressownershipprooftype ALTER COLUMN Id COMMENT 'Unique identifier for the proof type. Values: 1=Declaration, 2=Signature. Referenced by address verification records to indicate which proof method was used. (Tier 1 - upstream wiki, WalletDB.Dictionary.AddressOwnershipProofType)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_addressownershipprooftype ALTER COLUMN Name COMMENT 'Human-readable label for the proof type. Used in UI displays and compliance audit reports. (Tier 1 - upstream wiki, WalletDB.Dictionary.AddressOwnershipProofType)';

