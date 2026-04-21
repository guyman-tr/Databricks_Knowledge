# EXW_dbo.New_UsersAndWallets_Inventory — Column Lineage

**Generated**: 2026-04-20 | **ETL SP**: SP_New_UsersAndWallets_Inventory | **Load Pattern**: TRUNCATE + INSERT (no date param)

## ETL Pipeline

```
WalletDB.Wallet.WalletPool + WalletPoolStatuses + CustomerWalletsView
  |-- SP_EXW_WalletInventory (daily TRUNCATE+INSERT) --|
  v
EXW_dbo.EXW_WalletInventory
  |-- SP_New_UsersAndWallets_Inventory (TRUNCATE+INSERT, no date param) --|
  v
EXW_dbo.New_UsersAndWallets_Inventory (1,760,434 rows)
  |-- (no UC migration) --|
  v
_Not_Migrated
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|---|---|---|---|---|
| GCID | EXW_WalletInventory | GCID | Passthrough (WHERE GCID>0 excludes pool/omnibus) | Tier 1 — WalletDB.Wallet.CustomerWalletsView |
| WalletJoinDate | EXW_WalletInventory | Allocated | MIN per GCID×CryptoID | Tier 1 — WalletDB.Wallet.CustomerWalletsView |
| UserJoinDate | EXW_WalletInventory | Allocated | MIN per GCID (across all cryptos) | Tier 1 — WalletDB.Wallet.CustomerWalletsView |
| CryptoName | EXW_WalletInventory | CryptoName | Passthrough | Tier 2 — EXW_Wallet.CryptoTypes |
| CryptoID | EXW_WalletInventory | CryptoID | Passthrough | Tier 2 — EXW_Wallet.CryptoTypes |
| UpdateDate | GETDATE() | — | ETL timestamp | Tier 2 — SP_New_UsersAndWallets_Inventory |

## Source Objects

| Object | Role |
|---|---|
| EXW_dbo.EXW_WalletInventory | Sole source — provides GCID, Allocated, CryptoName, CryptoID |
| EXW_dbo.SP_New_UsersAndWallets_Inventory | Writer SP |
| EXW_dbo.SP_EXW_FirstTimeWalletsAndUsers | Reader SP — consumes UserJoinDate + WalletJoinDate for monthly first-time analysis |

## Tier Summary

| Tier | Count | Columns |
|---|---|---|
| Tier 1 | 3 | GCID, WalletJoinDate, UserJoinDate |
| Tier 2 | 3 | CryptoName, CryptoID, UpdateDate |
