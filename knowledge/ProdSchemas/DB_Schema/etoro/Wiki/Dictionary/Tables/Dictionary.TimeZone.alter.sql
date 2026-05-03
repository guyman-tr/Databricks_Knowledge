-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.TimeZone
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TimeZone.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_timezone
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_timezone (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_timezone SET TBLPROPERTIES (
    'comment' = 'Maps GMT offset time zones for customer profile geographic classification. Source: etoro.Dictionary.TimeZone on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TimeZone.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_timezone SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'TimeZone',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_timezone ALTER COLUMN TimeZoneID COMMENT 'Primary key identifying the time zone. 0=Unknown, 1-26=GMT-12 through GMT+13. Referenced by Customer.CustomerStatic, Customer.RegistrationRequest, History.Customer. (Tier 1 - upstream wiki, etoro.Dictionary.TimeZone)';
ALTER TABLE main.general.bronze_etoro_dictionary_timezone ALTER COLUMN Name COMMENT 'Time zone label (e.g., "GMT +02"). Fixed-width with trailing spaces. Unique via DTMZ_NAME index. (Tier 1 - upstream wiki, etoro.Dictionary.TimeZone)';
ALTER TABLE main.general.bronze_etoro_dictionary_timezone ALTER COLUMN Offset COMMENT 'UTC offset in hours. Range -12.00 to +13.00. Allows decimal for half-hour zones (though currently only whole-hour values used). (Tier 1 - upstream wiki, etoro.Dictionary.TimeZone)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
