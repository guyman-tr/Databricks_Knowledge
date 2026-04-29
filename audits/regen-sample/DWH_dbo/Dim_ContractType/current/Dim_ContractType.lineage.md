# Column Lineage: DWH_dbo.Dim_ContractType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ContractType` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype` (expected) |
| **Primary Source** | `Legacy DWH SQL Server` (DWH-internal affiliate commission model types) |
| **ETL SP** | None (frozen migration) |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
Legacy DWH SQL Server (DWH-internal affiliate data)
  |
  -> DWH_Migration.Dim_ContractType (one-time migration, NoDbObjectsScripts 2024-09-16)
       -> DWH_dbo.Dim_ContractType (Synapse, REPLICATE, 9 rows, frozen)

NOTE: No production etoro.Dictionary equivalent exists.
      etoro DB has no ContractType table - this is a DWH-internal classification.
      SP_Dim_Affiliate derives ContractType integers via CASE on ContractName text
      (independent of this table at ETL time).
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **rename** | Same value, different column name. |
| **cast/convert** | Type conversion only. |
| **ETL-computed** | Derived by ETL, not from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ContractTypeID | DWH_Migration.Dim_ContractType | ContractTypeID | passthrough | int in both; 9 values (0-8) |
| Name | DWH_Migration.Dim_ContractType | Name | passthrough | varchar(20) in both; abbreviated model names |
| InsertDate | DWH_Migration.Dim_ContractType | InsertDate | cast/convert | varchar(50) in migration -> datetime in DWH; all NULL in live |
| UpdateDate | DWH_Migration.Dim_ContractType | UpdateDate | cast/convert | varchar(50) in migration -> datetime in DWH; all NULL in live |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 (ContractTypeID, Name) |
| **Cast/Convert** | 2 (InsertDate, UpdateDate - both NULL in live) |
| **ETL-computed** | 0 |
| **Total** | 4 |
