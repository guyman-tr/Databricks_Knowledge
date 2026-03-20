# Column Lineage: DWH_dbo.Dim_RiskStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_RiskStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus` |
| **Primary Source** | `Dictionary.RiskStatus` (etoro) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.RiskStatus (production)
  -> Generic Pipeline (daily, Override)
  -> Bronze/etoro/Dictionary/RiskStatus/
  -> DWH_staging.etoro_Dictionary_RiskStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
     + DWHRiskStatusID = [RiskStatusID] alias
     + StatusID = hardcoded 1
  -> DWH_dbo.Dim_RiskStatus
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus
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
| RiskStatusID | Dictionary.RiskStatus | RiskStatusID | passthrough | PK. 0=None, 1=Normal, 2+=specific risk flags. 90 rows (0-90 with gaps). |
| Name | Dictionary.RiskStatus | Name | passthrough | Risk flag label. Mix of PascalCase and plain English. |
| IsActive | Dictionary.RiskStatus | IsActive | passthrough | 74 active, 16 inactive (legacy CHBK and deprecated flags). |
| DWHRiskStatusID | - | - | ETL-computed | `[RiskStatusID] as [DWHRiskStatusID]` - always equals RiskStatusID |
| StatusID | - | - | ETL-computed | Hardcoded `1 as [StatusID]` for all rows. Distinct from IsActive. |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP_Dictionaries reload time |
| InsertDate | - | - | ETL-computed | GETDATE() at SP_Dictionaries reload time |

## Lost Columns (Production -> DWH)

| Production Column | Reason Dropped |
|-------------------|----------------|
| RiskCategoryID | Not carried to DWH; FK to Dictionary.RiskCategories for category grouping |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **ETL-computed** | 4 |
| **Total** | 7 |
