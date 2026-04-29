MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now I have the full context. Let me proceed with the pipeline phases.

**Phase 1 — Structure Analysis (DDL)**

From the bundle DDL:
- **Table**: `Dealing_dbo.Dealing_CEPDailyAudit_Conditions`
- **13 columns**: Date, RuleID, RuleName, HedgeServerID, ConditionID, Property, Operator, Value, TypeOfChange, Comments, LoginName, ChangeTime, UpdateDate
- **Distribution**: ROUND_ROBIN
- **Clustered Index**: `[Date] ASC`

PHASE 1 CHECKPOINT: PASS

**Phase 2 — Live Data Sampling**
Good. Sample retrieved. Let me get the row count via an alternative method.
PHASE 2 CHECKPOINT: PASS

**Phase 3 — Distribution Analysis**
PHASE 3 CHECKPOINT: PASS

**Phase 4 — Lookup Resolution**

No FK columns reference Dim/Dictionary tables directly. `RuleID` references `Dealing_CEPDailyAudit_Rules`; `ConditionID` references conditions; `HedgeServerID` identifies the hedge server (from Rules dimension). All resolved from bundle context.

PHASE 4 CHECKPOINT: PASS

**Phase 5 — JOIN Analysis**

From SP code, the INSERT into `Dealing_CEPDailyAudit_Conditions` uses:
- `#Conditions_ChangesFinal rcf LEFT JOIN #Dim_ConditionRule dcr ON rcf.ConditionID=dcr.ConditionID`

This JOIN brings in `RuleID`, `RuleName`, `HedgeServerID` from the condition-to-rule dimension.

PHASE 5 CHECKPOINT: PASS

**Phase 6 — Business Logic**

From SP analysis:
- Change detection uses `LAG()` over `SysStartTime` partitioned by `ConditionID`
- TypeOfChange values: `New Condition`, `Condition Deleted`, `Property Change`, `Operator Change`, `Value Change`
- Comments carry previous values for change events
- Rule context via `#Dim_ConditionRule` (ConditionID → CP → Rule)

PHASE 6 CHECKPOINT: PASS

**Phase 7 — View Dependency Scan**
PHASE 7 CHECKPOINT: PASS

**Phase 8 — SP Scan**

Writer SP identified: `Dealing_dbo.SP_CEPDailyAudit` (already in bundle). No other SPs reference this table beyond the view.

PHASE 8 CHECKPOINT: PASS

**Phase 9 — SP Logic Extraction**

From the SP code (in bundle), the INSERT into `Dealing_CEPDailyAudit_Conditions`:

```sql
INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_Conditions
SELECT 
@Date Date,
RuleID,
RuleName,
HedgeServerID,
rcf.ConditionID,
rcf.Property,
rcf.Operator,
rcf.Value,
TypeOfChange,
Comments,
PreviousAppLoginName AS AppLoginName,
ChangeTime,
GETDATE()
FROM #Conditions_ChangesFinal rcf
LEFT JOIN #Dim_ConditionRule dcr ON rcf.ConditionID=dcr.ConditionID
WHERE rcf.Date=@Date
```

Column-level source mapping:
- `Date` ← `@Date` (SP parameter)
- `RuleID` ← `#Dim_ConditionRule.RuleID` (resolved via condition→CP→rule chain)
- `RuleName` ← `#Dim_ConditionRule.RuleName`
- `HedgeServerID` ← `#Dim_ConditionRule.HedgeServerID`
- `ConditionID` ← `#Conditions_ChangesFinal.ConditionID` (from `External_Etoro_History_Conditions` / `External_Etoro_CEP_Conditions`)
- `Property` ← `External_Etoro_Dictionary_ConditionProperties.Name` (joined via `PropertyID`)
- `Operator` ← `External_Etoro_Dictionary_ConditionOperators.Name` (joined via `OperatorID`)
- `Value` ← `External_Etoro_CEP_Conditions.Value` / `External_Etoro_History_Conditions.Value`
- `TypeOfChange` ← SP-derived: `Property Change`, `Operator Change`, `Value Change`, `New Condition`, `Condition Deleted`
- `Comments` ← SP-derived: `CONCAT('Previous Property: ', PreviousProperty)` etc.
- `LoginName` ← `COALESCE(AppLoginName, PreviousAppLoginName)` from conditions temporal tables
- `ChangeTime` ← `SysStartTime` (for changes/new) / `SysEndTime` (for deletions)
- `UpdateDate` ← `GETDATE()`

PHASE 9 CHECKPOINT: PASS

**Phase 9B — ETL Orchestration**

Same pattern as other CEPDailyAudit tables: DELETE + INSERT for `@Date`. Daily OpsDB/Service Broker schedule. Priority 0.

PHASE 9B CHECKPOINT: PASS

**Phase 10 — Atlassian**

No Atlassian sources found for CEP audit tables (consistent with sibling wikis).

PHASE 10 CHECKPOINT: PASS

**Phase 10A — Upstream Wiki**

Bundle provides 6 upstream wikis (sibling CEPDailyAudit tables). The Conditions table is the CONDITIONS DEFINITION audit — it shares the same writer SP and family pattern. Upstream source is `Dealing_staging.External_Etoro_CEP_Conditions` + `External_Etoro_History_Conditions` + two dictionary tables (`ConditionProperties`, `ConditionOperators`).

PHASE 10A CHECKPOINT: PASS

**Phase 10B — Column Lineage (writing .lineage.md FIRST)**

Now I'll write the three output files.
PHASE 10B CHECKPOINT: PASS

```
PHASE GATE — Dealing_dbo.Dealing_CEPDailyAudit_Conditions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — Dealing_dbo.Dealing_CEPDailyAudit_Conditions:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_Conditions/regen/attempt_1/Dealing_CEPDailyAudit_Conditions.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_Conditions/regen/attempt_1/Dealing_CEPDailyAudit_Conditions.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_Conditions/regen/attempt_1/Dealing_CEPDailyAudit_Conditions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 13    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (sibling wikis used for family context and SP code; no Tier 1 possible — all columns are SP-derived from unresolved staging sources with no upstream wikis)
```
