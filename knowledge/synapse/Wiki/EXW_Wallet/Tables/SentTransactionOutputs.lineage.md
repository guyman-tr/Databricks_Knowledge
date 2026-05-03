# EXW_Wallet.SentTransactionOutputs — Column Lineage

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|---|---|---|---|---|
| 1 | WalletDB.Wallet.SentTransactionOutputs | Table | Wallet | WalletDB | Production source (Generic Pipeline, Append) |
| 2 | EXW_Wallet.SentTransactions | Table | EXW_Wallet | Synapse | Joined in EXW_TransactionsView and reader SPs on SentTransactionId |
| 3 | EXW_Wallet.Redemptions | Table | EXW_Wallet | Synapse | Joined in SP_EXW_FactRedeemTransactions on SourceId = PositionId |
| 4 | EXW_Wallet.EXW_TransactionsView | View | EXW_Wallet | Synapse | Downstream consumer — unified wallet transactions view |
| 5 | EXW_dbo.SP_EXW_FactRedeemTransactions | Stored Procedure | EXW_dbo | Synapse | Reader — builds EXW_FactRedeemTransactions |
| 6 | EXW_dbo.SP_EXW_C2F_E2E | Stored Procedure | EXW_dbo | Synapse | Reader — crypto-to-fiat end-to-end |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.SentTransactionOutputs | Id | Passthrough (Generic Pipeline) | Tier 3 |
| 2 | SentTransactionId | WalletDB.Wallet.SentTransactionOutputs | SentTransactionId | Passthrough (Generic Pipeline) | Tier 3 |
| 3 | ToAddress | WalletDB.Wallet.SentTransactionOutputs | ToAddress | Passthrough (Generic Pipeline) | Tier 3 |
| 4 | Amount | WalletDB.Wallet.SentTransactionOutputs | Amount | Passthrough (Generic Pipeline) | Tier 3 |
| 5 | EtoroFees | WalletDB.Wallet.SentTransactionOutputs | EtoroFees | Passthrough (Generic Pipeline) | Tier 3 |
| 6 | BlockchainFees | WalletDB.Wallet.SentTransactionOutputs | BlockchainFees | Passthrough (Generic Pipeline) | Tier 3 |
| 7 | SourceId | WalletDB.Wallet.SentTransactionOutputs | SourceId | Passthrough (Generic Pipeline) | Tier 3 |
| 8 | SourceIdType | WalletDB.Wallet.SentTransactionOutputs | SourceIdType | Passthrough (Generic Pipeline) | Tier 3 |
| 9 | Occurred | WalletDB.Wallet.SentTransactionOutputs | Occurred | Passthrough (Generic Pipeline) | Tier 3 |
| 10 | IsEtoroFee | WalletDB.Wallet.SentTransactionOutputs | IsEtoroFee | Passthrough (Generic Pipeline) | Tier 3 |
| 11 | NormalizedToAddress | WalletDB.Wallet.SentTransactionOutputs | NormalizedToAddress | Passthrough (Generic Pipeline) | Tier 3 |
| 12 | etr_y | Generic Pipeline | — | ETL-added partition column: year extracted from Occurred | Tier 2 |
| 13 | etr_ym | Generic Pipeline | — | ETL-added partition column: year-month extracted from Occurred | Tier 2 |
| 14 | etr_ymd | Generic Pipeline | — | ETL-added partition column: year-month-day extracted from Occurred | Tier 2 |
| 15 | SynapseUpdateDate | Generic Pipeline | — | ETL-added: timestamp of last Synapse ingestion | Tier 2 |
| 16 | partition_date | Generic Pipeline | — | ETL-added: date partition key, indexed (NCI) | Tier 2 |
