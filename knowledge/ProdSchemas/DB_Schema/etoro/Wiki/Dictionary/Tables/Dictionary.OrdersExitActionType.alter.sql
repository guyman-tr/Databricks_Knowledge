-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.OrdersExitActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrdersExitActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_ordersexitactiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_ordersexitactiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_ordersexitactiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining exit order action types — currently empty in production, reserved for future classification of exit order resolution outcomes. Source: etoro.Dictionary.OrdersExitActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrdersExitActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_ordersexitactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'OrdersExitActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_ordersexitactiontype ALTER COLUMN ActionTypeID COMMENT 'Primary key identifying the exit order action type. Currently no values populated. When used, would classify exit order outcomes (execution, failure, cancellation). (Tier 1 - upstream wiki, etoro.Dictionary.OrdersExitActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_ordersexitactiontype ALTER COLUMN ActionName COMMENT 'Human-readable label for the exit order action type. NOT NULL constraint ensures all action types have a descriptive name. (Tier 1 - upstream wiki, etoro.Dictionary.OrdersExitActionType)';

