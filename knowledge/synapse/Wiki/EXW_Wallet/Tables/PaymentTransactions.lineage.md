# EXW_Wallet.PaymentTransactions — Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Schema | Database |
|---|--------------|-------------|--------------|--------|----------|
| 1 | Wallet.PaymentTransactions | Table | Generic Pipeline (Append) | Wallet | WalletDB |
| 2 | Wallet.Payments | Table | FK target (PaymentId) | Wallet | WalletDB |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | Id | Wallet.PaymentTransactions | Id | Passthrough | Tier 1 |
| 2 | PaymentId | Wallet.PaymentTransactions | PaymentId | Passthrough | Tier 1 |
| 3 | ExchangeRate | Wallet.PaymentTransactions | ExchangeRate | Passthrough | Tier 1 |
| 4 | ToAddress | Wallet.PaymentTransactions | ToAddress | Passthrough | Tier 1 |
| 5 | Amount | Wallet.PaymentTransactions | Amount | Passthrough | Tier 1 |
| 6 | EtoroFeePercentage | Wallet.PaymentTransactions | EtoroFeePercentage | Passthrough | Tier 1 |
| 7 | EtoroFeeCalculated | Wallet.PaymentTransactions | EtoroFeeCalculated | Passthrough | Tier 1 |
| 8 | ProviderFeePercentage | Wallet.PaymentTransactions | ProviderFeePercentage | Passthrough | Tier 1 |
| 9 | ProviderFeeCalculated | Wallet.PaymentTransactions | ProviderFeeCalculated | Passthrough | Tier 1 |
| 10 | EstimatedBlockChainFee | Wallet.PaymentTransactions | EstimatedBlockChainFee | Passthrough | Tier 1 |
| 11 | Occurred | Wallet.PaymentTransactions | Occurred | Passthrough | Tier 1 |
| 12 | etr_y | Generic Pipeline | - | ETL-added partition column (year) | Tier 2 |
| 13 | etr_ym | Generic Pipeline | - | ETL-added partition column (year-month) | Tier 2 |
| 14 | etr_ymd | Generic Pipeline | - | ETL-added partition column (year-month-day) | Tier 2 |
