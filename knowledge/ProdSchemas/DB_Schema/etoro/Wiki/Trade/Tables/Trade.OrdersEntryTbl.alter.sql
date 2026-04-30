-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.OrdersEntryTbl
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.OrdersEntryTbl.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_ordersentrytbl
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_ordersentrytbl (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl SET TBLPROPERTIES (
    'comment' = 'Disk-based table storing entry orders (pending limit/stop orders) that trigger position opens when market conditions are met; status 1 = active, archived to History.OrdersEntryTbl when closed/canceled. Source: etoro.Trade.OrdersEntryTbl on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.OrdersEntryTbl.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'OrdersEntryTbl',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN OrderID COMMENT 'Primary key; unique order identifier (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN CID COMMENT 'Customer ID; links to Trading.Customer (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN InstrumentID COMMENT 'Instrument (asset) to trade (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN Leverage COMMENT 'Leverage multiplier (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN Amount COMMENT 'Order size in currency (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN IsBuy COMMENT '1=Buy (long), 0=Sell (short) (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN StopLosPercentage COMMENT 'Stop-loss percentage (schema typo: StopLos) (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN TakeProfitPercentage COMMENT 'Take-profit percentage (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN Occurred COMMENT 'When order was created (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN ParentPositionID COMMENT 'Parent position for add-to-position; 0 or NULL if new position (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN MirrorID COMMENT '0=manual; >0=CopyTrader mirror ID (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN InitialMirrorAmountInCents COMMENT 'Mirror allocation amount in cents (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN IsTslEnabled COMMENT 'Trailing stop-loss enabled (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN AmountInUnitsDecimal COMMENT 'Order size in units (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN OrderTypeID COMMENT 'Dictionary.OrderType; 13=EntryOrderByAmount default (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN OpenOpenOperationTypeID COMMENT 'Open operation classification (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN IsDiscounted COMMENT 'Discount applied flag (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN StatusID COMMENT '1=active, 2=closed; Dictionary.OrderForExecutionStatus (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN CloseOccurred COMMENT 'When order was closed/canceled (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN CloseActionType COMMENT 'How order was closed (e.g. 4=parent position exit) (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN SettlementTypeID COMMENT 'Dictionary.SettlementTypes: 0=CFD, 1=REAL, etc. (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN IsNoStopLoss COMMENT 'User opted out of stop-loss (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';
ALTER TABLE main.trading.bronze_etoro_trade_ordersentrytbl ALTER COLUMN IsNoTakeProfit COMMENT 'User opted out of take-profit (Tier 1 - upstream wiki, etoro.Trade.OrdersEntryTbl)';

