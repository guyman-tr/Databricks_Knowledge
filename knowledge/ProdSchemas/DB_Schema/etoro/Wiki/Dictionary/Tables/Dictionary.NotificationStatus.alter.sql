-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.NotificationStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_notificationstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_notificationstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_notificationstatus SET TBLPROPERTIES (
    'comment' = 'Defines the delivery lifecycle states for platform notifications, tracking each notification from creation through processing to delivery or failure. Source: etoro.Dictionary.NotificationStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_notificationstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'NotificationStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_notificationstatus ALTER COLUMN NotificationStatusID COMMENT 'Unique identifier for the notification state: 1=Pending, 2=Processing, 3=Sent, 4=Failed. (Tier 1 - upstream wiki, etoro.Dictionary.NotificationStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_notificationstatus ALTER COLUMN Name COMMENT 'Human-readable state label. Nullable (unusual for lookup). Displayed in notification monitoring dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.NotificationStatus)';

