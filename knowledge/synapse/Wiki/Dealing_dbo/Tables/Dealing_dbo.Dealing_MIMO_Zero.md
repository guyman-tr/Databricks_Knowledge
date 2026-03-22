# Dealing_dbo.Dealing_MIMO_Zero

## 1. Overview
Daily calculation of eToro's implicit FX revenue ("Zero") from client deposits and withdrawals in non-USD currencies. When clients deposit in EUR/GBP/etc., eToro converts at a weighted-average rate; the difference between that rate and the end-of-day rate generates revenue (or loss). This table tracks that revenue per currency per day, including a rolling cumulative total.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (Date ASC) |
| **Row Count** | ~31K |
| **Date Range** | 2023-01-01 → present |
| **Grain** | One row per Date × CurrencyID |
| **Refresh** | Daily, via SP_MIMO_Zero |

## 2. Business Context
MIMO stands for "Money In Money Out" — the system governing deposits and withdrawals. When clients deposit in a non-USD currency, eToro converts to USD at the transaction rate. By end of day, the FX rate may have moved, creating an implicit gain or loss for eToro. This table quantifies that daily P&L per currency and tracks a rolling cumulative sum (`Net_Rolling_Zero`).

**Author**: Adva (created 2023-04-01). Key change by Adar (2023-08-06): corrected DailyNetZero & Net_Rolling_Zero to use `Deposits + Withdraws` instead of `Deposits - Withdraws`.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Business date | T2 | SP_MIMO_Zero: `@Date` parameter |
| CurrencyID | int | Yes | Currency identifier from DWH_dbo.Dim_Currency (CurrencyTypeID=1, excludes crypto 600-610) | T2 | SP_MIMO_Zero: from Dim_Currency |
| Currency_Name | varchar(100) | Yes | Currency abbreviation (e.g., EUR, GBP, AUD) | T2 | SP_MIMO_Zero: `dc.Abbreviation` |
| Deposits | money | Yes | Total deposit amount in USD for this currency on this date. Formula: `SUM(CASE WHEN TransactionType='Deposit' THEN AmountUSD END)` | T2 | SP_MIMO_Zero: from BI_DB_DepositWithdrawFee |
| Withdraws | money | Yes | Total withdrawal amount in USD (stored as positive). Formula: `ABS(SUM(CASE WHEN TransactionType='Withdraw' THEN AmountUSD END))` | T2 | SP_MIMO_Zero |
| Net | money | Yes | Net deposits minus withdrawals in USD. Formula: `Deposits + Withdraws` (Withdraws is negative in source, positive after ABS) | T2 | SP_MIMO_Zero |
| AvgRateWithdraws | float | Yes | Weighted-average FX conversion rate for withdrawals. Formula: `SUM(ExchangeRate * AmountUSD/TotalAmountUSD)`. For USD (CurrencyID=1): 1.0 | T2 | SP_MIMO_Zero |
| AvgRateDeposits | float | Yes | Weighted-average FX conversion rate for deposits | T2 | SP_MIMO_Zero |
| RateEndDay | float | Yes | End-of-day FX rate (to USD). Source depends on currency: SellCurrencyID≠1 uses `Dim_GetSpreadedPriceUSDConversionRate`, SellCurrencyID=1 uses `Fact_CurrencyPriceWithSplit.AskSpreaded` | T2 | SP_MIMO_Zero |
| RateStartDay | float | Yes | Start-of-day FX rate (previous day's closing rate). Same source logic as RateEndDay but for @DateBefore | T2 | SP_MIMO_Zero |
| DailyDepositsZero | money | Yes | Daily FX revenue from deposits. Formula: `DepositsInLocalValue * (EODRate - AvgRateDeposits)`. Positive = eToro gained from rate movement | T2 | SP_MIMO_Zero |
| DailyWithdrawsZero | money | Yes | Daily FX revenue from withdrawals. Formula: `WithdrawsInLocalValue * (EODRate - AvgRateWithdraws)` | T2 | SP_MIMO_Zero |
| DailyNetZero | money | Yes | Combined daily FX revenue. Formula: `DailyDepositsZero + DailyWithdrawsZero` | T2 | SP_MIMO_Zero |
| Net_Rolling_Zero | money | Yes | Cumulative rolling sum of DailyNetZero. Formula: `DailyNetZero + ISNULL(yesterday.Net_Rolling_Zero, 0)` | T2 | SP_MIMO_Zero: self-join to previous day |
| UpdateDate | datetime | Yes | Row write timestamp | T2 | SP_MIMO_Zero: `GETDATE()` |
| DepositsInLocalValue | money | Yes | Total deposit amount in local currency (non-USD). Formula: `SUM(CASE WHEN TransactionType='Deposit' THEN Amount END)` | T2 | SP_MIMO_Zero |
| WithdrawsInLocalValue | money | Yes | Total withdrawal amount in local currency (positive). Formula: `ABS(SUM(CASE WHEN TransactionType='Withdraw' THEN Amount END))` | T2 | SP_MIMO_Zero |
| NetInLocalValue | money | Yes | Net local-currency amount. Formula: `DepositsInLocalValue + WithdrawsInLocalValue` | T2 | SP_MIMO_Zero |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| BI_DB_dbo.BI_DB_DepositWithdrawFee | Deposit/withdrawal transactions | Date, TransactionType IN ('Deposit','Withdraw'), IsValidCustomer=1 |
| DWH_dbo.Dim_Currency | Currency lookup | CurrencyID, CurrencyTypeID=1 |
| DWH_dbo.Dim_Instrument | FX pair identification | BuyCurrencyID=1 or SellCurrencyID matched to currency |
| DWH_dbo.Dim_GetSpreadedPriceUSDConversionRate | EOD/SOD FX rates (non-USD sell currencies) | InstrumentID, DateFrom window |
| DWH_dbo.Fact_CurrencyPriceWithSplit | EOD/SOD FX rates (USD sell currencies) | InstrumentID, OccurredDate |
| Dealing_dbo.Dealing_MIMO_Zero (self) | Previous day | CurrencyID, Date=@DateBefore |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_MIMO_Zero` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | DELETE + INSERT for @Date |
| **Key Logic** | 1) Build currency list from Dim_Currency (exclude crypto 600-610, old abbreviations). 2) Map each currency to its USD FX instrument (inversed or USD convention). 3) Pull deposit/withdraw transactions from BI_DB_DepositWithdrawFee. 4) Calculate weighted-average rates. 5) Get EOD and SOD rates. 6) Compute Zero = LocalValue * (EODRate - AvgRate). 7) Self-join to yesterday for rolling total. 8) Filter: only insert rows where Net_Rolling_Zero≠0 OR CurrencyID=1 (always keep USD). |

## 6. Data Lifecycle
- **Retention**: No automated cleanup
- **Self-referencing**: Uses previous day's data for rolling calculations — gap in dates will break the rolling total

## 7. Known Gaps
- "Zero" naming is confusing — it means "zero explicit fee, but implicit FX revenue" (eToro's internal term)
- The rolling sum depends on sequential daily runs — missing a day will produce incorrect Net_Rolling_Zero

## 8. Quality Score
**8.0/10** — Rich FX revenue logic with clear computation formulas. Self-referencing rolling logic well documented. Business context from Atlassian (MIMO = Money In Money Out) enhances understanding.
