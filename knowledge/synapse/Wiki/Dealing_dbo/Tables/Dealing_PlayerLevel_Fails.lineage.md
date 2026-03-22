# Column Lineage: Dealing_dbo.Dealing_PlayerLevel_Fails

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_PlayerLevel_Fails` |
| **UC Target** | `general.dealing_dbo.dealing_playerlevel_fails` |
| **Primary Source** | `etoro.Trade.PositionFail` (via CopyFromLake.PositionFailReal_History_PositionFail_DWH) |
| **ETL SP** | `Dealing_dbo.SP_CommissionsAndFails_PerCID` |
| **Secondary Sources** | `DWH_dbo.Dim_Customer` (PlayerLevelID), `DWH_dbo.Dim_PlayerLevel` (PlayerLevel name) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
Trade.PositionFail → CopyFromLake.PositionFailReal_History_PositionFail_DWH
  → SP_CommissionsAndFails_PerCID
     #Fails + #Merge_Fails (FailReason2 classification via 28+ CASE WHEN)
     #PlayerLevel_Fails (GROUP BY PlayerLevelID, PlayerLevel, FailReason2 — full population)
  → Dealing_dbo.Dealing_PlayerLevel_Fails
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | SP parameter | @Date | passthrough | Direct: @Date | Partition date |
| PlayerLevelID | DWH_dbo.Dim_Customer | PlayerLevelID | passthrough | Direct: b.PlayerLevelID | Player tier ID |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | join-enriched | LEFT JOIN Dim_PlayerLevel ON PlayerLevelID | Text tier label |
| FailReason | Trade.PositionFail | FailReason | ETL-computed | 28+ CASE WHEN patterns → FailReason2; full population (not PI-filtered) | Same classification bucket as Dealing_FailReasons |
| Count_Fails | Trade.PositionFail | PositionFailID | ETL-computed | `COUNT(*) GROUP BY PlayerLevelID, PlayerLevel, FailReason2` | Fail count per tier × reason combination |
| UpdateDate | SP runtime | GETDATE() | etl_metadata | `GETDATE()` at INSERT time | ETL insert timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Join-enriched** | 1 |
| **ETL-computed** | 2 |
| **ETL metadata** | 1 |
| **Total** | 6 |
