-- =============================================================================
-- Databricks ALTER Script: bronze WalletDB.Dictionary.CorrelatedRequestsTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.CorrelatedRequestsTypes.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_walletdb_dictionary_correlatedrequeststypes
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_walletdb_dictionary_correlatedrequeststypes (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_correlatedrequeststypes SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the types of correlated (idempotent) requests used to prevent duplicate processing of wallet operations. Source: WalletDB.Dictionary.CorrelatedRequestsTypes on the WalletDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.CorrelatedRequestsTypes.md).'
);

ALTER TABLE main.bi_db.bronze_walletdb_dictionary_correlatedrequeststypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'WalletDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'CorrelatedRequestsTypes',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_correlatedrequeststypes ALTER COLUMN Id COMMENT 'Unique identifier for the correlated request type. Currently: 1=Bounceback. Referenced by Wallet.CorrelatedRequests to classify each idempotency record. (Tier 1 - upstream wiki, WalletDB.Dictionary.CorrelatedRequestsTypes)';
ALTER TABLE main.bi_db.bronze_walletdb_dictionary_correlatedrequeststypes ALTER COLUMN Name COMMENT 'Descriptive label for the request type. Used in operational monitoring to filter and analyze correlated request patterns. (Tier 1 - upstream wiki, WalletDB.Dictionary.CorrelatedRequestsTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:10:21 UTC
-- Bronze deploy: WalletDB batch 1
-- ====================
