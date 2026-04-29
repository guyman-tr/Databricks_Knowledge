# Column Lineage: Dealing_dbo.Dealing_Boundary_Cost

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Boundary_Cost` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | Multi-source (no single production table) |
| **ETL SP** | `Dealing_dbo.SP_Boundary_Cost` |
| **Secondary Sources** | `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Instrument`, `BI_DB_dbo.BI_DB_PositionPnL`, `BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp`, `dbo.etoro_Hedge_InstrumentBoundaries`, `DWH_dbo.Fact_CurrencyPriceWithSplit`, `DWH_dbo.Dim_HistorySplitRatio`, `DWH_dbo.Dim_PositionChangeLog` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Production (Trade.PositionTbl, Trade.Instrument, PriceLog feed)
    ↓ Generic Pipeline → Data Lake (positions, prices)
    ↓ DWH ETL → DWH_dbo.Dim_Position, DWH_dbo.Dim_Instrument
    ↓ BI_DB ETL → BI_DB_dbo.BI_DB_PositionPnL
    ↓ Lake COPY INTO → BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp
    ↓ SP_Boundary_Cost(@Date) — multi-source JOIN + window aggregation
    ↓ Dealing_dbo.Dealing_Boundary_Cost
```

**No direct Generic Pipeline mapping** — this table is an analytical computation over multiple DWH sources.

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **cast/convert** | Type conversion only. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **join-enriched** | Joined from a secondary source table during ETL. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@Date` parameter | SP input parameter |
| DateID | — | — | ETL-computed | `CONVERT(NVARCHAR, @Date, 112)` | YYYYMMDD integer |
| FromDate | #Minutes spine | — | ETL-computed | `DATEADD(MINUTE, n-1, CAST(@Date AS DATETIME))` | 1-minute bucket start |
| ToDate | #Minutes spine | — | ETL-computed | `DATEADD(MINUTE, n, CAST(@Date AS DATETIME))` | 1-minute bucket end |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | passthrough | Direct: Dim_Instrument.InstrumentID | PK |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | rename | Direct: Dim_Instrument.InstrumentDisplayName | Display name |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough | Direct: Dim_Instrument.InstrumentType | Type string |
| StdSpreadPercent | DWH_dbo.Dim_Position | InitForex_Bid, InitForex_Ask | ETL-computed | `AVG(STDEV((Ask-Bid)/Mid)) OVER (GROUP BY InstrumentID, Month, Year)` — quarterly |  |
| LastBid | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | Bid | rename | Last bid per minute window | Lake price feed |
| LastAsk | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | Ask | rename | Last ask per minute window | Lake price feed |
| Mid | — | LastBid, LastAsk | ETL-computed | `(LastAsk + LastBid) / 2` | |
| LastBidSpreaded | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | BidSpreaded | passthrough | Direct: PriceLog.BidSpreaded | Spreaded bid |
| LastAskSpreaded | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | AskSpreaded | passthrough | Direct: PriceLog.AskSpreaded | Spreaded ask |
| UnitsBuy | DWH_dbo.Dim_Position | AmountInUnitsDecimal | ETL-computed | `SUM(AmountInUnitsDecimal) WHERE IsBuy=1 AND OpenDateID=@DateID` by minute | |
| UnitsSell | DWH_dbo.Dim_Position | AmountInUnitsDecimal | ETL-computed | `SUM(AmountInUnitsDecimal) WHERE IsBuy=0 AND (OpenDateID=@DateID OR CloseDateID=@DateID)` by minute | |
| WAVG_BuyPrice | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate | ETL-computed | `SUM(units × InitForexRate) / SUM(units) WHERE IsBuy=1` | |
| WAVG_SellPrice | DWH_dbo.Dim_Position | AmountInUnitsDecimal, EndForexRate | ETL-computed | `SUM(units × EndForexRate) / SUM(units) WHERE IsBuy=0` | |
| NOP | BI_DB_dbo.BI_DB_PositionPnL, DWH_dbo.Dim_Position | AmountInUnitsDecimal | ETL-computed | `prev_day_NOP + SUM(UnitsBuy - UnitsSell) OVER (PARTITION BY InstrumentID, HedgeServerID, IsSettled ORDER BY ToDate)` | Cumulative window |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL metadata |
| VolumeBuy | DWH_dbo.Dim_Position | Volume | ETL-computed | `SUM(Volume) WHERE IsBuy=1 AND OpenDateID=@DateID` by minute | USD volume |
| VolumeSell | DWH_dbo.Dim_Position | VolumeOnClose | ETL-computed | `SUM(VolumeOnClose) WHERE IsBuy=0 AND CloseDateID=@DateID` by minute | |
| VariableSpread | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForex_Ask, InitForex_Bid | ETL-computed | `SUM(units × (Ask - Bid) × FX_conversion)` | Spread cost |
| LowerBoundary | dbo.etoro_Hedge_InstrumentBoundaries | CloseThresholdPercentage, OpenThresholdUSD | ETL-computed | `(-1) × (CloseThresholdPercentage × OpenThresholdUSD) / 100`; default -50000 for TypeID 5,6 | |
| UpperBoundary | dbo.etoro_Hedge_InstrumentBoundaries | OpenThresholdUSD | passthrough | Direct: etoro_Hedge_InstrumentBoundaries.OpenThresholdUSD; default 500000 for TypeID 5,6 | |
| HedgeRiskLimit | dbo.etoro_Hedge_InstrumentBoundaries | HedgeRiskLimitUSD | passthrough | Direct: etoro_Hedge_InstrumentBoundaries.HedgeRiskLimitUSD; default 250000 for TypeID 5,6 | |
| FX_Bid | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | ETL-computed | `IF SellCurrencyID=1 THEN 1 ELIF BuyCurrencyID=1 THEN 1/r.Bid ELSE COALESCE(1/r1.Bid, r2.Bid, 1)` | FX triangulation |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | passthrough | Direct: Dim_Instrument.InstrumentTypeID | |
| HedgeServerID | DWH_dbo.Dim_Position, Dim_PositionHedgeServerChangeLog_Snapshot | HedgeServerID | ETL-computed | `ISNULL(changelog.HedgeServerID, position.HedgeServerID)` — prefers snapshot HS | HS at @Date |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | passthrough | Direct: Dim_Position.IsSettled | 1=settled, 0=CFD |
| PriceRatio | DWH_dbo.Dim_HistorySplitRatio | — | ETL-computed | `ISNULL(sr.PriceRatio, 1)` applied only to first minute per instrument×HS×IsSettled | Split adjustment |
| HS_Moved_Units | DWH_dbo.Dim_PositionChangeLog | PreviousAmountInUnits, AmountInUnits | ETL-computed | Units moved between HedgeServers via ChangeTypeID=12 events; reconstructed from ChangeLog history | |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 6 |
| **Rename** | 3 |
| **ETL-computed** | 22 |
| **Total** | 31 |
