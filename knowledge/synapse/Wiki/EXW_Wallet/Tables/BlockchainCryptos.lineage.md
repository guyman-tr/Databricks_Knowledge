# EXW_Wallet.BlockchainCryptos — Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Database | Notes |
|---|--------------|------------|--------------|----------|-------|
| 1 | Wallet.BlockchainCryptos | Table | Direct copy via Generic Pipeline (CopyFromLake) | WalletDB | Production source — all 5 business columns are passthrough |
| 2 | Dictionary.CryptoCoinProviders | Table | FK target | WalletDB | CryptoCoinProviderId resolves to provider name |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|--------------|-----------|------|
| 1 | Id | Wallet.BlockchainCryptos | Id | Passthrough | Tier 1 |
| 2 | Name | Wallet.BlockchainCryptos | Name | Passthrough | Tier 1 |
| 3 | Occurred | Wallet.BlockchainCryptos | Occurred | Passthrough | Tier 1 |
| 4 | CryptoCoinProviderId | Wallet.BlockchainCryptos | CryptoCoinProviderId | Passthrough | Tier 1 |
| 5 | AddressPattern | Wallet.BlockchainCryptos | AddressPattern | Passthrough | Tier 1 |
| 6 | etr_y | Generic Pipeline | — | ETL partition column (extraction year) | Tier 2 |
| 7 | etr_ym | Generic Pipeline | — | ETL partition column (extraction year-month) | Tier 2 |
| 8 | etr_ymd | Generic Pipeline | — | ETL partition column (extraction year-month-day) | Tier 2 |
| 9 | SynapseUpdateDate | Generic Pipeline | — | GETDATE() at Synapse load time | Tier 2 |
