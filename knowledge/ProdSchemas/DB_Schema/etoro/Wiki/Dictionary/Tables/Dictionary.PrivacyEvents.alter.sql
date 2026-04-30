-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PrivacyEvents
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrivacyEvents.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_privacyevents
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_privacyevents (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_privacyevents SET TBLPROPERTIES (
    'comment' = 'Lookup table defining privacy-sensitive platform events — currently contains only "Championship" (1) as an event type requiring privacy policy enforcement. Source: etoro.Dictionary.PrivacyEvents on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrivacyEvents.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_privacyevents SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PrivacyEvents',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_privacyevents ALTER COLUMN PrivacyEventID COMMENT 'Auto-incrementing primary key. IDENTITY NOT FOR REPLICATION. Currently only 1=Championship. Referenced by Dictionary.PrivacyPolicyDetails for per-event privacy settings. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyEvents)';
ALTER TABLE main.general.bronze_etoro_dictionary_privacyevents ALTER COLUMN PrivacyEventName COMMENT 'Human-readable event name. "Championship" is the only current value. Used in privacy policy configuration and user privacy checks. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyEvents)';

