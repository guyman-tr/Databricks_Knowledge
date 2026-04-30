-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.NotificationTypeName
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationTypeName.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_notificationtypename
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_notificationtypename (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_notificationtypename SET TBLPROPERTIES (
    'comment' = 'Maps KYC document rejection and account action notification types to their notification template identifiers, enabling the system to send the correct customer communication for each compliance scenario. Source: etoro.Dictionary.NotificationTypeName on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.NotificationTypeName.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_notificationtypename SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'NotificationTypeName',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_notificationtypename ALTER COLUMN NotificationTypeID COMMENT 'Unique identifier for the KYC notification scenario. Values 1-40. Referenced by BackOffice.DocumentRejectReasonToNotificationType to map rejection reasons to email templates. (Tier 1 - upstream wiki, etoro.Dictionary.NotificationTypeName)';
ALTER TABLE main.general.bronze_etoro_dictionary_notificationtypename ALTER COLUMN NotificationType COMMENT 'Template identifier code used to select the correct email template for the compliance scenario. Format: {Category}{SpecificReason}Email (e.g., POIDocExpired, POAOlderThanSixMonths, SelfieMotionRejectedEmail). (Tier 1 - upstream wiki, etoro.Dictionary.NotificationTypeName)';

