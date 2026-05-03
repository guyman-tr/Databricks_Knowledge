MCP PRE-FLIGHT: PASS

Now loading the required rule files and the upstream bundle in parallel.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 9 columns, HASH(SentTransactionId), HEAP, NCI on partition_date.

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
Phase 2 sample obtained. Row count DMV denied — let me try an alternative count approach. Meanwhile reading the SP and view that reference this table.
**PHASE 2 CHECKPOINT: PASS** — 4,554,916 rows, date range 2018-04-23 to 2026-04-27. SynapseUpdateDate all NULL in sample.

**PHASE 8 CHECKPOINT: PASS** — No writer SP found. Table is read by: `SP_EXW_C2F_E2E` (joins on SentTransactionId, reads StatusId/Occurred), `EXW_TransactionsView` (subqueries for latest StatusId/Occurred). Loaded via Generic Pipeline (etr_* columns present).

Now running Phase 3 (distribution on StatusId — the only categorical column matching the regex) and checking the generic pipeline mapping.
**PHASE 3 CHECKPOINT: PASS** — StatusId distribution: 0=1,858,528, 2=1,851,258, 1=806,724, 3=27,486, 6=10,904, 4=10, 5=6. Only 1 categorical column matched the regex.

Now searching for the pipeline mapping entry and looking for the dictionary for StatusId.
**PHASE 4 CHECKPOINT: PASS** — StatusId → WalletDB_Dictionary_TransactionStatus: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError (7 values, inline).

**PHASE 5 CHECKPOINT: PASS** — JOIN patterns: SP_EXW_C2F_E2E joins on SentTransactionId and resolves StatusId via dictionary. EXW_TransactionsView uses correlated subqueries `SELECT TOP 1 StatusId ... ORDER BY Id DESC` to get latest status.

**PHASE 6 CHECKPOINT: PASS** — Status history table. Each SentTransaction accumulates multiple status records. Latest status = max Id. Lifecycle: Pending(0) → Confirmed(1) → Verified(2), error paths: Error(3), Timeout(4), PermanentError(5), WavedError(6).

**PHASE 7 CHECKPOINT: PASS** — Referenced by EXW_Wallet.EXW_TransactionsView.

**PHASE 9 CHECKPOINT: PASS** — No writer SP. Production source = WalletDB.Wallet.SentTransactionStatuses via Generic Pipeline (Append, daily).

**PHASE 9B CHECKPOINT: PASS** — Generic Pipeline, Append strategy, 1440 min (daily), parquet. UC target: `wallet.bronze_walletdb_wallet_senttransactionstatuses`.

**PHASE 10 CHECKPOINT: [-]** — Skipped (dormant object, no-upstream marker present).

**PHASE 10A CHECKPOINT: PASS** — No upstream wiki resolvable (confirmed by `_no_upstream_found.txt`). Production source: WalletDB.Wallet.SentTransactionStatuses.

**PHASE 10B CHECKPOINT: PASS** — Writing lineage file now.

```
PHASE GATE — EXW_Wallet.SentTransactionStatuses:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (dormant) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files.
All three files written. Final output check:

```
OUTPUT CHECK — EXW_Wallet.SentTransactionStatuses:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/SentTransactionStatuses/regen/attempt_1/SentTransactionStatuses.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/SentTransactionStatuses/regen/attempt_1/SentTransactionStatuses.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/SentTransactionStatuses/regen/attempt_1/SentTransactionStatuses.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 4    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
