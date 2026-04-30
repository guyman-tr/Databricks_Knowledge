-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Dictionary.AuthorizationTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.AuthorizationTypes.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dictionary_authorizationtypes
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dictionary_authorizationtypes (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_authorizationtypes SET TBLPROPERTIES (
    'comment' = 'Lookup table defining Card transaction authorization type values for the fiat platform. Source: FiatDwhDB.Dictionary.AuthorizationTypes on the FiatDwhDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.AuthorizationTypes.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_authorizationtypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'AuthorizationTypes',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_authorizationtypes ALTER COLUMN Id COMMENT 'Lookup identifier. Primary key. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.AuthorizationTypes)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_authorizationtypes ALTER COLUMN Name COMMENT 'Human-readable name for this value. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.AuthorizationTypes)';

