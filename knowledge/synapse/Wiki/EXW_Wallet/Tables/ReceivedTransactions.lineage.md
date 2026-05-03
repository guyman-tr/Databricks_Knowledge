# Lineage: EXW_Wallet.ReceivedTransactions

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship | Notes |
|---|---|---|---|---|---|---|
| 1 | WalletDB.Wallet.ReceivedTransactions | Production Table | Wallet | WalletDB | CopyFromLake (Append, 60 min) | Primary production source. No upstream wiki available. |
| 2 | EXW_Dictionary.ReceivedTransactionTypes | Dictionary | EXW_Dictionary | Synapse DWH | FK lookup | ReceivedTransactionTypeId → Id. 8 values. |
| 3 | EXW_Wallet.CryptoTypes | Dimension | EXW_Wallet | Synapse DWH | FK lookup | CryptoId → CryptoID. 128+ crypto assets. |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.ReceivedTransactions | Id | Passthrough (CopyFromLake) | Tier 3 |
| 2 | Occurred | WalletDB.Wallet.ReceivedTransactions | Occurred | Passthrough (CopyFromLake) | Tier 3 |
| 3 | WalletId | WalletDB.Wallet.ReceivedTransactions | WalletId | Passthrough (CopyFromLake) | Tier 3 |
| 4 | SenderAddress | WalletDB.Wallet.ReceivedTransactions | SenderAddress | Passthrough (CopyFromLake) | Tier 3 |
| 5 | ReceiverAddress | WalletDB.Wallet.ReceivedTransactions | ReceiverAddress | Passthrough (CopyFromLake) | Tier 3 |
| 6 | Amount | WalletDB.Wallet.ReceivedTransactions | Amount | Passthrough (CopyFromLake) | Tier 3 |
| 7 | BlockchainFee | WalletDB.Wallet.ReceivedTransactions | BlockchainFee | Passthrough (CopyFromLake) | Tier 3 |
| 8 | CorrelationId | WalletDB.Wallet.ReceivedTransactions | CorrelationId | Passthrough (CopyFromLake) | Tier 3 |
| 9 | BlockchainTransactionId | WalletDB.Wallet.ReceivedTransactions | BlockchainTransactionId | Passthrough (CopyFromLake) | Tier 3 |
| 10 | BlockchainTransactionDate | WalletDB.Wallet.ReceivedTransactions | BlockchainTransactionDate | Passthrough (CopyFromLake) | Tier 3 |
| 11 | CryptoId | WalletDB.Wallet.ReceivedTransactions | CryptoId | Passthrough (CopyFromLake) | Tier 3 |
| 12 | ReceivedTransactionTypeId | WalletDB.Wallet.ReceivedTransactions | ReceivedTransactionTypeId | Passthrough (CopyFromLake) | Tier 3 |
| 13 | NormalizedSenderAddress | WalletDB.Wallet.ReceivedTransactions | NormalizedSenderAddress | Passthrough (CopyFromLake) | Tier 3 |
| 14 | NormalizedReceiverAddress | WalletDB.Wallet.ReceivedTransactions | NormalizedReceiverAddress | Passthrough (CopyFromLake) | Tier 3 |
| 15 | ProviderTransactionId | WalletDB.Wallet.ReceivedTransactions | ProviderTransactionId | Passthrough (CopyFromLake) | Tier 3 |
| 16 | etr_y | Generic Pipeline | — | ETL partition metadata: year | Tier 2 |
| 17 | etr_ym | Generic Pipeline | — | ETL partition metadata: year-month | Tier 2 |
| 18 | etr_ymd | Generic Pipeline | — | ETL partition metadata: year-month-day | Tier 2 |
| 19 | SynapseUpdateDate | Generic Pipeline | — | GETDATE() at CopyFromLake load time | Tier 2 |
| 20 | partition_date | Generic Pipeline | — | Date-based partition key from source Occurred | Tier 2 |
| 21 | ReceiveRequestCorrelationId | WalletDB.Wallet.ReceivedTransactions | ReceiveRequestCorrelationId | Passthrough (CopyFromLake) | Tier 3 |
