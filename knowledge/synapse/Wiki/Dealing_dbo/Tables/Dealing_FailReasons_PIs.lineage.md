# Column Lineage: Dealing_dbo.Dealing_FailReasons_PIs

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_FailReasons_PIs` |
| **UC Target** | `general.dealing_dbo.dealing_failreasons_pis` |
| **Primary Source** | `etoro.Trade.PositionFail` (via CopyFromLake.PositionFailReal_History_PositionFail_DWH) |
| **ETL SP** | `Dealing_dbo.SP_CommissionsAndFails_PerCID` |
| **Secondary Sources** | `DWH_dbo.Dim_Customer` (GuruStatusID filter), `Dealing_staging.External_Etoro_Dictionary_FailType` (FailReason text) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
etoro.Trade.PositionFail (production SQL Server)
  → Generic Pipeline → Lake (Bronze/etoro/Trade/PositionFail/)
  → CopyFromLake.PositionFailReal_History_PositionFail_DWH
  → SP_CommissionsAndFails_PerCID
     #Fails (WHERE FailOccurred >= @Date AND FailOccurred < @NextDate)
     #Merge_Fails (28+ CASE WHEN FailReason LIKE patterns → FailReason2)
     #Fails_Data_PIs (WHERE GuruStatusID IN (5,6) → GROUP BY FailReason2, HedgeServerID)
  → Dealing_dbo.Dealing_FailReasons_PIs
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **ETL-computed** | Derived/calculated by ETL SP. |
| **etl_metadata** | Set by GETDATE() at SP execution. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | SP parameter | @Date | passthrough | Direct: @Date | Partition date for DELETE/INSERT cycle |
| FailReason | Trade.PositionFail | FailReason | ETL-computed | 28+ CASE WHEN `FailReason LIKE '%..%'` → canonical label; ELSE 'Other'. PI-subset: WHERE GuruStatusID IN (5,6) | Same 28-bucket classification as Dealing_FailReasons but PI-only population |
| Count_Fails | Trade.PositionFail | PositionFailID | ETL-computed | `COUNT(*) WHERE GuruStatusID IN (5,6) GROUP BY FailReason2, HedgeServerID` | PI fails only |
| UpdateDate | SP runtime | GETDATE() | etl_metadata | `GETDATE()` at INSERT time | ETL insert timestamp |
| HedgeServerID | Trade.PositionFail | HedgeServerID | passthrough | Direct: hf.HedgeServerID | NULL = platform-level rejection before server routing |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 2 |
| **ETL metadata** | 1 |
| **Total** | 5 |
