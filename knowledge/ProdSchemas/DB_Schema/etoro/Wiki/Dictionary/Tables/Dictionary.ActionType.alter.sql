-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_actiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_actiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_actiontype SET TBLPROPERTIES (
    'comment' = 'Legacy lookup table defining 16 user activity types - registrations, logins, game sessions, and championship events - from the platform''s early social trading/gaming era. Source: etoro.Dictionary.ActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_actiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_actiontype ALTER COLUMN ActionTypeID COMMENT 'Primary key identifying the activity type. 0=NULL/Unknown, 1=Registration Real, 2=Registration Demo, 3=Login, 4=Logout, 5-14=Game/Championship events, 15=Registration IB. Referenced by Customer.PostRegisterOperations and Customer.RegisterDemo for registration tracking. (Tier 1 - upstream wiki, etoro.Dictionary.ActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_actiontype ALTER COLUMN Name COMMENT 'Fixed-width human-readable name (padded with spaces). Legacy data type - modern tables use varchar. Unique index enforced (DACP_NAME). Trim trailing spaces when displaying. (Tier 1 - upstream wiki, etoro.Dictionary.ActionType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
