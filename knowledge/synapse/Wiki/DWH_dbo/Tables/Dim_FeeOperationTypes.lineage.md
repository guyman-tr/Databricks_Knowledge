# Column Lineage: DWH_dbo.Dim_FeeOperationTypes

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_FeeOperationTypes` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_feeoperationtypes` |
| **Primary Source** | `etoro.Dictionary.FeeOperationTypes` (`etoroDB-REAL`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.FeeOperationTypes (etoroDB-REAL)
    |
    v
[Generic Pipeline - Bronze/etoro/Dictionary/FeeOperationTypes/]
    |
    v
DWH_staging.etoro_Dictionary_FeeOperationTypes
    |
    v
SP_Dictionaries_DL_To_Synapse (INSERT ONLY - NO TRUNCATE BUG, ~line 1404)
    |
    v
DWH_dbo.Dim_FeeOperationTypes (ROUND_ROBIN / CLUSTERED INDEX)
  WARNING: 897 rows due to INSERT-only accumulation. Only 3 distinct values.
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
| FeeOperationTypeID | etoro.Dictionary.FeeOperationTypes | FeeOperationTypeID | passthrough | Same name and type (int). Values: 1=Open, 2=Close, 3=All. |
| FeeOperationTypeName | etoro.Dictionary.FeeOperationTypes | Name | rename | Name -> FeeOperationTypeName (added table prefix). nvarchar(max) in DWH. |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time. NOT NULL. Because there is no TRUNCATE, this stores the time of EACH accumulated run. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
