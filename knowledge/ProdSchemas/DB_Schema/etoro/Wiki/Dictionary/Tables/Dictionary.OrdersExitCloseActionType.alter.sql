-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.OrdersExitCloseActionType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrdersExitCloseActionType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_ordersexitcloseactiontype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_ordersexitcloseactiontype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_ordersexitcloseactiontype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 8 ways an exit-close order can be resolved - manual closure, execution success/failure, parent position close, retry exhaustion, redemption, account liquidation, or mirror unregister. Source: etoro.Dictionary.OrdersExitCloseActionType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.OrdersExitCloseActionType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_ordersexitcloseactiontype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'OrdersExitCloseActionType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_ordersexitcloseactiontype ALTER COLUMN ActionTypeID COMMENT 'Primary key identifying the exit-close action type. 0=Manual, 1=CloseByExecution, 2=CloseByExecutionFail, 3=CloseByPositionClose, 4=CloseByExecutionFailDueToMaxRetries, 5=CloseByRedeem, 6=ClosePartialByAccountLiquidation, 7=ClosePartialByMirrorUnregister. (Tier 1 - upstream wiki, etoro.Dictionary.OrdersExitCloseActionType)';
ALTER TABLE main.general.bronze_etoro_dictionary_ordersexitcloseactiontype ALTER COLUMN ActionName COMMENT 'Human-readable label for the exit-close action. Displayed in position lifecycle reports and execution audit trails. (Tier 1 - upstream wiki, etoro.Dictionary.OrdersExitCloseActionType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
