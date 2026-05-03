MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting pipeline for `EXW_Wallet.ConversionTransactions`.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 13 columns, HASH(ConversionId), HEAP.

Now running Phase 2 (sampling), Phase 3 prep, and Phase 8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — 98,713 rows sampled. Data spans 2018-12-24 to 2022-03-07+.

Now running Phase 3 (distribution on CryptoId — the only categorical column matching the regex) and checking the pipeline mapping.
**PHASE 3 CHECKPOINT: PASS** — CryptoId: 25 distinct values. EtoroFeePercentage: 3 values (0.10=99.98%).

Continuing with remaining phases.

**PHASE 4 CHECKPOINT: PASS** — CryptoId has no EXW_Dictionary lookup; resolves via EXW_Wallet.CryptoTypes.
**PHASE 5 CHECKPOINT: PASS** — EXW_TransactionsView joins ConversionTransactions via Conversions (conversion_in/out CTEs).
**PHASE 6 CHECKPOINT: PASS** — Per-leg transaction details for crypto conversions; ~2 rows per conversion.
**PHASE 7 CHECKPOINT: PASS** — Referenced by EXW_Wallet.EXW_TransactionsView.
**PHASE 8 CHECKPOINT: PASS** — No writer SPs found; data loaded via Generic Pipeline.
**PHASE 9 CHECKPOINT: [-]** — No SP code exists for this table (Generic Pipeline Bronze landing).
**PHASE 9B CHECKPOINT: PASS** — Generic Pipeline #656, WalletDB.Wallet.ConversionTransactions, daily Append, parquet.
**PHASE 10 CHECKPOINT: [-]** — Dormant table, low Jira value.
**PHASE 10A CHECKPOINT: PASS** — _no_upstream_found.txt confirmed; no production wiki resolvable.

Now writing the three output files.

```
PHASE GATE — EXW_Wallet.ConversionTransactions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic (no SP; Generic Pipeline Bronze)
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
```
OUTPUT CHECK — EXW_Wallet.ConversionTransactions:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/ConversionTransactions/regen/attempt_1/ConversionTransactions.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/ConversionTransactions/regen/attempt_1/ConversionTransactions.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/ConversionTransactions/regen/attempt_1/ConversionTransactions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 13    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
