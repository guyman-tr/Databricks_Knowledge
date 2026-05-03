-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.EligibilityStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.EligibilityStatuses.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_dictionary_eligibilitystatuses
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_dictionary_eligibilitystatuses (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_eligibilitystatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the crypto feature access levels that can be granted to customers, from fully blocked to all operations allowed. Source: WalletDB.Dictionary.EligibilityStatuses on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.EligibilityStatuses.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_dictionary_eligibilitystatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'EligibilityStatuses',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_eligibilitystatuses ALTER COLUMN Id COMMENT 'Unique identifier for the eligibility tier. Values: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. Used by application logic to gate crypto operations per customer. (Tier 1 - upstream wiki, WalletDB.Dictionary.EligibilityStatuses)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_eligibilitystatuses ALTER COLUMN Name COMMENT 'Descriptive label for the eligibility tier. Used in back-office tools, compliance dashboards, and customer support interfaces. (Tier 1 - upstream wiki, WalletDB.Dictionary.EligibilityStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
