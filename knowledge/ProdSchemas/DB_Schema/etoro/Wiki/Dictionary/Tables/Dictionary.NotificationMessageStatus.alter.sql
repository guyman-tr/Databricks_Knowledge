-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.NotificationMessageStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationMessageStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_notificationmessagestatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_notificationmessagestatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_notificationmessagestatus SET TBLPROPERTIES (
    'comment' = 'Tracks the processing pipeline states for outbound notification messages, from initial receipt through queuing, processing, and delivery or failure. Source: etoro.Dictionary.NotificationMessageStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationMessageStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_notificationmessagestatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'NotificationMessageStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_notificationmessagestatus ALTER COLUMN StatusID COMMENT 'Unique identifier for the message processing state: 1=Received, 2=Queued, 3=Processed, 4=SentToProcess, 5=Failed. Referenced by notification message tracking tables. (Tier 1 - upstream wiki, etoro.Dictionary.NotificationMessageStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_notificationmessagestatus ALTER COLUMN Name COMMENT 'Human-readable state label. Nullable (unusual for a lookup Name column). Displayed in notification monitoring dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.NotificationMessageStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
