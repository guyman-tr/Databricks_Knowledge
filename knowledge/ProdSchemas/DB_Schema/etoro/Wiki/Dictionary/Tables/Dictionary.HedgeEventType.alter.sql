-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.HedgeEventType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeEventType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_hedgeeventtype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_hedgeeventtype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_hedgeeventtype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the eight types of hedge infrastructure events - connection status changes, recovery outcomes, exposure zeroing, and volume anomaly detection for the hedge server monitoring system. Source: etoro.Dictionary.HedgeEventType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.HedgeEventType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_hedgeeventtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'HedgeEventType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_hedgeeventtype ALTER COLUMN EventTypeID COMMENT 'Primary key identifying the hedge event type. Connection: 1=Reconnect Primary, 2=Disconnect Primary, 3=Reconnect Backoffice, 4=Disconnect Backoffice. Recovery: 5=Success, 6=Fail. Business: 7=Exposures to 0, 8=Volume mismatch. Used in hedge event logging for monitoring and alerting. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeEventType)';
ALTER TABLE main.general.bronze_etoro_dictionary_hedgeeventtype ALTER COLUMN Name COMMENT 'Human-readable label for the event type. Used in hedge monitoring dashboards, alert notifications, and event log displays. Concisely describes what happened in the hedge infrastructure. (Tier 1 - upstream wiki, etoro.Dictionary.HedgeEventType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
