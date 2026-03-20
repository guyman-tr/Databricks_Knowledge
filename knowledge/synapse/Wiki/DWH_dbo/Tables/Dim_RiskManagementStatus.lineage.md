# Column Lineage: DWH_dbo.Dim_RiskManagementStatus

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_RiskManagementStatus` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus` |
| **Primary Source** | `Dictionary.RiskManagementStatus` (etoro) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.RiskManagementStatus (production)
  -> Generic Pipeline (daily, Override)
  -> Bronze/etoro/Dictionary/RiskManagementStatus/
  -> DWH_staging.etoro_Dictionary_RiskManagementStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
     + DWHRiskManagementStatusID = [RiskManagementStatusID] alias
     + StatusID = hardcoded 1
  -> DWH_dbo.Dim_RiskManagementStatus
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus
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
| RiskManagementStatusID | Dictionary.RiskManagementStatus | RiskManagementStatusID | passthrough | PK. 0=N/A sentinel (midnight timestamp), 1=Success, 2-69=block/decline reasons |
| Name | Dictionary.RiskManagementStatus | Name | passthrough | Internal code name for risk check outcome |
| DWHRiskManagementStatusID | - | - | ETL-computed | `[RiskManagementStatusID] as [DWHRiskManagementStatusID]` - always equals RiskManagementStatusID |
| StatusID | - | - | ETL-computed | Hardcoded `1 as [StatusID]` for all rows |
| UpdateDate | - | - | ETL-computed | GETDATE() for IDs 1-69; midnight (00:00:00) for ID=0 sentinel |
| InsertDate | - | - | ETL-computed | GETDATE() for IDs 1-69; midnight (00:00:00) for ID=0 sentinel |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 4 |
| **Total** | 6 |
