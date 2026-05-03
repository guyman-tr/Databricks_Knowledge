-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.OrdersActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrdersActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_ordersactiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_ordersactiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_ordersactiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 5 lifecycle actions for pending orders - from client creation through conversion to positions, manual BackOffice removal, and order-for-open conversion. Source: etoro.Dictionary.OrdersActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrdersActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_ordersactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'OrdersActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_ordersactiontype ALTER COLUMN ActionTypeID COMMENT 'Primary key identifying the order action type. 1=ClientRemove, 2=ConvertedToPosition, 3=ManualBackOffice, 4=ClientCreated, 5=ConvertedToOrderForOpen. Used in History.Orders and Trade.PositionOpen. (Tier 1 - upstream wiki, etoro.Dictionary.OrdersActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_ordersactiontype ALTER COLUMN ActionName COMMENT 'Human-readable label for the action. Displayed in BackOffice closed orders reports and order audit history. (Tier 1 - upstream wiki, etoro.Dictionary.OrdersActionType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
