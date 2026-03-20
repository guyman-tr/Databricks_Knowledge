# Column Lineage: DWH_dbo.Dim_PositionChangeLog

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PositionChangeLog` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog` |
| **Primary Source** | `etoro.History.PositionChangeLog` (`etoro`) |
| **ETL SP** | `SP_Dim_PositionChangeLog_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.History.PositionChangeLog  (many rows, daily appends)
      |
      v (Generic Pipeline -- daily load)
  Bronze/etoro/History/PositionChangeLog/
      |
      v (DWH staging import)
  DWH_staging.etoro_History_PositionChangeLog
      |
      v (SP_Dim_PositionChangeLog_DL_To_Synapse -- DELETE yesterday+ then INSERT)
  DWH_dbo.Dim_PositionChangeLog  (17 cols, incremental)
      |
      v (Generic Pipeline -- daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived by ETL SP. |
| **cast** | Type conversion applied. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PositionID | etoro_History_PositionChangeLog | PositionID | passthrough | |
| CID | etoro_History_PositionChangeLog | CID | passthrough | |
| Occurred | etoro_History_PositionChangeLog | Occurred | passthrough | |
| OccurredDateID | -- | Occurred | ETL-computed | CAST(CONVERT(VARCHAR(8), Occurred, 112) AS INT) |
| ChangeTypeID | etoro_History_PositionChangeLog | ChangeTypeID | passthrough | |
| PreviousAmount | etoro_History_PositionChangeLog | PreviousAmount | passthrough | |
| AmountChanged | etoro_History_PositionChangeLog | AmountChanged | passthrough | |
| NewAmount | etoro_History_PositionChangeLog | NewAmount | passthrough | |
| PreviousIsSettled | etoro_History_PositionChangeLog | PreviousIsSettled | cast | CAST(PreviousIsSettled AS INT) from bit |
| IsSettled | etoro_History_PositionChangeLog | IsSettled | cast | CAST(IsSettled AS INT) from bit |
| PreviousStopRate | etoro_History_PositionChangeLog | PreviousStopRate | passthrough | |
| StopRate | etoro_History_PositionChangeLog | StopRate | passthrough | |
| PreviousAmountInUnits | etoro_History_PositionChangeLog | PreviousAmountInUnits | passthrough | |
| AmountInUnits | etoro_History_PositionChangeLog | AmountInUnits | passthrough | |
| LotCountDecimal | etoro_History_PositionChangeLog | LotCountDecimal | passthrough | Added 2024-11-07 |
| PreviousLotCountDecimal | etoro_History_PositionChangeLog | PreviousLotCountDecimal | passthrough | Added 2024-11-07 |
| UpdateDate | -- | -- | ETL-computed | GETDATE() on each load |

## Dropped Production Columns (Schema Drift)

None known -- all staging columns are loaded.

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 14 |
| **ETL-computed** | 2 (OccurredDateID, UpdateDate) |
| **Cast** | 2 (PreviousIsSettled, IsSettled) |
| **Dropped from production** | 0 |
| **Total DWH columns** | 17 |
