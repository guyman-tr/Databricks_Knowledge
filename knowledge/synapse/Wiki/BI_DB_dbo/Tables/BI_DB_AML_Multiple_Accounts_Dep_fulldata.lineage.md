# Column Lineage: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep_fulldata

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep_fulldata` |
| **UC Target** | Not_Migrated |
| **Primary Source** | `DWH_dbo.Dim_Customer` (one row per CID in any BI_DB_AML_Multiple_Accounts_Dep FundingID group) |
| **ETL SP** | `SP_AML_Multiple_Accounts` (@Date parameter, on-demand / not in OpsDB standard schedule) |
| **Secondary Sources** | `BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep` (driving FundingID set), `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_PlayerStatus`, `DWH_dbo.Dim_PlayerLevel`, `DWH_dbo.Dim_EvMatchStatus`, `DWH_dbo.V_Liabilities` (at @DateID), `External_AlertServiceDB_*` (latest alert per CID via ROW_NUMBER) |
| **Generated** | 2026-04-23 |

## Lineage Chain

```
BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep   [FundingID population]
    │  JOIN Fact_BillingDeposit → get all CIDs sharing those FundingIDs
    │
    ├── JOIN DWH_dbo.Dim_Customer dc
    │     → core customer identity & demographics
    │
    ├── JOIN DWH_dbo.Dim_Regulation dr
    │     → Regulation name
    │
    ├── JOIN DWH_dbo.Dim_Country dc1
    │     → Country name
    │
    ├── JOIN DWH_dbo.Dim_PlayerStatus dps
    │     → PlayerStatus, PlayerStatusReason, PlayerStatusSubReasonName
    │
    ├── JOIN DWH_dbo.Dim_PlayerLevel dpl
    │     → Club name
    │
    ├── LEFT JOIN DWH_dbo.Dim_EvMatchStatus dems
    │     → EvMatchStatusName
    │
    ├── LEFT JOIN DWH_dbo.V_Liabilities (at @DateID)
    │     → Liabilities, RealizedEquity, PositionPnL, TotalEquity
    │
    ├── LEFT JOIN External_AlertServiceDB_* (ROW_NUMBER per CID, latest alert)
    │     → AlertID, CreationDate, ModificationDate, AlertType,
    │        AlertTypeDescription, CategoryName, TriggerType, StatusType, StatusReason
    │
    └─ SP_AML_Multiple_Accounts (Step 13)
        ├─ TRUNCATE TABLE target
        └─ INSERT → BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep_fulldata
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
| FundingID | DWH_dbo.Fact_BillingDeposit | FundingID | passthrough | The FundingID from the Dep table that this CID belongs to | Links back to BI_DB_AML_Multiple_Accounts_Dep |
| CID | DWH_dbo.Dim_Customer | RealCID | rename | `dc.RealCID AS CID` | eToro customer Real account ID |
| GCID | DWH_dbo.Dim_Customer | GCID | passthrough | `dc.GCID` | Global customer ID |
| UserName | DWH_dbo.Dim_Customer | UserName | passthrough | `dc.UserName` | eToro username |
| BirthDate | DWH_dbo.Dim_Customer | BirthDate | passthrough | `dc.BirthDate` | Customer date of birth |
| PhoneVerifiedName | DWH_dbo.Dim_Customer | PhoneVerifiedName | passthrough | `dc.PhoneVerifiedName` | Phone-verified display name |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | passthrough | `dc.RegisteredReal` | Real account registration date |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | passthrough | `dc.FirstDepositDate` | Date of first deposit |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough | `dc.VerificationLevelID` | KYC level: 2=Verified, 3=Enhanced |
| Country | DWH_dbo.Dim_Country | Name | join-enriched | `dc1.Name` via `Dim_Customer.CountryID = dc1.DWHCountryID` | Customer country of residence |
| Regulation | DWH_dbo.Dim_Regulation | Name | join-enriched | `dr.Name` via `Dim_Customer.RegulationID = dr.DWHRegulationID` | Regulatory jurisdiction |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | join-enriched | `dps.Name` via PlayerStatusID | Account restriction state |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatus | Reason | join-enriched | `dps.Reason` via PlayerStatusID | Reason for current PlayerStatus |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatus | SubReasonName | join-enriched | `dps.SubReasonName` via PlayerStatusID | Sub-reason for current PlayerStatus |
| Club | DWH_dbo.Dim_PlayerLevel | Name | join-enriched | `dpl.Name` via `Dim_Customer.PlayerLevelID = dpl.PlayerLevelID` | eToro Club loyalty tier |
| AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | passthrough | `dc.AffiliateID` | Affiliate/referring partner ID |
| City | DWH_dbo.Dim_Customer | City | passthrough | `dc.City` | Customer city of residence |
| Zip | DWH_dbo.Dim_Customer | Zip | passthrough | `dc.Zip` | Postal code |
| BuildingNumber | DWH_dbo.Dim_Customer | BuildingNumber | passthrough | `dc.BuildingNumber` | Address building number |
| Gender | DWH_dbo.Dim_Customer | Gender | passthrough | `dc.Gender` | Customer gender |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | join-enriched | `dems.EvMatchStatusName` via `Dim_Customer.EvMatchStatus = dems.EvMatchStatusID` | Electronic Verification match result |
| HasWallet | DWH_dbo.Dim_Customer | HasWallet | passthrough | `dc.HasWallet` | Whether customer has eToro Wallet |
| AccountProgram | DWH_dbo.Dim_Customer | AccountProgram | passthrough | `dc.AccountProgram` | Account program classification |
| Liabilities | DWH_dbo.V_Liabilities | Liabilities | join-enriched | Via CID at @DateID | Total customer liabilities at report date |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | join-enriched | Via CID at @DateID | Realized equity value at report date |
| PositionPnL | DWH_dbo.V_Liabilities | PositionPnL | join-enriched | Via CID at @DateID | Open position profit & loss at report date |
| TotalEquity | DWH_dbo.V_Liabilities | TotalEquity | join-enriched | Via CID at @DateID | Total equity (Liabilities + PositionPnL) at report date |
| AlertID | External_AlertServiceDB | AlertID | join-enriched | Latest alert per CID (ROW_NUMBER OVER PARTITION BY CID ORDER BY ModificationDate DESC = 1) | Most recent alert identifier from Alert Service |
| CreationDate | External_AlertServiceDB | CreationDate | join-enriched | From latest alert per CID | When the alert was first created |
| ModificationDate | External_AlertServiceDB | ModificationDate | join-enriched | From latest alert per CID | When the alert was last modified |
| AlertType | External_AlertServiceDB | AlertType | join-enriched | From latest alert per CID | Alert classification type |
| AlertTypeDescription | External_AlertServiceDB | AlertTypeDescription | join-enriched | From latest alert per CID | Human-readable description of alert type |
| CategoryName | External_AlertServiceDB | CategoryName | join-enriched | From latest alert per CID | Alert category (KYC, Risk, AML, eToroMoney, etc.) |
| TriggerType | External_AlertServiceDB | TriggerType | join-enriched | From latest alert per CID | What triggered the alert |
| StatusType | External_AlertServiceDB | StatusType | join-enriched | From latest alert per CID | Alert resolution status (Active/Clear/Follow Up) |
| StatusReason | External_AlertServiceDB | StatusReason | join-enriched | From latest alert per CID | Reason for current alert status |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 16 |
| **Rename** | 1 |
| **Join-enriched** | 20 |
| **ETL-computed** | 1 |
| **Total** | 38 |
