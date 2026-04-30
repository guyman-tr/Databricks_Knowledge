-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.NoteType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NoteType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_notetype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_notetype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_notetype SET TBLPROPERTIES (
    'comment' = 'Classifies the categories of internal notes that BackOffice staff attach to customer accounts for CRM tracking and operational context. Source: etoro.Dictionary.NoteType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NoteType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_notetype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'NoteType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_notetype ALTER COLUMN NoteTypeID COMMENT 'Unique identifier for the note category: 1=General, 2=Support, 3=Telemarketing, 4=Campaign. Referenced by History.CustomerNote and Maintenance.CustomerNoteAdd. (Tier 1 - upstream wiki, etoro.Dictionary.NoteType)';
ALTER TABLE main.general.bronze_etoro_dictionary_notetype ALTER COLUMN Name COMMENT 'Human-readable category label. Indexed (DCNT_NAME) for fast lookups. Displayed in BackOffice customer note forms and filters. (Tier 1 - upstream wiki, etoro.Dictionary.NoteType)';

