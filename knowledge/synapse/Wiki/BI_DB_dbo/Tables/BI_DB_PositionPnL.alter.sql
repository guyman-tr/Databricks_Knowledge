-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_PositionPnL
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_PositionPnL'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN CID COMMENT 'Customer identifier for the position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN PositionID COMMENT 'Unique position key; Synapse distribution key. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.PositionID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN InstrumentID COMMENT 'Traded instrument. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.InstrumentID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN MirrorID COMMENT 'Copy-trading mirror link when applicable. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.MirrorID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Commission COMMENT 'Opening commission in dollars. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Commission)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN InitForexRate COMMENT 'Open rate; split-adjusted in SP when position spans a split. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.InitForexRate / split logic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN SpreadedPipBid COMMENT 'Bid with spread at open. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SpreadedPipBid)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN SpreadedPipAsk COMMENT 'Ask with spread at open. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SpreadedPipAsk)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN PositionPnL COMMENT 'Unrealized P&L in USD; from `PnLInDollars` (replaces legacy formula). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.PnLInDollars)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Price COMMENT 'Per-unit price-move expression × USD conversion factor from `#Pre_UnrealizedPnL` (bid/ask vs InitForexRate and instrument FX chain). (Tier 2 -- SP_PositionPnL, computed from #OpenPositions + Dim_Instrument + #Prices)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN HedgeServerID COMMENT 'Hedge server for the position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.HedgeServerID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Amount COMMENT 'Position amount in USD; rewound via `Dim_PositionChangeLog` when SL/partial-close edits after `@dt`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Amount / PositionChangeLog.PreviousAmount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN AmountInUnitsDecimal COMMENT 'Size in instrument units; split-adjusted and rewound from partial-close log when applicable. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.AmountInUnitsDecimal / split + PositionChangeLog)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN LimitRate COMMENT 'Take-profit rate. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.LimitRate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN StopRate COMMENT 'Stop-loss rate; rewound to `PreviousStopRate` when edited after `@dt`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.StopRate / PositionChangeLog)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN IsBuy COMMENT 'Long (1) vs short (0). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.IsBuy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Occurred COMMENT 'Position open timestamp (`OpenOccurred`). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.OpenOccurred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Date COMMENT 'Snapshot calendar date `@dt`. (Tier 3 -- SP_PositionPnL, parameter @dt)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN DateID COMMENT 'Snapshot date as YYYYMMDD; partition key. (Tier 3 -- SP_PositionPnL, CAST(CONVERT(CHAR(8),@dt,112) AS INT))';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN UpdateDate COMMENT 'Row load timestamp at insert (`GETDATE()`). (Tier 3 -- SP_PositionPnL, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (`ChangeTypeID = 13`) when applicable. (Tier 5 — Expert Review)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN NOP COMMENT 'Net open position in USD from units × pair rate × direction × conversion (see `#Pre_UnrealizedPnL`). (Tier 2 -- SP_PositionPnL, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN DailyPnL COMMENT 'Day-over-day change: `PositionPnL - prior day PositionPnL` (NULL until post-switch UPDATE). (Tier 3 -- SP_PositionPnL, UPDATE vs prior DateID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Leverage COMMENT 'Position leverage. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Leverage)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN RateBid COMMENT 'EOD bid from latest `Fact_CurrencyPriceWithSplit` row before `@ReportDate`, split-adjusted; uses `BidLastWithoutSpread` when discounted. (Tier 2 -- SP_PositionPnL, DWH_dbo.Fact_CurrencyPriceWithSplit + split)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN RateAsk COMMENT 'EOD ask from same price row, split-adjusted. (Tier 2 -- SP_PositionPnL, DWH_dbo.Fact_CurrencyPriceWithSplit + split)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN USD_CR COMMENT 'End-of-day conversion rate used with PnL context; from Dim_Position `CurrentConversionRate`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentConversionRate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN SettlementTypeID COMMENT 'Modern settlement type from Dim_Position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SettlementTypeID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN EstimateCloseFeeForCFD COMMENT 'Estimated close fee for CFD from production PnL inputs. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeForCFD)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN EstimateCloseFeeOnOpenByUnits COMMENT 'Estimated close fee per units-at-open path. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeOnOpenByUnits)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN EstimateCloseFeeOnOpen COMMENT 'Estimated close fee from open parameters. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeOnOpen)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_PnLInDollars COMMENT 'Official close-price P&L in dollars from Dim_Position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_PnLInDollars)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_CalculationRate COMMENT 'Rate used for close P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_CalculationRate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_ConversionRate COMMENT 'FX conversion at close for regulated P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_ConversionRate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_PriceType COMMENT 'Close price type indicator from upstream PnL. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_PriceType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN CurrentCalculationRate COMMENT 'Max-date calculation rate for last-bid style P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentCalculationRate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN CurrentConversionRate COMMENT 'Conversion rate paired with current calculation rate (same source family as USD_CR). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentConversionRate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_NOP COMMENT 'NOP using close rates: `AmountInUnitsDecimal * Close_CalculationRate * Close_ConversionRate`. (Tier 2 -- SP_PositionPnL, computed in #Pre_UnrealizedPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Current_NOP COMMENT 'NOP using current rates: `AmountInUnitsDecimal * CurrentCalculationRate * CurrentConversionRate`. (Tier 2 -- SP_PositionPnL, computed in #Pre_UnrealizedPnL)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Commission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN InitForexRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN SpreadedPipBid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN SpreadedPipAsk SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN PositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Price SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN AmountInUnitsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN LimitRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN StopRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN DailyPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN RateBid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN RateAsk SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN USD_CR SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN SettlementTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN EstimateCloseFeeForCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN EstimateCloseFeeOnOpenByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN EstimateCloseFeeOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_PnLInDollars SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_CalculationRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_ConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_PriceType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN CurrentCalculationRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN CurrentConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Close_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl ALTER COLUMN Current_NOP SET TAGS ('pii' = 'none');
