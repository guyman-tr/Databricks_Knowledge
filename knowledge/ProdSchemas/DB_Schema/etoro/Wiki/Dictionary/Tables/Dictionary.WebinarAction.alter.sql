-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.WebinarAction
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WebinarAction.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_webinaraction
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_webinaraction (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_webinaraction SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the three stages of customer engagement with webinars - Registered, Attended, or Viewed (recording) - used to track customer participation in educational and marketing webinar events. Source: etoro.Dictionary.WebinarAction on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WebinarAction.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_webinaraction SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'WebinarAction',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_webinaraction ALTER COLUMN WebinarActionID COMMENT 'Unique identifier for the webinar engagement action: 0=Registered, 1=Attended, 2=Viewed. Referenced by BackOffice.Webinars and BackOffice.InsertWebinarData to classify customer webinar participation. (Tier 1 - upstream wiki, etoro.Dictionary.WebinarAction)';
ALTER TABLE main.general.bronze_etoro_dictionary_webinaraction ALTER COLUMN Name COMMENT 'Display name for the engagement action. Used in BackOffice reporting screens and marketing analytics to label customer webinar interactions. (Tier 1 - upstream wiki, etoro.Dictionary.WebinarAction)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
