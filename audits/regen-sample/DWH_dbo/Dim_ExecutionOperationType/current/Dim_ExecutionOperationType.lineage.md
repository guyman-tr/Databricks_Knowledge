# Column Lineage: DWH_dbo.Dim_ExecutionOperationType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ExecutionOperationType` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype` |
| **Primary Source** | `HistoryCosts.Dictionary.ExecutionOperationType` (`HistoryCosts`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
HistoryCosts.Dictionary.ExecutionOperationType (HistoryCosts production)
    |
    v
[Staging pipeline]
    |
    v
DWH_staging.HistoryCosts_Dictionary_ExecutionOperationType
    |
    v
SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, HistoryCosts section ~line 1392)
    |
    v
DWH_dbo.Dim_ExecutionOperationType (ROUND_ROBIN / CLUSTERED INDEX)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| OperationTypeId | HistoryCosts.Dictionary.ExecutionOperationType | Id | rename | Id -> OperationTypeId (added type prefix) |
| OperationType | HistoryCosts.Dictionary.ExecutionOperationType | OperationType | passthrough | Same name. Type widened to nvarchar(max) in DWH. |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time. NOT NULL in DWH. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
