# Lineage: Dealing_dbo.Dealing_MIMO_Zero

## Source Tables
| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_DepositWithdrawFee | Deposit/withdrawal transactions (AmountUSD, Amount, ExchangeRate) |
| DWH_dbo.Dim_Currency | Currency list (CurrencyTypeID=1, excludes crypto) |
| DWH_dbo.Dim_Instrument | Maps currency to FX instrument pair |
| DWH_dbo.Dim_GetSpreadedPriceUSDConversionRate | EOD/SOD USD conversion rates |
| DWH_dbo.Fact_CurrencyPriceWithSplit | EOD/SOD rates (for SellCurrencyID=1 pairs) |
| Dealing_dbo.Dealing_MIMO_Zero (self) | Previous day for rolling sum |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | Parameter | `@Date` |
| CurrencyID | Dim_Currency.CurrencyID | Direct |
| Currency_Name | Dim_Currency.Abbreviation | Direct |
| Deposits | BI_DB_DepositWithdrawFee.AmountUSD | `SUM(CASE WHEN TransactionType='Deposit' THEN AmountUSD)` |
| Withdraws | BI_DB_DepositWithdrawFee.AmountUSD | `ABS(SUM(CASE WHEN TransactionType='Withdraw' THEN AmountUSD))` |
| Net | Derived | `Deposits + Withdraws` (withdrawals negative in source) |
| AvgRateWithdraws | BI_DB_DepositWithdrawFee.ExchangeRate | Weighted avg: `SUM(ExchangeRate * weight)` |
| AvgRateDeposits | BI_DB_DepositWithdrawFee.ExchangeRate | Weighted avg |
| RateEndDay | Dim_GetSpreadedPriceUSDConversionRate / Fact_CurrencyPriceWithSplit | Latest rate <= @Date |
| RateStartDay | Same sources | Latest rate <= @DateBefore |
| DailyDepositsZero | Derived | `DepositsInLocalValue * (EODRate - AvgRateDeposits)` |
| DailyWithdrawsZero | Derived | `WithdrawsInLocalValue * (EODRate - AvgRateWithdraws)` |
| DailyNetZero | Derived | `DailyDepositsZero + DailyWithdrawsZero` |
| Net_Rolling_Zero | Self-join | `DailyNetZero + ISNULL(yesterday.Net_Rolling_Zero, 0)` |
| DepositsInLocalValue | BI_DB_DepositWithdrawFee.Amount | `SUM(CASE WHEN TransactionType='Deposit' THEN Amount)` |
| WithdrawsInLocalValue | BI_DB_DepositWithdrawFee.Amount | `ABS(SUM(CASE WHEN TransactionType='Withdraw' THEN Amount))` |
| NetInLocalValue | Derived | `DepositsInLocalValue + WithdrawsInLocalValue` |

## No Generic Pipeline Mapping
This table is not in the generic pipeline mapping.
