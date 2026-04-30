Starting MCP pre-flight check.
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline for `BI_DB_dbo.BI_DB_PositionPnL_SWITCH`.

**PHASE 1 — Structure Analysis (from DDL in bundle)**

The DDL is already in the bundle. 39 columns, identical schema to `BI_DB_PositionPnL`. HASH(PositionID), CLUSTERED INDEX on (DateID, Date, CID, PositionID), daily partitioned by DateID, NCI on (DateID, CID).

This is a **transient shadow table** used in the partition-switching pattern by `SP_BI_DB_PositionPnL_SWITCH`. It temporarily holds old partition data during the swap and is truncated at the end.

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
Table confirmed **empty (0 rows)** as expected — this is a transient shadow table that is truncated after every partition switch.

PHASE 2 CHECKPOINT: PASS (0 rows — table is always empty after ETL completes)

**PHASE 3 — Distribution Analysis**

No data to analyze — table is persistently empty (truncated at end of every SP_BI_DB_PositionPnL_SWITCH execution). No categorical columns to query.

PHASE 3 CHECKPOINT: PASS (0 rows — distribution analysis not applicable)

**Phases 4-9B** — Proceeding through remaining phases using the bundle.

From the SP code in the bundle (`SP_BI_DB_PositionPnL_SWITCH` and `SP_PositionPnL`):

- **P4 Lookup**: Same column set as BI_DB_PositionPnL — all lookups documented there.
- **P5 JOIN**: No JOINs in SP_BI_DB_PositionPnL_SWITCH — it's purely a partition swap mechanism.
- **P6 BizLogic**: Shadow table pattern — no business logic of its own.
- **P7 Views**: Let me check for views referencing this table.
No views reference this table. Only the two SPs (plus the backup) reference it.

- **P8 SP-scan**: Referenced by `SP_PositionPnL` (creates it dynamically) and `SP_BI_DB_PositionPnL_SWITCH` (uses it for partition swap).
- **P9 SP-logic**: From `SP_PositionPnL`, the SWITCH table is created via `CREATE TABLE ... AS SELECT TOP 0 * FROM BI_DB_PositionPnL` (empty clone). `SP_BI_DB_PositionPnL_SWITCH` swaps old partition data into it, swaps new data from SWITCH_SINGLE into the main table, then truncates SWITCH.
- **P9B ETL**: This table is part of the BI_DB_PositionPnL ETL pipeline, not independently scheduled.

Now let me check for UC target mapping.
No UC target — this is a transient infrastructure table, not migrated to Databricks.

```
PHASE GATE — BI_DB_dbo.BI_DB_PositionPnL_SWITCH:
  [x] P1 DDL          [x] P2 Sample        [-] P3 Dist (0 rows)
  [-] P4 Lookup       [-] P5 JOIN          [-] P6 BizLogic
  [-] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [-] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

P3: 0 rows, no distribution to analyze. P4-P6: Shadow table, no independent logic/lookups. P7: No views reference it. P9B: Not independently scheduled. P10: Regen harness, Jira skipped.

Now writing the three output files, starting with lineage.
Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_PositionPnL_SWITCH:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_PositionPnL_SWITCH/regen/attempt_1/BI_DB_PositionPnL_SWITCH.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_PositionPnL_SWITCH/regen/attempt_1/BI_DB_PositionPnL_SWITCH.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_PositionPnL_SWITCH/regen/attempt_1/BI_DB_PositionPnL_SWITCH.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 39    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES (BI_DB_PositionPnL wiki used for column descriptions)
```
