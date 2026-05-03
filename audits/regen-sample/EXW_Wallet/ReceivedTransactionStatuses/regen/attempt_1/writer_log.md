MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis**

From DDL: 10 columns, HASH(ReceivedTransactionId), HEAP, NCI on partition_date.

| # | Column | Type | Nullable |
|---|--------|------|----------|
| 1 | Id | bigint | YES |
| 2 | ReceivedTransactionId | bigint | YES |
| 3 | StatusId | int | YES |
| 4 | Occurred | datetime2(7) | YES |
| 5 | DetailsJson | varchar(max) | YES |
| 6 | etr_y | varchar(max) | YES |
| 7 | etr_ym | varchar(max) | YES |
| 8 | etr_ymd | varchar(max) | YES |
| 9 | SynapseUpdateDate | datetime | YES |
| 10 | partition_date | date | YES |

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling + row count), Phase 3 prep, and Phase 8 (SP scan) in parallel.
Good. Let me get the row count via a different method and continue with remaining phases.
PHASE 2 CHECKPOINT: PASS (5.6M rows, Sept 2018 to Apr 2026)

Now running Phase 3 (distribution) and checking pipeline mapping + SPs.
PHASE 3 CHECKPOINT: PASS (StatusId: 7 distinct values)

Let me verify SynapseUpdateDate before writing.
Good. Now I have all the data needed. Let me check the staging DDL for completeness.
Now I have all phase data. Let me print the gates and write the output files.

```
PHASE GATE — EXW_Wallet.ReceivedTransactionStatuses:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [-] P5 JOIN (no writer SPs)  [x] P6 BizLogic
  [x] P7 Views        [-] P8 SP-scan (CopyFromLake, no SPs)  [-] P9 SP-logic (no SPs)
  [-] P9B ETL (CopyFromLake daily)  [-] P10 Jira (regen harness)  [-] P10A Upstream (no upstream wiki)
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final checklist:

```
OUTPUT CHECK — EXW_Wallet.ReceivedTransactionStatuses:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/ReceivedTransactionStatuses/regen/attempt_1/ReceivedTransactionStatuses.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/ReceivedTransactionStatuses/regen/attempt_1/ReceivedTransactionStatuses.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/ReceivedTransactionStatuses/regen/attempt_1/ReceivedTransactionStatuses.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 5    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
