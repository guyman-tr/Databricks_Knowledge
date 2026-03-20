# Column Lineage: DWH_dbo.Dim_Position_Account_Statement_NetProfit

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Position_Account_Statement_NetProfit` |
| **UC Target** | _Pending_ |
| **Primary Source** | Unknown - no writer SP found in SSDT repo |
| **ETL SP** | None found |
| **Secondary Sources** | None identified |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
DWH ETL (NetProfit = 0 for all rows)  -|
                                        +-> [unknown ad-hoc script]
History/snapshot source (NetProfit)   -|
  -> DWH_dbo.Dim_Position_Account_Statement_NetProfit  [reconciliation artifact, no active refresh]
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
| NetProfit_dwh | DWH ETL output | NetProfit | passthrough | All values = 0.0000 - DWH lacked NetProfit calculation at capture time |
| NetProfit_history | History/snapshot source | NetProfit | passthrough | Contains actual NetProfit values (range: -29,575 to +39,676) |
| diff | Computed at load | NetProfit_dwh - NetProfit_history | computed | 0 matches, 251,813 mismatches; since _dwh=0, diff = -NetProfit_history for all rows |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **Computed** | 1 |
| **Total** | 4 |
