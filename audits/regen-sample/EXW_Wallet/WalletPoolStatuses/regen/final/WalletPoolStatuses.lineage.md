# Lineage: EXW_Wallet.WalletPoolStatuses

## Source Objects

| # | Source Object | Source Type | Relationship | Schema | Database |
|---|---|---|---|---|---|
| 1 | WalletDB.Wallet.WalletPoolStatuses | Production Table | Direct source (Generic Pipeline Append) | Wallet | WalletDB |
| 2 | CopyFromLake_staging.EXW_Wallet.WalletPoolStatuses | Staging Table | CopyFromLake staging relay | CopyFromLake_staging | Synapse |
| 3 | CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses | Dictionary Table | Status name lookup (reader SPs) | CopyFromLake | Synapse |
| 4 | EXW_Wallet.WalletPool | Sibling Table | FK target for WalletPoolId (reader SPs) | EXW_Wallet | Synapse |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.WalletPoolStatuses | Id | Passthrough | Tier 3 |
| 2 | WalletPoolId | WalletDB.Wallet.WalletPoolStatuses | WalletPoolId | Passthrough | Tier 3 |
| 3 | WalletPoolStatusId | WalletDB.Wallet.WalletPoolStatuses | WalletPoolStatusId | Passthrough | Tier 3 |
| 4 | Occurred | WalletDB.Wallet.WalletPoolStatuses | Occurred | Passthrough | Tier 3 |
| 5 | PromotionTagId | WalletDB.Wallet.WalletPoolStatuses | PromotionTagId | Passthrough | Tier 3 |
| 6 | CorrelationId | WalletDB.Wallet.WalletPoolStatuses | CorrelationId | Passthrough | Tier 3 |
| 7 | Processed | WalletDB.Wallet.WalletPoolStatuses | Processed | Passthrough | Tier 3 |
| 8 | CryptoId | WalletDB.Wallet.WalletPoolStatuses | CryptoId | Passthrough | Tier 3 |
| 9 | etr_y | Generic Pipeline | — | ETL partition year | Tier 3 |
| 10 | etr_ym | Generic Pipeline | — | ETL partition year-month | Tier 3 |
| 11 | etr_ymd | Generic Pipeline | — | ETL partition year-month-day | Tier 3 |
| 12 | SynapseUpdateDate | Generic Pipeline | — | Synapse load timestamp | Tier 3 |
| 13 | partition_date | Generic Pipeline | — | Physical partition date | Tier 3 |
