Starting the regen-harness pipeline for `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions`.

**Step 1: MCP Pre-flight check**
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing pipeline phases.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

14 columns identified: `FromDate`, `ToDate`, `RuleID`, `RuleName`, `HedgeServerID`, `ConditionID`, `Property`, `Operator`, `Value`, `TypeOfChange`, `Comments`, `LoginName`, `ChangeTime`, `UpdateDate`. Distribution: ROUND_ROBIN, Clustered Index on `[FromDate]`.

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
PHASE 2 CHECKPOINT: PASS — 12,661 rows, 2021-09-26 → 2026-04-19, 5 change types + placeholder rows.

PHASE 3 CHECKPOINT: PASS — TypeOfChange: New Condition (3,129), Value Change (3,102), Property Change (3,089), Operator Change (2,971), Condition Deleted (312), NULL placeholders (58). 16 distinct Property values, 8 distinct Operator values.

Now running remaining phases. Let me check for views referencing this table.
No views or additional SPs reference this table — only the DDL and writer SP.

PHASE 4 CHECKPOINT: PASS — No FK columns requiring Dim lookup
PHASE 5 CHECKPOINT: PASS — SP LEFT JOINs: #Conditions_ChangesFinal + #Dim_ConditionRule (via ConditionToCP→CPToRule→Rules chain)
PHASE 6 CHECKPOINT: PASS — 5 change event types + NULL placeholders
PHASE 7 CHECKPOINT: PASS — No views reference this table
PHASE 8 CHECKPOINT: PASS — Writer: SP_W_CEPWeeklyAudit, no reader SPs
PHASE 9 CHECKPOINT: PASS — Full column tracing complete from SP code
PHASE 9B CHECKPOINT: PASS — Weekly Sunday, DELETE+INSERT per week key
PHASE 10 CHECKPOINT: PASS — No Atlassian sources
PHASE 10A CHECKPOINT: PASS — Upstream staging externals unresolved (no wikis); sibling audit wikis used for relationship context
PHASE 10B — Writing lineage file now

```
PHASE GATE — Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
Now writing all three output files.
```
OUTPUT CHECK — Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_Conditions/regen/attempt_1/Dealing_CEPWeeklyAudit_Conditions.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_Conditions/regen/attempt_1/Dealing_CEPWeeklyAudit_Conditions.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_Conditions/regen/attempt_1/Dealing_CEPWeeklyAudit_Conditions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 13    Tier3: 0    Tier4: 1
  Bundle inheritance used: NO  (NO is valid — all upstream sources are unresolved Dealing_staging externals with no wikis)
```
