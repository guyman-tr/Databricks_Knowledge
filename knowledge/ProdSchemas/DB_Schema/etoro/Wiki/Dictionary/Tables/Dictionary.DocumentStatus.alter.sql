-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DocumentStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_documentstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_documentstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_documentstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 5 review states for KYC/AML identity documents uploaded by users. Source: etoro.Dictionary.DocumentStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_documentstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DocumentStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_documentstatus ALTER COLUMN DocumentStatusID COMMENT 'Primary key identifying the document review state. 1=Uploaded, 2=PendingReview, 3=Approved, 4=Declined, 5=Expired. See Document Status. (Dictionary.DocumentStatus) (Tier 1 - upstream wiki, etoro.Dictionary.DocumentStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_documentstatus ALTER COLUMN DocumentStatusName COMMENT 'Human-readable status label. Used in compliance review UI, customer communications, and regulatory reporting. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
