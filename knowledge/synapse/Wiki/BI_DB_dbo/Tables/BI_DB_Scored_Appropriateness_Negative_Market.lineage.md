# Column Lineage: BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `ComplianceStateDB.Compliance.CustomerRestrictions` + `ComplianceStateDB.Compliance.UserTradingData` (via external tables) |
| **ETL SP** | `SP_BI_DB_Scored_Appropriateness_Negative_Market` |
| **Secondary Sources** | `Dim_Customer`, `Dim_Regulation` (×2), `Dim_Country`, `ComplianceStateDB.History.UserTradingData`, `ComplianceStateDB.Dictionary.RestrictionStatus/Reason/Subreason` |
| **Generated** | 2026-03-28 |

## Lineage Chain

```
ComplianceStateDB.Compliance.CustomerRestrictions (production, since 2020-02-20)
ComplianceStateDB.Compliance.UserTradingData (production)
ComplianceStateDB.History.UserTradingData (production)
    │
    └─ External tables in BI_DB_dbo
        │
        └─ SP_BI_DB_Scored_Appropriateness_Negative_Market @Date
            ├─ CTAS #pop_AT: UNION of CustomerRestrictions (RestrictionStatusReasonID=14) + UserTradingData
            ├─ CTAS #pop_NM_Current: Current CFD restriction from UserTradingData
            ├─ CTAS #pop_NM_History: Historical CFD from History_UserTradingData (ROW_NUMBER latest)
            ├─ CTAS #blockingdata: Merge current + history for block/release dates
            ├─ KYC scoring steps (COMMENTED OUT — all KYC columns hardcoded to -1)
            ├─ CTAS #finaltable: JOIN #pop_AT + Dim_Customer + Dim_Regulation ×2 + Dim_Country + #blockingdata
            ├─ TRUNCATE TABLE target
            └─ INSERT → BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market (17.86M rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| RealCID | DWH_dbo.Dim_Customer (dc) | RealCID | passthrough | Direct: `dc.RealCID` | Customer Real account ID |
| GCID | DWH_dbo.Dim_Customer (dc) | GCID | passthrough | Direct: `dc.GCID` | Global Customer ID. Distribution key |
| IsDepositor | DWH_dbo.Dim_Customer (dc) | IsDepositor | passthrough | Direct: `dc.IsDepositor` | Ever-deposited flag |
| FTD_Date | DWH_dbo.Dim_Customer (dc) | FirstDepositDate | rename | `dc.FirstDepositDate AS FTD_Date` | First time deposit date |
| FTDDateID | — | — | ETL-computed | `CAST(CONVERT(CHAR(8), dc.FirstDepositDate, 112) AS INT)` | YYYYMMDD int of FTD_Date |
| EOW_FTD | — | — | ETL-computed | `DATEADD(dd, -(DATEPART(dw, FirstDepositDate) - 7), FirstDepositDate)` | End of week containing FTD |
| EOM_FTD | — | — | ETL-computed | `EOMONTH(FirstDepositDate)` | End of month containing FTD |
| FTD_Amount | DWH_dbo.Dim_Customer (dc) | FirstDepositAmount | rename | `dc.FirstDepositAmount AS FTD_Amount` | First deposit amount USD |
| RegulationID | DWH_dbo.Dim_Customer (dc) | RegulationID | passthrough | Direct: `dc.RegulationID` | Current regulation tinyint |
| RegulationName | DWH_dbo.Dim_Regulation (dr) | Name | join-enriched | `dr.Name` via `dc.RegulationID = dr.DWHRegulationID` | Current regulation name |
| RegionID | DWH_dbo.Dim_Country (dc1) | MarketingRegionID | rename | `dc1.MarketingRegionID AS RegionID` | Marketing region ID |
| RegionName | DWH_dbo.Dim_Country (dc1) | MarketingRegionManualName | rename | `dc1.MarketingRegionManualName AS RegionName` | Marketing region name |
| CountryID | DWH_dbo.Dim_Customer (dc) | CountryID | passthrough | Direct: `dc.CountryID` | Country of residence |
| CountryName | DWH_dbo.Dim_Country (dc1) | Name | join-enriched | `dc1.Name` via `dc.CountryID = dc1.CountryID` | Country name |
| IsKYC_NM_Trading_Experience | — | — | ETL-computed | Hardcoded `-1` (scoring logic commented out) | VESTIGIAL — always -1 |
| IsKYC_NM_Risk_Factor | — | — | ETL-computed | Hardcoded `-1` (scoring logic commented out) | VESTIGIAL — always -1 |
| IsKYC_NM | — | — | ETL-computed | Hardcoded `-1` (scoring logic commented out) | VESTIGIAL — always -1 |
| AT_Total_Score_KYC | — | — | ETL-computed | Hardcoded `-1` (scoring logic commented out) | VESTIGIAL — always -1 |
| AT_Total_Max_Potential_Score | — | — | ETL-computed | Hardcoded `-1` (scoring logic commented out) | VESTIGIAL — always -1 |
| IsKYC_AT_Passed | — | — | ETL-computed | Hardcoded `-1` (scoring logic commented out) | VESTIGIAL — always -1 |
| RestrictionStatusDesc | #blockingdata → ComplianceStateDB.Dictionary.RestrictionStatus | Name | join-enriched | `ISNULL(utd.RestrictionStatusDesc, 'Passed')` | CFD restriction: Passed/Failed |
| CFD_Status | #blockingdata | CFDRestrictionStatusID | ETL-computed | `CASE WHEN CFDRestrictionStatusID=1 THEN 'CFD_Blocked' ELSE 'CFD_Allowed'` | Derived CFD status |
| BlockDate | #blockingdata → ComplianceStateDB.UserTradingData | BeginTime | ETL-computed | Block: current.ReasonDate if StatusID=1; history.ReasonDateHistory if StatusID=2 | When CFD was blocked |
| BlockReasonID | #blockingdata → ComplianceStateDB.Dictionary.RestrictionStatusReason | RestrictionStatusReasonID | ETL-computed | From current or history depending on CFDRestrictionStatusID | Block reason FK |
| BlockReasonDesc | #blockingdata → ComplianceStateDB.Dictionary.RestrictionStatusReason | Name | join-enriched | From current or history ReasonDesc | Block reason name |
| ReleaseDate | #blockingdata → ComplianceStateDB.UserTradingData | BeginTime | ETL-computed | Only populated when CFDRestrictionStatusID=2 (released) | When CFD block was released |
| ReleaseReasonID | #blockingdata → ComplianceStateDB.Dictionary.RestrictionStatusReason | RestrictionStatusReasonID | ETL-computed | Only when CFDRestrictionStatusID=2 | Release reason FK |
| ReleaseReasonDesc | #blockingdata → ComplianceStateDB.Dictionary.RestrictionStatusReason | Name | join-enriched | Only when CFDRestrictionStatusID=2 | Release reason name |
| DateDiffBlockRelease | — | — | ETL-computed | `DATEDIFF(d, BlockDate, ReleaseDate)` | Days between block and release |
| AT_Date | ComplianceStateDB.Compliance.CustomerRestrictions | BeginTime | rename | `CR.BeginTime AS AT_Date` | Appropriateness test date |
| ApproprietnessScore_Status | ComplianceStateDB.Dictionary.RestrictionStatus | Name | join-enriched | `p.RestrictionStatus` via #pop_AT (filtered to RestrictionStatusReasonID=14) | Appropriateness test outcome |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |
| DesignatedRegulationName | DWH_dbo.Dim_Regulation (dr1) | Name | join-enriched | `dr1.Name` via `dc.DesignatedRegulationID = dr1.DWHRegulationID` | Designated (target) regulation |
| BlockSubReasonID | #blockingdata → ComplianceStateDB.Dictionary.RestrictionStatusSubreason | RestrictionStatusSubreasonID | rename | `utd.RestrictionStatusSubreasonID AS BlockSubReasonID` | Block sub-reason FK |
| BlockSubReasonDesc | #blockingdata → ComplianceStateDB.Dictionary.RestrictionStatusSubreason | Name | rename | `utd.RestrictionStatusSubreason AS BlockSubReasonDesc` | Block sub-reason name |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 5 |
| **Rename** | 7 |
| **Join-enriched** | 9 |
| **ETL-computed** | 14 |
| **Total** | 35 |
