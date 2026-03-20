# Column Lineage: DWH_dbo.Dim_FundType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_FundType` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype` |
| **Primary Source** | `etoro.Dictionary.FundType` (`etoroDB-REAL`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.FundType (etoroDB-REAL)
    |
    v
[Generic Pipeline - Bronze/etoro/Dictionary/FundType/]
    |
    v
DWH_staging.etoro_Dictionary_FundType
    |
    v
SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 632)
    |
    v
DWH_dbo.Dim_FundType (REPLICATE / CLUSTERED INDEX)
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
| FundTypeID | etoro.Dictionary.FundType | FundTypeID | passthrough | int. |
| FundTypeName | etoro.Dictionary.FundType | Description | rename | Description -> FundTypeName (added table prefix). varchar(50). |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time. NOT NULL. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
