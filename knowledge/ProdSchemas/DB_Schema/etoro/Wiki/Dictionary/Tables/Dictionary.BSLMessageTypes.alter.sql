-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.BSLMessageTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BSLMessageTypes.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_bslmessagetypes
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_bslmessagetypes (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_bslmessagetypes SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3 BSL (Balance Stop-Loss) message types - liquidation warning, forced liquidation, and account unblock - used by the margin call and equity protection system. Source: etoro.Dictionary.BSLMessageTypes on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.BSLMessageTypes.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_bslmessagetypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'BSLMessageTypes',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_bslmessagetypes ALTER COLUMN ID COMMENT 'Primary key identifying the BSL message type. Values: 1=Warning, 2=Liquidation, 3=Unblock. Referenced by Dictionary.BSLOperationThreshold.MessageTypeID to link equity thresholds to message types. JOINed by Trade.GetUsersFromBSLTables to resolve message type IDs in BSL event queries. (Tier 1 - upstream wiki, etoro.Dictionary.BSLMessageTypes)';
ALTER TABLE main.general.bronze_etoro_dictionary_bslmessagetypes ALTER COLUMN MessageTypeDecstiption COMMENT 'Description of the BSL message type. Note: column name contains a typo (''Decstiption'' instead of ''Description''). Used as the human-readable label in BSL reports - aliased as ''BSLOperation'' in Trade.GetUsersFromBSLTables. (Tier 1 - upstream wiki, etoro.Dictionary.BSLMessageTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
