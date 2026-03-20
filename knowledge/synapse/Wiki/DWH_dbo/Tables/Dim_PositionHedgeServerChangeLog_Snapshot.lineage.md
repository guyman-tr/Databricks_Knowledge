# Column Lineage: DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot` |
| **Primary Source** | `etoro.Trade.PositionsHedgeServerChangeLog` (`etoro`) |
| **ETL SP** | `SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse` + `SP_Dim_Position_PositionHedgeServerChangeLog` |
| **Secondary Sources** | `DWH_dbo.Dim_Position` (for OpenDateID lookup) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.Trade.PositionsHedgeServerChangeLog
      |
      v (Generic Pipeline -- daily)
  DWH_staging.etoro_Trade_PositionsHedgeServerChangeLog
      |
      v (SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse)
  DWH_dbo.Ext_Dim_Position_PositionHedgeServerChangeLog (staging buffer)
      |                     +--- DWH_dbo.Dim_Position (OpenDateID lookup)
      v (SP_Dim_Position_PositionHedgeServerChangeLog)
  DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot  (5 cols, SCD2)
      |
      v (Generic Pipeline -- daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from staging. |
| **ETL-computed** | Derived by ETL SP logic. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PositionID | etoro_Trade_PositionsHedgeServerChangeLog | PositionID | passthrough | Via Ext_Dim_Position_PositionHedgeServerChangeLog |
| HedgeServerID | etoro_Trade_PositionsHedgeServerChangeLog | FromHedgeServerID / ToHedgeServerID | ETL-computed | FromHedgeServerID for pre-change period rows; ToHedgeServerID for post-change/active rows |
| FromDate | Dim_Position | OpenDateID | ETL-computed | OpenDateID from Dim_Position for initial pre-change row; OccurredDateID for post-change row |
| ToDate | -- | -- | ETL-computed | OccurredDateID-1 for pre-change rows; 20991231 for active rows; @dateIDprev when closing superseded rows |
| UpdateDate | -- | -- | ETL-computed | GETDATE() on each ETL run |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **ETL-computed** | 4 |
| **Dropped from production** | 0 |
| **Total DWH columns** | 5 |
