-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ClientType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ClientType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_clienttype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_clienttype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_clienttype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 8 client application types - identifying which platform or app a customer is using (WebTrader, Android, iPhone, OpenBook, etc.). Source: etoro.Dictionary.ClientType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ClientType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_clienttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ClientType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_clienttype ALTER COLUMN ClientTypeID COMMENT 'Primary key identifying the client platform. Values 0-7. Uses tinyint (0-255 range) - sufficient for the small number of platform types. Recorded with user actions and sessions for analytics and feature gating. (Tier 1 - upstream wiki, etoro.Dictionary.ClientType)';
ALTER TABLE main.general.bronze_etoro_dictionary_clienttype ALTER COLUMN ClientTypeName COMMENT 'Name of the client platform (e.g., ''WebTrader'', ''Android'', ''iPhone'', ''OpenBook''). Enforced unique via UK_DCT_ClientTypeName constraint. Used in analytics reports and admin UIs to identify platform distribution. (Tier 1 - upstream wiki, etoro.Dictionary.ClientType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
