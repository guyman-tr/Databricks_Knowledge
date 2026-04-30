-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ProtocolDirection
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ProtocolDirection.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_protocoldirection
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_protocoldirection (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_protocoldirection SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 2 payment protocol communication directions — Direct (server-to-server) and Redirect (browser redirect) — for eToro''s billing payment processing. Source: etoro.Dictionary.ProtocolDirection on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ProtocolDirection.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_protocoldirection SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ProtocolDirection',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_protocoldirection ALTER COLUMN ProtocolDirectionID COMMENT 'Primary key. 1=Direct, 2=Redirect. Referenced by Dictionary.Protocol via FK. (Tier 1 - upstream wiki, etoro.Dictionary.ProtocolDirection)';
ALTER TABLE main.general.bronze_etoro_dictionary_protocoldirection ALTER COLUMN Name COMMENT 'Communication direction label. Unique index enforces no duplicates. Cached by Billing.LoadProtocolDirections. (Tier 1 - upstream wiki, etoro.Dictionary.ProtocolDirection)';

