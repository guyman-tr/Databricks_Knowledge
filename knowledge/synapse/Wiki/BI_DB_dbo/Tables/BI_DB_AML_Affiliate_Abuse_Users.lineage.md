# Lineage: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users

## Object
- **Schema**: BI_DB_dbo
- **Object**: BI_DB_AML_Affiliate_Abuse_Users
- **Type**: Table
- **Writer SP**: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)
- **UC Target**: Not_Migrated

## ETL Pipeline
```
DWH_dbo.Dim_Customer (dc)
  JOIN DWH_dbo.Dim_Affiliate (da) ON AffiliateID → SubChannelID filter (20,31,39,40,41,42,44)
  JOIN DWH_dbo.Dim_PlayerStatus, Dim_Regulation, Dim_Country, Dim_PlayerLevel
  LEFT JOIN BI_DB_dbo.BI_DB_First5Actions ON CID
  |-- SP Step 03: #cidlevel (CIDs for activated affiliates, RegisteredReal>=2023) ---|
  v
DWH_dbo.V_Liabilities (DateID=@DateID)
  |-- SP Step 04: #liabilities (equity snapshot) ---|
  v
DWH_dbo.Fact_BillingWithdraw
  |-- SP Step 05: #co_30 (approved CO within 30d of FTD) ---|
DWH_dbo.Fact_BillingDeposit
  |-- SP Step 05: #dep_30 (approved deposit within 30d of FTD) ---|
DWH_dbo.Dim_Position
  |-- SP Step 05: #position30 (distinct positions within 30d of FTD) ---|
  v
#final_CID (all fields merged)
  |-- TRUNCATE + INSERT (SP disabled 2024-12-31) ---|
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users (1,208,122 rows, RegisteredReal>=2023-01-01, frozen 2024-12-31)
```

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | passthrough |
| Channel | DWH_dbo.Dim_Affiliate | Channel | passthrough via JOIN on AffiliateID |
| SubChannel | DWH_dbo.Dim_Affiliate | SubChannel | passthrough via JOIN on AffiliateID |
| CID | DWH_dbo.Dim_Customer | RealCID | passthrough (aliased as CID) |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | passthrough; 1900-01-01 sentinel for non-depositors |
| EOM_FTD | SP computation | FirstDepositDate | EOMONTH(FirstDepositDate) |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | passthrough |
| EOM_Reg | SP computation | RegisteredReal | EOMONTH(RegisteredReal) |
| FirstDepositAmount | DWH_dbo.Dim_Customer | FirstDepositAmount | passthrough |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough |
| IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | passthrough |
| IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | passthrough |
| User_Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()); BirthDate='1900-01-02' sentinel → 0 |
| Gender | DWH_dbo.Dim_Customer | Gender | passthrough |
| IP | DWH_dbo.Dim_Customer | IP | passthrough |
| Country | DWH_dbo.Dim_Country | Name | passthrough via JOIN on CountryID |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | passthrough via JOIN on CountryID |
| Regulation | DWH_dbo.Dim_Regulation | Name | passthrough via DWHRegulationID=RegulationID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | passthrough via PlayerLevelID |
| Is_Blocked | SP computation | Dim_Customer.PlayerStatusID | CASE WHEN NOT IN (1,5) THEN 1 ELSE 0; 1=Active, 5=Warning are unblocked |
| TotalEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | passthrough |
| PositionPnL | DWH_dbo.V_Liabilities | PositionPnL | passthrough |
| Credit | DWH_dbo.V_Liabilities | Credit | passthrough |
| BonusCredit | DWH_dbo.V_Liabilities | BonusCredit | passthrough |
| Is_CO_30 | DWH_dbo.Fact_BillingWithdraw | WithdrawID | 1 if any approved cashout (CashoutStatusID_Funding=3) within 30 days of FTD, else 0 |
| Is_Dep_30 | DWH_dbo.Fact_BillingDeposit | DepositID | 1 if any approved deposit (PaymentStatusID=2) within 30 days of FTD, else 0 |
| Count_Positions_30 | DWH_dbo.Dim_Position | PositionID | COUNT DISTINCT positions opened within 30 days of FTD |
| Is_Open_Trade_30 | SP computation | Count_Positions_30 | CASE Count_Positions_30 ≠ 0 THEN 1 ELSE 0 |
| FirstAction | BI_DB_dbo.BI_DB_First5Actions | FirstAction | passthrough via LEFT JOIN |
| FirstActionDate | BI_DB_dbo.BI_DB_First5Actions | FirstActionDate | passthrough via LEFT JOIN |
| FirstInstrument | BI_DB_dbo.BI_DB_First5Actions | FirstInstrument | passthrough via LEFT JOIN |
| UpdateDate | ETL metadata | — | GETDATE() |

## Source Objects
- `DWH_dbo.Dim_Customer` — primary CID-level attributes (Tier 1 for customer demographics)
- `DWH_dbo.Dim_Affiliate` — channel/subchannel classification and SubChannelID filter
- `DWH_dbo.Dim_Country` — country name and marketing region
- `DWH_dbo.Dim_Regulation` — regulation entity name
- `DWH_dbo.Dim_PlayerLevel` — club/level name (Bronze/Silver/Gold/Platinum/Diamond)
- `DWH_dbo.V_Liabilities` — equity snapshot as of @DateID (2024-12-30)
- `DWH_dbo.Fact_BillingWithdraw` — cashout activity within 30 days of FTD
- `DWH_dbo.Fact_BillingDeposit` — deposit activity within 30 days of FTD
- `DWH_dbo.Dim_Position` — position count within 30 days of FTD
- `BI_DB_dbo.BI_DB_First5Actions` — first trading action details
