

MCP PRE-FLIGHT check:
MCP PRE-FLIGHT: PASS

Now loading rule files in parallel:
Rules loaded. Now executing pipeline phases. Starting with Phase 1 (DDL already in bundle), Phase 2 (sampling), Phase 3 (distribution), and Phase 8 (SP/view scan) in parallel.

PHASE 1 CHECKPOINT: PASS (DDL from bundle — 37 columns, ROUND_ROBIN, CLUSTERED INDEX on ReportDateID ASC, RealCID ASC)
Phase 2 sample collected. DMV permission denied for row count — let me get it another way, plus run distribution queries.
PHASE 2 CHECKPOINT: PASS (4.24M rows, date range 2025-04-26 to 2026-04-26, refreshed 2026-04-27)
PHASE 3 CHECKPOINT: PASS (distributions collected)
PHASE 4 CHECKPOINT: PASS (dim lookups resolved from bundle)
PHASE 5 CHECKPOINT: PASS (JOINs analyzed from SP code)
PHASE 6 CHECKPOINT: PASS (business logic: funnel conversion flags, contact tracking, verification stages)
PHASE 7 CHECKPOINT: [-] No views reference this table
PHASE 8 CHECKPOINT: PASS (SP_CIDFunnelFlow is sole writer, no consumer SPs found)
PHASE 9 CHECKPOINT: PASS (SP code fully traced — column lineage mapped)
PHASE 9B CHECKPOINT: PASS (daily TRUNCATE+INSERT, @Date parameter, 12-month rolling window)
PHASE 10 CHECKPOINT: [-] Skipped per regen harness
PHASE 10A CHECKPOINT: PASS (13 upstream wikis in bundle)
PHASE 10B — Writing lineage file first.
Now writing the main wiki file.
Now writing the review-needed file.
PHASE GATE — BI_DB_dbo.BI_DB_CIDFunnelFlow:
```
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_CIDFunnelFlow:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_CIDFunnelFlow/regen/attempt_1/BI_DB_CIDFunnelFlow.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_CIDFunnelFlow/regen/attempt_1/BI_DB_CIDFunnelFlow.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_CIDFunnelFlow/regen/attempt_1/BI_DB_CIDFunnelFlow.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 10    Tier2: 26    Tier3: 1    Tier4: 0
  Bundle inheritance used: YES
```
