# EXW_Wallet.WalletPool — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Database | Schema | Notes |
|---|---|---|---|---|---|---|
| 1 | WalletDB.Wallet.WalletPool | Production Table | Direct source via Generic Pipeline (CopyFromLake) | WalletDB | Wallet | Append strategy, every 120 min |
| 2 | EXW_Wallet.CryptoTypes | Synapse Lookup | FK from BlockchainCryptoId | Synapse | EXW_Wallet | Crypto type reference |
| 3 | EXW_Wallet.WalletPoolStatuses | Synapse Table | Related — latest status per wallet pool entry | Synapse | EXW_Wallet | Used by downstream SPs |
| 4 | CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses | CopyFromLake Dictionary | Related — status name lookup | Synapse | CopyFromLake | Dictionary for status IDs |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.WalletPool | Id | Passthrough (CopyFromLake) | Tier 3 |
| 2 | WalletId | WalletDB.Wallet.WalletPool | WalletId | Passthrough (CopyFromLake) | Tier 3 |
| 3 | BlockchainCryptoId | WalletDB.Wallet.WalletPool | BlockchainCryptoId | Passthrough (CopyFromLake) | Tier 3 |
| 4 | ProviderWalletId | WalletDB.Wallet.WalletPool | ProviderWalletId | Passthrough (CopyFromLake) | Tier 3 |
| 5 | PublicAddress | WalletDB.Wallet.WalletPool | PublicAddress | Passthrough (CopyFromLake) | Tier 3 |
| 6 | Created | WalletDB.Wallet.WalletPool | Created | Passthrough (CopyFromLake) | Tier 3 |
| 7 | WalletProviderId | WalletDB.Wallet.WalletPool | WalletProviderId | Passthrough (CopyFromLake) | Tier 3 |
| 8 | etr_y | CopyFromLake Pipeline | — | ETL-generated partition year | Tier 3 |
| 9 | etr_ym | CopyFromLake Pipeline | — | ETL-generated partition year-month | Tier 3 |
| 10 | etr_ymd | CopyFromLake Pipeline | — | ETL-generated partition year-month-day | Tier 3 |
| 11 | SynapseUpdateDate | CopyFromLake Pipeline | — | ETL-generated Synapse load timestamp | Tier 3 |
| 12 | partition_date | CopyFromLake Pipeline | — | ETL-generated date partition (indexed) | Tier 3 |
