# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_PnL

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_PnL` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `BI_DB_dbo.Function_PnL_Single_Day` (TVF) |
| **ETL SP** | `SP_DDR_Fact_PnL` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument` |
| **Generated** | 2026-03-26 |

## Lineage Chain

```
BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument
  + BI_DB_dbo.BI_DB_CopyFund_Positions + BI_DB_dbo.Function_Instrument_Snapshot_Enriched
  |-- Function_PnL_Single_Day(@dateID) ---|
  v
[position-level PnL rows]
  |-- SP_DDR_Fact_PnL: JOIN Dim_Instrument, GROUP BY, SUM/COUNT ---|
  v
BI_DB_dbo.BI_DB_DDR_Fact_PnL (aggregated CID × InstrumentType × flags)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from function output |
| **rename** | Same value, different column name |
| **ETL-computed** | Derived/calculated by SP logic |
| **join-enriched** | Joined from secondary source during ETL |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| DateID | Function_PnL_Single_Day | DateID | passthrough | Direct: frfc.DateID | GROUP BY key |
| Date | — | — | ETL-computed | `@date` parameter (DATE cast of DateID) | SP parameter |
| RealCID | Function_PnL_Single_Day | CID | rename | Direct: frfc.CID | GROUP BY key; renamed CID→RealCID |
| InstrumentTypeID | Dim_Instrument | InstrumentTypeID | join-enriched | `di.InstrumentTypeID` via `frfc.InstrumentID = di.InstrumentID` | GROUP BY key |
| IsCopy | Function_PnL_Single_Day | MirrorID | ETL-computed | `CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END` | GROUP BY key |
| IsSettled | Function_PnL_Single_Day | IsSettled | passthrough | Direct: frfc.IsSettled | GROUP BY key |
| UnrealizedPnLChange | Function_PnL_Single_Day | UnrealizedPnLChange | ETL-computed | `SUM(frfc.UnrealizedPnLChange)` | Aggregated per group |
| NetProfit | Function_PnL_Single_Day | NetProfit | ETL-computed | `SUM(frfc.NetProfit)` | Aggregated per group |
| CountPositions | Function_PnL_Single_Day | PositionID | ETL-computed | `COUNT(frfc.PositionID)` | Count of positions per group |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL timestamp |
| IsFuture | Function_PnL_Single_Day | IsFuture | passthrough | `ISNULL(frfc.IsFuture, 0)` | NULL→0 coercion; GROUP BY key |
| IsLeveraged | Function_PnL_Single_Day | Leverage | ETL-computed | `CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END` | GROUP BY key |
| IsBuy | Function_PnL_Single_Day | IsBuy | passthrough | Direct: frfc.IsBuy | GROUP BY key |
| IsCopyFund | Function_PnL_Single_Day | IsCopyFund | passthrough | `ISNULL(frfc.IsCopyFund, 0)` | NULL→0 coercion; GROUP BY key |
| IsSQF | Function_PnL_Single_Day | IsSQF | passthrough | `ISNULL(frfc.IsSQF, 0)` | NULL→0 coercion; GROUP BY key |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 5 |
| **Rename** | 1 |
| **ETL-computed** | 7 |
| **Join-enriched** | 1 |
| **SP-adjusted** | 0 |
| **Total** | 15 |
