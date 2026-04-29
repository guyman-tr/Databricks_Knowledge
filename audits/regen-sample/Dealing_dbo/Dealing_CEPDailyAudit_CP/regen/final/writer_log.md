Starting the regen-harness pipeline for `Dealing_dbo.Dealing_CEPDailyAudit_CP`.

**Step 1: MCP Pre-flight check**
MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now executing pipeline phases.

**PHASE 1 — Structure Analysis (from DDL)**

DDL already in bundle. 11 columns: `Date`, `RuleID`, `RuleName`, `CompoundPropertyID`, `CPName`, `HedgeServerID`, `TypeOfChange`, `Comments`, `LoginName`, `ChangeTime`, `UpdateDate`. ROUND_ROBIN distribution, CLUSTERED INDEX on `[Date] ASC`.

PHASE 1 CHECKPOINT: PASS

**PHASE 2 & 3 — Live Data Sampling + Distribution** (parallel MCP queries)
PHASE 2 CHECKPOINT: PASS (1,034 rows, 2023-12-15 to 2026-04-19, 3 TypeOfChange values)
PHASE 3 CHECKPOINT: PASS (375 distinct rules, 697 CPs, 58 hedge servers, 4 logins; significant NULLs in RuleID/RuleName/HedgeServerID — 314/1034 NULL from LEFT JOIN)

**Phase 4 — Lookup**: No FK references to dimension/dictionary tables in this audit table. All IDs are CEP-internal.
PHASE 4 CHECKPOINT: PASS (no lookups applicable)

**Phase 5 — JOIN Analysis**: From SP code, the INSERT for `Dealing_CEPDailyAudit_CP` does `#CPChangesFinal LEFT JOIN #Dim_CPtoRule ON CompoundPropertyID`. Rule context (RuleID, RuleName, HedgeServerID) resolved through CP-to-rule mapping dimension.
PHASE 5 CHECKPOINT: PASS

**Phase 6 — Business Logic**: 3 event types: `New Compound Property` (209), `Name Change` (98), `Compound Property Deleted` (727). Comments carries previous name for Name Change rows. Rule context NULL when CP has no active rule mapping (LEFT JOIN).
PHASE 6 CHECKPOINT: PASS

**Phase 7 — View Dependencies**
PHASE 7 CHECKPOINT: PASS (one view: `V_Dealing_CEPDailyAudit_CP_Last180Days` — recent 180 days)

**Phase 8 — SP Scan**: Writer SP is `SP_CEPDailyAudit`. Already in bundle.
PHASE 8 CHECKPOINT: PASS

**Phase 9 — SP Logic**: Fully analyzed from bundle SP code. CP section builds `#CPLog` from `External_Etoro_History_CompoundProperties` UNION `External_Etoro_CEP_CompoundProperties`, uses `LAG()` for name changes, `RN`/`RN_Desc` for create/delete detection. INSERT joins `#Dim_CPtoRule` for rule context.
PHASE 9 CHECKPOINT: PASS

**Phase 9B — ETL**: DELETE + INSERT for `@Date`, daily batch (Priority 0 — OpsDB / Service Broker).
PHASE 9B CHECKPOINT: PASS

**Phase 10 — Atlassian**: No Jira/Confluence sources found for CEPDailyAudit family (consistent with sibling wikis).
PHASE 10 CHECKPOINT: PASS

**Phase 10A — Upstream Wiki**: The bundle contains 6 sibling wikis (Rules, Conditions, ConditionToCP, CPToRule, NameLists, ListCIDMapping) — these are **peer** tables in the same audit family, NOT column-level upstreams for Tier 1 inheritance. The actual upstream sources are `Dealing_staging.External_Etoro_*` tables (unresolved — no wikis). All columns are SP-derived → Tier 2.
PHASE 10A CHECKPOINT: PASS

**Phase 10B — Lineage**: Writing lineage file first.

```
PHASE GATE — Dealing_dbo.Dealing_CEPDailyAudit_CP:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files. Let me ensure the output directory exists.
Good, directory exists. Writing the three files now.
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_CEPDailyAudit_CP:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_CP/regen/attempt_1/Dealing_CEPDailyAudit_CP.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_CP/regen/attempt_1/Dealing_CEPDailyAudit_CP.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_CP/regen/attempt_1/Dealing_CEPDailyAudit_CP.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 11    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (upstream wikis are sibling audit tables, not column-level sources — staging tables have no wikis)
```
