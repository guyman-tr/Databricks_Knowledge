-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Boundary_Cost
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost SET TBLPROPERTIES (
    'comment' = '`Dealing_Boundary_Cost` stores **per-minute snapshots of Net Open Position (NOP) and hedge boundary metrics** for every tradable instrument × HedgeServer × IsSettled combination, computed for a single trading day. Each row represents a one-minute window for a specific instrument on a specific HedgeServer, tracking how much client exposure (buy/sell units) entered or exited the market in that minute, the running cumulative NOP, current market prices, and whether the NOP is within the configured hedge boundary limits. The Dealing team uses this table to monitor **intraday hedge risk**: as NOP builds up throughout the trading day, it can breach the `LowerBoundary` (net sell exposure limit) or `UpperBoundary` (net buy exposure limit) configured for each instrument on each HedgeServer. This table is the data source for boundary-cost analysis, showing both the realized volumes and the price impact of client trading activity in real time. The table is populated once per trading day by `SP_Boundary_Cost(@Date)`. The '
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost SET TAGS (
    'domain' = 'finance',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN Date COMMENT 'The reporting date for which this set of minute snapshots was computed. All rows in a given batch share the same Date value. Set to `@Date` parameter in SP_Boundary_Cost. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN DateID COMMENT 'Integer representation of Date in YYYYMMDD format (e.g., 20240317). Used as the clustered index key for efficient date-range filtering. Computed as `CONVERT(NVARCHAR, @Date, 112)`. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN FromDate COMMENT 'Start of the one-minute time window for this row. Truncated to the minute boundary. Together with ToDate, defines the 1-minute bucket this row represents. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN ToDate COMMENT 'End of the one-minute time window (FromDate + 1 minute). Used as the join key when aligning volume data to the minute spine. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN InstrumentID COMMENT 'Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Referenced by virtually every trading fact table. FK to DWH_dbo.Dim_Instrument. (Tier 1 - DWH_dbo.Dim_Instrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN InstrumentName COMMENT 'User-facing instrument display name from `Dim_Instrument.InstrumentDisplayName`. More descriptive than the internal Name (e.g., ''Apple Inc.'' vs ''Apple''). NULL for instruments without metadata entries. (Tier 2 - SP_Boundary_Cost, via Dim_Instrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN InstrumentType COMMENT 'Text label for the instrument category: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. DWH-computed via CASE on InstrumentTypeID. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 1 - DWH_dbo.Dim_Instrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN StdSpreadPercent COMMENT 'Standard deviation of the bid-ask spread as a percentage of mid-price, averaged over the trailing quarterly period (2 months from start of current month). Computed from historical position open/close prices. Higher values indicate instruments with more volatile spreads - relevant for boundary risk estimation. NULL when insufficient price history exists. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LastBid COMMENT 'Last bid price observed in this minute window, sourced from the PriceLog lake feed (`PriceLog_History_CurrencyPrice_Active_tmp`). The most recent bid price before or at the ToDate boundary. NULL if no price tick arrived in this minute. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LastAsk COMMENT 'Last ask price observed in this minute window from the PriceLog lake feed. NULL if no price tick arrived. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN Mid COMMENT 'Mid-price computed as `(LastAsk + LastBid) / 2`. Used in spread percentage calculation. NULL when either bid or ask is NULL. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LastBidSpreaded COMMENT 'Bid price with eToro''s spread markup applied (spreaded = bid adjusted for client-facing spread). Sourced from `PriceLog_History_CurrencyPrice_Active_tmp.BidSpreaded`. This is the price a selling client receives. NULL if no price tick. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LastAskSpreaded COMMENT 'Ask price with eToro''s spread markup applied. Sourced from `PriceLog_History_CurrencyPrice_Active_tmp.AskSpreaded`. This is the price a buying client pays. NULL if no price tick. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN UnitsBuy COMMENT 'Net units of new long (buy) positions opened by clients in this minute window, summed across all valid customers active on `@Date`. Derived from `Dim_Position.AmountInUnitsDecimal` for positions where `IsBuy=1`. Zero when no buy activity in this minute. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN UnitsSell COMMENT 'Net units of new short (sell) positions opened (or long positions closed, which creates reverse exposure) in this minute window. Derived from `Dim_Position.AmountInUnitsDecimal` for positions where `IsBuy=0`. Zero when no sell activity. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN WAVG_BuyPrice COMMENT 'Volume-weighted average forex rate for buy positions opened in this minute. Computed as `SUM(units × InitForexRate) / SUM(units)` for `IsBuy=1`. Represents the effective price at which the net buy exposure was established. Zero when UnitsBuy=0. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN WAVG_SellPrice COMMENT 'Volume-weighted average forex rate for sell positions opened (or close events) in this minute. Computed as `SUM(units × EndForexRate) / SUM(units)` for `IsBuy=0`. Zero when UnitsSell=0. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN NOP COMMENT 'Cumulative Net Open Position in units at the end of this minute. Computed as: `previous_day_NOP (from BI_DB_PositionPnL) + SUM(UnitsBuy - UnitsSell) OVER (PARTITION BY InstrumentID, HedgeServerID, IsSettled ORDER BY ToDate)`. Positive NOP = net long client exposure (eToro is net short, may need to hedge); negative NOP = net short client exposure. This is the key risk metric compared against LowerBoundary / UpperBoundary. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was inserted by SP_Boundary_Cost (`GETDATE()`). Not a business timestamp. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN VolumeBuy COMMENT 'Total USD volume from buy position opens in this minute. Computed as `SUM(AmountInUnitsDecimal × InitForexRate)` for `IsBuy=1` × FX conversion. Represents the USD value of buy flow. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN VolumeSell COMMENT 'Total USD volume from sell position opens (or close events) in this minute. Computed as `SUM(VolumeOnClose)` for `IsBuy=0`. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN VariableSpread COMMENT 'Total variable spread cost in USD for all positions opened/closed in this minute. Computed as `SUM(units × (Ask - Bid) × FX_conversion_rate)`. This is the spread revenue/cost of the instrument in this window. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LowerBoundary COMMENT 'Lower NOP threshold (negative value) for this instrument×HedgeServer combination. Sourced from `dbo.etoro_Hedge_InstrumentBoundaries` as `(-1) × (CloseThresholdPercentage × OpenThresholdUSD) / 100`. When NOP drops below LowerBoundary, the position indicates excessive short client exposure. Default -50,000 for Stocks/ETFs when no boundary configured. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN UpperBoundary COMMENT 'Upper NOP threshold (positive value) for this instrument×HedgeServer. Sourced from `dbo.etoro_Hedge_InstrumentBoundaries.OpenThresholdUSD`. When NOP exceeds UpperBoundary, the instrument''s long client exposure may require hedging. Default 500,000 for Stocks/ETFs when no boundary configured. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN HedgeRiskLimit COMMENT 'Maximum acceptable hedge risk in USD for this instrument×HedgeServer. Sourced from `dbo.etoro_Hedge_InstrumentBoundaries.HedgeRiskLimitUSD`. Used to cap the total risk exposure managed by the dealing desk. Default 250,000 for Stocks/ETFs when no boundary configured. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN FX_Bid COMMENT 'FX conversion rate to USD for this instrument''s sell currency. Sourced from `Fact_CurrencyPriceWithSplit` for the reporting date. For USD-denominated instruments (SellCurrencyID=1), FX_Bid=1.0. For EUR instruments, FX_Bid = 1/EUR_Bid. Used to normalize NOP and volume metrics to USD equivalents. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Used for boundary default logic (Stocks/ETFs get defaults when no boundary configured). (Tier 1 - DWH_dbo.Dim_Instrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN HedgeServerID COMMENT 'Identifier for the hedge server holding these positions. Positions can be distributed across multiple hedge servers; this dimension tracks per-HS NOP separately. HS assignment at `@Date` is resolved via `Dim_PositionHedgeServerChangeLog_Snapshot` (handles same-day HS migrations). NULL for rows in the UNION ALL that only have NOP carry-forward data. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 - Expert Review)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN PriceRatio COMMENT 'Stock split-adjusted price ratio sourced from `DWH_dbo.Dim_HistorySplitRatio`. Applied only to the first minute of the day (ROW_NUMBER()=1 per instrument×HS×IsSettled) when a split occurred on `@Date`. Used to adjust NOP calculations when a stock split changes the unit count. 1.0 when no split occurred or for non-split instruments. (Tier 2 - SP_Boundary_Cost)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN HS_Moved_Units COMMENT 'Net units transferred between HedgeServers during `@Date` for this instrument×HS×IsSettled. Tracked via `Dim_PositionChangeLog` ChangeTypeID=12 (HedgeServer change events). Positive values indicate units arriving at this HS; negative values indicate units leaving. Used to reconcile NOP changes that are not due to new client trades but due to HS rebalancing. Zero when no HS moves occurred. (Tier 2 - SP_Boundary_Cost)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN FromDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN ToDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN StdSpreadPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LastBid SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LastAsk SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN Mid SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LastBidSpreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LastAskSpreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN UnitsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN UnitsSell SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN WAVG_BuyPrice SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN WAVG_SellPrice SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN VolumeBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN VolumeSell SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN VariableSpread SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN LowerBoundary SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN UpperBoundary SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN HedgeRiskLimit SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN FX_Bid SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN PriceRatio SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost ALTER COLUMN HS_Moved_Units SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 13:57:27 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 64/64 succeeded
-- ====================
