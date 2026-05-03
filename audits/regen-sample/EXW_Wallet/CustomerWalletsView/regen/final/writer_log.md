MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `EXW_Wallet.CustomerWalletsView`.

**PHASE 1 — Structure Analysis**

From the DDL in the bundle:
- 17 columns, ROUND_ROBIN distribution, HEAP (no clustered index)
- Columns: Id (uniqueidentifier), Gcid (int), CryptoId (int), Address (varchar max), BlockchainProviderWalletId (varchar max), Occurred (datetime2), WalletTypeId (int), IsActive (bit), Status (int), WalletRecordId (bigint), BlockchainCryptoId (int), WalletProviderId (int), IsActivated (bit), etr_y/etr_ym/etr_ymd (varchar max), SynapseUpdateDate (datetime)
- All columns nullable

PHASE 1 CHECKPOINT: PASS

Now running P2 (sampling + row count) and P8 (SP scan) in parallel.
P2 sample retrieved. DMV row count failed (permission denied). Let me get the count differently and read key source files.
PHASE 2 CHECKPOINT: PASS (1,780,174 rows, dates 2019-06-11 to 2026-04-27, full refresh pattern)

Now running Phase 3 (distribution for categorical columns matching regex: Status, WalletTypeId) and reading source tables.
PHASE 3 CHECKPOINT: PASS (Status: 2 values, WalletTypeId: 7 values)

Now reading source tables for P4/P5 (lookup + JOIN analysis) and key SPs for P8/P9.
PHASE 4 CHECKPOINT: PASS (Source tables identified: Wallets, WalletPool, WalletAssets, BlockchainCryptos)

Now reading key SPs and checking the generic pipeline mapping for this table.
Now checking the generic pipeline mapping and looking for UC target info.
PHASE 5 CHECKPOINT: PASS (Production view JOINs Wallets + WalletPool + WalletAssets on WalletId)
PHASE 6 CHECKPOINT: PASS (Business logic: wallet allocation, Status derivation from IsActivated)
PHASE 7 CHECKPOINT: PASS (EXW_CustomerWalletsView view references this table)
PHASE 8 CHECKPOINT: PASS (14 reader SPs found, 0 writer SPs — CopyFromLake table)
PHASE 9 CHECKPOINT: PASS (No writer SP — production view defines column mapping: Wallets + WalletPool + WalletAssets)
PHASE 9B CHECKPOINT: PASS (Generic Pipeline, Override, 120-min refresh from WalletDB.Wallet.CustomerWalletsView)

Now running Phase 10 (Jira search).
PHASE 10 CHECKPOINT: PASS (Confluence confirms CustomerWalletsView used for OmniBUS wallet ownership checks)
PHASE 10A CHECKPOINT: PASS (No upstream wiki — _no_upstream_found.txt confirmed)

Now writing the three output files. Starting with the lineage file.

```
PHASE GATE — EXW_Wallet.CustomerWalletsView:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
Now writing the main wiki.
Now writing the review-needed file.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.CustomerWalletsView:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/CustomerWalletsView/regen/attempt_1/CustomerWalletsView.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/CustomerWalletsView/regen/attempt_1/CustomerWalletsView.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/CustomerWalletsView/regen/attempt_1/CustomerWalletsView.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 12    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
