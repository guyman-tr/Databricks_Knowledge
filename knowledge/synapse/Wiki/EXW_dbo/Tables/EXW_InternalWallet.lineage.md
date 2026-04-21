# EXW_dbo.EXW_InternalWallet — Column Lineage

**Generated**: 2026-04-20  
**Object Type**: Table  
**Schema**: EXW_dbo  
**ETL Mechanism**: `EXW_dbo.SP_EXW_InternalWallet` — full TRUNCATE + INSERT (no parameters; complete snapshot refresh). Reads from `EXW_Wallet.CustomerWalletsView` (WHERE Gcid <= 0; internal/system wallets only) LEFT JOINed to `CopyFromLake.WalletDB_Dictionary_WalletTypes` and JOINed to `EXW_Wallet.CryptoTypes`. 10 columns. 6 T1 from CustomerWalletsView upstream wiki, 4 T2 from SP code/joins.

## ETL Pipeline Summary

```
WalletDB.Wallet.Wallets (production — WalletDB)
WalletDB.Wallet.WalletPool (address, provider)
WalletDB.Wallet.WalletAssets (asset visibility)
  |-- Generic Pipeline (Bronze export) --|
  v
EXW_Wallet.CustomerWalletsView (External View — mirrors WalletDB.Wallet.CustomerWalletsView)
EXW_Wallet.CryptoTypes (External Table — mirrors Wallet.CryptoTypes)
CopyFromLake.WalletDB_Dictionary_WalletTypes (Dictionary copy from WalletDB)
  |-- EXW_dbo.SP_EXW_InternalWallet --|
  |-- TRUNCATE TABLE EXW_InternalWallet --|
  |-- INSERT SELECT WHERE Gcid <= 0 (internal/system wallets only) --|
  v
EXW_dbo.EXW_InternalWallet (current snapshot, refreshed periodically)
  |-- No Gold layer UC target --|
  v
UC Target: _Not_Migrated
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | Id | EXW_Wallet.CustomerWalletsView (← WalletDB.Wallet.Wallets.WalletId) | Id | Passthrough — wallet universal business key (uniqueidentifier) | Tier 1 |
| 2 | Gcid | EXW_Wallet.CustomerWalletsView (← WalletDB.Wallet.Wallets.Gcid) | Gcid | Passthrough; WHERE Gcid <= 0 (internal/system wallets only; ≤0 = system account) | Tier 1 |
| 3 | CryptoId | EXW_Wallet.CustomerWalletsView (← WalletDB.Wallet.WalletAssets.CryptoId) | CryptoId | Passthrough; HASH distribution key | Tier 1 |
| 4 | Address | EXW_Wallet.CustomerWalletsView (← WalletDB.Wallet.WalletPool.PublicAddress) | Address | CAST to NVARCHAR(1000) from NVARCHAR(512) — blockchain public address | Tier 1 |
| 5 | BlockchainProviderWalletId | EXW_Wallet.CustomerWalletsView (← WalletDB.Wallet.WalletPool.ProviderWalletId) | BlockchainProviderWalletId | Passthrough | Tier 1 |
| 6 | Status | EXW_Wallet.CustomerWalletsView (computed) | Status | Passthrough — computed status: 0=Active (IsActivated=1), 5=Pending (IsActivated=0) | Tier 1 |
| 7 | UpdateDate | EXW_Wallet.CustomerWalletsView (← WalletDB.Wallet.WalletAssets.Occurred) | Occurred | Rename + CAST to DATETIME (from datetime2(7)) — asset creation/addition timestamp | Tier 2 |
| 8 | InternalWalletTypeId | EXW_Wallet.CustomerWalletsView (← WalletDB.Wallet.Wallets.WalletTypeId) | WalletTypeId | Rename only — wallet operational type (1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 6=C2F, 7=StakingRefund) | Tier 2 |
| 9 | InternalType | CopyFromLake.WalletDB_Dictionary_WalletTypes | Name | LEFT JOIN on WalletTypeId; CAST to NVARCHAR(50) — human-readable wallet type label | Tier 2 |
| 10 | CryptoName | EXW_Wallet.CryptoTypes (← WalletDB.Wallet.CryptoTypes.Name) | Name | JOIN on CryptoId; CAST to NVARCHAR(50) — cryptocurrency display name (e.g., "Ethereum", "Bitcoin") | Tier 2 |

## SP Filter Logic

```sql
-- SP_EXW_InternalWallet core filter
SELECT cw.Id, cw.Gcid, cw.CryptoId,
       CAST(cw.Address AS NVARCHAR(1000)),
       cw.BlockchainProviderWalletId, cw.Status,
       CAST(cw.Occurred AS DATETIME),
       cw.WalletTypeId,                           -- → InternalWalletTypeId
       CAST(wt.Name AS NVARCHAR(50)),              -- → InternalType (LEFT JOIN)
       CAST(ct.Name AS NVARCHAR(50))               -- → CryptoName (INNER JOIN)
FROM EXW_Wallet.CustomerWalletsView cw
LEFT JOIN CopyFromLake.WalletDB_Dictionary_WalletTypes wt ON cw.WalletTypeId = wt.Id
JOIN EXW_Wallet.CryptoTypes ct ON cw.CryptoId = ct.CryptoID
WHERE cw.Gcid <= 0                                -- internal/system wallets only
```

## Upstream Wikis

- **WalletDB.Wallet.CustomerWalletsView**: `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Views\Wallet.CustomerWalletsView.md`
  - Applies to: Id, Gcid, CryptoId, Address, BlockchainProviderWalletId, Status (T1 × 6)
- **WalletDB.Wallet.CryptoTypes**: `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Tables\Wallet.CryptoTypes.md`
  - Context for CryptoName and CryptoId semantics

## UC Target

`_Not_Migrated` — No Gold layer UC target in generic pipeline mapping.
