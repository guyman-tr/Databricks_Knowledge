---
object: Dealing_CIDs_CommissionsAndFails_PIs
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_CIDs_CommissionsAndFails_PIs

Source SP: `Dealing_dbo.SP_CommissionsAndFails_PerCID`

All column derivations are identical to `Dealing_CIDs_CommissionsAndFails`. The only difference is the filter applied before the TOP 20 selection.

### PI Filter Step

```sql
-- In #Commissions_Data_PIs:
WHERE isnull(tdcn.GuruStatusID, tdf.GuruStatusID) IN (5,6)
ORDER BY TotalCommission DESC
```

This filters the FULL OUTER JOIN of `#TotalData_CommissionNOP` and `#TotalData_Fails` to only rows where the customer's GuruStatusID is 5 (Popular Investor) or 6 (Popular Investor higher tier), then takes the top 20 by TotalCommission.

### Column-Level Lineage

Identical to `Dealing_CIDs_CommissionsAndFails`. See that table's lineage for the full derivation chain.

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `@Date` parameter | SP parameter | 2 |
| CID | `cd.CID` from #Commissions_Data_PIs (TOP 20 PIs by commission) | DWH_dbo.Dim_Position | 1 |
| UserName | `b.UserName` | DWH_dbo.Dim_Customer | 1 |
| Region | `dc.Region` | DWH_dbo.Dim_Country | 2 |
| PlayerLevelID | `b.PlayerLevelID` | DWH_dbo.Dim_Customer | 1 |
| PlayerLevel | `pl.Name` | DWH_dbo.Dim_PlayerLevel | 2 |
| GuruStatus | `gs.GuruStatusName` | DWH_dbo.Dim_GuruStatus (always non-null here: GuruStatusID IN (5,6)) | 2 |
| Regulation | `c.Name` | DWH_dbo.Dim_Regulation | 2 |
| NOP | `SUM(p.NOP)` | BI_DB_dbo.BI_DB_PositionPnL | 2 |
| Count_Fails | `COUNT(*)` of PI fail records | CopyFromLake.PositionFailReal_History_PositionFail_DWH | 2 |
| TotalCommission | Date-attribution CASE on FullCommissionOnClose/FullCommissionByUnits | DWH_dbo.Dim_Position | 2 |
| Success_Positions | `COUNT(*)` WHERE OpenDateID=@DateID OR CloseDateID=@DateID | DWH_dbo.Dim_Position | 2 |
| Ratio | `Count_Fails / Success_Positions` | Computed | 2 |
| UpdateDate | `GETDATE()` | System timestamp | 2 |

### Parallel Tables Written by Same SP

```
Dealing_dbo.SP_CommissionsAndFails_PerCID
    ├── Dealing_dbo.Dealing_CIDs_CommissionsAndFails         (all customers, TOP 20)
    ├── Dealing_dbo.Dealing_CIDs_CommissionsAndFails_PIs     ← THIS TABLE (PI only, TOP 20)
    ├── Dealing_dbo.Dealing_FailReasons                      (all fail reasons × HedgeServerID)
    ├── Dealing_dbo.Dealing_FailReasons_Top20                (fail reasons for top-20 non-PI CIDs)
    ├── Dealing_dbo.Dealing_FailReasons_Top20_PIs            (fail reasons for top-20 PI CIDs)
    ├── Dealing_dbo.Dealing_PlayerLevel_Data                 (commission/NOP/fails by PlayerLevel)
    ├── Dealing_dbo.Dealing_PlayerLevel_Fails                (fail reasons by PlayerLevel)
    └── Dealing_dbo.Dealing_PlayerLevel_Data_PIs             (PI variant of PlayerLevel_Data)
    └── Dealing_dbo.Dealing_PlayerLevel_Fails_PIs            (PI variant of PlayerLevel_Fails)
```
