-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DocumentType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_documenttype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_documenttype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_documenttype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 20 types of identity and verification documents accepted by eToro for KYC/AML compliance. Source: etoro.Dictionary.DocumentType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_documenttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DocumentType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_documenttype ALTER COLUMN DocumentTypeID COMMENT 'Primary key identifying the document type category. Values range from 1 to 20. Each ID maps to a specific kind of identity or verification document. See Document Type. (Dictionary.DocumentType) (Tier 1 - upstream wiki, etoro.Dictionary.DocumentType)';
ALTER TABLE main.general.bronze_etoro_dictionary_documenttype ALTER COLUMN Name COMMENT 'Document type label. Used in the document upload UI, compliance review screens, and regulatory reports. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentType)';
ALTER TABLE main.general.bronze_etoro_dictionary_documenttype ALTER COLUMN MaxAgeInMonths COMMENT 'Maximum permitted age of the document in months from its issue date. NULL=no freshness requirement (document valid until its own expiration). Non-NULL=document must have been issued within this many months of upload. Used by compliance validation to reject stale documents. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
