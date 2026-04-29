# Column Lineage: Dealing_dbo.Dealing_Boundary_Cost

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Boundary_Cost` |
| **UC Target** | N/A — Dealing_dbo not in Unity Catalog |
| **Primary Source** | Multi-source analytical computation (no single production table) |
| **ETL SP** | `Dealing_dbo.SP_Boundary_Cost` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Position`, `BI_DB_dbo.BI_DB_PositionPnL`, `BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp`, `dbo.etoro_Hedge_InstrumentBoundaries`, `DWH_dbo.Fact_CurrencyPriceWithSplit`, `DWH_dbo.Dim_HistorySplitRatio`, `DWH_dbo.Dim_PositionChangeLog`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Range`, `DWH_dbo.Dim_Date`, `DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot`, `DWH_dbo.etoro_Trade_PositionsHedgeServerChangeLog` |
| **Generated** | 2026-04-28 |

## Source Objects

| # | Source Object | Schema | Role | Wiki Available |
|---|--------------|--------|------|----------------|
| 1 | Dim_Instrument | DWH_dbo | Tradable instrument list (filtered: Tradable=1, VisibleInternallyOnly=0, specific TypeIDs) | YES |
| 2 | Dim_Position | DWH_dbo | Position data (open/close rates, units, volumes, IsSettled, HedgeServerID) | YES |
| 3 | BI_DB_PositionPnL | BI_DB_dbo | Previous-day NOP aggregation by instrument/HS/IsSettled | YES |
| 4 | PriceLog_History_CurrencyPrice_Active_tmp | BI_DB_staging | Intraday raw price feed (COPY INTO from Data Lake parquet) | NO |
| 5 | etoro_Hedge_InstrumentBoundaries | dbo | Instrument boundary thresholds per hedge server | NO |
| 6 | Fact_CurrencyPriceWithSplit | DWH_dbo | End-of-day bid/ask for FX rate triangulation | YES |
| 7 | Dim_HistorySplitRatio | DWH_dbo | Stock split price ratio for first-minute adjustment | YES |
| 8 | Dim_PositionChangeLog | DWH_dbo | Partial close unit tracking (ChangeTypeID=12) for HS movement calculations | YES |
| 9 | Fact_SnapshotCustomer | DWH_dbo | Valid customer filter (IsValidCustomer=1) for current and previous day | YES |
| 10 | Dim_Range | DWH_dbo | DateRangeID decode for Fact_SnapshotCustomer join | YES |
| 11 | Dim_Date | DWH_dbo | Date dimension for minute spine generation and customer range join | NO (unresolved) |
| 12 | Dim_PositionHedgeServerChangeLog_Snapshot | DWH_dbo | SCD2 hedge server assignment per position at @Date | YES |
| 13 | etoro_Trade_PositionsHedgeServerChangeLog | DWH_dbo | Intraday hedge server movement events on @Date | NO (staging) |

## Lineage Chain

```
Production (Trade.Instrument, Trade.PositionTbl, PriceLog feed, Hedge.InstrumentBoundaries)
    ↓ Generic Pipeline → Data Lake (positions, prices, instruments)
    ↓ DWH ETL → DWH_dbo.Dim_Instrument, DWH_dbo.Dim_Position, DWH_dbo.Fact_CurrencyPriceWithSplit
    ↓ BI_DB ETL → BI_DB_dbo.BI_DB_PositionPnL (previous-day NOP)
    ↓ Lake COPY INTO → BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp (intraday prices)
    ↓ SP_Boundary_Cost(@Date) — multi-source JOIN + minute-level aggregation + NOP window
    ↓ Dealing_dbo.Dealing_Boundary_Cost (DELETE @Date + INSERT)
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| Date | — | — | ETL-computed | `@Date` SP parameter |
| DateID | — | — | ETL-computed | `CONVERT(NVARCHAR, @Date, 112)` |
| FromDate | Dim_Date (cross join) | — | ETL-computed | Minute bucket start: `DATEADD(MINUTE, n-1, @Date)` |
| ToDate | Dim_Date (cross join) | — | ETL-computed | Minute bucket end: `DATEADD(MINUTE, n, @Date)` |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | passthrough | Via #Ins → #FinalPrices |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | rename | Dim_Instrument.InstrumentDisplayName AS InstrumentName |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough | Dim_Instrument.InstrumentType |
| StdSpreadPercent | DWH_dbo.Dim_Position | InitForex_Bid, InitForex_Ask, EndForex_Bid, EndForex_Ask | ETL-computed | `AVG(STDEV((Ask-Bid)/Mid))` over monthly buckets across 3-month lookback |
| LastBid | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | Bid | rename | Last bid per minute (ROW_NUMBER by Occurred DESC, rn=1) |
| LastAsk | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | Ask | rename | Last ask per minute |
| Mid | — | LastBid, LastAsk | ETL-computed | `(LastAsk + LastBid) / 2` |
| LastBidSpreaded | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | BidSpreaded | rename | Last spreaded bid per minute |
| LastAskSpreaded | BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp | AskSpreaded | rename | Last spreaded ask per minute |
| UnitsBuy | DWH_dbo.Dim_Position | AmountInUnitsDecimal | ETL-computed | `SUM(AmountInUnitsDecimal WHERE IsBuy=1)` by minute; open = open-day units, close = close-day units (direction flipped for closes) |
| UnitsSell | DWH_dbo.Dim_Position | AmountInUnitsDecimal | ETL-computed | `SUM(AmountInUnitsDecimal WHERE IsBuy=0)` by minute; direction flipped for closes |
| WAVG_BuyPrice | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate/EndForexRate | ETL-computed | `SUM(units*rate)/SUM(units) WHERE IsBuy=1` |
| WAVG_SellPrice | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate/EndForexRate | ETL-computed | `SUM(units*rate)/SUM(units) WHERE IsBuy=0` |
| NOP | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Position | Units (prev day) + UnitsBuy - UnitsSell | ETL-computed | `prev_day_NOP + SUM(UnitsBuy - UnitsSell) OVER (PARTITION BY InstrumentID, HedgeServerID, IsSettled ORDER BY ToDate)` |
| UpdateDate | — | — | ETL-computed | `GETDATE()` |
| VolumeBuy | DWH_dbo.Dim_Position | Volume, VolumeOnClose | ETL-computed | `SUM(Volume WHERE IsBuy=1)` for opens; `SUM(VolumeOnClose WHERE IsBuy=0)` for closes |
| VolumeSell | DWH_dbo.Dim_Position | Volume, VolumeOnClose | ETL-computed | `SUM(Volume WHERE IsBuy=0)` for opens; `SUM(VolumeOnClose WHERE IsBuy=1)` for closes |
| VariableSpread | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForex_Ask/Bid, InitForex_USDConversionRate | ETL-computed | `SUM(units * (Ask - Bid) * USDConversionRate)` per minute |
| LowerBoundary | dbo.etoro_Hedge_InstrumentBoundaries | CloseThresholdPercentage, OpenThresholdUSD | ETL-computed | `(-1)*(CloseThresholdPercentage*OpenThresholdUSD)/100`; default -50000 for InstrumentTypeID IN (5,6) |
| UpperBoundary | dbo.etoro_Hedge_InstrumentBoundaries | OpenThresholdUSD | passthrough | Direct; default 500000 for InstrumentTypeID IN (5,6) |
| HedgeRiskLimit | dbo.etoro_Hedge_InstrumentBoundaries | HedgeRiskLimitUSD | rename | Direct; default 250000 for InstrumentTypeID IN (5,6) |
| FX_Bid | DWH_dbo.Fact_CurrencyPriceWithSplit + DWH_dbo.Dim_Instrument | Bid, Ask, BuyCurrencyID, SellCurrencyID | ETL-computed | FX triangulation: if SellCurrencyID=1→1; if BuyCurrencyID=1→1/Bid; else cross-rate via COALESCE(1/r1.Bid, r2.Bid, 1) |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | passthrough | Via #Ins → #FinalPrices |
| HedgeServerID | DWH_dbo.Dim_Position + DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot | HedgeServerID | ETL-computed | `ISNULL(snapshot.HedgeServerID, position.HedgeServerID)` — prefers HS snapshot for @Date |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | passthrough | 1=real asset, 0=CFD |
| PriceRatio | DWH_dbo.Dim_HistorySplitRatio | PriceRatio | ETL-computed | `ISNULL(sr.PriceRatio, 1)` where MaxDate=@DateID; applied only to first minute per instrument/HS/IsSettled partition |
| HS_Moved_Units | DWH_dbo.etoro_Trade_PositionsHedgeServerChangeLog + DWH_dbo.Dim_PositionChangeLog | NetUnits, PreviousAmountInUnits, AmountInUnits | ETL-computed | Net units moved between hedge servers; reconstructed from HS change events + partial-close unit history |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 5 (InstrumentID, InstrumentType, InstrumentTypeID, UpperBoundary, IsSettled) |
| **Rename** | 5 (InstrumentName, LastBid, LastAsk, LastBidSpreaded, LastAskSpreaded, HedgeRiskLimit) |
| **ETL-computed** | 21 |
| **Total** | 31 |
