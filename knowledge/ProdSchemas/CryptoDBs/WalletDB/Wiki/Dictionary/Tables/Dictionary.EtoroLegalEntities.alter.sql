-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.EtoroLegalEntities
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.EtoroLegalEntities.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_dictionary_etorolegalentities
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_dictionary_etorolegalentities (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_etorolegalentities SET TBLPROPERTIES (
    'comment' = 'Lookup table of eToro''s regulated legal entities worldwide, used to associate customers and wallets with the correct regulatory jurisdiction. Source: WalletDB.Dictionary.EtoroLegalEntities on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.EtoroLegalEntities.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_dictionary_etorolegalentities SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'EtoroLegalEntities',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_etorolegalentities ALTER COLUMN Id COMMENT 'Unique identifier for the legal entity. Values: 1=EtoroX, 2=EtoroUS, 3=EtoroGermany, 4=EtoroDA, 5=EtoroSEY, 6=EtoroEU, 7=EtoroAUS, 8=EtoroME, 9=EtoroUK, 10=EtoroNY. Referenced by customer records for jurisdictional assignment. (Tier 1 - upstream wiki, WalletDB.Dictionary.EtoroLegalEntities)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_etorolegalentities ALTER COLUMN Name COMMENT 'Internal entity code. PascalCase format (e.g., "EtoroUS"). Used as a key in application configuration and routing logic. (Tier 1 - upstream wiki, WalletDB.Dictionary.EtoroLegalEntities)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_etorolegalentities ALTER COLUMN DisplayName COMMENT 'User-facing branded name (e.g., "eToroUS"). Shown in legal disclaimers, terms and conditions, and customer-facing communications. Nullable for potential future entities not yet branded. (Tier 1 - upstream wiki, WalletDB.Dictionary.EtoroLegalEntities)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
