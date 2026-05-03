-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DocumentRejectReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentRejectReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_documentrejectreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_documentrejectreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_documentrejectreason SET TBLPROPERTIES (
    'comment' = 'Lookup table enumerating 49 specific reasons why a KYC document was rejected - covering POI, POA, Selfie, SSN, and Visa document categories with granular rejection descriptions. Source: etoro.Dictionary.DocumentRejectReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentRejectReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_documentrejectreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DocumentRejectReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_documentrejectreason ALTER COLUMN RejectReasonID COMMENT 'Primary key identifying the rejection reason. 49 values from 0 (Other) to 54 (SSN Card - Damaged). Non-sequential - IDs 1-3, 7, 17, 20 are skipped. Referenced by BackOffice.DocumentRejectReasonToNotificationType for customer notification routing. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentRejectReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_documentrejectreason ALTER COLUMN RejectReasonName COMMENT 'Human-readable rejection reason displayed to the customer in their document status UI and in rejection notification emails. Prefixed by document type (POI/POA/Selfie) for clarity. (Tier 1 - upstream wiki, etoro.Dictionary.DocumentRejectReason)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
