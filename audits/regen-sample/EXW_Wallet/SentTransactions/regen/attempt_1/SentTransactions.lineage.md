# EXW_Wallet.SentTransactions — Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Notes |
|---|---|---|---|---|
| 1 | WalletDB.Wallet.SentTransactions | Production Table | Generic Pipeline (Append, hourly) | Primary production source; bronze copy |
| 2 | EXW_Dictionary.TransactionTypes | Synapse Dictionary | FK lookup (TransactionTypeId) | Transaction type resolution |
| 3 | EXW_Wallet.CryptoTypes | Synapse Lookup | FK lookup (CryptoId) | Cryptocurrency type resolution |
| 4 | EXW_Wallet.SentTransactionOutputs | Synapse Table | Child detail (SentTransactionId → Id) | Output details per sent transaction |
| 5 | EXW_Wallet.SentTransactionStatuses | Synapse Table | Child detail (SentTransactionId → Id) | Status history per sent transaction |
| 6 | EXW_Wallet.Redemptions | Synapse Table | Correlation link (SendRequestCorrelationId → CorrelationId) | Redeem flow linkage |

## Column Lineage

| Synapse Column | Production Source | Source Column | Transform | Tier |
|---|---|---|---|---|
| Id | WalletDB.Wallet.SentTransactions | Id | Passthrough | Tier 3 |
| BlockchainTransactionId | WalletDB.Wallet.SentTransactions | BlockchainTransactionId | Passthrough | Tier 3 |
| WalletId | WalletDB.Wallet.SentTransactions | WalletId | Passthrough | Tier 3 |
| Occurred | WalletDB.Wallet.SentTransactions | Occurred | Passthrough | Tier 3 |
| CorrelationId | WalletDB.Wallet.SentTransactions | CorrelationId | Passthrough | Tier 3 |
| TransactionTypeId | WalletDB.Wallet.SentTransactions | TransactionTypeId | Passthrough | Tier 3 |
| BlockchainFee | WalletDB.Wallet.SentTransactions | BlockchainFee | Passthrough | Tier 3 |
| CryptoId | WalletDB.Wallet.SentTransactions | CryptoId | Passthrough | Tier 3 |
| etr_y | Generic Pipeline | — | ETL-generated partition column (year) | Tier 2 |
| etr_ym | Generic Pipeline | — | ETL-generated partition column (year-month) | Tier 2 |
| etr_ymd | Generic Pipeline | — | ETL-generated partition column (year-month-day) | Tier 2 |
| SynapseUpdateDate | Generic Pipeline | — | ETL-generated load timestamp | Tier 2 |
| partition_date | Generic Pipeline | — | ETL-generated partition date | Tier 2 |
