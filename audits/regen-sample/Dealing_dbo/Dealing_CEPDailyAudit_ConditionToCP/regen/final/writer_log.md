Starting the regen harness for `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP`. First: MCP pre-flight.
MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now running Phase 1 (DDL already in bundle), Phase 2 (sample), Phase 3 (distribution), and repo searches in parallel.

**PHASE 1 CHECKPOINT: PASS** — DDL analyzed from bundle. 11 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on `[Date]`.
**PHASE 2 CHECKPOINT: PASS** — 6,604 rows, 2023-12-12 to 2026-04-19, 175 distinct dates. Active pipeline.
**PHASE 3 CHECKPOINT: PASS** — Distribution analysis complete. TypeOfChange has 2 values: `Condition Removed from CP` (5,812), `Condition Added To CP` (792). RuleID null in ~18% of rows (orphan CPs without rule mapping). LoginName null in ~63% of rows.

Now completing remaining phases. P4 (Lookup) — no FK-style lookup columns, all are CEP internal IDs. P5 (JOINs) — already analyzed from SP bundle. P6 (Business Logic) — derived from SP. P7 — no views reference this table. P8/P9 — SP_CEPDailyAudit is the sole writer, already in bundle.

**PHASE 4 CHECKPOINT: PASS** — No dictionary/dim joins for this table; all IDs are CEP-internal.
**PHASE 5 CHECKPOINT: PASS** — JOINs analyzed from SP: #ConditionToCP_ChangesFinal LEFT JOIN #Dim_CPtoRule.
**PHASE 6 CHECKPOINT: PASS** — Two event types: add/remove of conditions from CPs.
**PHASE 7 CHECKPOINT: PASS** — No views reference this table in the SSDT repo.
**PHASE 8 CHECKPOINT: PASS** — Only writer: SP_CEPDailyAudit. No other SPs reference this table.
**PHASE 9 CHECKPOINT: PASS** — Full SP logic traced (see analysis below).
**PHASE 9B CHECKPOINT: PASS** — Daily refresh, Priority 0 (OpsDB/Service Broker). DELETE + INSERT for @Date.
**PHASE 10 CHECKPOINT: PASS** — No Atlassian sources found.
**PHASE 10A CHECKPOINT: PASS** — 6 upstream wikis in bundle, all read. Production source: Dealing_staging CEP temporal tables.

Now analyzing column lineage from SP code for Phase 10B.

**SP Column Trace for ConditionToCP INSERT:**
- `Date` ← `@Date` (SP parameter)
- `RuleID` ← `#Dim_CPtoRule.RuleID` (LEFT JOIN on CompoundPropertyID) — resolved via CPToRule_Log → RulesLog chain
- `RuleName` ← `#Dim_CPtoRule.RuleName` — denormalized from rules
- `HedgeServerID` ← `#Dim_CPtoRule.HedgeServerID` — from rules
- `CompoundPropertyID` ← `#ConditionToCP_ChangesFinal.CompoundPropertyID` ← `#ConditionToCP_Log.CompoundPropertyID` ← `External_Etoro_CEP_ConditionToCompoundProperty` / `External_Etoro_History_ConditionToCompoundProperty`
- `CP_Name` ← `#ConditionToCP_Log.CP_Name` ← `#CPLog` (latest name by CompoundPropertyID)
- `ConditionID` ← `#ConditionToCP_ChangesFinal.ConditionID` ← source staging tables
- `TypeOfChange` ← SP-derived: `'Condition Added To CP'` or `'Condition Removed from CP'`
- `LoginName` ← `COALESCE(AppLoginName, PreviousAppLoginName)` (aliased as PreviousAppLoginName in temp table)
- `ChangeTime` ← `SysStartTime` (for adds) or `SysEndTime` (for removes)
- `UpdateDate` ← `GETDATE()`

**PHASE 10B CHECKPOINT: PASS**

Now writing the three output files.

```
PHASE GATE — Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_ConditionToCP/regen/attempt_1/Dealing_CEPDailyAudit_ConditionToCP.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_ConditionToCP/regen/attempt_1/Dealing_CEPDailyAudit_ConditionToCP.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_ConditionToCP/regen/attempt_1/Dealing_CEPDailyAudit_ConditionToCP.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 11    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (upstream wikis consulted for sibling table context and SP logic verification; 0 Tier 1 is correct because all columns are ETL-computed/SP-derived with no direct passthrough from an upstream wiki-documented source column)
```
