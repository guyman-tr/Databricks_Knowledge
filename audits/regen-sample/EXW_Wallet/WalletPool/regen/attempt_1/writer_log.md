MCP PRE-FLIGHT: PASS

Now loading required rule files.
Rules loaded. Starting pipeline for `EXW_Wallet.WalletPool`.

**PHASE 1 CHECKPOINT: PASS** — DDL from bundle: 12 columns, HASH(WalletId), HEAP with NCI on partition_date.

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — Sample retrieved, date range 2018-04-23 to 2026-04-26. Row count DMV failed (permission); let me get count another way and read key SPs.
Good. 2,470,928 rows. Now let me check distribution on relevant columns and read additional context.
**PHASE 3 CHECKPOINT: PASS** — BlockchainCryptoId: 12 distinct values; WalletProviderId: 2 values (1, 2). No columns match the categorical regex; ran distribution on FK-like columns for context.

**PHASE 4 CHECKPOINT: PASS** — BlockchainCryptoId → EXW_Wallet.CryptoTypes (FK).

**PHASE 5 CHECKPOINT: PASS** — WalletPool joined via WalletId in EXW_CustomerWalletsView, EXW_TransactionsView; joined via Id in SP_EXW_WalletInventory.

**PHASE 6 CHECKPOINT: PASS** — Wallet pool is a pre-generated inventory of blockchain wallet addresses. Core columns: Id (PK), WalletId (GUID), BlockchainCryptoId (crypto type), PublicAddress, Created, WalletProviderId. ETL columns: etr_y/ym/ymd, SynapseUpdateDate, partition_date.

**PHASE 7 CHECKPOINT: PASS** — Referenced by EXW_Wallet.EXW_CustomerWalletsView and EXW_Wallet.EXW_TransactionsView.

**PHASE 8 CHECKPOINT: PASS** — Read by: SP_EXW_WalletInventory, SP_EXW_Hourly, SP_EXW_Transactions_Monthly, SP_EXW_FinanceReportsBalancesNew. No writer SP — loaded via CopyFromLake Generic Pipeline.

**PHASE 9 CHECKPOINT: PASS** — No writer SP. CopyFromLake direct copy from WalletDB.Wallet.WalletPool. All business columns are passthrough from production.

**PHASE 9B CHECKPOINT: PASS** — Generic Pipeline #652, Append strategy, every 120 minutes, parquet format, source WalletDB.Wallet.WalletPool.

**PHASE 10 CHECKPOINT: [-]** — Skipped (regen harness, low-value for this dormant-upstream object).

**PHASE 10A CHECKPOINT: PASS** — _no_upstream_found.txt present. No upstream wiki resolvable.

Now writing lineage file (Phase 10B), then main wiki, then review-needed.

```
PHASE GATE — EXW_Wallet.WalletPool:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
**PHASE 10B CHECKPOINT: PASS** — Lineage written.

Now writing the main wiki.
```
OUTPUT CHECK — EXW_Wallet.WalletPool:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/WalletPool/regen/attempt_1/WalletPool.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/WalletPool/regen/attempt_1/WalletPool.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/WalletPool/regen/attempt_1/WalletPool.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 12    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
