# Column Lineage: DWH_dbo.Dim_Product

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Product` |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product` |
| **Primary Source** | Unknown - legacy DWH migration (2018) |
| **ETL SP** | None - no active ETL |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
Unknown legacy DWH source
  -> one-time migration (2018-09-02)
  -> DWH_dbo.Dim_Product (27 rows, frozen)
  -> Generic Pipeline export (Gold)
  -> bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ProductID | Unknown legacy DWH | ProductID | passthrough | PK. ID=99 = sentinel row. |
| Product | Unknown legacy DWH | Product or Name | passthrough | App display name |
| Platform | Unknown legacy DWH | Platform | passthrough | Top-level: Mobile or Web |
| SubPlatform | Unknown legacy DWH | SubPlatform | passthrough | OS/browser: Android, iOS, Browsers |
| InsertDate | - | - | ETL-computed | GETDATE() at migration time (2018-09-02) |
| UpdateDate | - | - | ETL-computed | GETDATE() at migration time; max = 2020-07-28 for newer rows |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 2 |
| **Total** | 6 |
