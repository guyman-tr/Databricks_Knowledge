-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DocumentSizeActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentSizeActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_documentsizeactiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_documentsizeactiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_documentsizeactiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the processing states of document image size reduction — whether the reduced-size version is ready, unavailable, or not yet processed. Source: etoro.Dictionary.DocumentSizeActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentSizeActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_documentsizeactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DocumentSizeActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_documentsizeactiontype ALTER COLUMN ID COMMENT 'Primary key identifying the size action state. 0=ready, 1=unavailable, 2=not yet processed. Referenced by BackOffice.CustomerDocument.DocumentSizeActionTypeID and set by document insertion procedures. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentSizeActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_documentsizeactiontype ALTER COLUMN ActionName COMMENT 'Descriptive text explaining the current size processing state. Written as full sentences (unusual for a dictionary table) — used directly in UI or logs without transformation. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentSizeActionType)';

