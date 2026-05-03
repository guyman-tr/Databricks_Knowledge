# Lineage — EXW_Wallet.ReceivedTransactionStatuses

## Source Objects

| # | Source Object | Source Type | Relationship | Schema |
|---|---|---|---|---|
| 1 | WalletDB.Wallet.ReceivedTransactionStatuses | Production Table | CopyFromLake (Append, daily) | Wallet |
| 2 | EXW_Dictionary.TransactionStatus | Dictionary | Lookup (StatusId → Id) | EXW_Dictionary |
| 3 | EXW_Wallet.ReceivedTransactions | Sibling Table | FK (ReceivedTransactionId → Id) | EXW_Wallet |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.ReceivedTransactionStatuses | Id | Passthrough | Tier 3 |
| 2 | ReceivedTransactionId | WalletDB.Wallet.ReceivedTransactionStatuses | ReceivedTransactionId | Passthrough | Tier 3 |
| 3 | StatusId | WalletDB.Wallet.ReceivedTransactionStatuses | StatusId | Passthrough | Tier 3 |
| 4 | Occurred | WalletDB.Wallet.ReceivedTransactionStatuses | Occurred | Passthrough | Tier 3 |
| 5 | DetailsJson | WalletDB.Wallet.ReceivedTransactionStatuses | DetailsJson | Passthrough | Tier 3 |
| 6 | etr_y | Generic Pipeline | — | ETL year partition from Occurred | Tier 2 |
| 7 | etr_ym | Generic Pipeline | — | ETL year-month partition from Occurred | Tier 2 |
| 8 | etr_ymd | Generic Pipeline | — | ETL year-month-day partition from Occurred | Tier 2 |
| 9 | SynapseUpdateDate | Generic Pipeline | — | GETDATE() at CopyFromLake load | Tier 2 |
| 10 | partition_date | Generic Pipeline | — | Date partition key from Occurred | Tier 2 |
