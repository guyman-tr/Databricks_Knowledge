MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now proceeding with the pipeline phases.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

- **Object**: `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP`
- **12 columns**: FromDate, ToDate, RuleID, RuleName, HedgeServerID, CompoundPropertyID, CP_Name, ConditionID, TypeOfChange, LoginName, ChangeTime, UpdateDate
- **Distribution**: ROUND_ROBIN
- **Clustered Index**: `[FromDate] ASC`

PHASE 1 CHECKPOINT: PASS

Running Phase 2 (sampling) and Phase 3 (distribution) in parallel.
PHASE 2 CHECKPOINT: PASS

**Phase 2 findings:**
- **~9,903 rows**, date range **2021-09-26 → 2026-04-19** (active)
- TypeOfChange: `Condition Removed from CP` (6,814), `Condition Added To CP` (3,041), NULL/placeholder (48)
- 731 distinct CPs, 5,170 distinct conditions, 446 distinct rules
- RuleID NULL in 1,306 rows (CP→Rule resolution gap)

PHASE 3 CHECKPOINT: PASS

**Phase 3 findings:** ROUND_ROBIN distribution, small-to-moderate table, no PII. No special distribution concerns.

**Phase 4 — Lookup**: No direct FK/dim lookups. Rule context resolved via CP→Rule chain in SP.

PHASE 4 CHECKPOINT: PASS

**Phase 5 — JOIN**: INSERT uses LEFT JOIN to `#ConditionToCP_ChangesFinal` and `#Dim_CPtoRule`. Fan-out possible when one CP maps to multiple rules.

PHASE 5 CHECKPOINT: PASS

**Phase 6 — Business Logic**: Two event types (add/remove condition from CP). Placeholder rows for empty weeks. Rule context denormalized via CP→Rule chain.

PHASE 6 CHECKPOINT: PASS

**Phase 7 — Views**: [-] No views reference this audit table (CEP audit tables are terminal).

**Phase 8 — SP Scan**: Writer is `Dealing_dbo.SP_W_CEPWeeklyAudit`. No reader SPs identified.

PHASE 8 CHECKPOINT: PASS

**Phase 9 — SP Logic**: Full column mapping traced from SP code (see analysis above). All columns sourced from `#ConditionToCP_ChangesFinal` + `#Dim_CPtoRule` + SP parameters.

PHASE 9 CHECKPOINT: PASS

**Phase 9B — ETL**: Weekly Sunday job, DELETE + INSERT for the week key. Priority 0 in OpsDB/Service Broker.

PHASE 9B CHECKPOINT: PASS

**Phase 10 — Atlassian**: [-] No Atlassian sources found for CEP audit tables (consistent with siblings).

**Phase 10A — Upstream Wiki**: Bundle contains 6 sibling wikis + SP code. Real upstream sources are `Dealing_staging.External_Etoro_*` tables (unresolved — no wikis). Sibling columns documented at Tier 2. No Tier 1 inheritance applicable.

PHASE 10A CHECKPOINT: PASS

Now writing Phase 10B (lineage) and then Phase 11 (documentation).

```
PHASE GATE — Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this audit table)
  [x] P8 SP-scan      [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (no Atlassian sources)
  [x] P10A Upstream   [x] P10B Lineage
  → Ready for P11
```
Directory exists. Now writing the three output files in order: lineage first, then wiki, then review-needed.
```
OUTPUT CHECK — Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_ConditionToCP/regen/attempt_1/Dealing_CEPWeeklyAudit_ConditionToCP.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_ConditionToCP/regen/attempt_1/Dealing_CEPWeeklyAudit_ConditionToCP.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_ConditionToCP/regen/attempt_1/Dealing_CEPWeeklyAudit_ConditionToCP.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 11    Tier3: 0    Tier4: 1
  Bundle inheritance used: NO  (NO is valid — upstream sources are all Dealing_staging External tables with no wikis; bundle contains sibling wikis only, not parent sources)
```
