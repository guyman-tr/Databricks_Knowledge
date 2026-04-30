-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ChampionshipType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ChampionshipType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_championshiptype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_championshiptype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_championshiptype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3 types of trading championships — NULL (unset), Public (open to all), and Private (invitation-only). Source: etoro.Dictionary.ChampionshipType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ChampionshipType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_championshiptype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ChampionshipType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_championshiptype ALTER COLUMN ChampionshipTypeID COMMENT 'Primary key identifying the championship type. Values: 0=NULL, 1=Public, 2=Private. Referenced by Championship.Championship.ChampionshipTypeID and History.Championship.ChampionshipTypeID. Also used by Internal.GetChampionshipTypeID for ID generation. (Tier 1 - upstream wiki, etoro.Dictionary.ChampionshipType)';
ALTER TABLE main.general.bronze_etoro_dictionary_championshiptype ALTER COLUMN Name COMMENT 'Type label (''NULL'', ''Public'', ''Private''). Enforced unique via DCHT_NAME index. Used in views and procedures for display and filtering. (Tier 1 - upstream wiki, etoro.Dictionary.ChampionshipType)';

