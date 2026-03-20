# Column Lineage: DWH_dbo.Dim_Range

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Range` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` |
| **Primary Source** | DWH-internal (no external production source) |
| **ETL SP** | SP_Fact_SnapshotEquity, SP_Fact_SnapshotCustomer |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
SP_Fact_SnapshotEquity (daily) ---+
                                  +--> INSERT (NOT EXISTS guard) --> DWH_dbo.Dim_Range
SP_Fact_SnapshotCustomer (daily) -+
                                        |
                                        v
                             Generic Pipeline (daily, Override)
                                        |
                                        v
                    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DateRangeID | - | - | ETL-computed | CONVERT(BIGINT, YYYYMMDD(@date) + MMDD(@largedate)). 12-char string concat. |
| FromDateID | - | - | ETL-computed | CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR), 8)) |
| ToDateID | - | - | ETL-computed | CONVERT(INT, LEFT(4 chars) + RIGHT(4 chars) of DateRangeID) |
| UpdateDate | - | - | ETL-computed | GETDATE() at INSERT time |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 4 |
| **Total** | 4 |
