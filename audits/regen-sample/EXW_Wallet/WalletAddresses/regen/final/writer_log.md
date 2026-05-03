MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now proceeding with the pipeline phases.

**Phase 1 — Structure Analysis**: DDL already provided in the bundle. 14 columns, HASH distributed on `WalletId`, HEAP storage, indexed on `partition_date`.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling), Phase 3 prep, and Phase 8 (SP scan) in parallel.
PHASE 2 CHECKPOINT: PASS (sample retrieved, 10 rows shown)

Let me get the row count via alternative method and read the SPs that reference this table.
Now let me check the view and the generic pipeline mapping.
PHASE 2 CHECKPOINT: PASS (2,465,354 rows, date range 2018-04-23 to 2026-04-26)

Phase 3 — Distribution Analysis. `CustomerWalletStatusId` is the only column matching the categorical regex (Status). Already queried — all 2,465,354 rows have value `1`. `IsMain` also queried — 2,465,304 True, 50 False.

PHASE 3 CHECKPOINT: PASS

Now let me check the generic pipeline mapping and look for the CopyFromLake source.
Good. Production source identified: `WalletDB.Wallet.WalletAddresses`, loaded via Generic Pipeline (Append, every 120 min). No writer SP — direct CopyFromLake ingestion.

PHASE 4 CHECKPOINT: PASS (CustomerWalletStatusId — no dictionary wiki found, all values = 1)
PHASE 5 CHECKPOINT: PASS (JOINed by SP_EXW_WalletInventory on WalletId+IsMain=1, SP_EXW_FactBalance indirectly, EXW_TransactionsView on NormalizedAddress)
PHASE 6 CHECKPOINT: PASS
PHASE 7 CHECKPOINT: PASS (EXW_TransactionsView references WalletAddresses for address exclusion filtering)
PHASE 8 CHECKPOINT: PASS (3 reader SPs found: SP_EXW_WalletInventory, SP_EXW_Hourly, SP_EXW_FactBalance; no writer SP — CopyFromLake direct load)
PHASE 9 CHECKPOINT: PASS (No writer SP; table loaded via Generic Pipeline CopyFromLake)
PHASE 9B CHECKPOINT: PASS (Generic Pipeline Append strategy, 120-min frequency, from WalletDB.Wallet.WalletAddresses)
PHASE 10 CHECKPOINT: [-] (Skipped — regen harness mode, Jira search not required)
PHASE 10A CHECKPOINT: PASS (_no_upstream_found.txt present — no upstream wiki resolvable)
PHASE 10B — Writing lineage file now.

```
PHASE GATE — EXW_Wallet.WalletAddresses:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.WalletAddresses:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/WalletAddresses/regen/attempt_1/WalletAddresses.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/WalletAddresses/regen/attempt_1/WalletAddresses.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/WalletAddresses/regen/attempt_1/WalletAddresses.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 9    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
