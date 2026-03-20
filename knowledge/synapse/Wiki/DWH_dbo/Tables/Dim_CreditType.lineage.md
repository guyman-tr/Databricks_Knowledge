# Column Lineage: DWH_dbo.Dim_CreditType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_CreditType` |
| **UC Target** | _Pending - resolved during write-objects_ |
| **Primary Source** | `etoro.Dictionary.CreditType` (etoro) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.CreditType
  -> [Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_CreditType (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_CreditType (33 rows)
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
| CreditTypeID | etoro.Dictionary.CreditType | CreditTypeID | passthrough | tinyint PK. 33 values (1-33). |
| CreditTypeName | etoro.Dictionary.CreditType | Name | rename | Source column is `Name`. DWH renames to CreditTypeName. char(50) type adds trailing spaces. |
| UpdateDate | - | - | ETL-computed | GETDATE() on each reload. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |
