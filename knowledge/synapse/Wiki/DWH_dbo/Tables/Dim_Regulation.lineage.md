# Column Lineage: DWH_dbo.Dim_Regulation

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Regulation` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` |
| **Primary Source** | `Dictionary.Regulation` (etoro) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.Regulation (production)
  -> Generic Pipeline (daily, Override)
  -> Bronze/etoro/Dictionary/Regulation/
  -> DWH_staging.etoro_Dictionary_Regulation
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
     + DWHRegulationID = [ID] alias
     + StatusID = hardcoded 1
     + ClusterRegulationID = CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END
  -> DWH_dbo.Dim_Regulation
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
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
| ID | Dictionary.Regulation | ID | passthrough | PK. 0=None, 1=CySEC ... 14=NYDFS+FINRA |
| Name | Dictionary.Regulation | Name | passthrough | Short regulation code |
| DWHRegulationID | - | - | ETL-computed | `[ID] as [DWHRegulationID]` - always equals ID. DWH-specific alias. |
| StatusID | - | - | ETL-computed | Hardcoded `1 as [StatusID]` for all rows. Not in production source. |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP reload time |
| InsertDate | - | - | ETL-computed | GETDATE() at SP reload time. Same value as UpdateDate (TRUNCATE+INSERT pattern). |
| ClusterRegulationID | - | - | ETL-computed | `CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END`. Groups None/CySEC/BVI into cluster 1. |

## Lost Columns (Production -> DWH)

| Production Column | Reason Dropped |
|-------------------|----------------|
| IsUSA | Not carried to DWH - hardcode IDs 6,7,8,12,14 for US |
| JurisdictionName | Not carried to DWH |
| BankID | Not carried to DWH |
| RegulationLongName | Not carried to DWH |
| RegulationShortName | Not carried to DWH |
| DefaultRegulationID | Not carried to DWH |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 5 |
| **Total** | 7 |
