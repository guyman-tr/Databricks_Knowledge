-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.CloseExecutionPlan
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CloseExecutionPlan.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_closeexecutionplan
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_closeexecutionplan (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_closeexecutionplan SET TBLPROPERTIES (
    'comment' = 'Memory-optimized table storing the execution plan for closing positions—maps which positions and units to close for each order-for-close before actual hedge execution. Source: etoro.Trade.CloseExecutionPlan on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.CloseExecutionPlan.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_closeexecutionplan SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'CloseExecutionPlan',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_closeexecutionplan ALTER COLUMN OrderID COMMENT 'References Trade.OrderForClose.OrderID. The close order this plan belongs to. (Tier 1 - upstream wiki, etoro.Trade.CloseExecutionPlan)';
ALTER TABLE main.trading.bronze_etoro_trade_closeexecutionplan ALTER COLUMN PositionID COMMENT 'References Trade.PositionTbl.PositionID. The position to close. (Tier 1 - upstream wiki, etoro.Trade.CloseExecutionPlan)';
ALTER TABLE main.trading.bronze_etoro_trade_closeexecutionplan ALTER COLUMN Units COMMENT 'Number of units to close for this position in this plan. (Tier 1 - upstream wiki, etoro.Trade.CloseExecutionPlan)';
ALTER TABLE main.trading.bronze_etoro_trade_closeexecutionplan ALTER COLUMN Level COMMENT 'Tree level (0=root). Used for hierarchical close ordering; Level=0 commonly filters root positions. (Tier 1 - upstream wiki, etoro.Trade.CloseExecutionPlan)';
ALTER TABLE main.trading.bronze_etoro_trade_closeexecutionplan ALTER COLUMN CID COMMENT 'Customer ID. References Customer.CustomerStatic.CID. (Tier 1 - upstream wiki, etoro.Trade.CloseExecutionPlan)';
ALTER TABLE main.trading.bronze_etoro_trade_closeexecutionplan ALTER COLUMN CloseActionType COMMENT 'Reason/type of close. Maps to Dictionary.OrderForExecutionCloseActionType.ID. (Tier 1 - upstream wiki, etoro.Trade.CloseExecutionPlan)';
ALTER TABLE main.trading.bronze_etoro_trade_closeexecutionplan ALTER COLUMN IsHedged COMMENT 'Whether the position has an open hedge. Affects execution path and fee logic. (Tier 1 - upstream wiki, etoro.Trade.CloseExecutionPlan)';

