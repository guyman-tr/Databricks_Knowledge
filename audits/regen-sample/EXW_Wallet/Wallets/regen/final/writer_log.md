MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting pipeline for `EXW_Wallet.Wallets`.

## Phase 1 — Structure Analysis

DDL from bundle — 14 columns:

| # | Column | Type | Nullable |
|---|--------|------|----------|
| 1 | Id | bigint | YES |
| 2 | WalletId | uniqueidentifier | YES |
| 3 | Gcid | int | YES |
| 4 | BlockchainCryptoId | int | YES |
| 5 | WalletTypeId | int | YES |
| 6 | IsActive | bit | YES |
| 7 | Occurred | datetime2(7) | YES |
| 8 | BeginDate | datetime2(7) | YES |
| 9 | EndDate | datetime2(7) | YES |
| 10 | IsActivated | bit | YES |
| 11 | etr_y | varchar(max) | YES |
| 12 | etr_ym | varchar(max) | YES |
| 13 | etr_ymd | varchar(max) | YES |
| 14 | SynapseUpdateDate | datetime | YES |

Distribution: HASH(WalletId), HEAP.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
Phase 2 sampling successful. Let me get row count via COUNT and check views + SPs.
PHASE 2 CHECKPOINT: PASS — 1,498,021 rows, Occurred from 2018-04-23 to 2026-04-27.

Now running Phase 3 (distribution on categorical columns) and checking generic pipeline mapping.
PHASE 3 CHECKPOINT: PASS — WalletTypeId (7 values), IsActive (2 values), IsActivated (2 values).

Now searching for the pipeline mapping entry and checking lookup tables.
Good. Production source: WalletDB.Wallet.Wallets, Generic Pipeline Override daily, UC: `wallet.bronze_walletdb_wallet_wallets`.

Now Phase 4 (Lookup) and Phase 5 (JOIN).
PHASE 4 CHECKPOINT: PASS — WalletTypeId → EXW_Dictionary.WalletTypes (7 values), BlockchainCryptoId → EXW_Wallet.BlockchainCryptos (12 values).

Phase 5 through 10 — let me check the CopyFromLake staging and finalize the remaining phases.
All phases complete. Let me print the phase gate and write the three output files.

```
PHASE GATE — EXW_Wallet.Wallets:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic (no writer SP; Generic Pipeline landing table)
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

PHASE 5 CHECKPOINT: PASS
PHASE 6 CHECKPOINT: PASS
PHASE 7 CHECKPOINT: PASS
PHASE 8 CHECKPOINT: PASS
PHASE 9 CHECKPOINT: PASS (skipped — no writer SP)
PHASE 9B CHECKPOINT: PASS
PHASE 10 CHECKPOINT: PASS (skipped — SOFT)
PHASE 10A CHECKPOINT: PASS (no upstream wiki — _no_upstream_found.txt present)
PHASE 10B CHECKPOINT: PASS

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.Wallets:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/Wallets/regen/attempt_1/Wallets.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/Wallets/regen/attempt_1/Wallets.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/Wallets/regen/attempt_1/Wallets.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 4    Tier3: 10    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
