# EXW_Wallet.Wallets — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|---|---|---|---|
| 1 | WalletDB.Wallet.Wallets | Production table | Direct source via Generic Pipeline (Override, daily) | Generic Pipeline mapping ID 658 |
| 2 | EXW_Wallet.BlockchainCryptos | Dictionary table | FK lookup for BlockchainCryptoId | DDL + EXW_CustomerWalletsView |
| 3 | EXW_Dictionary.WalletTypes | Dictionary table | FK lookup for WalletTypeId | DDL + EXW_CustomerWalletsView |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.Wallets | Id | Passthrough | Tier 3 |
| 2 | WalletId | WalletDB.Wallet.Wallets | WalletId | Passthrough | Tier 3 |
| 3 | Gcid | WalletDB.Wallet.Wallets | Gcid | Passthrough | Tier 3 |
| 4 | BlockchainCryptoId | WalletDB.Wallet.Wallets | BlockchainCryptoId | Passthrough; FK to EXW_Wallet.BlockchainCryptos | Tier 3 |
| 5 | WalletTypeId | WalletDB.Wallet.Wallets | WalletTypeId | Passthrough; FK to EXW_Dictionary.WalletTypes | Tier 3 |
| 6 | IsActive | WalletDB.Wallet.Wallets | IsActive | Passthrough | Tier 3 |
| 7 | Occurred | WalletDB.Wallet.Wallets | Occurred | Passthrough | Tier 3 |
| 8 | BeginDate | WalletDB.Wallet.Wallets | BeginDate | Passthrough | Tier 3 |
| 9 | EndDate | WalletDB.Wallet.Wallets | EndDate | Passthrough | Tier 3 |
| 10 | IsActivated | WalletDB.Wallet.Wallets | IsActivated | Passthrough | Tier 3 |
| 11 | etr_y | Generic Pipeline | — | ETL partition column (year) | Tier 2 |
| 12 | etr_ym | Generic Pipeline | — | ETL partition column (year-month) | Tier 2 |
| 13 | etr_ymd | Generic Pipeline | — | ETL partition column (year-month-day) | Tier 2 |
| 14 | SynapseUpdateDate | Generic Pipeline | — | ETL load timestamp | Tier 2 |

## Notes

- No upstream wiki exists for WalletDB.Wallet.Wallets (`_no_upstream_found.txt` present).
- All business columns are Tier 3: passthrough from production but no upstream documentation available.
- ETL metadata columns (etr_*, SynapseUpdateDate) are Tier 2: added by Generic Pipeline infrastructure.
- No writer SP exists; table is loaded directly via Generic Pipeline Override strategy.
