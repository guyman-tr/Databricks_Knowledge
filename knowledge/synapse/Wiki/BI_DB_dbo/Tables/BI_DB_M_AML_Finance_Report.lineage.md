# Column Lineage: BI_DB_dbo.BI_DB_M_AML_Finance_Report

## Writer SP
`BI_DB_dbo.SP_M_AML_Finance_Report`

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Alias rename. Filtered: IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3 |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID. Filtered: NOT IN (3=NFA, 5=BVI, 6=eToroUS) |
| Country | DWH_dbo.Dim_Country | Name | JOIN on DWHCountryID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on PlayerStatusID. Filtered to IN (1=Normal, 5=Warning) |
| Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID |
| Equity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL(vl.Liabilities,0) + ISNULL(vl.ActualNWA,0). LEFT JOIN on CID + DateID |
| EOM | (computed) | @EndOfMonth | SP parameter capped to EOMONTH(GETDATE(),-1). End-of-month reporting date |
| UpdateDate | (computed) | GETDATE() | ETL metadata timestamp |
| Last_Login | DWH_dbo.Fact_CustomerAction | DateID | MAX(fca.DateID) WHERE ActionTypeID=14 (LoggedIn). Integer YYYYMMDD format |

## Source Objects
- `DWH_dbo.Fact_SnapshotCustomer` — customer snapshot with status, regulation, country, player level
- `DWH_dbo.Dim_Range` — date range for snapshot partitioning
- `DWH_dbo.Dim_PlayerStatus` — PlayerStatusID → Name lookup (1=Normal, 5=Warning)
- `DWH_dbo.Dim_Regulation` — DWHRegulationID → Name lookup (excludes NFA, BVI, eToroUS)
- `DWH_dbo.Dim_Country` — DWHCountryID → Name lookup
- `DWH_dbo.Dim_PlayerLevel` — PlayerLevelID → Name lookup (club tier)
- `DWH_dbo.Dim_Customer` — JOIN on RealCID (used for population filter)
- `DWH_dbo.V_Liabilities` — view providing Liabilities + ActualNWA for equity calculation
- `DWH_dbo.Fact_CustomerAction` — customer actions, filtered to ActionTypeID=14 (LoggedIn)
- `BI_DB_dbo.BI_DB_DDR_CID_Level` — DDR CID-level metrics, filtered to Funded_New_Def=1
