# Column Lineage: DWH_dbo.Dim_PendingClosureStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PendingClosureStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus` |
| **Primary Source** | `Dictionary.PendingClosureStatus` (`etoro`) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.Dictionary.PendingClosureStatus
      |
      v (Generic Pipeline -- Override, daily, 1440 min)
  Bronze/etoro/Dictionary/PendingClosureStatus/
      |
      v (DWH staging import)
  DWH_staging.etoro_Dictionary_PendingClosureStatus
      |
      v (SP_Dictionaries_DL_To_Synapse -- TRUNCATE + INSERT)
  DWH_dbo.Dim_PendingClosureStatus
      |
      v (Generic Pipeline -- Override, daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus
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
| PendingClosureStatusID | Dictionary.PendingClosureStatus | PendingClosureStatusID | passthrough | PK in both layers |
| PendingClosureStatusName | Dictionary.PendingClosureStatus | PendingClosureStatusName | passthrough | Same column name |
| UpdateDate | -- | -- | ETL-computed | GETDATE() on each reload; not from production source |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
