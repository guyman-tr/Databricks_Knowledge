-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AuthenticationReasonPOI
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AuthenticationReasonPOI.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_authenticationreasonpoi
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_authenticationreasonpoi (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreasonpoi SET TBLPROPERTIES (
    'comment' = 'Lookup table for Proof of Identity (POI) specific document authentication reasons. Exists in SSDT but not deployed to the live database - likely replaced by the unified Dictionary.AuthenticationReason table. Source: etoro.Dictionary.AuthenticationReasonPOI on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AuthenticationReasonPOI.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreasonpoi SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AuthenticationReasonPOI',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreasonpoi ALTER COLUMN ReasonID COMMENT 'Primary key for POI-specific authentication reason. Same structure as Dictionary.AuthenticationReason.ReasonID. Table not deployed - likely consolidated into the main AuthenticationReason table. (Tier 1 - upstream wiki, etoro.Dictionary.AuthenticationReasonPOI)';
ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreasonpoi ALTER COLUMN Reason COMMENT 'Human-readable POI authentication reason description. Same structure as Dictionary.AuthenticationReason.Reason. (Tier 1 - upstream wiki, etoro.Dictionary.AuthenticationReasonPOI)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
