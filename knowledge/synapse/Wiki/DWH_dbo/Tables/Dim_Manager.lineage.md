# Column Lineage: DWH_dbo.Dim_Manager

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Manager` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` |
| **Primary Source** | `etoro.BackOffice.Manager` (BackOffice CRM) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | Salesforce SalesForceToBOManagerMapping (SFManagerID) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.BackOffice.Manager  (BackOffice CRM)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_BackOffice_Manager
  |-- SP_Dictionaries_DL_To_Synapse (UPDATE existing + INSERT new, daily) ---|
  |-- post-load UPDATE from SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping ---|
  v
DWH_dbo.Dim_Manager  (5,152 rows; never truncated, incremental)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Manager/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **rename** | Same value, different column name. |
| **ETL-computed** | Derived by SP logic; not from any source column. |
| **post-load UPDATE** | Set via a separate UPDATE after main INSERT. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ManagerID | etoro.BackOffice.Manager | ManagerID | passthrough | PK (NOT ENFORCED) |
| UserGroup | -- | -- | ETL-computed | Hardcoded 'Not Available' for all rows |
| ParentUserGroup | -- | -- | ETL-computed | Hardcoded 'Not Available' for all rows |
| FirstName | etoro.BackOffice.Manager | FirstName | passthrough | Updated daily via SP UPDATE |
| LastName | etoro.BackOffice.Manager | LastName | passthrough | Updated daily via SP UPDATE |
| IsActive | etoro.BackOffice.Manager | IsActive | passthrough | Updated daily; 1=currently active |
| IsTeamLeader | etoro.BackOffice.Manager | IsTeamLeader | passthrough | Updated daily |
| DWHManagerID | etoro.BackOffice.Manager | ManagerID | rename | Always = ManagerID |
| StatusID | -- | -- | ETL-computed | Hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed | GETDATE() on each daily UPDATE |
| InsertDate | -- | -- | ETL-computed | GETDATE() on first INSERT only; not updated on subsequent runs |
| SFManagerID | Salesforce SalesForceToBOManagerMapping | SFManagerID | post-load UPDATE | Via ManagerID join; NULL if no Salesforce mapping |
| CalendlyID | etoro.BackOffice.Manager | CalendlyID | passthrough | Updated daily; 'etoro-club' default for inactive managers |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 7 |
| **Rename** | 1 |
| **Post-load UPDATE** | 1 |
| **ETL-computed** | 4 |
| **Total** | 13 |
