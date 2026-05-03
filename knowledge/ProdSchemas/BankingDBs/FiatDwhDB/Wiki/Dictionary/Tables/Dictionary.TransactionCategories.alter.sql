-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Dictionary.TransactionCategories
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.TransactionCategories.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dictionary_transactioncategories
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dictionary_transactioncategories (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_transactioncategories SET TBLPROPERTIES (
    'comment' = 'Lookup table defining Transaction category values for the fiat platform. Source: FiatDwhDB.Dictionary.TransactionCategories on the FiatDwhDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.TransactionCategories.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_transactioncategories SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TransactionCategories',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_transactioncategories ALTER COLUMN Id COMMENT 'Lookup identifier. Primary key. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.TransactionCategories)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_transactioncategories ALTER COLUMN Name COMMENT 'Human-readable name for this value. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.TransactionCategories)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
