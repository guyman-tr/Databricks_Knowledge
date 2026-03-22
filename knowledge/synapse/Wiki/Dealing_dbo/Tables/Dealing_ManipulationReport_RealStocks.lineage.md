# Column Lineage: Dealing_dbo.Dealing_ManipulationReport_RealStocks

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_ManipulationReport_RealStocks` |
| **UC Target** | N/A — Dealing_dbo not yet in Unity Catalog |
| **Primary Source** | `DWH_dbo.Dim_Position` (Trade.PositionTbl, etoroDB-REAL) |
| **ETL SP** | `Dealing_dbo.SP_ManipulationReport_RealStocks` |
| **Secondary Sources** | `CopyFromLake.Rankings_StockInfo_DailyInstrumentInfo`, `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted`, `DWH_staging.etoro_Trade_InstrumentMetaData`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Regulation` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Production (Trade.PositionTbl, etoroDB-REAL)
    ↓ DWH ETL → DWH_dbo.Dim_Position
    ↓ ─────────────────────────────────────────────────────────
CopyFromLake.Rankings_StockInfo_DailyInstrumentInfo ← Lake (market data: MarketCap MetadataID=8735, DailyVolume MetadataID=8708)
DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted ← Price candle data (60-min intervals)
DWH_staging.etoro_Trade_InstrumentMetaData ← Exchange hours (ExchangeID groups)
    ↓
SP_ManipulationReport_RealStocks(@dd) — KPI computation (8+ manipulation signal patterns)
    ↓
Dealing_dbo.Dealing_ManipulationReport_RealStocks
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@dd` parameter | Weekdays only (DATEPART(dw) BETWEEN 2 AND 6) |
| KPI | — | — | ETL-computed | UNION ALL branch label (string literal per segment) | Values: First10Minutes, Last10Minutes, Flag2, Top20_Volume, Top20_Volume_LowMktCap, Top20_Volume_20Min, Top20_Volume_20Min_LowMktCap, AvgVolume |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | passthrough | GROUP BY key | Filtered to InstrumentTypeID IN (5,6), IsSettled=1 |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | passthrough | Direct join on InstrumentID | User-facing display name |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough | Direct join on InstrumentID | 'Stocks' or 'ETF' |
| Regulation | DWH_dbo.Dim_Regulation | Name | passthrough | Join via Fact_SnapshotCustomer → Dim_Regulation | RegulationID IN (1,2,4) only |
| RN | — | — | ETL-computed | `ROW_NUMBER() OVER (PARTITION BY Regulation, IsLowMktCap ORDER BY Volume DESC)` | Populated for Top20_Volume* KPIs; NULL for others |
| Volume | DWH_dbo.Dim_Position | Volume, VolumeOnClose | ETL-computed | `SUM(Volume + VolumeOnClose)` CAST AS BIGINT | Total USD client volume (opens + closes) |
| Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal | ETL-computed | `SUM(AmountInUnitsDecimal)` across opens and closes | Total shares traded (not USD) |
| Last30DaysAvgVolume | DWH_dbo.Dim_Position | Volume | ETL-computed | `SUM(Volume for trailing 30 working days) / 30` per InstrumentID | 30-day trailing baseline; computed in #AvgDailyKPIs temp table |
| ExchangeUnitsVolume | CopyFromLake.Rankings_StockInfo_DailyInstrumentInfo | Value (MetadataID=8708) | rename | `Value WHERE MetadataID = 8708` = exchange daily trading volume in shares | Cast to BIGINT; used for Units/ExchangeUnitsVolume ratio |
| MA_10Days | CopyFromLake.Rankings_StockInfo_DailyInstrumentInfo | Value (MetadataID=8708) | ETL-computed | `AVG(Value) OVER (PARTITION BY InstrumentID ORDER BY Occurred ROWS BETWEEN 9 PRECEDING AND CURRENT ROW)` | 10-day moving average of exchange daily volume |
| MaxToMinChange | DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | BidMax, BidMin | ETL-computed | `(MAX(BidMax) / MIN(BidMin)) - 1` across all 60-min candles for @dd | Decimal fraction; ≥0.20 = high volatility threshold for Flag2 |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL run timestamp; not a business field |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 9 |
| **Rename** | 1 |
| **Total** | 14 |
