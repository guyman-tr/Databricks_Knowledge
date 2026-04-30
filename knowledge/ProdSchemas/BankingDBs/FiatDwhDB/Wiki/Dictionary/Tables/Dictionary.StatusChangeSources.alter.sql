-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Dictionary.StatusChangeSources
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.StatusChangeSources.md
-- Layer: bronze
-- UC Target: main.general.bronze_fiatdwhdb_dictionary_statuschangesources
-- =============================================================================

-- ---- UC Target: main.general.bronze_fiatdwhdb_dictionary_statuschangesources (business_group=general) ----
ALTER TABLE main.general.bronze_fiatdwhdb_dictionary_statuschangesources SET TBLPROPERTIES (
    'comment' = 'Lookup table defining Balance status change source values for the fiat platform. Source: FiatDwhDB.Dictionary.StatusChangeSources on the FiatDwhDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.StatusChangeSources.md).'
);

ALTER TABLE main.general.bronze_fiatdwhdb_dictionary_statuschangesources SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'StatusChangeSources',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_fiatdwhdb_dictionary_statuschangesources ALTER COLUMN Id COMMENT 'Lookup identifier. Primary key. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.StatusChangeSources)';
ALTER TABLE main.general.bronze_fiatdwhdb_dictionary_statuschangesources ALTER COLUMN Name COMMENT 'Human-readable name for this value. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.StatusChangeSources)';

