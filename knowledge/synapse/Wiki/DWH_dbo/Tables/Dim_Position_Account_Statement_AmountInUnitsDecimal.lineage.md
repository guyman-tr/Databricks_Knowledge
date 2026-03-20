# Column Lineage: DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal` |
| **UC Target** | _Pending_ |
| **Primary Source** | Unknown - no writer SP found in SSDT repo |
| **ETL SP** | None found |
| **Secondary Sources** | None identified |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
DWH ETL (AmountInUnitsDecimal computation)  -|
                                              +-> [unknown ad-hoc script]
History/snapshot source (AmountInUnits)     -|
  -> DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal  [reconciliation artifact, no active refresh]
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **computed** | Derived at load time from two source columns. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PositionID | Unknown ad-hoc source | PositionID | passthrough | bigint key joining to positions universe |
| AmountInUnitsDecimal_dwh | DWH ETL output | AmountInUnitsDecimal | passthrough | DWH-computed value at time of investigation |
| AmountInUnitsDecimal_history | History/snapshot source | AmountInUnitsDecimal | passthrough | Alternative computation baseline |
| diff | Computed at load | AmountInUnitsDecimal_dwh - AmountInUnitsDecimal_history | computed | 169 matches (diff=0), 34,089 mismatches |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **Computed** | 1 |
| **Total** | 4 |
