# Column Lineage: DWH_dbo.Dim_BonusType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_BonusType` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `BackOffice.BonusType` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.BackOffice.BonusType (etoroDB-REAL, 66 rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min, parquet]
Bronze/etoro/BackOffice/BonusType/
  |
  v [staging]
DWH_staging.etoro_BackOffice_BonusType
  |
  v [SP_Dictionaries_DL_To_Synapse - TRUNCATE + INSERT]
DWH_dbo.Dim_BonusType (66 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **excluded** | Column exists in production source but not loaded into DWH. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| BonusTypeID | BackOffice.BonusType | BonusTypeID | passthrough | smallint in DWH vs int IDENTITY in production |
| Name | BackOffice.BonusType | Name | passthrough | Internal BackOffice name (NOT customer-facing DisplayName) |
| IsWithdrawable | BackOffice.BonusType | IsWithdrawable | passthrough | Currently False for all rows |
| IsActive | BackOffice.BonusType | IsActive | passthrough | False for IDs 0, 17, 23 |
| DWHBonusTypeID | BackOffice.BonusType | BonusTypeID | ETL-computed | SELECT BonusTypeID AS DWHBonusTypeID -- always equals BonusTypeID |
| StatusID | - | - | ETL-computed | Hardcoded to 1 for all rows |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time |
| InsertDate | - | - | ETL-computed | GETDATE() at SP execution time (equals UpdateDate) |
| *(not in DWH)* | BackOffice.BonusType | ParentID | excluded | Departmental hierarchy parent -- not loaded |
| *(not in DWH)* | BackOffice.BonusType | DisplayName | excluded | Customer-facing label -- not loaded |
| *(not in DWH)* | BackOffice.BonusType | IsDepositRelated | excluded | Deposit-trigger flag -- not loaded |
| *(not in DWH)* | BackOffice.BonusType | HideFromAffwiz | excluded | Affiliate visibility flag -- not loaded |
| *(not in DWH)* | BackOffice.BonusType | Configuration | excluded | XML configuration payload -- not loaded |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 4 |
| **Excluded (not loaded)** | 5 |
| **Total (DWH columns)** | 8 |
