# EXW_dbo.EXW_WalletInventory — Column Lineage

> Generated: 2026-04-20 | Phase 10B | Source: WalletDB.Wallet.WalletPool + WalletPoolStatuses + CustomerWalletsView + WalletAddresses

## Production Source

| Property | Value |
|----------|-------|
| **Primary Source DB** | WalletDB |
| **Primary Source Table** | Wallet.WalletPool |
| **Status Source** | Wallet.WalletPoolStatuses (latest status via ROW_NUMBER window) |
| **Assignment Source** | Wallet.CustomerWalletsView (GCID, Address, OccurredERC — occupied wallets only) |
| **Address Source** | Wallet.WalletAddresses (NormalizedAddress, IsMain=1) |
| **Name Source** | EXW_Wallet.CryptoTypes (CryptoName), EXW_Wallet.BlockchainCryptos (BlockchainCryptoName) |
| **Status Dictionary** | CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses (WalletStatus name) |
| **Writer SP** | EXW_dbo.SP_EXW_WalletInventory (TRUNCATE + INSERT, daily) |
| **Last Load** | 2026-04-20 (UpdateDate uniform today — ACTIVE refresh) |
| **Data Range** | 2018-04-23 to 2026-04-09 (Created); actively updated |

## Load Pattern

`SP_EXW_WalletInventory` does a full TRUNCATE + INSERT daily. Sources: WalletPool (pool wallet master) LEFT JOINed to WalletPoolStatuses (latest status via ROW_NUMBER PARTITION BY WalletPoolId ORDER BY Occurred DESC) and LEFT JOINed to a CustomerWalletsView subquery (GCID + address for occupied wallets). The filter `WHERE dd.CryptoID = dd.BlockchainCryptoId` excludes ERC-20 token wallets where the platform CryptoId doesn't match the BlockchainCryptoId — this means only native blockchain coin wallets (BTC, ETH, LTC, etc.) are included, not derivative ERC-20 tokens.

## ETL Pipeline

```
WalletDB (etoro-walletdb-prod)
  Wallet.WalletPool               ← pool wallet registry (WalletId, BlockchainCryptoId, Created)
  Wallet.WalletPoolStatuses       ← status event history (latest via ROW_NUMBER)
  WalletDB_Dictionary_WalletPoolStatuses ← status name lookup (CopyFromLake Bronze)
  Wallet.CustomerWalletsView      ← GCID + Address + OccurredERC (occupied wallets only)
  Wallet.WalletAddresses          ← NormalizedAddress (IsMain=1)
  EXW_Wallet.CryptoTypes          ← CryptoName (ERC/blockchain)
  EXW_Wallet.BlockchainCryptos    ← BlockchainCryptoName
    |
    |-- [SP_EXW_WalletInventory — TRUNCATE+INSERT daily] --|
    |   WHERE CryptoID = BlockchainCryptoId (excludes ERC-20 tokens)
    v
EXW_dbo.EXW_WalletInventory (2,748,419 rows — ACTIVE)
    |
    |-- [Referenced by SP_New_UsersAndWallets_Inventory, SP_EXW_Inventory_Snapshot_History] --|
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | WalletID | Wallet.WalletPool | WalletId | Passthrough (cast to nvarchar(max)) | Tier 1 |
| 2 | CryptoID | Wallet.WalletPool / EXW_Wallet.CryptoTypes | BlockchainCryptoId / CryptoId | CASE: ERC CryptoId if available, else BlockchainCryptoId; WHERE dd.CryptoID=dd.BlockchainCryptoId ensures native coins only | Tier 2 |
| 3 | ProviderWalletID | Wallet.WalletPool (via CustomerWalletsView) | ProviderWalletId | Passthrough via CustomerWalletsView; NULL for unoccupied pool wallets | Tier 1 |
| 4 | PublicAddress | Wallet.CustomerWalletsView | Address | Passthrough; NULL for unoccupied pool wallets | Tier 1 |
| 5 | Created | Wallet.WalletPool | Created | CAST to DATETIME (WalletPool.Created is datetime2) | Tier 1 |
| 6 | Occupied | SP computation | — | 1 if GCID IS NOT NULL (assigned to user), else 0 (pool) | Tier 2 |
| 7 | GCID | Wallet.CustomerWalletsView | Gcid | Passthrough rename (Gcid→GCID); NULL for unoccupied pool wallets | Tier 1 |
| 8 | UpdateDate | ETL load process | — | GETDATE() at SP execution | Tier 2 |
| 9 | WalletPoolID | Wallet.WalletPool | WalletId | Duplicate of WalletID — both set to WalletPool.WalletId | Tier 4 |
| 10 | CryptoName | EXW_Wallet.CryptoTypes | Name (ERC or blockchain) | CASE: ERC name if available, else WalletPool's blockchain CryptoName; mirrors CryptoID logic | Tier 2 |
| 11 | LastWalletPoolStatus | Wallet.WalletPoolStatuses | WalletPoolStatusId | Latest status event per wallet via ROW_NUMBER() OVER (PARTITION BY WalletPoolId ORDER BY Occurred DESC) | Tier 1 |
| 12 | WalletStatus | WalletDB_Dictionary_WalletPoolStatuses | Name | JOIN on LastWalletPoolStatus ID → status name string | Tier 2 |
| 13 | PromotionTagID | Wallet.WalletPoolStatuses | PromotionTagId | Passthrough from latest status event | Tier 1 |
| 14 | IsPromotionReady | SP computation | — | 1 if PromotionTagId=1 AND CryptoID is a supported blockchain crypto, else 0 | Tier 2 |
| 15 | Allocated | Wallet.CustomerWalletsView | Occurred | CAST to DATE; date when user was assigned this wallet; NULL for unoccupied | Tier 1 |
| 16 | BlockchainCryptoId | Wallet.WalletPool | BlockchainCryptoId | Passthrough (always = CryptoID due to WHERE filter) | Tier 1 |
| 17 | BlockchainCryptoName | EXW_Wallet.BlockchainCryptos | Name | JOIN on BlockchainCryptoId | Tier 2 |
| 18 | CreatedDateID | SP computation | — | CAST(CONVERT(VARCHAR(8), Created, 112) AS INT) → YYYYMMDD integer | Tier 2 |
| 19 | NormalizedAddress | Wallet.WalletAddresses | NormalizedAddress | Passthrough (IsMain=1); NULL for unoccupied | Tier 1 |
_DDL column count: 19. Lineage rows 1–19 account for all columns._

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 10 | WalletID, ProviderWalletID, PublicAddress, Created, GCID, LastWalletPoolStatus, PromotionTagID, Allocated, BlockchainCryptoId, NormalizedAddress |
| Tier 2 | 8 | CryptoID, Occupied, UpdateDate, CryptoName, WalletStatus, IsPromotionReady, BlockchainCryptoName, CreatedDateID |
| Tier 4 | 1 | WalletPoolID (duplicate of WalletID) |

## UC External Lineage

No UC mapping found for EXW_dbo.EXW_WalletInventory in Generic Pipeline mapping.
UC Target: `_Not_Migrated`
