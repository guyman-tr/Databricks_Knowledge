---
object: eMoney_Risk_Portfolio
schema: eMoney_dbo
type: Table
lineage_version: 1
generated: "2026-04-20"
---

# Column Lineage — eMoney_Risk_Portfolio

## §1 Source Objects

| Alias | Object | Role |
|-------|--------|------|
| DA | eMoney_dbo.eMoney_Dim_Account | Primary eMoney account eligibility and identifiers (CurrencyBalanceCreateDate <= @Date AND GCID<>0) |
| FCS | External_FiatDwhDB_FiatCurrencyBalancesStatuses | Currency balance status history (ROW_NUMBER by EventTimestamp < @NextDate) |
| FAS | External_FiatDwhDB_FiatAccountStatuses | Account status history (ROW_NUMBER by Created < @NextDate) |
| SCS | External_FiatDwhDB_Dictionary_StatusChangeSources | Status change source display names |
| SCR | External_FiatDwhDB_Dictionary_StatusChangeReasons | Status change reason display names |
| FSC | DWH_dbo.Fact_SnapshotCustomer | Daily customer snapshot (ClubID, CountryID, Regulation, PlayerStatus, etc.) |
| DC | DWH_dbo.Dim_Country | Country display name for KYC_Country |
| DR | DWH_dbo.Dim_Regulation | Regulation display name |
| DPS | DWH_dbo.Dim_PlayerStatus | Player status display name |
| DPL | DWH_dbo.Dim_PlayerLevel | Club/PlayerLevel display name |
| DPR | DWH_dbo.Dim_PlayerStatusReasons | Player status reason display name |
| DPSR | DWH_dbo.Dim_PlayerStatusSubReasons (implicit) | Player status sub-reason display name |
| BD | DWH_dbo.Fact_BillingDeposit | Platform FTD data (IsFTD=1, PaymentStatusID=2) |
| FCA | DWH_dbo.Fact_CustomerAction | Platform deposit totals (ActionTypeID=7, USD→EUR conversion via rate) |
| FCP | DWH_dbo.Fact_CurrencyPriceWithSplit | USD/EUR conversion rate (InstrumentID=2) |
| ETX | eMoney_dbo.eMoney_Dim_Transaction | eMoney transactions (TxStatusID=2) for FTD and turnover |
| EAS | eMoney_dbo.ETL_AccountSnapshot | eMoney settled balance snapshot (MAX date <= @DateID) |
| RCL | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | Trading risk score (TradingRiskScore = RiskScoreName) |
| KYC | BI_DB_dbo.BI_DB_KYC_Panel | Occupation (Q18 answer text) |
| DOC | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | HasProofOfIncome (DocumentTypeID=7 or SuggestedDocumentTypeID=7) |

## §2 ETL Pattern

- Writer SP: `SP_eMoney_Risk_Portfolio`
- Author: Inessa Kontorovich, 2023-11-14
- Lines: 866
- Pattern: WHILE loop daily; watermark = MAX(ReportDate), starting from '20231201'
- Per iteration: `@3MonthsAgo = DATEADD(MONTH,-3,@Date)`, `@NextDate = DATEADD(DAY,1,@Date)`
- DELETE WHERE ReportDate=@Date; INSERT from #final; SET @MaxDate = DATEADD(DAY,1,@MaxDate)
- Eligibility: eMoney_Dim_Account WHERE CurrencyBalanceCreateDate<=@Date AND GCID<>0

## §3 Column-Level Lineage

| # | Column | Source Object | Source Column / Expression | Tier |
|---|--------|--------------|---------------------------|------|
| 1 | RealCID | eMoney_Dim_Account | CID (renamed; same as Customer.CustomerStatic.CID) | Tier 1 |
| 2 | GCID | eMoney_Dim_Account | GCID (passthrough from dbo.FiatAccount) | Tier 1 |
| 3 | FirstName | DWH_dbo.Dim_Customer | FirstName (PII) | Tier 2 |
| 4 | LastName | DWH_dbo.Dim_Customer | LastName (PII) | Tier 2 |
| 5 | Regulation | DWH_dbo.Dim_Regulation | DisplayName (via RegulationID from FSC) | Tier 2 |
| 6 | KYC_Country | DWH_dbo.Dim_Country | DisplayName (via CountryID from FSC) | Tier 2 |
| 7 | Club | DWH_dbo.Dim_PlayerLevel | DisplayName (via PlayerLevelID from FSC) | Tier 2 |
| 8 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | DisplayName (via PlayerStatusID from FSC) | Tier 2 |
| 9 | PlayerStatusID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID (sourced from Customer.CustomerStatic via DWH) | Tier 1 |
| 10 | PlayerLevelID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID (sourced from Customer.CustomerStatic via DWH) | Tier 1 |
| 11 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | StatusReasonName (via PlayerStatusReasonID from FSC) | Tier 2 |
| 12 | PlayerStatusSubReasonName | DWH_dbo (implicit) | Sub-reason display name from Dim_PlayerStatusSubReasons | Tier 2 |
| 13 | VerificationLevelID | DWH_dbo.Dim_Customer or FSC | Verification level; trading-side attribute | Tier 2 |
| 14 | IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer flag | Tier 2 |
| 15 | IsDepositor | DWH_dbo.Fact_BillingDeposit | CASE WHEN PaymentStatusID=2 AND IsFTD=1 THEN 1 (via #mop) | Tier 2 |
| 16 | CitizenshipCountry | DWH_dbo.Dim_Customer | CitizenshipCountry (nationality field) | Tier 2 |
| 17 | POB_Country | DWH_dbo.Dim_Customer | Place of birth country | Tier 2 |
| 18 | ScreeningStatus | DWH_dbo.Dim_Customer or AML system | AML screening status | Tier 4 |
| 19 | RegisteredReal | DWH_dbo.Dim_Customer | Registration datetime (TP registration timestamp) | Tier 2 |
| 20 | PlatformFTD | DWH_dbo.Fact_BillingDeposit | FTD datetime (IsFTD=1, PaymentStatusID=2) | Tier 2 |
| 21 | PlatformFTDUSD | DWH_dbo.Fact_BillingDeposit | FTD amount in USD | Tier 2 |
| 22 | PlatformFTDFundingType | DWH_dbo.Fact_BillingDeposit | FundingType name of first deposit | Tier 2 |
| 23 | EvMatchStatus | DWH_dbo.Dim_Customer | Electronic verification match status (int) | Tier 2 |
| 24 | EvMatch | DWH_dbo.Dim_Customer | Electronic verification match result (varchar) | Tier 2 |
| 25 | AccountSubProgram | eMoney_Dim_Account | Sub-program name (via SubPrograms lookup) | Tier 2 |
| 26 | ProviderHolderID | eMoney_Dim_Account | Provider holder identifier from FiatDwhDB | Tier 2 |
| 27 | ProviderCurrencyBalanceID | eMoney_Dim_Account | Provider-side currency balance ID | Tier 2 |
| 28 | eMoneyAccountCreateDate | eMoney_Dim_Account | CurrencyBalanceCreateDate (date of eMoney account creation) | Tier 2 |
| 29 | CurrencyBalanceID | eMoney_Dim_Account | CurrencyBalanceID (passthrough from dbo.FiatCurrencyBalances) | Tier 1 |
| 30 | CurrencyBalanceCreateDate | eMoney_Dim_Account | CurrencyBalanceCreateDate (same as eMoneyAccountCreateDate; redundant duplicate) | Tier 2 |
| 31 | CurrencyBalanceStatus | #currency_balance_status | Status name at @NextDate (from FiatCurrencyBalancesStatuses → eMoney_Dictionary_CurrencyBalanceStatus) | Tier 2 |
| 32 | AccountStatusID | #account_status | Account status as of @NextDate (ROW_NUMBER by FiatAccountStatuses.Created < @NextDate) | Tier 1 |
| 33 | eMoneyAccountStatus | #account_status | Account status display name (via eMoney_Dictionary_AccountStatus) | Tier 2 |
| 34 | eMoneyAccountStatusDate | #account_status | Date of latest account status change event before @NextDate | Tier 2 |
| 35 | CurrencyBalanceStatusID | #currency_balance_status | Currency balance status code as of @NextDate (0=Active,1=ReceiveOnly,2=SpendOnly,3=Suspended,4=Blocked) | Tier 2 |
| 36 | CurrencyBalanceStatusDate | #currency_balance_status | EventTimestamp of latest currency balance status change before @NextDate | Tier 2 |
| 37 | StatusChangeSourceId | #currency_balance_status | Source ID of the latest CurrencyBalance status change event | Tier 2 |
| 38 | StatusChangeReasonId | #currency_balance_status | Reason ID of the latest CurrencyBalance status change event | Tier 2 |
| 39 | CurrencyBalanceStatusChangeSource | External_FiatDwhDB_Dictionary_StatusChangeSources | Display name for StatusChangeSourceId | Tier 2 |
| 40 | CurrencyBalanceStatusChangeReason | External_FiatDwhDB_Dictionary_StatusChangeReasons | Display name for StatusChangeReasonId | Tier 2 |
| 41 | IsTestAccount | eMoney_Dim_Account | Test account flag from eMoney_google_sheets.emoney_test_users | Tier 2 |
| 42 | PlatformTotalDepositUSD | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=7 (deposit) in USD | Tier 2 |
| 43 | PlatformTotalDepositEUR | DWH_dbo.Fact_CustomerAction | PlatformTotalDepositUSD × USD_EUR_Rate | Tier 2 |
| 44 | USD_EUR_Rate | DWH_dbo.Fact_CurrencyPriceWithSplit | Exchange rate for InstrumentID=2 (USD/EUR) at @Date | Tier 2 |
| 45 | USD_EUR_RateDate | DWH_dbo.Fact_CurrencyPriceWithSplit | Date of the exchange rate used | Tier 2 |
| 46 | HasProofOfIncome | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | 1 if DocumentTypeID=7 or SuggestedDocumentTypeID=7 (proof of income document) | Tier 2 |
| 47 | Occupation | BI_DB_dbo.BI_DB_KYC_Panel | Q18_AnswerText (KYC question 18 = occupation) | Tier 2 |
| 48 | HasAnyTransUpToDate | eMoney_dbo.eMoney_Dim_Transaction | 1 if customer has any eMoney transaction with TxStatusID=2, TxStatusModificationDateID <= @DateID | Tier 2 |
| 49 | HasTrans3MonthsBeforeDate | eMoney_dbo.eMoney_Dim_Transaction | 1 if customer has any eMoney transaction in 3M before @Date (from #eMoneyTXDB) | Tier 2 |
| 50 | eMoneyFTDTxType | eMoney_dbo.eMoney_Dim_Transaction | TxType name of the first settled eMoney transaction (ROW_NUMBER per CurrencyBalanceID by TxStatusModificationTime ASC) | Tier 2 |
| 51 | CountryOneMoneyFTD | eMoney_dbo.eMoney_Dim_Transaction | Country of the eMoney FTD provider/transaction (from #eMoneyFTD) | Tier 4 |
| 52 | eMoneyFTDAmount | eMoney_dbo.eMoney_Dim_Transaction | Amount of first settled eMoney transaction in account currency | Tier 2 |
| 53 | eMoneyFTDDate | eMoney_dbo.eMoney_Dim_Transaction | Date of first settled eMoney transaction (TxStatusModificationTime, ROW_NUMBER=1) | Tier 2 |
| 54 | eMoneyDepositType | eMoney_dbo.eMoney_Dim_Transaction | Inflow type of eMoney FTD: BankingPaymentsIN (TxTypeID=7) or MoneyInFromTP (TxTypeID=5) | Tier 2 |
| 55 | MoneyOutToTP | eMoney_dbo.eMoney_Dim_Transaction | Cumulative amount moved OUT to eToro Trading Platform (TxTypeID=6) up to @Date | Tier 2 |
| 56 | MoneyOutExternal | eMoney_dbo.eMoney_Dim_Transaction | Cumulative amount moved OUT externally (non-TP, non-banking, non-other TxTypes) | Tier 4 |
| 57 | MoneyOutBankingPayments | eMoney_dbo.eMoney_Dim_Transaction | Cumulative amount moved OUT via IBAN / banking payments (TxTypeID=8) up to @Date | Tier 2 |
| 58 | MoneyOutOther | eMoney_dbo.eMoney_Dim_Transaction | Cumulative amount moved OUT through other channels (residual TxTypes) | Tier 4 |
| 59 | MoneyOutTotal | SP computed | MoneyOutToTP + MoneyOutBankingPayments + MoneyOutExternal + MoneyOutOther | Tier 2 |
| 60 | MoneyInFromTP | eMoney_dbo.eMoney_Dim_Transaction | Cumulative amount moved IN from eToro Trading Platform (TxTypeID=5) up to @Date | Tier 2 |
| 61 | MoneyInExternal | eMoney_dbo.eMoney_Dim_Transaction | Cumulative amount moved IN from external sources (non-TP, non-banking, non-other TxTypes) | Tier 4 |
| 62 | MoneyInBankingPayments | eMoney_dbo.eMoney_Dim_Transaction | Cumulative amount moved IN via IBAN / banking payments (TxTypeID=7) up to @Date | Tier 2 |
| 63 | MoneyInOther | eMoney_dbo.eMoney_Dim_Transaction | Cumulative amount moved IN through other channels (residual TxTypes) | Tier 4 |
| 64 | MoneyInTotal | SP computed | MoneyInFromTP + MoneyInBankingPayments + MoneyInExternal + MoneyInOther | Tier 2 |
| 65 | TurnOver | SP computed | MoneyInTotal + MoneyOutTotal — total money movement through the eMoney account up to @Date | Tier 2 |
| 66 | MoneyOutRisk | SP computed | CASE: Low if MoneyOutToTP is dominant channel; Medium if banking/other; NULL if no money-out | Tier 2 |
| 67 | MoneyInRisk | SP computed | CASE: Low if MoneyInFromTP is dominant channel; Medium if banking/other; NULL if no money-in | Tier 2 |
| 68 | MainIn | SP computed | Dominant inflow amount (max of MoneyInFromTP, MoneyInBankingPayments, MoneyInExternal, MoneyInOther) | Tier 2 |
| 69 | TurnOverRisk | SP computed | CASE TurnOver < 50000 → Low; 50000–250000 → Medium; ≥250000 → High; NULL if no transactions | Tier 2 |
| 70 | SettledBalance | eMoney_dbo.ETL_AccountSnapshot | Account settled balance from ETL_AccountSnapshot WHERE DateID = MAX snapshot date ≤ @DateID | Tier 2 |
| 71 | SettledBalanceDate | eMoney_dbo.ETL_AccountSnapshot | Date of the ETL_AccountSnapshot row used for SettledBalance | Tier 2 |
| 72 | TradingRiskScore | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName — trading risk classification from the Risk Classification data lake | Tier 2 |
| 73 | eMoneyRiskScore | SP computed | CASE combining MoneyOutRisk + MoneyInRisk: Low if both Low; High if either High; Medium otherwise | Tier 2 |
| 74 | OverallRiskScore | SP computed | max(eMoneyRiskScore, TradingRiskScore); High takes priority over Medium/Low | Tier 2 |
| 75 | ReportDate | SP loop | @Date loop variable | Tier 2 |
| 76 | ReportDateID | SP computed | CONVERT(int, @Date, 112) — YYYYMMDD integer FK to Dim_Date | Tier 2 |
| 77 | IsEU | eMoney_Dim_Account | CASE WHEN CurrencyBalanceISOCode=978 (EUR) THEN 1 ELSE 0 — Malta entity indicator | Tier 2 |
| 78 | AccountID | eMoney_Dim_Account | AccountID (passthrough from dbo.FiatAccount) | Tier 1 |
| 79 | UpdateDate | SP computed | GETDATE() at SP execution time | Tier 2 |

## §4 Tier 1 Coverage Summary

- Tier 1: 7 columns (RealCID, GCID, CurrencyBalanceID, AccountID, AccountStatusID, PlayerStatusID, PlayerLevelID)
- Tier 2: 67 columns (SP computed, cross-schema passthrough with clear SP trace)
- Tier 4: 5 columns (ScreeningStatus, CountryOneMoneyFTD, MoneyOutExternal, MoneyOutOther, MoneyInExternal, MoneyInOther — source unclear from SP summary)

## §5 UC External Lineage

UC Target: `_Not_Migrated` (eMoney_dbo tables are Synapse-only)
