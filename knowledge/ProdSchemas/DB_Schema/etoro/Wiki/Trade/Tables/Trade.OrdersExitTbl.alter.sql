-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.OrdersExitTbl
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.OrdersExitTbl.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_ordersexittbl
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_ordersexittbl (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl SET TBLPROPERTIES (
    'comment' = 'Partitioned disk-based table storing exit orders (pending take-profit, stop-loss, trailing stop) that close existing positions when market conditions are met; status 1 = active, archived to History.OrdersExitTbl when closed/canceled. Source: etoro.Trade.OrdersExitTbl on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.OrdersExitTbl.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'OrdersExitTbl',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN OrderID COMMENT 'Primary key component; unique order identifier (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN CID COMMENT 'Customer ID; links to Trading.Customer (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN PositionID COMMENT 'Position to close; links to Trade.Position (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN OpenOccurred COMMENT 'When exit order was created (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN MirrorID COMMENT '0=manual; >0=CopyTrader mirror ID (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN MirrorCloseActionType COMMENT 'Close action type for mirror scenarios (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN OpenActionType COMMENT 'Dictionary.OrdersExitOpenActionType: 0=Manual, 1=OpenByUnregisterMirror, etc. (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN RedeemID COMMENT 'Redeem operation ID for fund redemption (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN RedeemReasonID COMMENT 'Reason for redemption (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN UnitsToDeduct COMMENT 'Units to close (partial close); NULL = full close (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN CloseByUnitsID COMMENT 'Links to partial close order when closing by units (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN PartitionCol COMMENT 'Persisted computed: CID % 50; partition key for PS_ORDERS (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN StatusID COMMENT '1=active, 2=closed; Dictionary.OrderForExecutionStatus (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN CloseOccurred COMMENT 'When exit order was closed/canceled (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersexittbl ALTER COLUMN CloseActionType COMMENT 'How order was closed (e.g. executed, canceled) (Tier 1 - upstream wiki, etoro.Trade.OrdersExitTbl)';

