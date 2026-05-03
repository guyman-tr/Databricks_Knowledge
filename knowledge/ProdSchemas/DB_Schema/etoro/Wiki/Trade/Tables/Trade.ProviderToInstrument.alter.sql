-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.ProviderToInstrument
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderToInstrument.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_providertoinstrument
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_providertoinstrument (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument SET TBLPROPERTIES (
    'comment' = 'Per-provider, per-instrument trading configuration that defines fees, limits, allowed operations, and risk parameters for each instrument routed through each execution provider. Source: etoro.Trade.ProviderToInstrument on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderToInstrument.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'ProviderToInstrument',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN ProviderID COMMENT 'FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tradonomi). Part of PK. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument. Identifies the tradeable instrument. Part of PK. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN Precision COMMENT 'Decimal places for price display and rounding. Used by Trade.ChangeTreePropertiesPerInstrument, Trade.UpdatePositionsTakeProfitByInstrumentID. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN PaymentBid COMMENT 'Bid-side payment adjustment (basis points or similar). Negative values observed (e.g., -250). (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN PaymentAsk COMMENT 'Ask-side payment adjustment. Positive values observed (e.g., 250). (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN PresentationCode COMMENT 'Display code for the instrument (e.g., EURUSD=, GBP=, JPY=). Used in UI and reporting. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN StopLossPercentage COMMENT 'Legacy or alternate SL percentage field. Sample data shows 0. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN EndOfWeekFee COMMENT 'End-of-week holding fee. Used in ClaimEndOfWeekFee, fee calculations. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN Unit COMMENT 'Base unit size for the instrument. HedgeExposureQuery uses PTI.Unit. Typically 1000 for forex. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN UnitMargin COMMENT 'Margin factor per unit. Used in margin and exposure calculations. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN Benchmark COMMENT 'Reference value for pricing (e.g., 10000 for forex). (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN LiquidityLotSize COMMENT 'Lot size for liquidity provider orders. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN LiquidityLotCost COMMENT 'Cost per liquidity lot. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN DisplayOrder COMMENT 'Sort order for UI display. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN WeekendPips COMMENT 'Weekend spread or fee in pips. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MinimumSpread COMMENT 'Minimum spread allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN OrdersSpread COMMENT 'Spread applied to orders. Sample 200. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN OrdersSpreadMax COMMENT 'Maximum spread for orders. Sample 10. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MarketRange COMMENT 'Market range validation limit. Sample 10000000. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN SpreadPct COMMENT 'Spread as percentage. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN BonusCreditUsePercent COMMENT 'Percentage of position that can use bonus credit. Trade.InstrumentNWADecreasePercentage view. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN BuyEOWFee COMMENT 'End-of-week fee for buy positions. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN SellEOWFee COMMENT 'End-of-week fee for sell positions. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN BuyOverNightFee COMMENT 'Overnight fee for buy positions. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN SellOverNightFee COMMENT 'Overnight fee for sell positions. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MaxStopLossPercentage COMMENT 'Maximum allowed stop-loss percentage. Enforced on edit. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN Enabled COMMENT '1=instrument tradeable through this provider, 0=disabled. Trade.GetProviderToInstrument filters Enabled=1. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowedRateDiffPercentage COMMENT 'Max allowed rate difference for order execution validation. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN EtoroHoldingFeeSpreadFactor COMMENT 'Multiplier for eToro holding fee. CHECK > 0. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MaxPositionUnits COMMENT 'Max position size in units. CHECK <= 2147483647. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MinPositionAmount COMMENT 'Minimum position size in currency. Trade.InstrumentMinPositionAmount view. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowBuy COMMENT '1=buy allowed, 0=buy disabled for this instrument-provider pair. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowSell COMMENT '1=sell allowed, 0=sell disabled. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowPendingOrders COMMENT '1=pending orders allowed, 0=market only. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowEntryOrders COMMENT '1=entry orders allowed, 0=no entry orders. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN VisibleInternallyOnly COMMENT '1=hidden from external clients (internal/ops only), 0=visible to all. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowClosePosition COMMENT '1=user can close position, 0=close disabled. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowExitOrder COMMENT '1=exit orders allowed, 0=no exit orders. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN GuaranteeSLTP COMMENT '1=broker guarantees SL/TP execution, 0=no guarantee. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowEditSLTP COMMENT '1=user can edit SL/TP after open, 0=no edit. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MaxTakeProfitPercentage COMMENT 'Maximum allowed take-profit percentage. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MaxClosingPriceDiffPercentage COMMENT 'Max allowed closing price difference. Sample 5. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN SettledBuyMaxLeverage COMMENT 'Max leverage for settled (real) buy positions. 0=not applicable. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN SettledSellMaxLeverage COMMENT 'Max leverage for settled sell positions. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowManualTrading COMMENT '1=manual trading allowed, 0=copy-only or disabled. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN Leverage1MaintenanceMargin COMMENT 'Maintenance margin percentage at 1x leverage. Sample 100 or 11.11. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN RequiresW8Ben COMMENT '1=US tax form W-8BEN required for this instrument, 0=not required. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MinStopLossPercentage COMMENT 'Minimum allowed stop-loss percentage. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MinTakeProfitPercentage COMMENT 'Minimum allowed take-profit percentage. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN DefaultStopLossPercentage COMMENT 'Default SL when opening without explicit SL. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN DefaultTakeProfitPercentage COMMENT 'Default TP when opening without explicit TP. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowTrailingStopLoss COMMENT '1=trailing SL allowed, 0=not allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN DefaultTrailingStopLoss COMMENT '1=trailing SL on by default, 0=off by default. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowEditStopLoss COMMENT '1=user can edit SL, 0=no edit. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowEditTakeProfit COMMENT '1=user can edit TP, 0=no edit. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowLeveragedLongSL COMMENT '1=SL allowed for leveraged long positions, 0=not allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowNonLeveragedLongSL COMMENT '1=SL allowed for non-leveraged long, 0=not allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowLeveragedShortSL COMMENT '1=SL allowed for leveraged short, 0=not allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowNonLeveragedShortSL COMMENT '1=SL allowed for non-leveraged short, 0=not allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowLeveragedLongTP COMMENT '1=TP allowed for leveraged long, 0=not allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowNonLeveragedLongTP COMMENT '1=TP allowed for non-leveraged long, 0=not allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowLeveragedShortTP COMMENT '1=TP allowed for leveraged short, 0=not allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowNonLeveragedShortTP COMMENT '1=TP allowed for non-leveraged short, 0=not allowed. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowRedeem COMMENT 'Redeem/withdrawal allowance. 0=no redeem, 1+=allowed with constraints. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MinPositionUnitsForRedeem COMMENT 'Min units for redeem when AllowRedeem > 0. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MaxPositionUnitsForRedeem COMMENT 'Max units for redeem. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowEditStopLossLeveraged COMMENT '1=edit SL allowed for leveraged positions, 0=no edit. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowEditTakeProfitLeveraged COMMENT '1=edit TP allowed for leveraged positions, 0=no edit. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowPartialClosePosition COMMENT '1=partial close allowed, 0=full close only. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN DefaultStopLossPercentageLeveraged COMMENT 'Default SL for leveraged positions. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN DefaultStopLossPercentageNonLeveraged COMMENT 'Default SL for non-leveraged positions. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN ExchangeFeeMultiplier COMMENT 'Multiplier for exchange fee. Sample 2 or 4. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). Current DB login. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application context. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN SysStartTime COMMENT 'System versioning row start. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN SysEndTime COMMENT 'System versioning row end. GENERATED ALWAYS AS ROW END. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AboveDollarPrecision COMMENT 'Precision for amounts above dollar threshold. Sample 3 or 5. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MarketRangeValidationType COMMENT 'How market range is validated. 1=default, 2=percentage-based. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN MarketRangePercentage COMMENT 'Market range as percentage when MarketRangeValidationType=2. Sample 0.2, 0.5. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN DesignatedExecutionSystem COMMENT 'Execution system routing. 1=default. Trade.UpdateDesignatedExecutionSystemBulk updates. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN InitialMarginInAssetCurrency COMMENT 'Initial margin in asset currency. Sample 90, 3, or NULL. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN StopLossMarginInAssetCurrency COMMENT 'Stop-loss margin in asset currency. Sample 80, 3, or NULL. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowedOpenOrderType COMMENT 'Allowed open order types. 0=default. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN UnitsQuantityType COMMENT 'How units/quantity are expressed. 0=default. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN TradeUnitType COMMENT 'Unit type for trading. 0=default. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN OrderFillBehaviorType COMMENT 'Order fill behavior. 0=default. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AmountFormula COMMENT 'Formula for position amount calculation. Indexed for lookups. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN Slippage COMMENT 'Allowed slippage. Sample 0, 3, 8. Trade.GetInstrumentSlippage, Trade.SetInstrumentSlippage. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN ExtendedMarginAllowed COMMENT '1=extended margin allowed, 0=standard only. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument ALTER COLUMN AllowedRateDiffPercentageUpside COMMENT 'Max rate diff on upside. Default 999 (effectively unlimited). (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
