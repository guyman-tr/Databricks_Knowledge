MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now proceeding with the pipeline phases.

**Phase 1 — Structure Analysis**: DDL already provided in the bundle. 10 columns identified.

Let me run the next phases in parallel.
PHASE 1 CHECKPOINT: PASS — 10 columns from DDL, HASH(WalletId), HEAP, NCI on partition_date.

PHASE 2 — Sample retrieved (10 rows). Row count DMV failed (permission denied). Let me get count via alternative and continue with Phase 3 + SP/view analysis.
PHASE 2 CHECKPOINT: PASS — 1,780,223 rows, date range 2019-06-11 to 2026-04-27, SynapseUpdateDate appears NULL in sample.

PHASE 3 CHECKPOINT: PASS — IsShown: True=1,780,157 / False=66. CryptoId: 174 distinct values. No other categorical columns match the distribution regex.

Now checking for ETL pipeline and additional context.
Good. The generic pipeline mapping shows: **WalletDB.Wallet.WalletAssets** → Bronze Append, daily (1440 min), parquet, UC target: `wallet.bronze_walletdb_wallet_walletassets`. Depth 0 = base table (no writer SPs).

Let me check for lookup tables and downstream references.
PHASE 2 CHECKPOINT: PASS — 1,780,223 rows, 2019-06-11 to 2026-04-27. SynapseUpdateDate populated from ~2025-04 onwards (daily ~06:00 UTC). etr_y/etr_ym/etr_ymd populated for historical data, empty for recent rows.

PHASE 3 CHECKPOINT: PASS — IsShown: 2 values (True=1,780,157, False=66). CryptoId: 174 distinct values (>15, not inlined).
PHASE 4 CHECKPOINT: PASS — CryptoId is an integer FK; no cryptocurrency dictionary table available in Synapse (CryptoCoinProviders maps blockchain providers, not crypto types).

PHASE 5 CHECKPOINT: PASS — WalletAssets joins via WalletId to EXW_CustomerWalletsView (through WalletPool).

PHASE 6 CHECKPOINT: PASS — Column groups: Identity (Id), Wallet key (WalletId), Asset ref (CryptoId), Timestamps (Occurred, SynapseUpdateDate), ETL partition (etr_y/etr_ym/etr_ymd, partition_date), Visibility (IsShown).

PHASE 7 CHECKPOINT: PASS — Referenced by EXW_CustomerWalletsView (active), EXW_TransactionsView (commented out).

PHASE 8 CHECKPOINT: [-] No stored procedures reference WalletAssets. Data loaded via Generic Pipeline.

PHASE 9 CHECKPOINT: [-] No writer SPs — Generic Pipeline direct load from WalletDB.Wallet.WalletAssets.

PHASE 9B CHECKPOINT: PASS — Generic Pipeline #651, Append, daily (1440 min), parquet.

PHASE 10 CHECKPOINT: [-] Skipped (regen harness, soft phase).

PHASE 10A CHECKPOINT: PASS — `_no_upstream_found.txt` present. Production source: WalletDB.Wallet.WalletAssets.

PHASE 10B — Writing lineage file.

```
PHASE GATE — EXW_Wallet.WalletAssets:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [-] P8 SP-scan (no SPs reference this table)
  [-] P9 SP-logic (no writer SPs)
  [x] P9B ETL         [-] P10 Jira (soft, regen)
  [x] P10A Upstream   [x] P10B Lineage
  → Ready for P11
```

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.WalletAssets:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/WalletAssets/regen/attempt_1/WalletAssets.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/WalletAssets/regen/attempt_1/WalletAssets.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/WalletAssets/regen/attempt_1/WalletAssets.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 10    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
