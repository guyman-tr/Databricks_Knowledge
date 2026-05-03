-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ThreeDsResponseTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ThreeDsResponseTypes.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_threedsresponsetypes
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_threedsresponsetypes (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_threedsresponsetypes SET TBLPROPERTIES (
    'comment' = 'Classifies 3D Secure (3DS) authentication response outcomes for credit card deposit transactions. Source: etoro.Dictionary.ThreeDsResponseTypes on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ThreeDsResponseTypes.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_threedsresponsetypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ThreeDsResponseTypes',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_threedsresponsetypes ALTER COLUMN ThreeDsResponseTypeID COMMENT 'Primary key identifying the 3DS response outcome. Sequential 0-14. Referenced by Billing.CreditCardAuthentication and History.BillingCreditCardAuthenticationHistory. (Tier 1 - upstream wiki, etoro.Dictionary.ThreeDsResponseTypes)';
ALTER TABLE main.general.bronze_etoro_dictionary_threedsresponsetypes ALTER COLUMN Name COMMENT 'Human-readable response description. Nullable in DDL but populated for all rows. (Tier 1 - upstream wiki, etoro.Dictionary.ThreeDsResponseTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
