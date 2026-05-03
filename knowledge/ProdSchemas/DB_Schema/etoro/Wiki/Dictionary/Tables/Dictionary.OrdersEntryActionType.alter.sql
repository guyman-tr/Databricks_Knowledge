-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.OrdersEntryActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrdersEntryActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_ordersentryactiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_ordersentryactiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_ordersentryactiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 6 action types for entry orders - tracking how entry (pending) orders are resolved: manual close, execution success/failure, parent position closure, or client removal. Source: etoro.Dictionary.OrdersEntryActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrdersEntryActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_ordersentryactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'OrdersEntryActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_ordersentryactiontype ALTER COLUMN ActionTypeID COMMENT 'Primary key identifying the entry order action type. 0=Manual, 1=CloseByExecution, 2=CloseByExecutionFail, 3=CloseByExecutionFailDueToMaxRetries, 4=Closed due to parent position close, 5=ClientRemove. (Tier 1 - upstream wiki, etoro.Dictionary.OrdersEntryActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_ordersentryactiontype ALTER COLUMN ActionName COMMENT 'Human-readable label for the action. Displayed in order audit reports and execution tracking. (Tier 1 - upstream wiki, etoro.Dictionary.OrdersEntryActionType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
