# EXW_WalletInventory — Review Needed

**Generated**: 2026-04-20 | **Batch**: 3 | **Object**: EXW_dbo.EXW_WalletInventory

---

## Tier 4 Items (Unverified / Needs Human Review)

| # | Column | Reason |
|---|--------|--------|
| 1 | WalletPoolID | Duplicate of WalletID in all 2,748,419 rows. Both set to WalletPool.WalletId (GUID) in the SP: `dd.WalletId AS WalletID` and `dd.WalletId AS WalletPoolID`. Tier 4 assigned — reviewer should confirm whether WalletPoolID was intended to store a different value (e.g., the integer WalletPool.Id surrogate key) and the SP was written incorrectly, or if this is intentional redundancy from an early schema design. |

---

## Open Questions for Reviewer

1. **ERC-20 wallet exclusion — WHERE dd.CryptoID = dd.BlockchainCryptoId**: The SP filters out rows where the platform CryptoID doesn't match BlockchainCryptoId. This effectively excludes USDEX, EURX, GBPX and other ERC-20 stablecoins that live on the ETH blockchain. Confirm: Is this intentional (this table covers only native coin wallets) or a design limitation that causes reporting gaps for stablecoin wallet analytics? If ERC-20 wallets need to be tracked, a separate filter path would be needed.

2. **ProviderWalletID source — WalletAddresses vs. CustomerWalletsView**: In the SP's CustomerWalletsView subquery, `c.BlockchainProviderWalletId` comes from CustomerWalletsView, which aliases `Wallet.WalletPool.ProviderWalletId`. However, the WalletAddresses table also has its own `BlockchainProviderWalletId`. These should be the same value, but confirm: has any divergence ever been observed (e.g., after a provider migration from BitGo to CUG)?

3. **IsPromotionReady logic with PromotionTagId=1 hardcode**: The SP hardcodes `PromotionTagId=1` as the condition for `IsPromotionReady=1`. This means only wallets with the first promotion tag are flagged as ready. Confirm: Is PromotionTagId=1 the canonical "default promotion" tag, or does this logic need to be updated as new promotion types are added?

4. **GCID distribution key with large NULL population**: 976,952 rows (36%) have GCID=NULL (unoccupied pool wallets). All NULL-GCID rows hash to the same distribution node in Synapse HASH(GCID), creating significant skew. Confirm: Is this skew acceptable given that pool-wallet queries are rare in practice, or should the distribution key be changed to WalletID for more even distribution?

5. **FundingVerified wallets (208,808)**: These wallets have been pre-funded but are not yet assigned to customers. Confirm: Are these wallets part of an active promotion pipeline, or is this a legacy state from a previous funding flow that is no longer used? The distinction matters for pool availability calculations (should FundingVerified wallets be counted as "available"?).

6. **WalletPoolID nvarchar(max) type**: Both WalletID and WalletPoolID are declared as `nvarchar(max)` in the DDL, but WalletPool.WalletId is a `uniqueidentifier`. The implicit CAST to nvarchar is handled by SQL Server. Confirm: Was `nvarchar(max)` for a GUID column intentional, or would `uniqueidentifier` or `nvarchar(36)` be more appropriate? The current type wastes significant storage.

---

## Cross-Object Consistency Check

✅ `GCID` description: "Global Customer ID of the wallet owner. For customer wallets (type 5, the vast majority), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets." — verbatim from CustomerWalletsView.md (Tier 1 — WalletDB.Wallet.CustomerWalletsView), with HASH distribution note appended.
✅ `WalletID` description matches Wallet.WalletPool.md Element 2 verbatim.
✅ `PromotionTagID` description matches Wallet.WalletPoolStatuses.md Element 5 verbatim.
✅ `LastWalletPoolStatus` value mappings (1=Pending, 2=Verified, 3=Failed, 4=FundingInitiated...) confirmed against Wallet.WalletPoolStatuses.md Element 3 upstream description.
✅ `NormalizedAddress` description matches Wallet.WalletAddresses.md Element 9 verbatim.
✅ `PublicAddress` description matches Wallet.WalletPool.md Element 5 verbatim.
✅ `Created` description matches Wallet.WalletPool.md Element 6 verbatim.
✅ `Allocated` description matches CustomerWalletsView.md Element 6 (Occurred) verbatim.
✅ WalletStatus distribution confirmed against live data: Verified=2,532,501; FundingVerified=208,808; Failed=4,682; Pending=2,411; VerifiedForAssign=17 — consistent with LastWalletPoolStatus distribution (1:1 mapping confirmed).

---

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 19 cols, HASH(GCID), HEAP; confirmed from SSDT |
| P2 Sample | PASS | 2,748,419 rows total; 702,412 distinct GCIDs; Created 2018-04-23 to 2026-04-09; UpdateDate today |
| P3 Distribution | PASS | Occupied (1=64%, 0=36%), WalletStatus distribution (5 values), CryptoID top 10 verified |
| P4 Lookup | PASS | WalletPoolStatuses status codes (1-11) confirmed from upstream wiki; WalletStatus strings confirmed |
| P5 JOINs | PASS | GCID is HASH join key to all EXW_dbo co-distributed tables; WalletID joins to EXW_FactTransactions |
| P6 BizLogic | PASS | Pool architecture, status lifecycle, ERC-20 exclusion, promotion tracking all documented |
| P7 Views | PASS | SP_New_UsersAndWallets_Inventory and SP_EXW_Inventory_Snapshot_History consume this table |
| P8 SP Scan | PASS | Writer: SP_EXW_WalletInventory (TRUNCATE+INSERT, daily) |
| P9 SP Logic | PASS | Full source-to-target map traced through all JOIN layers |
| P9B ETL Orch | PASS | Daily TRUNCATE+INSERT; actively refreshed (UpdateDate = today) |
| P10 Atlassian | [-] | Skipped — no Atlassian MCP configured |
| P10A Upstream | PASS | Wallet.WalletPool.md, WalletPoolStatuses.md, WalletAddresses.md, CustomerWalletsView.md, BlockchainCryptos.md all read |
| P10B Lineage | PASS | .lineage.md written (19 cols: 10 T1, 8 T2, 1 T4); UC Target: _Not_Migrated |
| P11 Generate | PASS | .md written (19/19 elements, 8 sections); .review-needed.md written |
