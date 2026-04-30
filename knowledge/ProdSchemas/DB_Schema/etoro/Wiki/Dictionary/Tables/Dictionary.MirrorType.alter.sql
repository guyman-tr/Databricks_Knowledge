-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.MirrorType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MirrorType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_mirrortype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_mirrortype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_mirrortype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 4 types of CopyTrading (mirror) relationships on the eToro platform. Source: etoro.Dictionary.MirrorType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MirrorType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_mirrortype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'MirrorType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_mirrortype ALTER COLUMN MirrorTypeID COMMENT 'Primary key identifying the copy relationship type. 1=Regular (standard copy), 2=CopyMe (legacy), 3=Social Index (algorithmic), 4=Fund (managed). See Mirror Type. (Dictionary.MirrorType) (Tier 1 - upstream wiki, etoro.Dictionary.MirrorType)';
ALTER TABLE main.general.bronze_etoro_dictionary_mirrortype ALTER COLUMN MirrorTypeName COMMENT 'Short code name used in code branching and API responses. (Tier 1 - upstream wiki, etoro.Dictionary.MirrorType)';
ALTER TABLE main.general.bronze_etoro_dictionary_mirrortype ALTER COLUMN Description COMMENT 'Human-readable description for display. More descriptive than MirrorTypeName. (Tier 1 - upstream wiki, etoro.Dictionary.MirrorType)';

