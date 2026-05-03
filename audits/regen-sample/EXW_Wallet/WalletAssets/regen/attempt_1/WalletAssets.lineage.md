# Lineage: EXW_Wallet.WalletAssets

## Source Objects

| # | Source Object | Source Type | Database | Schema | Relationship | Evidence |
|---|---|---|---|---|---|---|
| 1 | WalletDB.Wallet.WalletAssets | Production Table | WalletDB | Wallet | Generic Pipeline (Append) | Generic Pipeline mapping #651 |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier | Confidence Reason |
|---|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.WalletAssets | Id | Passthrough | Tier 3 | No upstream wiki available; grounded in DDL + live data |
| 2 | WalletId | WalletDB.Wallet.WalletAssets | WalletId | Passthrough | Tier 3 | No upstream wiki available; grounded in DDL + live data |
| 3 | CryptoId | WalletDB.Wallet.WalletAssets | CryptoId | Passthrough | Tier 3 | No upstream wiki available; grounded in DDL + live data |
| 4 | Occurred | WalletDB.Wallet.WalletAssets | Occurred | Passthrough | Tier 3 | No upstream wiki available; grounded in DDL + live data |
| 5 | etr_y | WalletDB.Wallet.WalletAssets | etr_y | Passthrough (ETL partition) | Tier 3 | No upstream wiki available; ETL partition column derived from Occurred year |
| 6 | etr_ym | WalletDB.Wallet.WalletAssets | etr_ym | Passthrough (ETL partition) | Tier 3 | No upstream wiki available; ETL partition column derived from Occurred year-month |
| 7 | etr_ymd | WalletDB.Wallet.WalletAssets | etr_ymd | Passthrough (ETL partition) | Tier 3 | No upstream wiki available; ETL partition column derived from Occurred year-month-day |
| 8 | SynapseUpdateDate | — | — | ETL-injected | Tier 3 | No upstream wiki available; Synapse load timestamp |
| 9 | partition_date | WalletDB.Wallet.WalletAssets | partition_date | Passthrough | Tier 3 | No upstream wiki available; grounded in DDL + live data |
| 10 | IsShown | WalletDB.Wallet.WalletAssets | IsShown | Passthrough | Tier 3 | No upstream wiki available; grounded in DDL + live data |
