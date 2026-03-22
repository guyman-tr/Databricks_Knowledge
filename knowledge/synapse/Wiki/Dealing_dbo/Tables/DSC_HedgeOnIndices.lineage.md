# Column Lineage: Dealing_dbo.DSC_HedgeOnIndices

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.DSC_HedgeOnIndices` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `DWH_dbo.Dim_Position` (Synapse DWH) |
| **ETL SP** | `Dealing_dbo.SP_Dealing_DSC_HedgeOnIndices` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
DWH_dbo.Dim_Position ─────────────────────┐
DWH_dbo.Dim_Instrument ──────────────────┤
DWH_dbo.Dim_Customer ────────────────────┤──► SP_Dealing_DSC_HedgeOnIndices ──► DSC_HedgeOnIndices_H ──► DSC_HedgeOnIndices
DWH_dbo.Dim_GetSpreadedPriceCandle60Min ─┘     (hourly aggregation)              (daily aggregation)
```

No Generic Pipeline mapping — this is a DWH-computed analytics table, not a production mirror.

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
| DateID | — | — | ETL-computed | `CAST(FORMAT(Se, 'yyyyMMdd') AS INT)` from hourly timestamp bucketing | Date as integer YYYYMMDD |
| Date | — | — | ETL-computed | `CAST(Date AS DATE)` from DSC_HedgeOnIndices_H.Date | Daily date from hourly rollup |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | passthrough | Direct: Dim_Position.InstrumentID | Filtered to InstrumentID IN (27,28,29,32) — 4 major indices |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | join-enriched | From Dim_Instrument.InstrumentType via InstrumentID JOIN | Always 'Indices' for this table |
| Name | DWH_dbo.Dim_Instrument | Name | join-enriched | From Dim_Instrument.Name via InstrumentID JOIN | Instrument display name (SPX500/USD, NSDQ100/USD, etc.) |
| Zero | DWH_dbo.Dim_Position | NetProfit, Commission | ETL-computed | `SUM(ISNULL(realised,0) + ISNULL(unrealdiff,0))` per day/instrument. Realised = SUM(NetProfit) + SUM(Commission) from closed positions. Unrealdiff = delta in unrealized PnL between consecutive hours. | Net zero = realized + unrealized change |
| HC_ALL | DWH_dbo.Dim_Position | AmountInUnitsDecimal, SpreadOpen, SpreadClose | ETL-computed | `SUM(LotCountDecimal * SpreadOpen/2)` for opens + `SUM(LotCountDecimal * SpreadClose/2)` for closes, converted to USD via currency conversion. Daily sum of hourly HC_ALL values. | Hedge cost from spread at open/close |
| TheoreticalBoundaryCost | — | — | ETL-computed | `SUM(Zero) - SUM(SyntheticAccountPnL)` from DSC_HedgeOnIndices_H. Difference between actual zero and synthetic account PnL. | Theoretical cost of boundary hedging |
| SpreadLPBoundary | — | — | ETL-computed | `SUM(-boundariesvolume * @spread)` where @spread=0.00004125 and boundariesvolume = Conversion * ABS(units_delta) * BidLast * 0.8. Daily sum of hourly values. | LP boundary spread cost |
| UpdateDate | — | — | ETL-computed | `GETDATE()` at SP execution time | ETL load timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Join-enriched** | 2 |
| **ETL-computed** | 7 |
| **Total** | 10 |
