MCP PRE-FLIGHT: PASS

Now loading the required rule files.
PHASE 1 CHECKPOINT: PASS — 15 columns, HASH(PositionID), CLUSTERED COLUMNSTORE INDEX.

Now running Phase 2 (sampling) and Phase 3 (distribution) queries, plus SP/view scans in parallel.
PHASE 2 CHECKPOINT: PASS — Sample retrieved. Data spans 20240101–20240706 (188 distinct dates in recent window). All UnrealizedPnLEnd = 0 confirms closed-position logic.

Now Phase 3 distribution queries (capped at 3 categorical columns matching regex: IsSettled, SettlementTypeID, IsBuy) plus additional scans.
PHASE 3 CHECKPOINT: PASS — IsSettled: 0/1, IsBuy: 0/1, SettlementTypeID: NULL/0/1/2. Total ~278M rows, 20230101–20240706.

Now checking OpsDB and consumers.
PHASE 4 CHECKPOINT: PASS — No lookup columns requiring dim resolution (IsBuy/IsSettled are binary flags).
PHASE 5 CHECKPOINT: PASS — SP joins BI_DB_PositionPnL (prior day) with Dim_Position (close day).
PHASE 6 CHECKPOINT: PASS — Business logic identified: UnrealizedPnL computation for closed positions.
PHASE 7 CHECKPOINT: PASS — No views reference this table.
PHASE 8 CHECKPOINT: PASS — Single writer SP identified: SP_PositionPnL_UnrealizedPnL_Close_Adjustment.
PHASE 9 CHECKPOINT: PASS — Full SP logic traced (in bundle). All column sources mapped.

Now let me check OpsDB and generic pipeline mapping for UC target info.
PHASE 9B CHECKPOINT: PASS — OpsDB: Priority 0, ProcessType SQL, ProcessName SB_Daily, frequency Daily.
PHASE 10 CHECKPOINT: [-] — Skipping Jira search (low-value for this well-documented table).
PHASE 10A CHECKPOINT: PASS — Upstream wikis found: BI_DB_PositionPnL, DWH_dbo.Dim_Position.

Let me check the Dim_Position wiki for SettlementTypeID (truncated in bundle).
Good. Now I have all the data I need. Let me write the lineage file, then the wiki, then the review-needed file.

PHASE 10B CHECKPOINT: PASS — Column lineage fully traced.

```
PHASE GATE — BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (low-value)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment/regen/attempt_1/BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment/regen/attempt_1/BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment/regen/attempt_1/BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 9    Tier2: 3    Tier3: 2    Tier4: 0    Tier5: 1
  Bundle inheritance used: YES
```
