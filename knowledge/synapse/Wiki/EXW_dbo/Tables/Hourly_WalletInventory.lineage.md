# EXW_dbo.Hourly_WalletInventory — Column Lineage

**Object**: EXW_dbo.Hourly_WalletInventory  
**Type**: Table  
**Generated**: 2026-04-20  
**ETL Writer**: EXW_dbo.SP_EXW_Hourly (TRUNCATE + INSERT, runs hourly, snapshot of current pool state)  
**Primary Source**: EXW_Wallet.WalletPool (via #EXW_WalletInventory temp table) + EXW_Wallet.CustomerWalletsView (allocation status)  
**Scope**: Native coin wallets only (WHERE CryptoID = BlockchainCryptoId — ERC-20 token wallets excluded)  
**Grain**: One row per CryptoID × WalletStatus combination

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | CryptoID | EXW_Wallet.CryptoTypes + EXW_Wallet.CustomerWalletsView | CryptoID / CryptoId | CASE WHEN CryptoIDERC IS NULL THEN BlockchainCryptoId ELSE CryptoIDERC END in #EXW_WalletInventory. Final INSERT: WHERE CryptoID = BlockchainCryptoId restricts to native coins only. GROUP BY key. | Tier 2 |
| 2 | WalletStatus | CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses | Name | Most recent WalletPoolStatus name per wallet pool entry, resolved via ROW_NUMBER() OVER (PARTITION BY WalletPoolId ORDER BY Occurred DESC) = 1 on EXW_Wallet.WalletPoolStatuses. JOIN WalletDB_Dictionary_WalletPoolStatuses ON WalletPoolStatusId. GROUP BY key. Values: Verified, FundingVerified, Pending, Failed, VerifiedForAssign. | Tier 2 |
| 3 | TotalWalletsInInventory | EXW_Wallet.WalletPool | WalletPoolID (= WalletId) | COUNT(WalletPoolID) — total wallets in this CryptoID × WalletStatus group, regardless of allocation status. | Tier 2 |
| 4 | TotalAllocated | EXW_Wallet.CustomerWalletsView | Gcid | SUM(CASE WHEN GCID IS NOT NULL THEN 1 ELSE 0 END) — wallets with a non-NULL GCID, indicating customer assignment. | Tier 2 |
| 5 | TotalFreeInventory | EXW_Wallet.CustomerWalletsView | Gcid | SUM(CASE WHEN GCID IS NULL THEN 1 ELSE 0 END) — wallets with NULL GCID, i.e., not yet allocated to any customer. | Tier 2 |
| 6 | PromotionReadyAvailable | EXW_Wallet.WalletPoolStatuses + EXW_Wallet.CryptoTypes | PromotionTagId | SUM(CASE WHEN IsPromotionReady = 1 AND GCID IS NULL THEN 1 ELSE 0 END). IsPromotionReady = 1 when PromotionTagId=1 AND CryptoID IN (SELECT DISTINCT BlockchainCryptoId FROM EXW_Wallet.CryptoTypes). | Tier 2 |
| 7 | PromotionReadyAllocated | EXW_Wallet.WalletPoolStatuses + EXW_Wallet.CryptoTypes | PromotionTagId | SUM(CASE WHEN IsPromotionReady = 1 AND GCID IS NOT NULL THEN 1 ELSE 0 END) — promotion-eligible wallets currently assigned to customers. | Tier 2 |
| 8 | Created7Days | EXW_Wallet.WalletPool | Created | SUM(CASE WHEN Created BETWEEN CAST(GETDATE()-7 AS DATE) AND GETDATE() THEN 1 ELSE 0 END) — wallets added to the pool in the last 7 days. Created upstream: "Timestamp when this pool wallet was created." | Tier 2 |
| 9 | Allocated7Days | EXW_Wallet.CustomerWalletsView | Occurred (→ Allocated date) | SUM(CASE WHEN Allocated BETWEEN CAST(GETDATE()-7 AS DATE) AND GETDATE() THEN 1 ELSE 0 END). Allocated = CAST(CustomerWalletsView.Occurred AS DATE) — the date the wallet was assigned to a customer. | Tier 2 |
| 10 | AllocatedToday | EXW_Wallet.CustomerWalletsView | Occurred (→ Allocated date) | SUM(CASE WHEN Allocated BETWEEN CAST(GETDATE() AS DATE) AND GETDATE() THEN 1 ELSE 0 END) — wallets allocated since midnight of the SP run date. | Tier 2 |
| 11 | TodayAllocationPace | ETL (computed) | AllocatedToday, GETDATE() | (AllocatedToday × DATEDIFF(HOUR, CAST(GETDATE() AS DATE), GETDATE())) / 24 — integer arithmetic. SP comment: "pro rate hourly for the full day." See gotcha in wiki. | Tier 2 |
| 12 | YesterdayAllocation | EXW_Wallet.CustomerWalletsView | Occurred (→ Allocated date) | SUM(CASE WHEN Allocated BETWEEN CAST(GETDATE()-1 AS DATE) AND CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) — wallets allocated yesterday. | Tier 2 |
| 13 | SameDayLastWeekAllocation | EXW_Wallet.CustomerWalletsView | Occurred (→ Allocated date) | SUM(CASE WHEN Allocated BETWEEN CAST(GETDATE()-7 AS DATE) AND CAST(GETDATE()-6 AS DATE) THEN 1 ELSE 0 END) — wallets allocated on the same calendar day last week (7-day lag). | Tier 2 |
| 14 | UpdateDate | ETL | n/a | GETDATE() at INSERT time — timestamp of the specific SP run. | Tier 2 |
| 15 | ReportDate | ETL | n/a | CAST(GETDATE() AS DATE) — calendar date of the SP run. Same for all rows in a given run. | Tier 2 |

---

## Source Objects

| Source Object | Access Method | Role |
|--------------|---------------|------|
| EXW_Wallet.WalletPool | Direct SELECT (DISTINCT by WalletId) | Primary source: all pool wallets (WalletId, BlockchainCryptoId, Created) |
| EXW_Wallet.WalletPoolStatuses | Subquery: ROW_NUMBER() PARTITION BY WalletPoolId ORDER BY Occurred DESC → RN=1 | Latest pool status per wallet (WalletPoolStatusId, PromotionTagId) |
| CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses | JOIN ON WalletPoolStatusId | Status name lookup (Name → WalletStatus) |
| EXW_Wallet.CryptoTypes | LEFT JOIN ON BlockchainCryptoId | Crypto name and CryptoID mapping; also used in IsPromotionReady check |
| EXW_Wallet.CustomerWalletsView | LEFT JOIN ON WalletId | Allocation state: GCID (if assigned), Occurred (→ Allocated date), Address, CryptoId (CryptoIDERC for ERC-20) |
| EXW_Wallet.WalletAddresses | JOIN ON WalletId AND IsMain=1 | Main normalized address per wallet (used in #EXW_WalletInventory NormalizedAddress) |
| EXW_Wallet.BlockchainCryptos | JOIN ON BlockchainCryptoId | BlockchainCryptoName for the temp table |

---

## ETL Pipeline

```
WalletDB.Wallet.WalletPool (production — pre-provisioned blockchain wallets)
  |-- EXW_Wallet.WalletPool (live Synapse table, synced from WalletDB) --|
  |-- EXW_Wallet.WalletPoolStatuses (latest status per wallet, ROW_NUMBER) --|
  |-- CopyFromLake.WalletDB_Dictionary_WalletPoolStatuses (status names) --|
  |-- EXW_Wallet.CryptoTypes (crypto name + CryptoID mapping) --|
  |-- EXW_Wallet.CustomerWalletsView (GCID + allocation date, if assigned) --|
  |-- EXW_Wallet.WalletAddresses (main address, IsMain=1) --|
  |-- EXW_Wallet.BlockchainCryptos (blockchain crypto name) --|
  |-- SP_EXW_Hourly: complex JOIN → #EXW_WalletInventory (HASH(GCID), HEAP) --|
  |-- WHERE CryptoID = BlockchainCryptoId (native coins only) --|
  |-- GROUP BY CryptoID, WalletStatus --|
  v
EXW_dbo.Hourly_WalletInventory
  (26 rows, 12 cryptos, 5 WalletStatuses, ~2.47M total wallets, HASH(CryptoID), HEAP)
  UC Target: _Not_Migrated (operational KPI, Synapse-only)
```

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (all columns are aggregated CASE/SUM expressions or lookup-enriched; no direct passthrough) |
| Tier 2 | 15 | CryptoID, WalletStatus, TotalWalletsInInventory, TotalAllocated, TotalFreeInventory, PromotionReadyAvailable, PromotionReadyAllocated, Created7Days, Allocated7Days, AllocatedToday, TodayAllocationPace, YesterdayAllocation, SameDayLastWeekAllocation, UpdateDate, ReportDate |
| Tier 3 | 0 | — |

**Upstream wikis consulted**: WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md (WalletId, Created descriptions); no direct T1 columns because all DWH columns are aggregated.
