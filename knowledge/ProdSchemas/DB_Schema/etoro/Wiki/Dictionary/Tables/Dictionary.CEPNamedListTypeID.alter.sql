-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CEPNamedListTypeID
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CEPNamedListTypeID.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cepnamedlisttypeid
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cepnamedlisttypeid (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cepnamedlisttypeid SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 2 types of CEP (Complex Event Processing) named lists — Normal (manually configured) and DB Generated (auto-populated from database queries). Source: etoro.Dictionary.CEPNamedListTypeID on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CEPNamedListTypeID.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cepnamedlisttypeid SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CEPNamedListTypeID',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cepnamedlisttypeid ALTER COLUMN NamedListTypeID COMMENT 'Primary key identifying the named list type. Values: 1=Normal (manual), 2=DB Generated (automatic). Referenced by CEP.NamedLists.NamedListTypeID (FK) to classify each named list''s population strategy. (Tier 1 - upstream wiki, etoro.Dictionary.CEPNamedListTypeID)';
ALTER TABLE main.general.bronze_etoro_dictionary_cepnamedlisttypeid ALTER COLUMN Description COMMENT 'Human-readable label for the list type (e.g., ''Normal'', ''DB Generated Named List''). Used in the CEP management UI to indicate how a list''s contents are maintained. (Tier 1 - upstream wiki, etoro.Dictionary.CEPNamedListTypeID)';

