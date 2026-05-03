# EXW_Wallet.Redemptions — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Database | Schema | Notes |
|---|---|---|---|---|---|---|
| 1 | WalletDB.Wallet.Redemptions | Production Table | Generic Pipeline (Override, daily) | WalletDB | Wallet | Primary production source. No upstream wiki available. |
| 2 | EXW_Wallet.CryptoTypes | Synapse Lookup Table | FK lookup (CryptoId) | Synapse | EXW_Wallet | Cryptocurrency reference table. Used by downstream SP only. |
| 3 | EXW_Wallet.Requests | Synapse Table | Downstream JOIN | Synapse | EXW_Wallet | Joined in SP_EXW_FactRedeemTransactions via CorrelationId = SendRequestCorrelationId. |
| 4 | EXW_Wallet.SentTransactions | Synapse Table | Downstream JOIN | Synapse | EXW_Wallet | Joined in SP_EXW_FactRedeemTransactions via CorrelationId = SendRequestCorrelationId. |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.Redemptions | Id | Passthrough (Generic Pipeline) | Tier 3 |
| 2 | OriginalRequestGuid | WalletDB.Wallet.Redemptions | OriginalRequestGuid | Passthrough (Generic Pipeline) | Tier 3 |
| 3 | SendRequestCorrelationId | WalletDB.Wallet.Redemptions | SendRequestCorrelationId | Passthrough (Generic Pipeline) | Tier 3 |
| 4 | PositionId | WalletDB.Wallet.Redemptions | PositionId | Passthrough (Generic Pipeline) | Tier 3 |
| 5 | RequestingGcid | WalletDB.Wallet.Redemptions | RequestingGcid | Passthrough (Generic Pipeline) | Tier 3 |
| 6 | CryptoId | WalletDB.Wallet.Redemptions | CryptoId | Passthrough (Generic Pipeline) | Tier 3 |
| 7 | RequestedAmount | WalletDB.Wallet.Redemptions | RequestedAmount | Passthrough (Generic Pipeline) | Tier 3 |
| 8 | eToroFeeAmount | WalletDB.Wallet.Redemptions | eToroFeeAmount | Passthrough (Generic Pipeline) | Tier 3 |
| 9 | RedemptionStatus | WalletDB.Wallet.Redemptions | RedemptionStatus | Passthrough (Generic Pipeline) | Tier 3 |
| 10 | BillingTransId | WalletDB.Wallet.Redemptions | BillingTransId | Passthrough (Generic Pipeline) | Tier 3 |
| 11 | BillingRedeemId | WalletDB.Wallet.Redemptions | BillingRedeemId | Passthrough (Generic Pipeline) | Tier 3 |
| 12 | BeginDate | WalletDB.Wallet.Redemptions | BeginDate | Passthrough (Generic Pipeline) | Tier 3 |
| 13 | EndDate | WalletDB.Wallet.Redemptions | EndDate | Passthrough (Generic Pipeline) | Tier 3 |
| 14 | EstimatedBlockchainFee | WalletDB.Wallet.Redemptions | EstimatedBlockchainFee | Passthrough (Generic Pipeline) | Tier 3 |
| 15 | InitialFeeAmount | WalletDB.Wallet.Redemptions | InitialFeeAmount | Passthrough (Generic Pipeline) | Tier 3 |
| 16 | SourceWalletId | WalletDB.Wallet.Redemptions | SourceWalletId | Passthrough (Generic Pipeline) | Tier 3 |
| 17 | TransactionTypeId | WalletDB.Wallet.Redemptions | TransactionTypeId | Passthrough (Generic Pipeline) | Tier 3 |
| 18 | etr_y | Generic Pipeline | — | ETL-generated year partition string | Tier 2 |
| 19 | etr_ym | Generic Pipeline | — | ETL-generated year-month partition string | Tier 2 |
| 20 | etr_ymd | Generic Pipeline | — | ETL-generated year-month-day partition string | Tier 2 |
| 21 | SynapseUpdateDate | Generic Pipeline | — | ETL-generated Synapse refresh timestamp | Tier 2 |
| 22 | partition_date | Generic Pipeline | — | ETL-generated partition date column | Tier 2 |
