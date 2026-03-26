# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform — Column Lineage

> Source-to-target column mapping from `SP_DDR_Fact_MIMO_Trading_Platform`.

## Sources

| Source | Type | Role |
|--------|------|------|
| DWH_dbo.Fact_CustomerAction | Table (DWH) | Primary — deposit/withdraw events |
| DWH_dbo.Fact_BillingDeposit | Table (DWH) | Deposit original currency, funding type, recurring flag |
| DWH_dbo.Fact_BillingWithdraw | Table (DWH) | Withdraw original currency, funding type |
| DWH_dbo.Dim_Currency | Table (DWH) | Currency abbreviation |
| DWH_dbo.Dim_Customer | Table (DWH) | FTD transaction ID for FTD flag recovery |
| BI_DB_dbo.BI_DB_DepositWithdrawFee | Table (BI_DB) | Alternative withdraw amount source |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DateID | SP parameter | @dateID | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | ETL-computed |
| Date | SP parameter | @date | passthrough | |
| RealCID | Fact_CustomerAction | RealCID | passthrough | |
| MIMOAction | SP logic | — | 'Deposit' for ActionTypeID 7/44, 'Withdraw' for 8/45 | ETL-computed |
| OrigIdentifier | SP logic | — | 'DepositID' for deposits, 'WithdrawPaymentID' for withdraws | ETL-computed |
| TransactionID | Fact_CustomerAction | DepositID / WithdrawPaymentID | passthrough | Depends on MIMOAction |
| AmountUSD | Fact_CustomerAction | Amount | passthrough | USD amount |
| AmountOrigCurrency | Fact_BillingDeposit / Fact_BillingWithdraw | Amount / Amount_WithdrawToFunding÷ExchangeRate | passthrough (deposits), COALESCE(BI_DB_DepositWithdrawFee.Amount, ROUND(Amount_WithdrawToFunding/ExchangeRate)) (withdraws) | Original currency |
| FundingTypeID | Fact_BillingDeposit / Fact_BillingWithdraw | FundingTypeID / FundingTypeID_Funding | passthrough | |
| CurrencyID | Fact_BillingDeposit / Fact_BillingWithdraw | CurrencyID / ProcessCurrencyID | passthrough | |
| Currency | Dim_Currency | Abbreviation | rename | Joined via CurrencyID |
| IsFTD | Dim_Customer + post-insert UPDATE | FTDTransactionID = DepositID | CASE + UPDATE recovery | FTD from Dim_Customer; post-insert update for late-arriving FTDs (≥20250901) |
| IsInternalTransfer | Fact_BillingDeposit / Fact_BillingWithdraw | FundingTypeID | CASE WHEN FundingTypeID = 33 THEN 1 ELSE 0 | FundingTypeID 33 = internal |
| IsRedeem | Fact_CustomerAction | IsRedeem | passthrough (withdraws), 0 (deposits) | |
| UpdateDate | SP | GETDATE() | ETL-computed | Load timestamp |
| IsIBANTrade | Fact_CustomerAction | ActionTypeID | CASE WHEN ActionTypeID IN (44,45) THEN 1 ELSE 0 | IBAN sweep deposits/withdraws |
| IsCryptoToFiat | SP hardcoded | 0 | ETL-computed | Always 0 — crypto-to-fiat tracked separately |
| IsRecurring | Fact_BillingDeposit | IsRecurring | ISNULL(IsRecurring, 0) | Deposits only; 0 for withdraws |
| IsIBANQuickTransfer | Fact_CustomerAction | MoveMoneyReasonID | CASE WHEN MoveMoneyReasonID = 6 THEN 1 ELSE 0 | Quick transfer from IBAN |
