# BI_DB_dbo.BI_DB_CopyDailyData — Column Lineage

Generated: 2026-04-23 | Schema: BI_DB_dbo | Object: BI_DB_CopyDailyData

## ETL Chain

```
DWH_dbo.Fact_SnapshotCustomer + DWH_dbo.Dim_Range (PI + Portfolio population as of @date)
  |-- SP_CopyDailyData (@date parameter) ---|
  |   + DWH_dbo.Dim_Customer (UserName, ID, Gender, RegisteredReal, FirstDepositDate, AffiliateID)
  |   + DWH_dbo.Dim_Language (Name → Language)
  |   + DWH_dbo.Dim_Country (Name → Country, Region)
  |   + DWH_dbo.Dim_Manager (FirstName+' '+LastName → Manager)
  |   + DWH_dbo.Dim_GuruStatus (GuruStatusName → PI_Level, PI_Level_Previous)
  |   + DWH_dbo.Dim_PlayerLevel (Name → Club)
  |   + DWH_dbo.Dim_MifidCategorization (Name → MifidCatigorization)
  |   + DWH_dbo.Dim_Fund + DWH_dbo.Dim_FundType (FundTypeName → ProtfoilioType)
  |   + DWH_dbo.V_Liabilities (equity, risk, AUM, credit, positions)
  |   + DWH_dbo.Dim_Mirror + DWH_dbo.Dim_Position (commission calculation)
  |   + DWH_dbo.Fact_CustomerAction (MI, MO, netMI, NewMirror, UnMirror — ActionTypes 15-18)
  |   + DWH_dbo.Fact_SnapshotCustomer (DaysAsPI, DaysInCurrnetStatus via Dim_Range)
  |   + general.etoroGeneral_History_GuruCopiers (NumOfCopiers, CopyAUM, CopyPnL)
  |   + BI_DB_dbo.BI_DB_User_Segment_Snapshot (Acc_RiskIndex)
  |   + BI_DB_dbo.BI_DB_UsageTracking_SF (LastContactDate)
  v
BI_DB_dbo.BI_DB_CopyDailyData (DELETE+INSERT per @date, append-mode history, ROUND_ROBIN)
  |-- Not in Generic Pipeline (no UC target) ---|
  v
UC Target: _Not_Migrated
```

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (via #CopiedPop) | Tier 1 |
| UserName | DWH_dbo.Dim_Customer | UserName | Passthrough | Tier 1 |
| ID | DWH_dbo.Dim_Customer | ID | Passthrough (system GUID) | Tier 1 |
| Language | DWH_dbo.Dim_Language | Name | Passthrough via LanguageID lookup | Tier 1 |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via CountryID lookup | Tier 1 |
| Region | DWH_dbo.Dim_Country | Region | Passthrough via CountryID lookup | Tier 2 |
| Manager | DWH_dbo.Dim_Manager | FirstName+' '+LastName | String concatenation | Tier 2 |
| Gender | DWH_dbo.Dim_Customer | Gender | Passthrough | Tier 1 |
| GuruStatusID | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | Passthrough (via #CopiedPop) | Tier 1 |
| PI_Level | DWH_dbo.Dim_GuruStatus | GuruStatusName | Passthrough via GuruStatusID lookup (today's PI tier name) | Tier 1 |
| MifidCatigorization | DWH_dbo.Dim_MifidCategorization | Name | Passthrough via MifidCategorizationID lookup | Tier 1 |
| Registered | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough (renamed column) | Tier 1 |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough | Tier 2 |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough via PlayerLevelID lookup | Tier 1 |
| CopyType | DWH_dbo.Fact_SnapshotCustomer | AccountTypeID | CASE: AccountTypeID=9→'Portfolio', else→'PI' | Tier 2 |
| ProtfoilioType | DWH_dbo.Dim_FundType | FundTypeName | Passthrough via FundType lookup; NULL for PI accounts | Tier 2 |
| AffiliateAccount | DWH_dbo.Dim_Customer | AffiliateID | Passthrough (renamed column) | Tier 1 |
| Acc_RiskIndex | BI_DB_dbo.BI_DB_User_Segment_Snapshot | RiskIndex | Passthrough as of @date | Tier 2 |
| LastNightRiskScore | DWH_dbo.V_Liabilities | StandardDeviation | CASE 10-band volatility-to-score mapping (1–10); 0 if no match | Tier 2 |
| TotalEquity | DWH_dbo.V_Liabilities | Liabilities, ActualNWA | Liabilities + ActualNWA | Tier 2 |
| CurrenyEquity | DWH_dbo.V_Liabilities | TotalPositionsAmount, PositionPnL | TotalPositionsAmount + PositionPnL (column name is a typo) | Tier 2 |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | Passthrough | Tier 2 |
| TotalPositionsAmount | DWH_dbo.V_Liabilities | TotalPositionsAmount | Passthrough | Tier 2 |
| Credit | DWH_dbo.V_Liabilities | Credit | Passthrough | Tier 2 |
| PI_CopyAUM | DWH_dbo.V_Liabilities | AUM, CopyPositionPnL | AUM + CopyPositionPnL | Tier 2 |
| PI_ManualStocks | DWH_dbo.V_Liabilities | TotalStockManualPosition, ManualStockPositionPnL | TotalStockManualPosition + ManualStockPositionPnL | Tier 2 |
| PI_ManualCrypto | DWH_dbo.V_Liabilities | TotalCryptoManualPosition, ManualCryptoPositionPnL | TotalCryptoManualPosition + ManualCryptoPositionPnL | Tier 2 |
| InProcessCashouts | DWH_dbo.V_Liabilities | InProcessCashouts | Passthrough | Tier 2 |
| NumOfCopiers | general.etoroGeneral_History_GuruCopiers | (count of copier rows) | COUNT(*) of valid depositor copiers as of @date | Tier 2 |
| CopyAUM | general.etoroGeneral_History_GuruCopiers | Cash, Investment, PnL, DetachedPosInvestment, Dit_PnL | ISNULL(SUM(...), 0) | Tier 2 |
| Date | ETL parameter | @date | GETDATE()-1 (prior business day) | Tier 2 |
| DateID | ETL parameter | @date_int | CONVERT(VARCHAR(8), @date, 112) as INT — YYYYMMDD | Tier 2 |
| DaysAsPI | DWH_dbo.Fact_SnapshotCustomer | FullDate (via Dim_Date, Dim_Range) | DATEDIFF(DAY, MIN(FullDate WHERE GuruStatusID>=2), @date) | Tier 2 |
| commission | DWH_dbo.Dim_Position | Commission, FullCommission, CommissionOnClose, FullCommissionOnClose | SUM of open/close/straddle commission since 2011-01-01 to @date via Dim_Mirror+Dim_Position | Tier 2 |
| MI | DWH_dbo.Fact_CustomerAction | Amount (ActionTypeID IN (15,17)) | SUM(-Amount) for money-in and new-copy actions on @date | Tier 2 |
| MO | DWH_dbo.Fact_CustomerAction | Amount (ActionTypeID IN (16,18)) | SUM(Amount) for money-out and stop-copy actions on @date | Tier 2 |
| netMI | DWH_dbo.Fact_CustomerAction | Amount (ActionTypeID IN (15,16,17,18)) | SUM(-Amount) for all mirror flow actions on @date | Tier 2 |
| NewMirror | DWH_dbo.Fact_CustomerAction | (ActionTypeID=17) | COUNT of new copy-start events on @date | Tier 2 |
| UnMirror | DWH_dbo.Fact_CustomerAction | (ActionTypeID=18) | COUNT of copy-stop events on @date | Tier 2 |
| DaysInCurrnetStatus | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID (via Dim_Range) | DATEDIFF from earliest date of current PI tier (column name typo: "Currnet") | Tier 2 |
| UpdateDate | ETL metadata | (none) | GETDATE() | Propagation |
| CopyPnL | general.etoroGeneral_History_GuruCopiers | PnL, DetachedPosInvestment, Dit_PnL | ISNULL(SUM(PnL+DetachedPosInvestment+Dit_PnL), 0) | Tier 2 |
| LastContactDate | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate | Most recent Phone_Call_Succeed__c or Completed_Contact_Email__c by PI's manager; ISNULL→'1900-01-01' | Tier 2 |
| PI_Level_Previous | DWH_dbo.Dim_GuruStatus | GuruStatusName | Yesterday's PI tier name via #CopiedPopYesterday; NULL if PI had no prior status | Tier 2 |

## Source Objects

- `DWH_dbo.Fact_SnapshotCustomer` — PI/Portfolio population filter by date range; DaysAsPI, DaysInCurrnetStatus
- `DWH_dbo.Dim_Range` — date range lookup for Fact_SnapshotCustomer validity window
- `DWH_dbo.Dim_Customer` — customer master attributes
- `DWH_dbo.Dim_Language` — language name lookup
- `DWH_dbo.Dim_Country` — country name and region lookup
- `DWH_dbo.Dim_Manager` — account manager display name
- `DWH_dbo.Dim_GuruStatus` — PI tier names (today and yesterday)
- `DWH_dbo.Dim_PlayerLevel` — Club/PlayerLevel tier names
- `DWH_dbo.Dim_MifidCategorization` — MiFID II classification labels
- `DWH_dbo.Dim_Fund` + `DWH_dbo.Dim_FundType` — Portfolio fund type lookup
- `DWH_dbo.V_Liabilities` — daily equity snapshot (equity, AUM, credit, positions, risk)
- `DWH_dbo.Dim_Mirror` + `DWH_dbo.Dim_Position` — commission calculation inputs
- `DWH_dbo.Fact_CustomerAction` — MIMO daily events (ActionTypes 15-18)
- `general.etoroGeneral_History_GuruCopiers` — copier AUM and count
- `BI_DB_dbo.BI_DB_User_Segment_Snapshot` — account-level risk index
- `BI_DB_dbo.BI_DB_UsageTracking_SF` — Salesforce contact history (last successful PI contact)

## UC External Lineage

UC Target: _Not_Migrated — not in Generic Pipeline mapping
