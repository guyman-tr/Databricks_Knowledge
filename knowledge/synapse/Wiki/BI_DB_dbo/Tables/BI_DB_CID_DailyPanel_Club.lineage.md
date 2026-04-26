# BI_DB_dbo.BI_DB_CID_DailyPanel_Club — Lineage

## ETL Pipeline

```
BI_DB_ClubChangeLogProduct (tier change events, most-recent per CID)
  + DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer, RegulationID, IsProCustomer, AccountManagerID)
  + DWH_dbo.Dim_Range (date range filter: FromDateID <= @ddINT <= ToDateID)
  + DWH_dbo.Dim_Customer (FTDDate, GCID)
  + DWH_dbo.Dim_Country (CountryID)
  + DWH_dbo.Dim_PlayerLevel (tier name→sort mapping, tier equity bounds)
  + DWH_dbo.V_Liabilities (RealizedEquity, Equity, RealizedEquityNoCFD)
  + BI_DB_DepositWithdrawFee (daily MIMO amounts and fees by transaction type)
  + DWH_dbo.Fact_BillingWithdraw (actual cashout fees paid)
  + BI_DB_DailyCommisionReport (Revenue post-2023-08-23)
  + DWH_dbo.Fact_CustomerAction (Revenue/InvestedAmount pre-2023-08-23 only)
  + BI_DB_Daily_CreditLine (credit line amounts and status)
  + eMoney_dbo.CustomerEODBalance (eMoneyBalance via GCID)
  + External_MoneyFarm_CID_DailyPanelClub (Moneyfarm investment via external table)
  + External_Interest_Trade_InterestConsent (IOB opt-in consent via external table)
  + External_Interest_Trade_InterestDaily_CID_DailyPanelClub (DailyCalculationInterest)
  + BI_DB_UsageTracking_SF (LastContacted via Phone_Call_Succeed__c / Completed_Contact_Email__c)
  -> SP_CID_DailyPanel_Club(@Date) — DELETE WHERE DateID = @ddINT + INSERT
  -> BI_DB_dbo.BI_DB_CID_DailyPanel_Club
```

**Orchestration**: OpsDB ProcessName=SB_Daily, Priority=0 (base layer, no intra-schema dependencies), Frequency=Daily.

## Source → Target Column Mapping

| Target Column | Source Object | Source Column / Expression | Tier |
|--------------|---------------|----------------------------|------|
| DateID | Computed | CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT) | T2 |
| Date | Parameter | @Date (YYYYMMDD) | T2 |
| CID | BI_DB_ClubChangeLogProduct | CID (most-recent-row-per-CID via ROW_NUMBER OVER CID ORDER BY Date DESC) | T2 |
| TierChangeDate | BI_DB_ClubChangeLogProduct | Date (last tier-change date) | T2 |
| TierChangeType | BI_DB_ClubChangeLogProduct | PLChangeType (Upgrade / Downgrade / First Club / FirstClub) | T2 |
| IsUpgrade | Computed | 1 IF TierChangeDate=@Date AND TierChangeType IN ('Upgrade','First Club') AND NewLevel>1 | T2 |
| IsDowngrade | Computed | 1 IF TierChangeDate=@Date AND TierChangeType='Downgrade' | T2 |
| CurrentTier | BI_DB_ClubChangeLogProduct | CurrentTier → Dim_PlayerLevel.PlayerLevelID | T2 |
| LastTier | BI_DB_ClubChangeLogProduct | OldTier (PlayerLevelID of prior tier before last change) | T2 |
| MaxTier | BI_DB_ClubChangeLogProduct + Dim_PlayerLevel | MAX(CurrentSort) OVER (PARTITION BY CID) → Dim_PlayerLevel.PlayerLevelID via Sort | T2 |
| CountryID | DWH_dbo.Dim_Country | CountryID (via Fact_SnapshotCustomer.CountryID join) | T2 |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | T2 |
| IsProCustomer | DWH_dbo.Fact_SnapshotCustomer | CASE WHEN MifidCategorizationID IN (2,3) THEN 1 ELSE 0 END | T2 |
| Classification | Computed | NULL (deprecated since 2022-01-03 — cluster removed) | T2 |
| FTDDate | DWH_dbo.Dim_Customer | FirstDepositDate | T2 |
| FTCDate | BI_DB_ClubChangeLogProduct | Date WHERE IsFTC=1 (first-ever promotion above Bronze) | T2 |
| IsFTC | BI_DB_ClubChangeLogProduct | IsFTC (1=first promotion above Bronze) | T2 |
| DaysTillFTC | Computed | DATEDIFF(DAY, FTDDate, FTCDate) | T2 |
| DaysFromFTD | Computed | DATEDIFF(DAY, FTDDate, @Date) | T2 |
| DaysInClub | Computed | DATEDIFF(DAY, FTCDate, @Date) | T2 |
| DaysInCurrentClub | Computed | DATEDIFF(DAY, TierChangeDate, @Date) | T2 |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity WHERE DateID=@ddINT | T2 |
| Equity | DWH_dbo.V_Liabilities | ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) | T2 |
| Revenue | BI_DB_DailyCommisionReport (post-2023-08-23) | SUM(RollOverFee + FullCommissions) | T2 |
| Revenue | DWH_dbo.Fact_CustomerAction (pre-2023-08-23) | FullOpenCommission + FullTotalCommissionOnClose + RollOverFee | T2 |
| InvestedAmount | DWH_dbo.Fact_CustomerAction (pre-2023-08-23) | -1 * SUM(Amount) WHERE ActionTypeID IN (1,2,3,39) | T2 |
| InvestedAmount | DWH_dbo.Fact_CustomerAction (post 2023-01-01) | SUM(MoneyIn) WHERE ActionTypeID IN (1,15,17) | T2 |
| IsFundedCurrentTier | Computed | 1 IF RealizedEquityClub BETWEEN tier LowerBound AND UpperBound | T2 |
| IsFunded | Computed | 1 IF Equity > 25 | T2 |
| AmountToUpgrade | Computed | NextTierUpperBound - RealizedEquityClub (0 for Diamond) | T2 |
| AmountToRemain | Computed | TierLowerBound - RealizedEquityClub (if below LowerBound, else 0) | T2 |
| IsExpectedDowngrade | Computed | Hardcoded 0 (external table logic commented out) | T2 |
| ExpectedDowngradePlayerLevelID | Computed | Hardcoded 0 (deprecated) | T2 |
| IsOptInInterest | External_Interest_Trade_InterestConsent | CASE WHEN ConsentStatusID=1 THEN 1 ELSE 0 END | T2 |
| OptInDate | External_Interest_Trade_InterestConsent | ValidFrom (most recent consent record) | T2 |
| DepositAmount | BI_DB_DepositWithdrawFee | SUM(AmountUSD) WHERE TransactionType='Deposit' | T2 |
| DepositTransactions | BI_DB_DepositWithdrawFee | COUNT(DISTINCT DepositWithdrawID) WHERE TransactionType='Deposit' | T2 |
| DepositAmountWireTransfer | BI_DB_DepositWithdrawFee | SUM(AmountUSD) WHERE PaymentMethod='WireTransfer' AND Deposit | T2 |
| DepositWireTransferTransactions | BI_DB_DepositWithdrawFee | COUNT(DISTINCT DepositWithdrawID) WHERE WireTransfer AND Deposit | T2 |
| DepositConversionFee | BI_DB_DepositWithdrawFee | SUM((BaseExchangeRate-ExchangeRate)*Amount) WHERE Deposit | T2 |
| DepositConversionFeeExemption | BI_DB_DepositWithdrawFee | SUM(0.0025*Amount) WHERE WireTransfer AND Club IN (Platinum,'Platinum Plus') OR 0.005 WHERE Diamond | T2 |
| WithdrawAmount | BI_DB_DepositWithdrawFee | SUM(-1*AmountUSD) WHERE TransactionType='Withdraw' | T2 |
| WithdrawAmountWireTransfer | BI_DB_DepositWithdrawFee | SUM(-1*AmountUSD) WHERE WireTransfer AND Withdraw | T2 |
| WithdrawTransactions | BI_DB_DepositWithdrawFee | COUNT(DISTINCT DepositWithdrawID) WHERE Withdraw | T2 |
| WithdrawWireTransferTransactions | BI_DB_DepositWithdrawFee | COUNT(DISTINCT DepositWithdrawID) WHERE WireTransfer AND Withdraw | T2 |
| WithdrawAmountWallet | BI_DB_DepositWithdrawFee | SUM(-1*AmountUSD) WHERE PaymentMethod='eToroCryptoWallet' AND Withdraw | T2 |
| WithdrawWalletTransactions | BI_DB_DepositWithdrawFee | COUNT(DISTINCT DepositWithdrawID) WHERE eToroCryptoWallet AND Withdraw | T2 |
| WithdrawConversionFee | BI_DB_DepositWithdrawFee | SUM((BaseExchangeRate-ExchangeRate)*Amount) WHERE Withdraw | T2 |
| WithdrawConversionFeeExemption | BI_DB_DepositWithdrawFee | WireTransfer fee exemption for Platinum/PP/Diamond on withdrawals | T2 |
| CashoutFeeExemption | BI_DB_DepositWithdrawFee | Withdrawals * PotentialFee (5 or 25 USD) WHERE PlayerLevelID IN (2,6,7) | T2 |
| CashoutFeePaid | DWH_dbo.Fact_BillingWithdraw | MAX(Fee) per WithdrawID (actual billing fee) | T2 |
| TotalCLAmount | BI_DB_Daily_CreditLine | TotalCLAmount WHERE RealCID=CID AND DateID=@ddINT | T2 |
| DailyFee | BI_DB_Daily_CreditLine | DailyFee | T2 |
| IsOpenCreditLine | BI_DB_Daily_CreditLine | 1 IF DateReceive IS NOT NULL | T2 |
| IsClosedCreditLine | BI_DB_Daily_CreditLine | 1 IF DateDeduct IS NOT NULL AND TotalCLAmount <= 0 | T2 |
| IsCreditLineCustomer | BI_DB_Daily_CreditLine | 1 IF TotalCLAmount > 0 | T2 |
| IsCreditEligible | Computed | 1 IF Equity >= 10000 AND RegulationID=1 AND Dim_PlayerLevel.Sort > 1 | T2 |
| DailyCalculationInterest | External_Interest_Trade_InterestDaily_CID_DailyPanelClub | DailyInterest | T2 |
| MonthlyInterestPayments | Computed | Hardcoded 0 (deprecated) | T2 |
| UpdateDate | Computed | GETDATE() | T2 |
| ExpectedDowngradeDate | Computed | Hardcoded '1900-01-01' (external table logic commented out) | T2 |
| ExpectedDowngradeTierLT | Computed | Hardcoded 0 (deprecated) | T2 |
| AccountManagerID | DWH_dbo.Fact_SnapshotCustomer | AccountManagerID | T2 |
| RealizedEquityNoCFD | DWH_dbo.V_Liabilities | TotalRealStocks + TotalRealCrypto + TotalCash | T2 |
| Moneyfarm | External_MoneyFarm_CID_DailyPanelClub | SUM(CalculatedAmountInUSD) GROUP BY GCID | T2 |
| eMoneyBalance | eMoney_dbo.CustomerEODBalance | ISNULL(EODBalanceAmount_USD,0) (most recent by GCID, DateId <= @ddINT) | T2 |
| RealizedEquityClub | Computed | RealizedEquityNoCFD + eMoneyBalance + Moneyfarm | T2 |
| ExpectedDowngradeStartDate | Computed | Hardcoded '1900-01-01' (external table logic commented out) | T2 |
| LastContacted | BI_DB_UsageTracking_SF | MAX(CreatedDate_SF) WHERE ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c') | T2 |

## Branch Logic Note

The SP contains three branched INSERT blocks controlled by `@Date`:
- **`@Date < '2023-01-01'`**: Revenue from `Fact_CustomerAction` (trading commissions + rollover); no Moneyfarm/eMoneyBalance; `IsFundedCurrentTier` based on `RealizedEquity` vs tier bounds.
- **`'2023-01-01' <= @Date < '2023-08-23'`**: Revenue from `BI_DB_DailyCommisionReport`; adds Moneyfarm (external), eMoneyBalance; `IsFundedCurrentTier` based on `RealizedEquityClub` (non-CFD + Moneyfarm + eMoney) vs tier bounds; adds IOB opt-in (external).
- **`@Date >= '2023-08-23'` (current)**: Same as middle branch. Adds `IsOptInInterest`/`OptInDate` from external consent table and `DailyCalculationInterest` from external interest daily table.

For all historical dates, the active branch at load time determines which columns were populated.
