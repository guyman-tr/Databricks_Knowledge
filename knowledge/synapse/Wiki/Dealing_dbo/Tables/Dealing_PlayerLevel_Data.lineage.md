# Column Lineage: Dealing_dbo.Dealing_PlayerLevel_Data

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_PlayerLevel_Data` |
| **UC Target** | `general.dealing_dbo.dealing_playerlevel_data` |
| **Primary Source** | `DWH_dbo.Dim_Position` + `CopyFromLake.PositionFailReal_History_PositionFail_DWH` |
| **ETL SP** | `Dealing_dbo.SP_CommissionsAndFails_PerCID` |
| **Secondary Sources** | `DWH_dbo.Dim_Customer` (PlayerLevelID, PlayerLevel), `DWH_dbo.Dim_Instrument`, `BI_DB_dbo.BI_DB_PositionPnL` (NOP) |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
DWH_dbo.Dim_Position + CopyFromLake.PositionFailReal_History_PositionFail_DWH
  → SP_CommissionsAndFails_PerCID
     #Positions (open+active positions on @Date, with PlayerLevel from Dim_Customer)
     #Commission (TotalCommission per position)
     #Add_NOP (NOP from BI_DB_PositionPnL)
     #TotalData_CommissionNOP (aggregated by CID)
     #Fails (raw fails) → #TotalData_Fails
     #PlayerLevel_Data (GROUP BY PlayerLevelID, PlayerLevel — full population)
  → Dealing_dbo.Dealing_PlayerLevel_Data
```

## Column Lineage

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | SP parameter | @Date | passthrough | Direct: @Date | Partition date |
| PlayerLevelID | DWH_dbo.Dim_Customer | PlayerLevelID | passthrough | Direct: b.PlayerLevelID from #Positions | Player tier integer ID |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | join-enriched | LEFT JOIN Dim_PlayerLevel ON PlayerLevelID | Text label (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond) |
| TotalCommission | DWH_dbo.Dim_Position | FullCommission/FullCommissionOnClose/FullCommissionByUnits | ETL-computed | `SUM(CASE WHEN OpenDateID=@DateID AND CloseDateID=@DateID THEN FullCommissionOnClose WHEN OpenDateID<@DateID AND CloseDateID=@DateID THEN FullCommissionOnClose-FullCommissionByUnits WHEN OpenDateID=@DateID AND CloseDateID>@DateID THEN FullCommissionByUnits ELSE 0 END)` aggregated per PlayerLevel | Revenue-attribution formula: attributtes commission to the date of open or close event |
| NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | ETL-computed | `SUM(NOP)` per PlayerLevel (LEFT JOIN on PositionID + DateID=@DateID) | Net Open Position in USD per player tier |
| Count_Fails | Trade.PositionFail | PositionFailID | ETL-computed | `SUM(Count_Fails)` from #TotalData_Fails, full population | Total fail count across all clients in each player tier |
| Success_Positions | DWH_dbo.Dim_Position | PositionID | ETL-computed | `SUM(Success_Positions)` — positions opened OR closed on @Date | Count of successful trade actions per tier |
| Ratio | Dim_Position + PositionFail | — | ETL-computed | `SUM(Count_Fails) / SUM(Success_Positions)` aggregated per PlayerLevel | Fail-to-success ratio per player tier; higher = more problematic tier |
| UpdateDate | SP runtime | GETDATE() | etl_metadata | `GETDATE()` at INSERT time | ETL insert timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Join-enriched** | 1 |
| **ETL-computed** | 5 |
| **ETL metadata** | 1 |
| **Total** | 9 |
