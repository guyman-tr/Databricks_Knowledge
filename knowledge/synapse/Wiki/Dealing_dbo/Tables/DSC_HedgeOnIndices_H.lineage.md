# Column Lineage: Dealing_dbo.DSC_HedgeOnIndices_H

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.DSC_HedgeOnIndices_H` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `DWH_dbo.Dim_Position` (Synapse DWH) |
| **ETL SP** | `Dealing_dbo.SP_Dealing_DSC_HedgeOnIndices` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
DWH_dbo.Dim_Position ─────────────────────┐
DWH_dbo.Dim_Instrument ──────────────────┤──► SP_Dealing_DSC_HedgeOnIndices ──► DSC_HedgeOnIndices_H
DWH_dbo.Dim_Customer ────────────────────┤     (hourly position aggregation)
DWH_dbo.Dim_GetSpreadedPriceCandle60Min ─┘
```

No Generic Pipeline mapping — this is a DWH-computed analytics table.

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| DateID | — | — | ETL-computed | `CAST(FORMAT(Se, 'yyyyMMdd') AS INT)` from hourly timestamp | YYYYMMDD integer |
| Date | — | — | ETL-computed | Hourly bucket datetime `Se` from WHILE loop | Hourly interval start time |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | passthrough | Direct: Dim_Position.InstrumentID | Filtered to IN (27,28,29,32) |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | join-enriched | From Dim_Instrument via InstrumentID JOIN | Always 'Indices' |
| Name | DWH_dbo.Dim_Instrument | Name | join-enriched | From Dim_Instrument via InstrumentID JOIN | Instrument display name |
| Unreals | — | — | ETL-computed | Unrealized PnL at start of hour. Computed as `-units * ConversionRate * (InitForexRate - AskLast/BidLast) * MULTIPLIER` for each position group | Start-of-hour unrealized |
| Unreale | — | — | ETL-computed | Unrealized PnL at end of hour (same formula, next hour's prices) | End-of-hour unrealized |
| Realised | DWH_dbo.Dim_Position | NetProfit, Commission | ETL-computed | `ISNULL(SUM(NetProfit), 0) + ISNULL(SUM(Commission), 0)` from positions closed during this hour | Realized P&L from closes |
| AskLast | DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | AskLast | passthrough | Direct: Dim_GetSpreadedPriceCandle60MinSplitted.AskLast for end-of-hour | Hourly ask price |
| BidLast | DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | BidLast | passthrough | Direct: same source, BidLast for end-of-hour | Hourly bid price |
| units | — | — | ETL-computed | `SUM(IsBuy * LotCount + (IsBuy-1) * LotCount)` for positions open during this hour. Net units = long - short. | Net position units |
| Spread | DWH_dbo.Dim_Position | SpreadClose | ETL-computed | `AVG(SpreadClose)` from positions closed during this hour | Average close spread |
| Commission | DWH_dbo.Dim_Position | FullCommissionOnClose | ETL-computed | `ISNULL(SUM(Commission), 0)` from closed positions | Total commission |
| Zero | — | — | ETL-computed | `ISNULL(realised, 0) + ISNULL(unrealdiff, 0)` where unrealdiff = Unreale - Unreals | Net P&L zero |
| SyntheticAccountPnL | — | — | ETL-computed | `(BidLast_delta * units * 0.8) * ConversionRate - boundariesvolume * 0.00004125` | Synthetic hedge PnL |
| HC_ALL | — | — | ETL-computed | `SUM(LotCount * Spread/2)` at opens + closes, converted to USD | Hedge cost from spread |
| SpreadLPBoundary | — | — | ETL-computed | `-boundariesvolume * 0.00004125` where boundariesvolume = Conversion * ABS(units_delta) * BidLast * 0.8 | LP boundary cost |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL load timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **Join-enriched** | 2 |
| **ETL-computed** | 12 |
| **Total** | 17 |
