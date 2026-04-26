# BI_DB_dbo.BI_DB_Local_Currencies_MIMO — Column Lineage

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| DateID | SP parameter | @DateID | CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT) | Tier 2 |
| Deposit/WD_ID | Fact_BillingDeposit / Fact_BillingWithdraw | DepositID / WithdrawID | Passthrough | Tier 2 |
| Country and Currency | DWH_dbo.Dim_Currency | Name | JOIN on CurrencyID/ProcessCurrencyID | Tier 2 |
| Currency Amount | Fact_BillingDeposit / Fact_BillingWithdraw | Amount / Amount_WithdrawToFunding | Passthrough for deposits; ISNULL(Amount_WithdrawToFunding, Amount_Withdraw) for cashouts | Tier 2 |
| FX Income | SP computed | Amount, BaseExchangeRate, ExchangeRate | Deposits: (Amount * BaseExchangeRate) - (Amount * ExchangeRate). Cashouts: PIPsCalculation * ExchangeRate | Tier 2 |
| FX Cost | SP computed | Amount, BaseExchangeRate | Amount * BaseExchangeRate * 0.008 (0 for selected currencies) | Tier 2 |
| Fee Percentage | SP computed | ExchangeRate, BaseExchangeRate | 1 - (ExchangeRate / BaseExchangeRate). NULL if BaseExchangeRate = 0 | Tier 2 |
| Exchange Rate | Fact_BillingDeposit / BI_DB_DepositWithdrawFee | ExchangeRate | eToro exchange rate with markup | Tier 2 |
| Base Exchange Rate | Fact_BillingDeposit / BI_DB_DepositWithdrawFee | BaseExchangeRate | Mid-market rate (no markup) | Tier 2 |
| Payment Status | DWH_dbo.Dim_PaymentStatus / Dim_CashoutStatus | Name / DWHCashoutStatusID | JOIN lookup | Tier 2 |
| Payment Date | Fact_BillingDeposit / Fact_BillingWithdraw | PaymentDate / RequestDate | CAST to DATE | Tier 2 |
| USD Amount | SP computed | Amount, ExchangeRate | Amount * ExchangeRate | Tier 2 |
| FX Revenue | SP computed | FX Income, FX Cost | FX Income - FX Cost | Tier 2 |
| IND | SP computed | -- | 'Deposits' or 'Cashout' | Tier 2 |
| UpdateDate | SP | GETDATE() | ETL timestamp | Tier 5 |
| Date | SP parameter | @Date | Business date | Tier 2 |
| Provider | DWH_dbo.Dim_BillingDepot | Name | JOIN on DepotID | Tier 2 |

## Source Objects

| Source Object | Role | Schema |
|---------------|------|--------|
| DWH_dbo.Fact_BillingDeposit | Deposit transactions (FundingTypeID=1, non-major currencies) | DWH_dbo |
| DWH_dbo.Fact_BillingWithdraw | Withdrawal transactions (FundingTypeID=1, non-major currencies) | DWH_dbo |
| BI_DB_dbo.BI_DB_DepositWithdrawFee | Withdrawal FX rates (PIPsCalculation, ExchangeRate) | BI_DB_dbo |
| DWH_dbo.Dim_Currency | Currency name lookup | DWH_dbo |
| DWH_dbo.Dim_PaymentStatus | Deposit payment status lookup | DWH_dbo |
| DWH_dbo.Dim_CashoutStatus | Withdrawal cashout status lookup | DWH_dbo |
| DWH_dbo.Dim_BillingDepot | Payment provider name | DWH_dbo |
