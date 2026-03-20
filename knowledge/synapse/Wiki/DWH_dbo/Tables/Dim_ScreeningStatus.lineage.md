# Column Lineage: DWH_dbo.Dim_ScreeningStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ScreeningStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus` |
| **Primary Source** | `Dictionary.ScreeningStatus` (ScreeningService) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
ScreeningService.Dictionary.ScreeningStatus (ScreeningServiceDB - AML compliance microservice)
  -> Generic Pipeline (daily, Override)
  -> Bronze/ScreeningService/Dictionary/ScreeningStatus/
  -> bi_db.bronze_screeningservice_dictionary_screeningstatus (UC Bronze)
  -> DWH_staging.ScreeningService_Dictionary_ScreeningStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
     + ID renamed to ScreeningStatusID
  -> DWH_dbo.Dim_ScreeningStatus
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **rename** | Same value, different column name in DWH. |
| **passthrough** | Column copied as-is. |
| **ETL-computed** | Derived/calculated by ETL SP. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ScreeningStatusID | ScreeningService.Dictionary.ScreeningStatus | ID | rename | ID -> ScreeningStatusID. 0=Unknown thru 7=SanctionsMatch |
| Name | ScreeningService.Dictionary.ScreeningStatus | Name | passthrough | AML screening outcome code name |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP_Dictionaries reload time |

## Summary

| Category | Count |
|----------|-------|
| **Rename** | 1 |
| **Passthrough** | 1 |
| **ETL-computed** | 1 |
| **Total** | 3 |

## Note on Source System

Unlike all other DWH_dbo.Dim_ tables which source from etoro.Dictionary.* (via DWH_staging.etoro_Dictionary_*), this table sources from ScreeningService.Dictionary.ScreeningStatus on ScreeningServiceDB. The staging table naming convention is ScreeningService_Dictionary_ScreeningStatus (not etoro_Dictionary_*). No upstream wiki exists for this source.
