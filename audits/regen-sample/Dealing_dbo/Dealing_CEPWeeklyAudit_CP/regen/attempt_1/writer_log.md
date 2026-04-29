MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Now let me run Phase 2 (sampling) and Phase 3 (distribution) queries in parallel.
PHASE 1 CHECKPOINT: PASS — DDL read from bundle. 12 columns, ROUND_ROBIN, CLUSTERED INDEX on `[FromDate]`.
PHASE 2 CHECKPOINT: PASS — 1,365 rows, date range 2021-09-26 → 2026-04-25, ACTIVE load.
PHASE 3 CHECKPOINT: PASS — TypeOfChange: `Compound Property Deleted` (727), `New Compound Property` (355), `Name Change` (204), NULL (79). 234 distinct weeks, 730 distinct CPs, 403 distinct rules, 989 NULL LoginName rows.

Now running phases 4-8 in parallel.
PHASE 4 CHECKPOINT: PASS — No FK/Dim lookups for this table; all columns are ETL-derived from staging externals.
PHASE 5 CHECKPOINT: PASS — JOIN patterns analyzed from SP code (LEFT JOIN #CPChangesFinal + LEFT JOIN #Dim_CPtoRule).
PHASE 6 CHECKPOINT: PASS — Business logic: 3 change types (New/NameChange/Deleted), Comments carries previous name for renames, NULL TypeOfChange = no-change placeholder.
PHASE 7 CHECKPOINT: PASS — No views reference this table.
PHASE 8 CHECKPOINT: PASS — Single writer: `SP_W_CEPWeeklyAudit`. No reader SPs found.
PHASE 9 CHECKPOINT: PASS — SP logic fully traced (see bundle). CP section sources from `#CPLog` → `#CPChangesFinal`, rule context from `#Dim_CPtoRule`.
PHASE 9B CHECKPOINT: PASS — Weekly Sunday batch, DELETE+INSERT per week key, Priority 0 in orchestration.
PHASE 10 CHECKPOINT: PASS — No Atlassian sources found.
PHASE 10A CHECKPOINT: PASS — Upstream bundle contains 6 sibling wikis (Rules, Conditions, ConditionToCP, CPToRule, NameLists, ListCIDMapping). These are related objects in same weekly audit family, not column-level Tier 1 sources for this CP table. All columns are ETL-computed by SP from staging externals.

Now let me confirm the output directory exists and write the three files.
PHASE GATE — Dealing_dbo.Dealing_CEPWeeklyAudit_CP:
```
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files. Lineage first.
PHASE 10B CHECKPOINT: PASS — lineage written.
```
OUTPUT CHECK — Dealing_dbo.Dealing_CEPWeeklyAudit_CP:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_CP/regen/attempt_1/Dealing_CEPWeeklyAudit_CP.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_CP/regen/attempt_1/Dealing_CEPWeeklyAudit_CP.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_CP/regen/attempt_1/Dealing_CEPWeeklyAudit_CP.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 11    Tier3: 0    Tier4: 1
  Bundle inheritance used: NO  (staging externals are unresolved — no upstream wiki provides column-level Tier 1 for CEP CompoundProperties; sibling wikis are related objects, not column sources)
```
