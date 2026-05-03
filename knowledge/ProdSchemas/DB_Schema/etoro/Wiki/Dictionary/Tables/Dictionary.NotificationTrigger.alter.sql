-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.NotificationTrigger
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationTrigger.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_notificationtrigger
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_notificationtrigger (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_notificationtrigger SET TBLPROPERTIES (
    'comment' = 'Defines the business events that trigger outbound customer notifications, mapping system events like processed cashouts and margin calls to notification workflows. Source: etoro.Dictionary.NotificationTrigger on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationTrigger.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_notificationtrigger SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'NotificationTrigger',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_notificationtrigger ALTER COLUMN NotificationTriggerID COMMENT 'Unique identifier for the trigger event: 1=ProcessedCashout, 2=RejectedCashout, 3=CanceledCashout, 4=NegativeEquityInformant, 5=NegativeEquityMarginCall. (Tier 1 - upstream wiki, etoro.Dictionary.NotificationTrigger)';
ALTER TABLE main.general.bronze_etoro_dictionary_notificationtrigger ALTER COLUMN Name COMMENT 'Human-readable trigger event name. Used to configure notification-to-template mappings and in notification audit logs. (Tier 1 - upstream wiki, etoro.Dictionary.NotificationTrigger)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
