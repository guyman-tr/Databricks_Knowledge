# Column Lineage: Dealing_dbo.Dealing_PlayerLevel_Fails_PIs

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_PlayerLevel_Fails_PIs` |
| **UC Target** | `general.dealing_dbo.dealing_playerlevel_fails_pis` |
| **Primary Source** | `etoro.Trade.PositionFail` (via CopyFromLake.PositionFailReal_History_PositionFail_DWH) |
| **ETL SP** | `Dealing_dbo.SP_CommissionsAndFails_PerCID` |
| **Secondary Sources** | `DWH_dbo.Dim_Customer` (GuruStatusID filter), `DWH_dbo.Dim_PlayerLevel` (PlayerLevel name) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Trade.PositionFail → CopyFromLake.PositionFailReal_History_PositionFail_DWH
  → SP_CommissionsAndFails_PerCID
     #Merge_Fails (FailReason2 classification)
     #PlayerLevel_Fails_PIs (WHERE GuruStatusID IN (5,6), GROUP BY PlayerLevelID, PlayerLevel, FailReason2)
  → Dealing_dbo.Dealing_PlayerLevel_Fails_PIs
```

## Column Lineage

Identical to Dealing_PlayerLevel_Fails but PI-filtered (GuruStatusID IN (5,6)).

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | SP parameter | @Date | passthrough | Direct: @Date | Partition date |
| PlayerLevelID | DWH_dbo.Dim_Customer | PlayerLevelID | passthrough | Direct: b.PlayerLevelID (PI subset) | PI tier ID |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | join-enriched | ISNULL lookup, PI subset | PI tier label |
| FailReason | Trade.PositionFail | FailReason | ETL-computed | 28+ CASE WHEN → FailReason2, WHERE GuruStatusID IN (5,6) | Standardized fail reason for PI population |
| Count_Fails | Trade.PositionFail | PositionFailID | ETL-computed | `COUNT(*) WHERE GuruStatusID IN (5,6) GROUP BY PlayerLevelID, PlayerLevel, FailReason2` | PI fail count per tier × reason |
| UpdateDate | SP runtime | GETDATE() | etl_metadata | `GETDATE()` at INSERT time | ETL insert timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Join-enriched** | 1 |
| **ETL-computed** | 2 |
| **ETL metadata** | 1 |
| **Total** | 6 |
