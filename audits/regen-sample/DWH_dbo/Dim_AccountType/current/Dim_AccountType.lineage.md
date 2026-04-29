# Column Lineage: DWH_dbo.Dim_AccountType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_AccountType` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Dictionary.AccountType` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Dictionary.AccountType (etoroDB-REAL, 19 rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/AccountType/
  |
  v [staging]
DWH_staging.etoro_Dictionary_AccountType
  |
  v [SP_Dictionaries_DL_To_Synapse - TRUNCATE + INSERT]
DWH_dbo.Dim_AccountType (19 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **passthrough (renamed)** | Column copied as-is but given a different name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| AccountTypeID | Dictionary.AccountType | AccountTypeID | passthrough | Primary key; 0=N/A from production source (no explicit DWH placeholder insert) |
| Name | Dictionary.AccountType | AccountTypeName | passthrough (renamed) | Production column AccountTypeName renamed to Name in DWH |
| DWHAccountTypeID | Dictionary.AccountType | AccountTypeID | ETL-computed | SELECT AccountTypeID AS DWHAccountTypeID -- always equals AccountTypeID |
| StatusID | - | - | ETL-computed | Hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time |
| InsertDate | - | - | ETL-computed | GETDATE() at SP execution time (always equals UpdateDate) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Passthrough (renamed)** | 1 |
| **ETL-computed** | 4 |
| **Total** | 6 |
