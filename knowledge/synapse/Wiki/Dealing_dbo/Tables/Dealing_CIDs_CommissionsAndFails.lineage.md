---
object: Dealing_CIDs_CommissionsAndFails
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_CIDs_CommissionsAndFails

Source SP: `Dealing_dbo.SP_CommissionsAndFails_PerCID`

### Column-Level Lineage

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `@Date` parameter | SP parameter | 2 |
| CID | `cd.CID` from #Commissions_Data (TOP 20 by TotalCommission) | DWH_dbo.Dim_Position | 1 |
| UserName | `b.UserName` | DWH_dbo.Dim_Customer | 1 |
| Region | `dc.Region` | DWH_dbo.Dim_Country (via Dim_Customer.CountryID) | 2 |
| PlayerLevelID | `b.PlayerLevelID` | DWH_dbo.Dim_Customer | 1 |
| PlayerLevel | `pl.Name` | DWH_dbo.Dim_PlayerLevel | 2 |
| GuruStatus | `gs.GuruStatusName` | DWH_dbo.Dim_GuruStatus | 2 |
| Regulation | `c.Name` | DWH_dbo.Dim_Regulation | 2 |
| NOP | `SUM(p.NOP)` from BI_DB_PositionPnL at @DateID | BI_DB_dbo.BI_DB_PositionPnL | 2 |
| Count_Fails | `COUNT(*)` of fail records | CopyFromLake.PositionFailReal_History_PositionFail_DWH | 2 |
| TotalCommission | CASE date-attribution: OpenDateID vs CloseDateID vs @DateID → FullCommissionOnClose / FullCommissionByUnits | DWH_dbo.Dim_Position | 2 |
| Success_Positions | `COUNT(*)` WHERE OpenDateID=@DateID OR CloseDateID=@DateID | DWH_dbo.Dim_Position | 2 |
| Ratio | `Count_Fails / Success_Positions` (FULL OUTER JOIN result) | Computed | 2 |
| UpdateDate | `GETDATE()` | System timestamp | 2 |

### Pipeline Flow

```
DWH_dbo.Dim_Position  (commissions, dates)
    + DWH_dbo.Dim_Customer  (UserName, PlayerLevelID, GuruStatusID, CountryID, RegulationID)
    + DWH_dbo.Dim_Instrument  (InstrumentName, InstrumentType)
    + DWH_dbo.Dim_Country  (Region)
    + DWH_dbo.Dim_PlayerLevel  (PlayerLevel text)
    + DWH_dbo.Dim_GuruStatus  (GuruStatus text)
    + DWH_dbo.Dim_Regulation  (Regulation text)
    │
    ▼  #Positions (all open positions on @Date)
    ▼  #Commission (TotalCommission per position via date-attribution)
    ▼  #Add_NOP (+ NOP from BI_DB_PositionPnL)
    ▼  #TotalData_CommissionNOP (GROUP BY CID → sum NOP, commission, count)

CopyFromLake.PositionFailReal_History_PositionFail_DWH
    + Dealing_staging.External_Etoro_Dictionary_FailType
    │
    ▼  #Fails → #Merge_Fails (standardize FailReason text)
    ▼  #TotalData_Fails (GROUP BY CID → COUNT fails)

FULL OUTER JOIN on CID → TOP 20 by TotalCommission → #Commissions_Data
    │
    ▼
Dealing_dbo.Dealing_CIDs_CommissionsAndFails
```

### Notes
- CID is Tier 1 (upstream wiki: Customer.CustomerStatic PK).
- UserName is Tier 1 (upstream wiki: Customer.CustomerStatic).
- PlayerLevelID is Tier 1 (upstream wiki: Customer.CustomerStatic).
- All other columns are Tier 2 from SP_CommissionsAndFails_PerCID code analysis.
