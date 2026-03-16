# Bottom-Up Deep Lineage Propagation Report

**Generated**: 2026-03-16 12:49 | Mode: FULL RUN (discover + execute)
**Total elapsed**: 1013s (16.9 min)
**Tables processed**: 4

## Summary

| Metric | Value |
|--------|-------|
| Tables processed | 4 |
| Downstream objects discovered | 166 |
| Column matches (identical) | 1463 |
| Renames detected | 0 |
| Statements succeeded | 1369 |
| Statements failed | 365 |

## Per-Table Results

| # | Table | Depth | Downstream | Matches | Renames | Succeeded | Failed | Time | Status |
|---|-------|-------|------------|---------|---------|-----------|--------|------|--------|
| 1 | `DWH_dbo.Dim_Position` | 1 | 63 | 575 | 0 | 442 | 133 | 476.6s | completed |
| 2 | `DWH_dbo.Fact_BillingDeposit` | 1 | 22 | 289 | 0 | 271 | 18 | 226.7s | completed |
| 3 | `DWH_dbo.Fact_CustomerAction` | 2 | 62 | 366 | 0 | 309 | 57 | 302.1s | completed |
| 4 | `BI_DB_dbo.BI_DB_CIDFirstDates` | 3 | 19 | 233 | 0 | 347 | 157 | 8.0s | completed |
