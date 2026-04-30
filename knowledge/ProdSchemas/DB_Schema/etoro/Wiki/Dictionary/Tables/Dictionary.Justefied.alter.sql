-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Justefied
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Justefied.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_justefied
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_justefied (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_justefied SET TBLPROPERTIES (
    'comment' = 'Configuration table storing justified (acceptable) failure identifiers for trading position failure reporting — entries in this table represent known failure patterns that have been reviewed and deemed acceptable, filtering them out of operational failure dashboards. Source: etoro.Dictionary.Justefied on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Justefied.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_justefied SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Justefied',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_justefied ALTER COLUMN ID COMMENT 'Auto-incrementing identifier. Secondary to the Name column — not used as a join key by consuming procedures. Provides a numeric reference for each justified failure entry. (Tier 1 - upstream wiki, etoro.Dictionary.Justefied)';
ALTER TABLE main.general.bronze_etoro_dictionary_justefied ALTER COLUMN Name COMMENT 'Primary key and lookup column. Stores the failure pattern identifier that is matched against position failure reports. The large size (900 chars) accommodates composite failure identifiers. Used by 5+ failure reporting procedures for whitelist filtering. (Tier 1 - upstream wiki, etoro.Dictionary.Justefied)';

