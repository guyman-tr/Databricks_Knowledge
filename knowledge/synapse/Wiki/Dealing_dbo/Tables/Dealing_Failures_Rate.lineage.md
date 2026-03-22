# Column Lineage: Dealing_dbo.Dealing_Failures_Rate

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Failures_Rate` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `etoro.Hedge.ExecutionLog` (production) |
| **ETL SP** | `SP_Failures` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
etoro.Hedge.ExecutionLog ──► CopyFromLake.etoro_Hedge_ExecutionLog ──► SP_Failures ──► Dealing_Failures_Rate
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@Date` SP parameter | Report date |
| Failure_Rate | CopyFromLake.etoro_Hedge_ExecutionLog | Success | ETL-computed | `SUM(CASE WHEN Success=0 THEN COUNT ELSE 0 END) / NULLIF(SUM(COUNT), 0)` | Ratio of failed to total hedge executions |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL load timestamp |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 3 |
| **Total** | 3 |
