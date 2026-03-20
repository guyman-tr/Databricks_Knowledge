# Column Lineage: DWH_dbo.Dim_ExtendedUserField

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ExtendedUserField` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield` |
| **Primary Source** | `UserApiDB.Dictionary.ExtendedUserField` (`UserApiDB`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
UserApiDB.Dictionary.ExtendedUserField (UserApiDB-REAL)
    |
    v
[Staging pipeline]
    |
    v
DWH_staging.UserApiDB_Dictionary_ExtendedUserField
    |
    v
SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 315)
    |
    v
DWH_dbo.Dim_ExtendedUserField (REPLICATE / HEAP)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| FieldID | UserApiDB.Dictionary.ExtendedUserField | FieldId | rename | FieldId -> FieldID (case: lowercase d to uppercase D) |
| FieldTypeID | UserApiDB.Dictionary.ExtendedUserField | FieldTypeId | rename | FieldTypeId -> FieldTypeID (case: lowercase d to uppercase D) |
| ExtendedUserFieldName | UserApiDB.Dictionary.ExtendedUserField | Name | rename | Name -> ExtendedUserFieldName (added table prefix) |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time. |

## Summary

| Category | Count |
|----------|-------|
| **Rename** | 3 |
| **ETL-computed** | 1 |
| **Total** | 4 |
