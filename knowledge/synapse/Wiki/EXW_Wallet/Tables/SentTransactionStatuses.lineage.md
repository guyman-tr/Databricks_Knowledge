# Lineage — EXW_Wallet.SentTransactionStatuses

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|---------------|------|--------|----------|--------------|
| 1 | WalletDB.Wallet.SentTransactionStatuses | Table | Wallet | WalletDB | Production source (Generic Pipeline, Append) |
| 2 | WalletDB_Dictionary_TransactionStatus | Dictionary | Dictionary | WalletDB | StatusId lookup (via CopyFromLake) |
| 3 | EXW_Wallet.SentTransactions | Table | EXW_Wallet | Synapse | Parent table (SentTransactionId FK) |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|---------------|---------------|-----------|------|
| 1 | Id | WalletDB.Wallet.SentTransactionStatuses | Id | Passthrough | Tier 3 |
| 2 | SentTransactionId | WalletDB.Wallet.SentTransactionStatuses | SentTransactionId | Passthrough | Tier 3 |
| 3 | StatusId | WalletDB.Wallet.SentTransactionStatuses | StatusId | Passthrough | Tier 3 |
| 4 | Occurred | WalletDB.Wallet.SentTransactionStatuses | Occurred | Passthrough | Tier 3 |
| 5 | etr_y | Generic Pipeline | Occurred | YEAR extract for partitioning | Tier 2 |
| 6 | etr_ym | Generic Pipeline | Occurred | YYYY-MM extract for partitioning | Tier 2 |
| 7 | etr_ymd | Generic Pipeline | Occurred | YYYY-MM-DD extract for partitioning | Tier 2 |
| 8 | SynapseUpdateDate | Generic Pipeline | — | GETDATE() at load time | Tier 2 |
| 9 | partition_date | Generic Pipeline | Occurred | DATE partition key | Tier 2 |
