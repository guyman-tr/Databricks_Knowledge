-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.NotificationType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_notificationtype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_notificationtype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_notificationtype SET TBLPROPERTIES (
    'comment' = 'Defines the delivery channels (email providers, push notification) used to send customer notifications. Source: etoro.Dictionary.NotificationType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_notificationtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'NotificationType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_notificationtype ALTER COLUMN NotificationTypeID COMMENT 'Unique identifier for the delivery channel: 1=SilverPopEmail, 2=SmtpEmail, 3=PushNotification. (Tier 1 - upstream wiki, etoro.Dictionary.NotificationType)';
ALTER TABLE main.general.bronze_etoro_dictionary_notificationtype ALTER COLUMN Name COMMENT 'Human-readable channel name. Used in notification configuration to select the delivery method. (Tier 1 - upstream wiki, etoro.Dictionary.NotificationType)';

