# EXW_Wallet.CustomerWalletsView — Lineage

## Source Objects

| # | Source Object | Source Type | Database | Schema | Relationship | Evidence |
|---|---|---|---|---|---|---|
| 1 | WalletDB.Wallet.CustomerWalletsView | Production View | WalletDB | Wallet | Direct CopyFromLake source | Generic Pipeline mapping (generic_id=664), CopyFromLake staging table |
| 2 | EXW_Wallet.Wallets | Synapse Table | Synapse | EXW_Wallet | Underlying source (production view base) | EXW_CustomerWalletsView view definition — aliased as `w` |
| 3 | EXW_Wallet.WalletPool | Synapse Table | Synapse | EXW_Wallet | Underlying source (production view base) | EXW_CustomerWalletsView view definition — aliased as `wp`, JOIN ON wp.WalletId = w.WalletId |
| 4 | EXW_Wallet.WalletAssets | Synapse Table | Synapse | EXW_Wallet | Underlying source (production view base) | EXW_CustomerWalletsView view definition — aliased as `wa`, JOIN ON wa.WalletId = wp.WalletId |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier | Confidence Reason |
|---|---|---|---|---|---|---|
| 1 | Id | WalletDB.Wallet.Wallets | WalletId | Rename: WalletId → Id | Tier 3 | No upstream wiki for WalletDB; traced via EXW_CustomerWalletsView view: `w.WalletId Id` |
| 2 | Gcid | WalletDB.Wallet.Wallets | Gcid | Passthrough | Tier 3 | No upstream wiki for WalletDB; traced via view: `w.Gcid` |
| 3 | CryptoId | WalletDB.Wallet.WalletAssets | CryptoId | Passthrough | Tier 3 | No upstream wiki for WalletDB; traced via view: `wa.CryptoId` |
| 4 | Address | WalletDB.Wallet.WalletPool | PublicAddress | Rename: PublicAddress → Address | Tier 3 | No upstream wiki for WalletDB; traced via view: `wp.PublicAddress Address` |
| 5 | BlockchainProviderWalletId | WalletDB.Wallet.WalletPool | ProviderWalletId | Rename: ProviderWalletId → BlockchainProviderWalletId | Tier 3 | No upstream wiki for WalletDB; traced via view: `wp.ProviderWalletId BlockchainProviderWalletId` |
| 6 | Occurred | WalletDB.Wallet.WalletAssets | Occurred | Passthrough | Tier 3 | No upstream wiki for WalletDB; traced via view: `wa.Occurred Occurred` |
| 7 | WalletTypeId | WalletDB.Wallet.Wallets | WalletTypeId | Passthrough | Tier 3 | No upstream wiki for WalletDB; traced via view: `w.WalletTypeId` |
| 8 | IsActive | WalletDB.Wallet.Wallets | IsActive | Passthrough (always 1 — view has WHERE w.IsActive = 1) | Tier 3 | No upstream wiki for WalletDB; traced via view: `w.IsActive` with filter |
| 9 | Status | WalletDB.Wallet.Wallets | IsActivated | CASE WHEN w.IsActivated = 1 THEN 0 ELSE 5 END | Tier 2 | Computed in production view from Wallets.IsActivated |
| 10 | WalletRecordId | WalletDB.Wallet.Wallets | Id | Rename: Id → WalletRecordId | Tier 3 | No upstream wiki for WalletDB; traced via view: `w.Id WalletRecordId` |
| 11 | BlockchainCryptoId | WalletDB.Wallet.Wallets | BlockchainCryptoId | Passthrough | Tier 3 | No upstream wiki for WalletDB; traced via view: `w.BlockchainCryptoId` |
| 12 | WalletProviderId | WalletDB.Wallet.WalletPool | WalletProviderId | Passthrough | Tier 3 | No upstream wiki for WalletDB; traced via view: `wp.WalletProviderId` |
| 13 | IsActivated | WalletDB.Wallet.Wallets | IsActivated | Passthrough | Tier 3 | No upstream wiki for WalletDB; traced via view: `w.IsActivated` |
| 14 | etr_y | Generic Pipeline | — | ETL partition column (year) | Tier 2 | Added by CopyFromLake pipeline, not in production view |
| 15 | etr_ym | Generic Pipeline | — | ETL partition column (year-month) | Tier 2 | Added by CopyFromLake pipeline, not in production view |
| 16 | etr_ymd | Generic Pipeline | — | ETL partition column (year-month-day) | Tier 2 | Added by CopyFromLake pipeline, not in production view |
| 17 | SynapseUpdateDate | Generic Pipeline | — | ETL load timestamp (GETDATE at load time) | Tier 2 | Added by CopyFromLake pipeline, not in production view |
