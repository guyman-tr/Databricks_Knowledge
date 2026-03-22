# Column Lineage: Dealing_dbo.Dealing_Failures

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Failures` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `etoro.History.OrdersFail` (production) |
| **ETL SP** | `SP_Failures` |
| **Secondary Sources** | `PositionFailReal.History.PositionFail`, `etoro.History.OrdersMarketFail` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
etoro.History.OrdersFail ──────────────────┐
PositionFailReal.History.PositionFail ─────┼──► CopyFromLake / Dealing_staging ──► SP_Failures ──► Dealing_Failures
etoro.History.OrdersMarketFail ────────────┘
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **ETL-computed** | Derived/calculated by ETL SP. |
| **passthrough** | Column copied as-is. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@Date` SP parameter | Report date |
| ErrorCode | Multiple fail tables | ErrorCode | passthrough | Direct: UNION of 3 fail sources | Numeric error code from dealing execution |
| Description | Multiple fail tables | FailReason | ETL-computed | `REPLACE(FailReason, '0'-'9', 'X')` for non-NULL ErrorCode; digits stripped for NULL ErrorCode. ROW_NUMBER per ErrorCode. | Generic fail description (numbers masked) |
| Count | — | — | ETL-computed | `COUNT(*)` GROUP BY ErrorCode, FailReason_Generic | Occurrences of each error code per day |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL load timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **ETL-computed** | 4 |
| **Total** | 5 |
