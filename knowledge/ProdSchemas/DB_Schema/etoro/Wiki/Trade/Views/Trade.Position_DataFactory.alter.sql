-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.Position_DataFactory
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.Position_DataFactory.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_position_datafactory
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_position_datafactory (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory SET TBLPROPERTIES (
    'comment' = 'ETL-optimized variant of Trade.Position for data factory/CDC consumption, excluding markup columns and adding RowVersionIDByPosition for incremental loads. Source: etoro.Trade.Position_DataFactory on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.Position_DataFactory.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'Position_DataFactory',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN PositionID COMMENT 'Primary key. Unique identifier for the open position. (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN RowVersionIDByPosition COMMENT 'BIGINT cast of RowVersionPosition for CDC/incremental load watermark. (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN CID COMMENT 'Customer ID. FK to Customer.Customer. (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN InstrumentID COMMENT 'Instrument traded. FK to Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN Amount COMMENT 'Position size in denomination currency. (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN AmountInUnitsDecimal COMMENT 'Position size in units/shares. (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN InitialUnits COMMENT 'Computed: ISNULL(InitialUnits, AmountInUnitsDecimal). (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN UnitsBaseValueCents COMMENT 'Computed: ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN CommissionByUnits COMMENT 'Computed: Prorated commission for partial close. (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN FullCommissionByUnits COMMENT 'Computed: Prorated full commission for partial close. (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
ALTER TABLE main.trading.bronze_etoro_trade_position_datafactory ALTER COLUMN `(Remaining columns)` COMMENT 'All other columns from Trade.Position except excluded markup/pricing columns. Includes ForexResultID, CurrencyID, ProviderID, GameServerID, HedgeID, HedgeServerID, OrderID, Leverage, UnitMargin, LotCountDecimal, NetProfit, InitForexRate, InitDateTime, LimitRate, StopRate, SpreadedPipBid, SpreadedPipAsk, IsBuy, CloseOnEndOfWeek, EndOfWeekFee, Commission, SpreadedCommission, FullCommission, SettlementTypeID, and tree/hierarchy/version columns. (Tier 1 - upstream wiki, etoro.Trade.Position_DataFactory)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
