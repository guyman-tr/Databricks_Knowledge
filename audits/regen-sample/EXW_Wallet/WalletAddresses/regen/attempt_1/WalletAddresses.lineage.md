# EXW_Wallet.WalletAddresses — Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Documentation |
|---|---|---|---|---|
| 1 | WalletDB.Wallet.WalletAddresses | Production Table | Primary source via Generic Pipeline (CopyFromLake) | No upstream wiki |
| 2 | CopyFromLake_staging.EXW_Wallet.WalletAddresses | Staging Table | Intermediate landing table for Generic Pipeline | SSDT DDL only |
| 3 | Generic Pipeline (id=717) | ETL Framework | Append strategy, 120-min frequency, parquet format | _generic_pipeline_mapping.json |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.WalletAddresses | Id | Passthrough | Tier 3 |
| 2 | WalletId | WalletDB.Wallet.WalletAddresses | WalletId | Passthrough | Tier 3 |
| 3 | Address | WalletDB.Wallet.WalletAddresses | Address | Passthrough | Tier 3 |
| 4 | IsMain | WalletDB.Wallet.WalletAddresses | IsMain | Passthrough | Tier 3 |
| 5 | BlockchainProviderWalletId | WalletDB.Wallet.WalletAddresses | BlockchainProviderWalletId | Passthrough | Tier 3 |
| 6 | CustomerWalletStatusId | WalletDB.Wallet.WalletAddresses | CustomerWalletStatusId | Passthrough | Tier 3 |
| 7 | Occurred | WalletDB.Wallet.WalletAddresses | Occurred | Passthrough | Tier 3 |
| 8 | BalanceAccountID | WalletDB.Wallet.WalletAddresses | BalanceAccountID | Passthrough | Tier 3 |
| 9 | NormalizedAddress | WalletDB.Wallet.WalletAddresses | NormalizedAddress | Passthrough | Tier 3 |
| 10 | etr_y | Generic Pipeline | Derived | ETL-generated partition year extracted from Occurred | Tier 2 |
| 11 | etr_ym | Generic Pipeline | Derived | ETL-generated partition year-month extracted from Occurred | Tier 2 |
| 12 | etr_ymd | Generic Pipeline | Derived | ETL-generated partition year-month-day extracted from Occurred | Tier 2 |
| 13 | SynapseUpdateDate | Generic Pipeline | Derived | Synapse ingestion timestamp | Tier 2 |
| 14 | partition_date | Generic Pipeline | Derived | Partition date for incremental loading, indexed | Tier 2 |

## Downstream Consumers

| # | Consumer Object | Consumer Type | Columns Used | Purpose |
|---|---|---|---|---|
| 1 | EXW_dbo.SP_EXW_WalletInventory | Stored Procedure | WalletId, IsMain, Address, BlockchainProviderWalletId, NormalizedAddress | JOIN to CustomerWalletsView on WalletId + IsMain=1 to get public address and normalized address for wallet inventory |
| 2 | EXW_Wallet.EXW_TransactionsView | View | WalletId, NormalizedAddress | Filters out internal addresses (NOT IN subquery) to identify external-only transactions |
| 3 | EXW_dbo.SP_EXW_Hourly | Stored Procedure | (indirect via SP_EXW_WalletInventory subquery) | Used in wallet inventory aggregation within hourly KPI SP |
