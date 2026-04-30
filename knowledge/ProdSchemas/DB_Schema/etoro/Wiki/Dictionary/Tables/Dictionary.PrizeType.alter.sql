-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PrizeType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrizeType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_prizetype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_prizetype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_prizetype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 4 championship prize calculation methods — Unknown, Fix, Percent, and Product — used by the eToro championship/competition system. Source: etoro.Dictionary.PrizeType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrizeType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_prizetype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PrizeType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_prizetype ALTER COLUMN PrizeTypeID COMMENT 'Primary key identifying the prize calculation method. Values 0-3 are the 4 supported types. Referenced by Championship.Championship and History.Championship tables. (Tier 1 - upstream wiki, etoro.Dictionary.PrizeType)';
ALTER TABLE main.general.bronze_etoro_dictionary_prizetype ALTER COLUMN Name COMMENT 'Human-readable label for the prize type. Padded to 50 chars (CHAR type). Used in championship configuration UI and resolved by Internal.GetPrizeTypeID. Unique index enforces no duplicate names. (Tier 1 - upstream wiki, etoro.Dictionary.PrizeType)';

