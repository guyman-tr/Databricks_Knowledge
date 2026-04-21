# EXW_dbo.EXW_FirstTimeWalletsAndUsers — Column Lineage

**Object Type**: Table
**Schema**: EXW_dbo
**Generated**: 2026-04-20
**Pipeline Phase**: 10B

## Table Definition Summary

Daily pre-aggregated count of new wallet users (UserJoinDate=@d) and new wallets (WalletJoinDate=@d) per Country×Regulation×CryptoName×RealUser×Region×State combination. Writer: SP_EXW_FirstTimeWalletsAndUsers(@d date). Strategy: DELETE for FullDateID, then INSERT. HASH(FullDateID), HEAP.

Source: EXW_dbo.New_UsersAndWallets_Inventory (pending documentation). NewUsers uses ROW_NUMBER() deduplication per GCID so each new user is counted only once even if they opened multiple wallets on the same day.

642,093 rows (2018-07-12 to 2026-04-11, active — updated daily).

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Confidence |
|---|--------|---------------|---------------|-----------|------------|
| 1 | Country | EXW_dbo.EXW_DimUser | Country | Direct passthrough via LEFT JOIN on GCID | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 2 | RealUser | EXW_dbo.EXW_DimUser_Enriched | UserType | Direct passthrough (LEFT JOIN on GCID). Values: 'RealUser', 'eTorian', 'TestUser' | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 3 | CryptoNameERC | EXW_dbo.New_UsersAndWallets_Inventory | CryptoName | Aliased as CryptoNameERC; internal ERC-level name from the inventory table | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 4 | CryptoName | EXW_Wallet.CryptoTypes | Name | CryptoTypes.Name WHERE CryptoID=BlockchainCryptoId — canonical blockchain crypto name | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 5 | Regulation | EXW_dbo.EXW_DimUser | Regulation | Direct passthrough via LEFT JOIN on GCID | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 6 | Region | EXW_dbo.EXW_DimUser | Region | Direct passthrough via LEFT JOIN on GCID | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 7 | StateCode | DWH_dbo.Dim_State_and_Province | ShortName | JOIN on EXW_DimUser.UserRegion_State=Dim_State_and_Province.Name; NULL for non-US users | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 8 | State | EXW_dbo.EXW_DimUser | UserRegion_State | Direct passthrough via LEFT JOIN on GCID; NULL for non-US users | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 9 | FullDate | (SP parameter) | — | @d — the execution date passed to the SP | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 10 | FullDateID | (SP parameter) | — | CAST(CONVERT(VARCHAR(8),@d,112) AS INT) — YYYYMMDD integer form of @d | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 11 | NewUsers | EXW_dbo.New_UsersAndWallets_Inventory | GCID (via UserJoinDate) | COUNT(CASE WHEN CIDtype='NewCID' AND RN=1 THEN GCID END) — deduped count of GCIDs with UserJoinDate=@d | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 12 | NewWallets | EXW_dbo.New_UsersAndWallets_Inventory | CryptoNameERC (via WalletJoinDate) | COUNT(CryptoNameERC) — count of new wallets with WalletJoinDate=@d, including existing users opening new wallets | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |
| 13 | UpdateDate | (computed) | — | GETDATE() at SP run time | Tier 2 — SP_EXW_FirstTimeWalletsAndUsers |

## Source Objects

| Source Object | Relationship | Notes |
|---------------|-------------|-------|
| EXW_dbo.New_UsersAndWallets_Inventory | Primary source | Provides UserJoinDate, WalletJoinDate, GCID, CryptoName, CryptoID — pending documentation |
| EXW_Wallet.CryptoTypes | JOIN on CryptoID=BlockchainCryptoId | Canonical blockchain crypto name |
| EXW_Wallet.CustomerWalletsView | JOIN on CryptoId+GCID | Validates wallet scope; filters Gcid>0 |
| EXW_dbo.EXW_DimUser | LEFT JOIN on GCID | Country, Regulation, Region, UserRegion_State |
| EXW_dbo.EXW_DimUser_Enriched | LEFT JOIN on GCID | RealUser (UserType) |
| DWH_dbo.Dim_State_and_Province | LEFT JOIN on EXW_DimUser.UserRegion_State=Name | StateCode (ShortName) |

## UC Lineage

UC Target: `_Not_Migrated`
No UC entity exists for this table. Documentation is for knowledge purposes only.
