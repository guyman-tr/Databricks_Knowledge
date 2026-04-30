-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Dictionary.TribeScriptStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.TribeScriptStatus.md
-- Layer: bronze
-- UC Target: main.emoney.bronze_fiatdwhdb_dictionary_tribescriptstatus
-- =============================================================================

-- ---- UC Target: main.emoney.bronze_fiatdwhdb_dictionary_tribescriptstatus (business_group=emoney) ----
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_tribescriptstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining Script approval workflow values for the fiat platform. Source: FiatDwhDB.Dictionary.TribeScriptStatus on the FiatDwhDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.TribeScriptStatus.md).'
);

ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_tribescriptstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'TribeScriptStatus',
    'business_group' = 'emoney',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_tribescriptstatus ALTER COLUMN Id COMMENT 'Lookup identifier. Primary key. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.TribeScriptStatus)';
ALTER TABLE main.emoney.bronze_fiatdwhdb_dictionary_tribescriptstatus ALTER COLUMN Name COMMENT 'Human-readable name for this value. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.TribeScriptStatus)';

