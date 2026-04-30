

MCP PRE-FLIGHT: Testing Synapse connectivity...
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now proceeding through the pipeline phases.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

DDL already in the bundle:
- 6 columns: CID (int NOT NULL), Week1 (int NULL), Year1 (int NULL), NewTrades (int NOT NULL), UpdateDate (datetime NOT NULL), FirstDayOfWeek (date NULL)
- Distribution: HASH(CID)
- Index: CLUSTERED INDEX (CID ASC)

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
PHASE 2 CHECKPOINT: PASS
- ~4,419 distinct CIDs, 225 distinct weeks
- Date range: 2019-12-29 to 2024-04-14
- Data stopped refreshing 2024-04-15 (consistent with parent SP)
- ~3,220 rows per weekly slice (latest)
- NewTrades range: 0 to 8,400, avg ~9.07

**PHASE 3 — Distribution Analysis** (no categorical columns match the regex — skip distribution queries per cap rule)

PHASE 3 CHECKPOINT: PASS (no categorical columns to analyze)

**PHASE 4 — Lookup Resolution** — No FK IDs in this table. All columns are simple integers/dates.

PHASE 4 CHECKPOINT: PASS

**PHASE 5 — JOIN Analysis** — Already traced from SP code in bundle. The table is consumed by section 4.2 of the SP for `AVG(NewTrades)`.

PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic** — Simple shadow cache with PI population filter + weekly trade count aggregation.

PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependencies** — No views reference this table (it's a PI dashboard intermediate).

PHASE 7 CHECKPOINT: PASS

**PHASE 8 — SP Scan** — Writer: `SP_PI_Dashboard_COPYDATA_RuningSideBySide` (sections 4.1 + daily refresh). Consumer: same SP section 4.2.

PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic** — Fully traced from bundle SP code. Column mappings:
- CID ← BI_DB_CID_WeeklyPanel_FullData.CID (passthrough)
- Week1 ← BI_DB_CID_WeeklyPanel_FullData.SSWeekNumberOfYear (passthrough)
- Year1 ← BI_DB_CID_WeeklyPanel_FullData.CalendarYear (passthrough)
- NewTrades ← BI_DB_CID_WeeklyPanel_FullData.NewTrades_Total (passthrough)
- UpdateDate ← GETDATE()
- FirstDayOfWeek ← BI_DB_CID_WeeklyPanel_FullData.FirstDayOfWeek (passthrough)

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration** — Maintained by SP_PI_Dashboard_COPYDATA_RuningSideBySide, daily schedule. Stopped ~2024-04-15.

PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Atlassian** — Skipped (regen harness mode).

PHASE 10 CHECKPOINT: [-] Skipped (regen harness)

**PHASE 10A — Upstream Wiki** — Bundle contains upstream wikis for BI_DB_CID_WeeklyPanel_FullData, Dim_Customer, and all other sources.

PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage** — Writing lineage file first.

```
PHASE GATE — BI_DB_dbo.BI_DB_PI_WeeklyTrades:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_PI_WeeklyTrades:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_WeeklyTrades/regen/attempt_1/BI_DB_PI_WeeklyTrades.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_WeeklyTrades/regen/attempt_1/BI_DB_PI_WeeklyTrades.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_WeeklyTrades/regen/attempt_1/BI_DB_PI_WeeklyTrades.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 1    Tier2: 5    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
