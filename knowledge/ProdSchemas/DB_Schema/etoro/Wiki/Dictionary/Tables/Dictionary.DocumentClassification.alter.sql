-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DocumentClassification
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentClassification.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_documentclassification
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_documentclassification (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_documentclassification SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 73 specific document sub-classifications within each KYC document type — mapping granular document names (Passport, Utility Bill, Bank Statement, etc.) to their parent document types with optional age limits. Source: etoro.Dictionary.DocumentClassification on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentClassification.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_documentclassification SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DocumentClassification',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_documentclassification ALTER COLUMN DocumentClassificationID COMMENT 'Primary key identifying the specific document classification. 73 values from 1 (Passport) to 73. Referenced by BackOffice.CustomerDocumentToDocumentType.DocumentClassificationID and multiple BackOffice procedures. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentClassification)';
ALTER TABLE main.general.bronze_etoro_dictionary_documentclassification ALTER COLUMN Name COMMENT 'Human-readable document sub-type name (Passport, Utility Bill, Bank Statement, etc.). Displayed in the BackOffice document review UI. Nullable but all rows have values. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentClassification)';
ALTER TABLE main.general.bronze_etoro_dictionary_documentclassification ALTER COLUMN DocumentTypeID COMMENT 'FK to Dictionary.DocumentType — the parent document type this classification belongs to. Groups classifications into POI (2), POA (1), Corporate (5), Source of Funds (7), Bank Details (8), Compliance (9), etc. See Document Type. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentClassification)';
ALTER TABLE main.general.bronze_etoro_dictionary_documentclassification ALTER COLUMN MaxAgeInMonths COMMENT 'Maximum age in months for this document to be accepted. NULL = no age limit. Only Driving License POA (40) and StateID (41) have values (24 months). Used by BackOffice.GetDocumentMaxAge to enforce document freshness rules. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentClassification)';

