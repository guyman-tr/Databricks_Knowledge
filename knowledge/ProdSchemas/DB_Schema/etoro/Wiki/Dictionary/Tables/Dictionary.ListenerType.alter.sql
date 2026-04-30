-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ListenerType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ListenerType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_listenertype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_listenertype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_listenertype SET TBLPROPERTIES (
    'comment' = 'Classifies the types of real-time event listeners that subscribe to broker message broadcasts in the platform''s messaging infrastructure. Source: etoro.Dictionary.ListenerType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ListenerType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_listenertype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ListenerType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_listenertype ALTER COLUMN ListenerTypeID COMMENT 'Unique identifier for each listener category. Currently only 1 (BackOffice) exists. Referenced by Broker.Listener and Broker.ListenerTypeToMessage as the FK target. (Tier 1 - upstream wiki, etoro.Dictionary.ListenerType)';
ALTER TABLE main.general.bronze_etoro_dictionary_listenertype ALTER COLUMN Name COMMENT 'Human-readable label for the listener type. Enforced unique by index DLST_NAME. Used in Broker.Broadcast view to identify subscriber tiers. (Tier 1 - upstream wiki, etoro.Dictionary.ListenerType)';

