# Column Lineage: BI_DB_dbo.BI_DB_M_AML_Account_Closed

## Writer SP
`BI_DB_dbo.SP_M_AML_Account_Closed`

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Alias rename. Filtered: IsDepositor=1, VerificationLevelID=3, IsValidCustomer=1 |
| Regualtion | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID = fsc.RegulationID. Note: column name has typo (Regualtion, not Regulation) |
| Country | DWH_dbo.Dim_Country | Name | JOIN on DWHCountryID = fsc.CountryID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID |
| EOM | (computed) | @EndOfMonth | SP parameter: capped to EOMONTH(GETDATE(),-1). End-of-month date for the reporting period |
| Current_PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on PlayerStatusID. Filtered to PlayerStatusID IN (2,4) = Blocked, Blocked Upon Request |
| Previous_PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | LAG(PlayerStatusID,1,0) OVER(PARTITION BY RealCID ORDER BY FromDateID) → last status before current blocking. ROW_NUMBER=1 DESC to get most recent change in the month |
| Change_Date | DWH_dbo.Dim_Range | FromDateID | CONVERT(DATE, CONVERT(CHAR(8), dr.FromDateID)) — date when the player status changed to Blocked/Blocked Upon Request within the month |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | LEFT JOIN on PlayerStatusReasonID. May be NULL |
| AMLComment | general.etoro_History_BackOfficeCustomer | AMLComment | ROW_NUMBER() OVER(PARTITION BY CID ORDER BY ValidFrom DESC) = 1. Latest non-NULL AML comment. LEFT JOIN |
| ValidFrom | general.etoro_History_BackOfficeCustomer | ValidFrom | From same ROW_NUMBER=1 record as AMLComment |
| ValidTo | general.etoro_History_BackOfficeCustomer | ValidTo | From same ROW_NUMBER=1 record as AMLComment |
| UpdateDate | (computed) | GETDATE() | ETL metadata timestamp |
| Is_AML_Reason | (computed) | CASE logic | CASE WHEN PlayerStatusReason IN ('AML','Account Closed','AML Account Closed') THEN 1 ELSE 0. Further filtered: only rows that also have a matching SF case with ActionType LIKE '%AML%' within 30 days of Change_Date (via BI_DB_SF_Cases_Panel) |

## Source Objects
- `DWH_dbo.Fact_SnapshotCustomer` — customer snapshot with PlayerStatusID, RegulationID, CountryID, PlayerLevelID
- `DWH_dbo.Dim_Range` — date range for snapshot partitioning
- `DWH_dbo.Dim_PlayerStatus` — PlayerStatusID → Name lookup (2=Blocked, 4=Blocked Upon Request)
- `DWH_dbo.Dim_Regulation` — DWHRegulationID → Name lookup
- `DWH_dbo.Dim_Country` — DWHCountryID → Name lookup
- `DWH_dbo.Dim_PlayerLevel` — PlayerLevelID → Name lookup (club level)
- `DWH_dbo.Dim_PlayerStatusReasons` — PlayerStatusReasonID → Name lookup
- `BI_DB_dbo.BI_DB_SF_Cases_Panel` — Salesforce cases filtered for AML-type actions within 30 days of blocking
- `general.etoro_History_BackOfficeCustomer` — historical AML comments with validity dates
