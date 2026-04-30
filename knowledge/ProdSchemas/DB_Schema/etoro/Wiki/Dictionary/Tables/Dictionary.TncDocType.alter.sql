-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.TncDocType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TncDocType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_tncdoctype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_tncdoctype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_tncdoctype SET TBLPROPERTIES (
    'comment' = 'Classifies Terms & Conditions document types for regulatory compliance across jurisdictions and product lines. Source: etoro.Dictionary.TncDocType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TncDocType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_tncdoctype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'TncDocType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_tncdoctype ALTER COLUMN ID COMMENT 'Primary key identifying the document type. Sequential 1-18. Referenced by BackOffice.TncDocument. (Tier 1 - upstream wiki, etoro.Dictionary.TncDocType)';
ALTER TABLE main.general.bronze_etoro_dictionary_tncdoctype ALTER COLUMN Name COMMENT 'Document type label. Nullable in DDL but populated for all rows. (Tier 1 - upstream wiki, etoro.Dictionary.TncDocType)';

