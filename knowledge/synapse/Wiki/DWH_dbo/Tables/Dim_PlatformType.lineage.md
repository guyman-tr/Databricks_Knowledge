# Column Lineage: DWH_dbo.Dim_PlatformType

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PlatformType` |
| **UC Target** | _Pending_ |
| **Primary Source** | Legacy DWH SQL Server (on-premises) |
| **ETL SP** | None - one-time migration from DWH_Migration.Dim_PlatformType |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
Legacy DWH SQL Server (on-premises)
  -> DWH_Migration.Dim_PlatformType  [staging DDL: varchar columns for BCP bulk load]
  -> DWH_dbo.Dim_PlatformType  [ONE-TIME migration, static frozen since load]
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **cast/convert** | Type conversion only. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| ProductID | DWH_Migration.Dim_PlatformType | ProductID | cast/convert | varchar(10) in migration -> smallint in DWH |
| Product | DWH_Migration.Dim_PlatformType | Product | passthrough | varchar(50) in both |
| Platform | DWH_Migration.Dim_PlatformType | Platform | passthrough | varchar(50) in both |
| SubPlatform | DWH_Migration.Dim_PlatformType | SubPlatform | passthrough | varchar(50) in both |
| CanManualTrade | DWH_Migration.Dim_PlatformType | CanManualTrade | cast/convert | varchar(1) in migration -> bit in DWH |
| CanOpenMirror | DWH_Migration.Dim_PlatformType | CanOpenMirror | cast/convert | varchar(1) in migration -> bit in DWH |
| CanCopyTrade | DWH_Migration.Dim_PlatformType | CanCopyTrade | cast/convert | varchar(1) in migration -> bit in DWH |
| CanDeposit | DWH_Migration.Dim_PlatformType | CanDeposit | cast/convert | varchar(1) in migration -> bit in DWH |
| CanCashout | DWH_Migration.Dim_PlatformType | CanCashout | cast/convert | varchar(1) in migration -> bit in DWH |
| InDevelopment | DWH_Migration.Dim_PlatformType | InDevelopment | cast/convert | varchar(1) in migration -> bit in DWH |
| InsertDate | DWH_Migration.Dim_PlatformType | InsertDate | cast/convert | varchar(50) in migration -> datetime in DWH. All NULL in live data. |
| UpdateDate | DWH_Migration.Dim_PlatformType | UpdateDate | cast/convert | varchar(50) in migration -> datetime in DWH. All NULL in live data. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **cast/convert** | 9 |
| **Total** | 12 |
