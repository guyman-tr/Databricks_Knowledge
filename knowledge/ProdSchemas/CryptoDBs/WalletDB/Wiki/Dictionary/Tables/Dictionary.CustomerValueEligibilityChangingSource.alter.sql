-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.CustomerValueEligibilityChangingSource
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.CustomerValueEligibilityChangingSource.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_dictionary_customervalueeligibilitychangingsource
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_dictionary_customervalueeligibilitychangingsource (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_customervalueeligibilitychangingsource SET TBLPROPERTIES (
    'comment' = 'Lookup table identifying the source system that changed a customer''s eligibility for value-based crypto features (e.g., tier upgrades, premium access). Source: WalletDB.Dictionary.CustomerValueEligibilityChangingSource on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.CustomerValueEligibilityChangingSource.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_dictionary_customervalueeligibilitychangingsource SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'CustomerValueEligibilityChangingSource',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_customervalueeligibilitychangingsource ALTER COLUMN Id COMMENT 'Unique identifier for the change source. Values: 0=Unknown, 1=BackOffice, 2=Banking, 3=Crypto. (Tier 1 - upstream wiki, WalletDB.Dictionary.CustomerValueEligibilityChangingSource)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_customervalueeligibilitychangingsource ALTER COLUMN ChangingSource COMMENT 'Name of the system or team that triggered the eligibility change. Used in audit logs and customer support investigations. (Tier 1 - upstream wiki, WalletDB.Dictionary.CustomerValueEligibilityChangingSource)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
