-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.OrderType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrderType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_ordertype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_ordertype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_ordertype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 21 types of trading orders supported by the eToro execution engine. Source: etoro.Dictionary.OrderType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrderType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_ordertype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'OrderType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_ordertype ALTER COLUMN OrderTypeID COMMENT 'Primary key identifying the order type. 0-20. Referenced by order tables in the Trade schema to classify each trading instruction. (Tier 1 - upstream wiki, etoro.Dictionary.OrderType)';
ALTER TABLE main.general.bronze_etoro_dictionary_ordertype ALTER COLUMN Name COMMENT 'Order type name. PascalCase format. Right-padded with spaces (char type). Used in execution engine routing, API request classification, and trading activity logs. (Tier 1 - upstream wiki, etoro.Dictionary.OrderType)';

