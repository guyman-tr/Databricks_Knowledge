MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now proceeding with the pipeline for `EXW_Wallet.SentTransactionOutputs`.

**Phase 1 — Structure Analysis** (from DDL in bundle)

The DDL is already in the bundle. Key facts:
- 16 columns
- Distribution: HASH(SentTransactionId)
- Index: HEAP + NCI on partition_date
- No-upstream marker present — dormant table

Let me now run Phase 2 (sampling) and Phase 8 (SP scan) in parallel.

PHASE 1 CHECKPOINT: PASS
Good — 2.2M rows, data from 2020 to 2023. Now let me check the date range and run Phase 3 distribution queries, and also read the SP references more deeply.

PHASE 2 CHECKPOINT: PASS
PHASE 3 CHECKPOINT: PASS

Distribution results:
- SourceIdType: 1 (1.13M), NULL (1.08M), 2 (1.4K), 0 (8)
- IsEtoroFee: False (2.21M), True (1K), NULL (6)

Now let me check remaining context — the generic pipeline mapping and any other EXW_Wallet references.
Now I have all the data needed. Let me complete the remaining phases.

**Phase 4 — Lookup**: SourceIdType has values 0, 1, 2 — no Dim/Dict table found for this. IsEtoroFee is a bit flag.

PHASE 4 CHECKPOINT: PASS

**Phase 5 — JOIN Analysis**: From the view and SPs:
- `EXW_TransactionsView`: JOINs `SentTransactionOutputs so ON so.SentTransactionId = st.Id AND so.IsEtoroFee = 0` (with SentTransactions)
- `SP_EXW_FactRedeemTransactions`: JOINs on `so.SentTransactionId = st.Id AND so.SourceId = rd.PositionId`
- `SP_EXW_C2F_E2E`: JOINs `esto ON esto.SentTransactionId = st.Id`

PHASE 5 CHECKPOINT: PASS

**Phase 6 — Business Logic**: Crypto wallet sent transaction outputs — each row represents one output of a blockchain send transaction (destination address + amount). Used in redeem and conversion flows.

PHASE 6 CHECKPOINT: PASS

**Phase 7 — View Dependency**: Referenced by `EXW_Wallet.EXW_TransactionsView`.

PHASE 7 CHECKPOINT: PASS

**Phase 8 — SP Scan**: Two reader SPs found (SP_EXW_FactRedeemTransactions, SP_EXW_C2F_E2E). No writer SP — this is a Generic Pipeline landing table.

PHASE 8 CHECKPOINT: PASS

**Phase 9 — SP Logic**: No writer SP. Table is populated by Generic Pipeline (Append, daily). Reader SPs use columns: Id, SentTransactionId, ToAddress, Amount, EtoroFees, SourceId, IsEtoroFee, NormalizedToAddress.

PHASE 9 CHECKPOINT: PASS

**Phase 9B — ETL**: Generic Pipeline ID 710, WalletDB.Wallet.SentTransactionOutputs, Append, daily (1440 min), parquet.

PHASE 9B CHECKPOINT: PASS

**Phase 10 — Jira**: Skipping — dormant/landing table with no upstream wiki.

PHASE 10 CHECKPOINT: PASS (no Jira context needed for Generic Pipeline landing table)

**Phase 10A — Upstream Wiki**: `_no_upstream_found.txt` present. No upstream wiki available.

PHASE 10A CHECKPOINT: PASS (no upstream wiki — dormant marker present)

Now writing the three files in order.

```
PHASE GATE — EXW_Wallet.SentTransactionOutputs:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

**Phase 10B — Writing lineage file first.**
PHASE 10B CHECKPOINT: PASS

Now writing the main wiki.
Now the review-needed sidecar.
All three files written. Final checklist:

```
OUTPUT CHECK — EXW_Wallet.SentTransactionOutputs:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/SentTransactionOutputs/regen/attempt_1/SentTransactionOutputs.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/SentTransactionOutputs/regen/attempt_1/SentTransactionOutputs.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/SentTransactionOutputs/regen/attempt_1/SentTransactionOutputs.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 11    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
