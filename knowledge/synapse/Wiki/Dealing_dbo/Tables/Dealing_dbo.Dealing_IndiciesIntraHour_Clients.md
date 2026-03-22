# Dealing_dbo.Dealing_IndiciesIntraHour_Clients

## 1. Overview
Minute-by-minute client-side trading activity for index instruments (SPX500=27, DJ30=28, NSDQ100=32), capturing open positions, volumes, realized/unrealized P&L, and bid/ask prices at each minute of the trading day. Enables intraday analysis of client exposure and P&L dynamics.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (Date ASC) |
| **Row Count** | ~12.7M |
| **Date Range** | 2022-05-22 → present |
| **Grain** | One row per Date × Minute × InstrumentID × HedgeServerID |
| **Refresh** | Daily, via SP_IntraHourIndexReport |

## 2. Business Context
This table provides a minute-resolution view of how client positions evolve throughout the trading day for the three main index instruments. It shows volumes of new buy/sell positions, total open position value (long/short), and unrealized P&L at the start and end of each minute. Combined with the companion table `Dealing_IndiciesIntraHour_Etoro`, it enables client-vs-LP hedging analysis at minute granularity. Uses price-dragging (forward-fill) to smooth gaps in price data.

**Author**: Graham Ellinson (created 2022-05-29). SR-249626 (2024-04-30) by Gal added HedgeServerID and removed hedge server filters.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Trading date | T2 | SP_IntraHourIndexReport: `CONVERT(DATE, o.fromMinute)` |
| Minute_Start | datetime | Yes | Start of the 1-minute interval | T2 | SP_IntraHourIndexReport: `o.fromMinute` |
| Minute_End | datetime | Yes | End of the 1-minute interval (= Minute_Start + 1 min) | T2 | SP_IntraHourIndexReport: `o.toMinute` |
| InstrumentID | int | Yes | Index instrument (27=SPX500, 28=DJ30, 32=NSDQ100) | T2 | SP_IntraHourIndexReport: from #IniIns hardcoded set |
| VolumeBuy | bigint | Yes | Count of new long positions opened/short positions closed in this minute | T2 | SP_IntraHourIndexReport: from `#Volume` aggregation |
| VolumeSell | bigint | Yes | Count of new short positions opened/long positions closed in this minute | T2 | SP_IntraHourIndexReport |
| OP_Buy_Units | float | Yes | Total open long position size in units at minute start | T2 | SP_IntraHourIndexReport: `SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal)` |
| OP_Buy | float | Yes | Total open long position value in USD at minute start. Formula: `SUM(AmountInUnitsDecimal * FirstBid * ConversionFirst)` for IsBuy=1 | T2 | SP_IntraHourIndexReport |
| OP_Sell_Units | float | Yes | Total open short position size in units at minute start | T2 | SP_IntraHourIndexReport |
| OP_Sell | float | Yes | Total open short position value in USD at minute start. Formula: `SUM(AmountInUnitsDecimal * FirstAsk * ConversionFirst)` for IsBuy=0 | T2 | SP_IntraHourIndexReport |
| UnrealizedStart | float | Yes | Unrealized P&L across all positions at minute start. Formula: `SUM(AmountInUnitsDecimal * ConversionFirst * (IsBuy?FirstBid-InitForexRate : InitForexRate-FirstAsk) + FullCommissionByUnits)` — excludes newly opened positions in this minute | T2 | SP_IntraHourIndexReport |
| UnrealizedEnd | float | Yes | Unrealized P&L at minute end. Uses next minute's UnrealizedStart value. Formula: `o2.UnrealizedStart` from self-join on `o.toMinute = o2.fromMinute` | T2 | SP_IntraHourIndexReport |
| Realized | float | Yes | Realized P&L from positions closed in this minute. Formula: `SUM(NetProfit + FullCommissionOnClose)` for positions with CloseDateID=@DateInt | T2 | SP_IntraHourIndexReport |
| Bid | float | Yes | Bid price at minute start (forward-filled from PriceLog). Formula: `pf.FirstBid` | T2 | SP_IntraHourIndexReport |
| Ask | float | Yes | Ask price at minute start (forward-filled) | T2 | SP_IntraHourIndexReport: `pf.FirstAsk` |
| UpdateDate | datetime | Yes | Row write timestamp | T2 | SP_IntraHourIndexReport: `GETDATE()` |
| HedgeServerID | int | Yes | Hedge server identifier. Added SR-249626 (2024-04-30) | T2 | SP_IntraHourIndexReport: from Dim_Position |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| DWH_dbo.Dim_Position | Client position lifecycle | InstrumentID, OpenDateID/CloseDateID range, CID |
| DWH_dbo.Dim_Customer | IsValidCustomer=1 filter | RealCID |
| CopyFromLake.PriceLog_History_CurrencyPrice | Minute-resolution raw prices | InstrumentID, Occurred (minute-truncated) |
| Dealing_staging.etoro_History_PortfolioConversionConfigurations | Hedge instrument mapping | InstrumentID → InstrumentIDToHedge |
| Dealing_dbo.Dealing_IndiciesIntraHour_Etoro | Companion LP-side table | Same SP, same instruments, same time grain |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_IntraHourIndexReport` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | DELETE + INSERT for @Date |
| **Key Logic** | 1) Define 3 index instruments (27,28,32). 2) Resolve hedge instruments via PortfolioConversionConfigurations. 3) Generate minute grid for full day. 4) Pull raw prices from PriceLog_History_CurrencyPrice, dedup to 1 per minute. 5) Forward-fill (drag) prices for missing minutes using OUTER APPLY. 6) Compute FirstBid/FirstAsk via LAG(). 7) Join Dim_Position for all open positions at each minute. 8) Aggregate volumes, OP, unrealized P&L. 9) Calculate realized P&L from closed positions. 10) Self-join for UnrealizedEnd. |
| **Dependencies** | Calls `CopyFromLake.SP_Copy_Temporary_Data` for PriceLog_History_CurrencyPrice |

## 6. Data Lifecycle
- **Retention**: No automated cleanup
- **Volume**: ~1440 minutes × 3 instruments × N hedge servers per day

## 7. Known Gaps
- Only covers 3 index instruments — other asset classes have separate IntraHour tables
- Forward-fill extends up to 5 days back to cover weekends
- Price source (PriceLog_History_CurrencyPrice) must be pre-loaded via CopyFromLake

## 8. Quality Score
**7.5/10** — Complex minute-resolution analysis with well-traced formulas. Forward-fill logic is sophisticated. Companion table relationship with Etoro side is clear.
