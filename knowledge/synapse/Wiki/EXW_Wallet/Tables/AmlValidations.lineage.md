# EXW_Wallet.AmlValidations — Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Schema | Database |
|---|--------------|-------------|--------------|--------|----------|
| 1 | WalletDB.Wallet.AmlValidations | Production Table | Direct source (Generic Pipeline bronze import) | Wallet | WalletDB |
| 2 | EXW_Wallet_tmp.AmlValidations_tmp | Staging Table | Generic Pipeline staging relay | EXW_Wallet_tmp | Synapse |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|---------------|---------------|-----------|------|
| 1 | Id | WalletDB.Wallet.AmlValidations | Id | Passthrough | Tier 3 |
| 2 | AmlProviderId | WalletDB.Wallet.AmlValidations | AmlProviderId | Passthrough | Tier 3 |
| 3 | IsSend | WalletDB.Wallet.AmlValidations | IsSend | Passthrough | Tier 3 |
| 4 | Address | WalletDB.Wallet.AmlValidations | Address | Passthrough | Tier 3 |
| 5 | WalletId | WalletDB.Wallet.AmlValidations | WalletId | Passthrough | Tier 3 |
| 6 | Amount | WalletDB.Wallet.AmlValidations | Amount | Passthrough | Tier 3 |
| 7 | ProviderStatus | WalletDB.Wallet.AmlValidations | ProviderStatus | Passthrough | Tier 3 |
| 8 | IsPositiveDecision | WalletDB.Wallet.AmlValidations | IsPositiveDecision | Passthrough | Tier 3 |
| 9 | CorrelationId | WalletDB.Wallet.AmlValidations | CorrelationId | Passthrough | Tier 3 |
| 10 | Created | WalletDB.Wallet.AmlValidations | Created | Passthrough | Tier 3 |
| 11 | BlockchainTransactionId | WalletDB.Wallet.AmlValidations | BlockchainTransactionId | Passthrough | Tier 3 |
| 12 | DetailsJson | WalletDB.Wallet.AmlValidations | DetailsJson | Passthrough | Tier 3 |
| 13 | CryptoId | WalletDB.Wallet.AmlValidations | CryptoId | Passthrough | Tier 3 |
| 14 | etr_y | Generic Pipeline | — | ETL-added partition column (year) | Tier 2 |
| 15 | etr_ym | Generic Pipeline | — | ETL-added partition column (year-month) | Tier 2 |
| 16 | etr_ymd | Generic Pipeline | — | ETL-added partition column (year-month-day) | Tier 2 |
| 17 | SynapseUpdateDate | Generic Pipeline | — | ETL-added Synapse ingestion timestamp | Tier 2 |
| 18 | partition_date | Generic Pipeline | — | ETL-added partition date | Tier 2 |
| 19 | CategoryId | WalletDB.Wallet.AmlValidations | CategoryId | Passthrough | Tier 3 |
