Starting the regen pipeline for `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule`.
MCP PRE-FLIGHT: PASS

Now loading rule files and reading the GOLDEN-REFERENCE in parallel.
Rules loaded. Now executing phases. Starting with P1 (DDL already in bundle), P2 (live sample), P3 (distribution), and P7/P8 (view/SP scans) in parallel.

**PHASE 1 CHECKPOINT: PASS** — DDL from bundle: 11 columns, ROUND_ROBIN, CLUSTERED INDEX on `[Date]`.
**PHASE 2 CHECKPOINT: PASS** — Sample retrieved. Active pipeline, max Date 2026-03-25. Now getting row count and distribution.
**PHASE 3 CHECKPOINT: PASS** — Distribution analyzed. 39,440 rows, 2023-12-15 to 2026-03-25. 4 TypeOfChange values, IsTrue is bit (True/False).

Now completing remaining phases. P4 (no FK lookups needed — all columns are audit fields), P5/P6 (JOIN patterns from SP already in bundle), P7 (no views reference this table), P8 (only SP_CEPDailyAudit references it), P9 (SP logic fully traced from bundle).

**PHASE 4 CHECKPOINT: PASS** — No FK lookups required; all columns are audit-context fields with no dim references.

**PHASE 5 CHECKPOINT: PASS** — JOINs traced from SP: `#CPToRule_Log` LEFT JOIN `#Dim_CPtoRule` for RuleName/HedgeServerID context.

**PHASE 6 CHECKPOINT: PASS** — Column groups: identifiers (RuleID, CompoundPropertyID), context (RuleName, CP_Name, HedgeServerID, IsTrue), event (TypeOfChange), attribution (LoginName, ChangeTime), metadata (Date, UpdateDate).

**PHASE 7 CHECKPOINT: PASS** — No views reference this table (grep returned empty from Views folder).

**PHASE 8 CHECKPOINT: PASS** — Only writer SP: `Dealing_dbo.SP_CEPDailyAudit`. No other SPs reference this table.

**PHASE 9 CHECKPOINT: PASS** — Full column lineage traced from SP code (see bundle analysis).

**PHASE 9B CHECKPOINT: PASS** — Daily refresh via `SP_CEPDailyAudit(@Date)`, DELETE+INSERT pattern, Priority 0 (OpsDB/Service Broker).

**PHASE 10 CHECKPOINT: PASS** — No Atlassian sources found for this specific object.

**PHASE 10A CHECKPOINT: PASS** — Production source: `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` + `External_Etoro_History_CompoundPropertyToRule`. No production wikis exist for these staging tables (unresolved in bundle). Sibling CEPDailyAudit wikis used for relationship context only.

Now writing the three output files. Lineage first.

```
PHASE GATE — Dealing_dbo.Dealing_CEPDailyAudit_CPToRule:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
**PHASE 10B CHECKPOINT: PASS** — Lineage file written.

Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_CEPDailyAudit_CPToRule:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_CPToRule/regen/attempt_1/Dealing_CEPDailyAudit_CPToRule.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_CPToRule/regen/attempt_1/Dealing_CEPDailyAudit_CPToRule.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_CPToRule/regen/attempt_1/Dealing_CEPDailyAudit_CPToRule.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 11    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (sibling wikis used for relationship context; no Tier 1 inheritance possible — all staging sources unresolved)
```
