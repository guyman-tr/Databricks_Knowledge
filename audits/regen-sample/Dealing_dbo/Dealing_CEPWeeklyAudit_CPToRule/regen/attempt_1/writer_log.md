Starting the regen harness pipeline for `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule`.

**Step 1: MCP Pre-flight check.**
MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now executing pipeline phases. Starting with Phase 1 (DDL already in bundle) and MCP queries for Phases 2-3 in parallel.

**PHASE 1 CHECKPOINT: PASS** — DDL parsed from bundle. 12 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on `[FromDate]`.
**PHASE 2 CHECKPOINT: PASS** — 58,248 rows, date range 2021-09-26 → 2026-04-19.
**PHASE 3 CHECKPOINT: PASS** — Distribution analyzed. TypeOfChange: 4 event types + 56 placeholders. LoginName NULL in 31,383 rows (54%).

Continuing through remaining phases.
**PHASE 4 CHECKPOINT: PASS** — No FK/dim lookups; all IDs are denormalized context.
**PHASE 5 CHECKPOINT: PASS** — JOINs analyzed from SP: `#CPToRule_Log` → `#CPToRule_ChangesFinal` → LEFT JOIN `#Dim_CPtoRule` for RuleName/HedgeServerID.
**PHASE 6 CHECKPOINT: PASS** — 4 change types: CP Added to Rule, CP Removed from Rule, Mapping Changed (True↔Not True).
**PHASE 7 CHECKPOINT: PASS** — No views reference this table.
**PHASE 8 CHECKPOINT: PASS** — Writer: `SP_W_CEPWeeklyAudit`. No reader SPs.
**PHASE 9 CHECKPOINT: PASS** — Full column trace completed from SP source.
**PHASE 9B CHECKPOINT: PASS** — Weekly Sunday batch, DELETE+INSERT for week key.
**PHASE 10 CHECKPOINT: PASS** — Skipped in regen harness.
**PHASE 10A CHECKPOINT: PASS** — Bundle consumed. No production wikis exist for staging source tables.
**PHASE 10B CHECKPOINT: PASS** — Lineage ready.

```
PHASE GATE — Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_CPToRule/regen/attempt_1/Dealing_CEPWeeklyAudit_CPToRule.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_CPToRule/regen/attempt_1/Dealing_CEPWeeklyAudit_CPToRule.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_CPToRule/regen/attempt_1/Dealing_CEPWeeklyAudit_CPToRule.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 11    Tier3: 0    Tier4: 1
  Bundle inheritance used: NO  (NO is valid — staging source tables are unresolved external tables with no wikis; sibling weekly audit wikis reviewed for consistency but are not upstream data sources for CPToRule columns)
```
