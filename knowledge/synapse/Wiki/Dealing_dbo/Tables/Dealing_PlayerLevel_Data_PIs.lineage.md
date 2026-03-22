# Column Lineage: Dealing_dbo.Dealing_PlayerLevel_Data_PIs

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_PlayerLevel_Data_PIs` |
| **UC Target** | `general.dealing_dbo.dealing_playerlevel_data_pis` |
| **Primary Source** | `DWH_dbo.Dim_Position` + `CopyFromLake.PositionFailReal_History_PositionFail_DWH` |
| **ETL SP** | `Dealing_dbo.SP_CommissionsAndFails_PerCID` |
| **Secondary Sources** | `DWH_dbo.Dim_Customer` (PlayerLevelID, GuruStatusID filter), `BI_DB_dbo.BI_DB_PositionPnL` (NOP) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Same pipeline as Dealing_PlayerLevel_Data, PI subset only.
  → SP_CommissionsAndFails_PerCID
     #PlayerLevel_Data_PIs (FULL OUTER JOIN tdcn + tdf WHERE tdcn.GuruStatusID IN (5,6))
  → Dealing_dbo.Dealing_PlayerLevel_Data_PIs
```

## Column Lineage

Identical to Dealing_PlayerLevel_Data with one additional filter:
- All aggregations scoped to `GuruStatusID IN (5,6)` (Popular Investors only)

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | SP parameter | @Date | passthrough | Direct: @Date | Partition date |
| PlayerLevelID | DWH_dbo.Dim_Customer | PlayerLevelID | passthrough | Direct: b.PlayerLevelID (PI subset) | PI PlayerLevel ID |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | join-enriched | ISNULL(tdf.PlayerLevel, tdcn.PlayerLevel) | Text label for PI tier |
| TotalCommission | DWH_dbo.Dim_Position | FullCommission* | ETL-computed | Same commission formula as PlayerLevel_Data, WHERE GuruStatusID IN (5,6) | Commission from PI positions only |
| NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | ETL-computed | `SUM(NOP)` per PlayerLevel, PI subset | NOP for PIs per tier |
| Count_Fails | Trade.PositionFail | PositionFailID | ETL-computed | `SUM(Count_Fails)` from #TotalData_Fails, WHERE GuruStatusID IN (5,6) | PI fail count per tier |
| Success_Positions | DWH_dbo.Dim_Position | PositionID | ETL-computed | `SUM(Success_Positions)` per tier, PI subset | PI successful trades per tier |
| Ratio | — | — | ETL-computed | `SUM(Count_Fails) / SUM(Success_Positions)` for PI subset | Fail rate for PIs per tier |
| UpdateDate | SP runtime | GETDATE() | etl_metadata | `GETDATE()` at INSERT time | ETL insert timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Join-enriched** | 1 |
| **ETL-computed** | 5 |
| **ETL metadata** | 1 |
| **Total** | 9 |
