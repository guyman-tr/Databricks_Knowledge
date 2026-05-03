# Lineage: EXW_Wallet.Payments

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|--------------|-------------|--------|----------|-------------|
| 1 | Wallet.Payments | Table | Wallet | WalletDB | Direct source via Generic Pipeline (Append) |
| 2 | EXW_Wallet.EXW_TransactionsView | View | EXW_Wallet | Synapse | Downstream consumer — joins Payments on CorrelationId via SentTransactions |
| 3 | EXW_Wallet.PaymentTransactions | Table | EXW_Wallet | Synapse | Child table — PaymentTransactions.PaymentId → Payments.Id |
| 4 | EXW_Wallet.PaymentStatuses | Table | EXW_Wallet | Synapse | Child table — PaymentStatuses.PaymentId → Payments.Id |
| 5 | EXW_Wallet.FiatTypes | Table | EXW_Wallet | Synapse | Lookup — FiatTypes.FiatId resolves FiatId to fiat currency name |
| 6 | EXW_Wallet.CryptoTypes | Table | EXW_Wallet | Synapse | Lookup — CryptoTypes.CryptoID resolves CryptoId to cryptocurrency name |

## Column Lineage

| Synapse Column | Source Column | Source Object | Transform | Tier |
|---------------|--------------|---------------|-----------|------|
| Id | Id | WalletDB.Wallet.Payments | Passthrough (Generic Pipeline) | Tier 3 |
| WalletId | WalletId | WalletDB.Wallet.Payments | Passthrough (Generic Pipeline) | Tier 3 |
| ProviderPaymentId | ProviderPaymentId | WalletDB.Wallet.Payments | Passthrough (Generic Pipeline) | Tier 3 |
| Amount | Amount | WalletDB.Wallet.Payments | Passthrough (Generic Pipeline) | Tier 3 |
| FiatId | FiatId | WalletDB.Wallet.Payments | Passthrough (Generic Pipeline); FK to EXW_Wallet.FiatTypes | Tier 3 |
| CorrelationId | CorrelationId | WalletDB.Wallet.Payments | Passthrough (Generic Pipeline) | Tier 3 |
| Occurred | Occurred | WalletDB.Wallet.Payments | Passthrough (Generic Pipeline) | Tier 3 |
| CryptoId | CryptoId | WalletDB.Wallet.Payments | Passthrough (Generic Pipeline); FK to EXW_Wallet.CryptoTypes | Tier 3 |
| etr_y | — | Generic Pipeline | ETL partition column: year extracted from ingestion date | Tier 2 |
| etr_ym | — | Generic Pipeline | ETL partition column: year-month extracted from ingestion date | Tier 2 |
| etr_ymd | — | Generic Pipeline | ETL partition column: year-month-day extracted from ingestion date | Tier 2 |
