-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DocumentSide
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentSide.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_documentside
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_documentside (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_documentside SET TBLPROPERTIES (
    'comment' = 'Lookup table defining which side(s) of a document were captured in an uploaded KYC image - Front, Back, Both, or Not Recognizable. Source: etoro.Dictionary.DocumentSide on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentSide.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_documentside SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DocumentSide',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_documentside ALTER COLUMN SideID COMMENT 'Primary key identifying the document side. 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. Referenced by BackOffice.CustomerDocumentToDocumentType.DocumentSideID. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentSide)';
ALTER TABLE main.general.bronze_etoro_dictionary_documentside ALTER COLUMN Name COMMENT 'Human-readable side label. Used in BackOffice document review UI and KYC status displays. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentSide)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
