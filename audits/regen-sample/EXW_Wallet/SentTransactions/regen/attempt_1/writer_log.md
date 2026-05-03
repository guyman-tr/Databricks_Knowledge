MCP PRE-FLIGHT: PASS

Now loading rule files.
Rules loaded. Starting pipeline for `EXW_Wallet.SentTransactions`.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 13 columns, HASH(Id), HEAP with NCI on partition_date. All columns nullable.

Now running Phase 2 (sampling) and Phase 8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — 1,860,740 rows, date range 2018-04-23 to 2026-04-27.

**PHASE 3 CHECKPOINT: PASS** — TransactionTypeId: 14 distinct values. CryptoId: 121 distinct values (too many for inline).

Now checking generic pipeline mapping and continuing remaining phases.
Good. Now I have the complete picture. Let me check the EXW_Dictionary.TransactionTypes table for TransactionTypeId values.
**PHASE 4 CHECKPOINT: PASS** — TransactionTypeId → EXW_Dictionary.TransactionTypes (14 values, inline). CryptoId → EXW_Wallet.CryptoTypes (121 values, join target).

**PHASE 5 CHECKPOINT: PASS** — JOINs via CorrelationId to Redemptions/Requests/Conversions; via Id to SentTransactionOutputs/SentTransactionStatuses.

**PHASE 6 CHECKPOINT: PASS** — Transaction type categorization, blockchain fee tracking, correlation-based subsystem linking.

**PHASE 7 CHECKPOINT: PASS** — Referenced by EXW_Wallet.EXW_TransactionsView.

**PHASE 8 CHECKPOINT: PASS** — Read by SP_EXW_Fact_Transactions, SP_EXW_C2F_E2E, SP_EXW_FactRedeemTransactions. No SP writes to this table.

**PHASE 9 CHECKPOINT: PASS** — All three SPs only READ from this table. It is a bronze source table loaded via Generic Pipeline.

**PHASE 9B CHECKPOINT: PASS** — Generic Pipeline, Append strategy, hourly (60 min), from WalletDB.Wallet.SentTransactions.

**PHASE 10 CHECKPOINT: PASS** — Skipped (regen harness, SOFT phase).

**PHASE 10A CHECKPOINT: PASS** — _no_upstream_found.txt exists, no upstream wiki resolvable.

**PHASE 10B CHECKPOINT: PASS** — Writing lineage now.

```
PHASE GATE — EXW_Wallet.SentTransactions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.SentTransactions:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/SentTransactions/regen/attempt_1/SentTransactions.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/SentTransactions/regen/attempt_1/SentTransactions.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/SentTransactions/regen/attempt_1/SentTransactions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 8    Tier4: 0
  Bundle inheritance used: NO  (NO is valid because _no_upstream_found.txt exists)
```
