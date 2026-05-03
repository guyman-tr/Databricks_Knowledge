-- =============================================================================
-- Databricks ALTER Script: bronze FiatDwhDB.Dictionary.ProgramTransitionEligibilityStatuses
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.ProgramTransitionEligibilityStatuses.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses SET TBLPROPERTIES (
    'comment' = 'Lookup table defining Eligibility outcome values for the fiat platform. Source: FiatDwhDB.Dictionary.ProgramTransitionEligibilityStatuses on the FiatDwhDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.ProgramTransitionEligibilityStatuses.md).'
);

ALTER TABLE main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'FiatDwhDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'ProgramTransitionEligibilityStatuses',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses ALTER COLUMN Id COMMENT 'Lookup identifier. Primary key. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.ProgramTransitionEligibilityStatuses)';
ALTER TABLE main.bi_db.bronze_fiatdwhdb_dictionary_programtransitioneligibilitystatuses ALTER COLUMN Name COMMENT 'Human-readable name for this value. (Tier 1 - upstream wiki, FiatDwhDB.Dictionary.ProgramTransitionEligibilityStatuses)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:05:44 UTC
-- Bronze deploy: FiatDwhDB batch 1
-- ====================
