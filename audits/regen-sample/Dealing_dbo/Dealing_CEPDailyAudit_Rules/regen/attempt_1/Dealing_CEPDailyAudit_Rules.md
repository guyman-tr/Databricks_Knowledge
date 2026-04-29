# Dealing_dbo.Dealing_CEPDailyAudit_Rules

> 1,052-row daily audit trail of **CEP Rule** definition changes from 2023-12-13 to 2026-04-16 — captures name changes, description edits, activation/deactivation, priority shifts, hedge server reassignments, and rule creation/deletion in eToro's Client Execution Platform hedging rule engine. Loaded by `SP_CEPDailyAudit` (DELETE+INSERT per date). Active pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables via SP_CEPDailyAudit |
| **Refresh** | Daily (Priority 0 — OpsDB/Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table records every **CEP Rule definition change** detected by the daily audit pipeline. CEP (Client Execution Platform) rules control how eToro routes and hedges client positions. Each rule has a name, description, priority, activation status, and hedge server assignment. When any of these attributes changes — or when a rule is created or deleted — one row is written per change event for that business date.

**Source and lineage**: Data flows from `Dealing_staging.External_Etoro_CEP_Rules` (current state) and `External_Etoro_History_Rules` (temporal history). The writer SP `SP_CEPDailyAudit` uses `LAG()` window functions over system-time versioned records to detect changes across six attributes, then classifies each event by type via UNION ALL branches.

**Scale**: 1,052 rows from 2023-12-13 through 2026-04-16. Moderate volume — this table records rule-level definition changes (not CP-to-Rule mapping changes, which are higher volume at ~32K rows in the sibling `Dealing_CEPDailyAudit_CPToRule`).

**Load pattern**: `SP_CEPDailyAudit` performs `DELETE + INSERT` for the supplied `@Date`. Daily refresh. SLA: typically next business day for date D. Rows appear only on dates when rule changes actually occur — sparse relative to calendar days.

**Why it matters**: CEP rules are the top-level entities in the hedging rule hierarchy (Rule → Compound Property → Condition). Changes to rules — especially activation/deactivation and hedge server reassignments — can directly affect which client trades are hedged and through which server. This audit trail supports regulatory compliance, post-incident investigation, and governance oversight by the Dealing team.

---

## 2. Business Logic

### 2.1 Change Detection via Temporal Tables

**What**: The SP detects rule attribute changes by comparing successive system-time versions using `LAG()` window functions partitioned by `RuleID` and ordered by `SysStartTime`.

**Columns Involved**: `TypeOfChange`, `Comments`, `ChangeTime`, `LoginName`

**Rules**:
- Six attribute comparisons drive change detection: `Name`, `Description`, `IsActive`, `HedgeRuleActionTypeID` (→ HedgeServerID), `Priority`, plus creation/deletion
- Each attribute change produces a separate row via UNION ALL in `#RuleChangesFinal`
- A single rule with multiple attribute changes on the same date produces multiple rows (one per changed attribute)

### 2.2 Event Classification (TypeOfChange Values)

**What**: Eight distinct event types classify every rule change.

**Columns Involved**: `TypeOfChange`, `Comments`

**Rules**:
- `Name Change` — rule renamed; Comments = `"Previous Name: {oldName}"`
- `Description Change` — rule description edited; Comments = `"Previous Description: {oldDesc}"`
- `Activated` — `IsActive` flipped 0→1; Comments = NULL
- `Deactivated` — `IsActive` flipped 1→0; Comments = NULL
- `HedgeServerID Change` — hedge server reassigned; Comments = `"Previous HedgeServerID: {oldID}"`
- `Priority Change` — priority value changed; Comments = `"Previous Priority: {oldPriority}"`
- `New Rule` — rule created (RN=1 AND ChangeDate=@Date AND within 60 minutes of ValidFrom); Comments = NULL
- `Rule Deleted` — rule removed (RN_Desc=1 AND SysEndTime date=@Date); Comments = NULL

### 2.3 LoginName Resolution

**What**: Captures the CEP application user responsible for each change, even for deletion events.

**Columns Involved**: `LoginName`

**Rules**:
- Uses `COALESCE(AppLoginName, PreviousAppLoginName)` — the `PreviousAppLoginName` is derived via `LEAD(AppLoginName, 1) OVER (PARTITION BY RuleID ORDER BY SysEndTime DESC)` to capture the user identity from the temporal record even when the current row's `AppLoginName` is NULL (deletion scenarios)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `Date`. Small table (~1,052 rows). ROUND_ROBIN is appropriate for audit/log tables with no natural join key. No performance concerns for any query pattern.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What rule changes happened on date X? | `WHERE Date = 'YYYY-MM-DD'` |
| All changes to a specific rule | `WHERE RuleID = @id ORDER BY Date DESC` |
| When was a rule activated or deactivated? | `WHERE RuleID = @id AND TypeOfChange IN ('Activated', 'Deactivated')` |
| All new rules created in a date range | `WHERE Date BETWEEN @start AND @end AND TypeOfChange = 'New Rule'` |
| Hedge server reassignments | `WHERE TypeOfChange = 'HedgeServerID Change' ORDER BY Date DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_CEPDailyAudit_CP | `RuleID + Date` | Correlate rule-level changes with CP-level changes on the same day |
| Dealing_CEPDailyAudit_CPToRule | `RuleID + Date` | See which CP-to-Rule mappings changed alongside rule definition changes |
| Dealing_CEPDailyAudit_Conditions | `RuleID + Date` | Correlate condition changes with rule changes |

### 3.4 Gotchas

- **Multiple rows per rule per date**: A rule that changes name AND priority on the same day produces two rows. Don't assume one row per RuleID per Date.
- **`LoginName` contains trailing NULL bytes**: Sampled data shows `LoginName` values padded with `\0` characters — likely a fixed-length field artifact from the CEP system. Use `RTRIM()` or `REPLACE(LoginName, CHAR(0), '')` for clean display.
- **No sentinel rows**: Unlike sibling CEPDailyAudit tables (e.g., CP), this table has 0 NULL `TypeOfChange` values — no placeholder rows are written on days with no rule changes.
- **`HedgeServerID` is renamed from source**: The staging column is `HedgeRuleActionTypeID`; the SP renames it to `HedgeServerID` in `#RulesLog`.
- **`Description` column vs `Description Change` event**: The `Description` column holds the rule's current description text. The `Description Change` TypeOfChange event indicates the description was edited; the previous value is in `Comments`.
- This is one of 7 CEPDailyAudit tables, all written by the same SP: CP, CPToRule, ConditionToCP, Conditions, ListCIDMapping, NameLists, Rules.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date on which this rule change was recorded — equals `@Date` supplied to `SP_CEPDailyAudit`. Clustered index key. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | Unique identifier of the CEP Rule that changed. From `External_Etoro_CEP_Rules.RuleID`. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | Name of the CEP Rule at the time of the change. Mapped from source column `Name` (renamed to `RuleName` in DDL). For `Name Change` events, this is the NEW name; the previous name is in `Comments`. (Tier 2 — SP_CEPDailyAudit) |
| 4 | Description | varchar(max) | YES | Description text of the CEP Rule at the time of the change. For `Description Change` events, this is the NEW description; the previous is in `Comments`. (Tier 2 — SP_CEPDailyAudit) |
| 5 | HedgeServerID | int | YES | Hedge server associated with this rule — identifies which hedging server processes the rule. Renamed from source column `HedgeRuleActionTypeID`. For `HedgeServerID Change` events, this is the NEW value; the previous is in `Comments`. (Tier 2 — SP_CEPDailyAudit) |
| 6 | Priority | int | YES | Rule priority value controlling evaluation order within CEP. For `Priority Change` events, this is the NEW priority; the previous is in `Comments`. (Tier 2 — SP_CEPDailyAudit) |
| 7 | TypeOfChange | varchar(max) | YES | Change event type. Values: `Name Change`, `Description Change`, `Activated`, `Deactivated`, `HedgeServerID Change`, `Priority Change`, `New Rule`, `Rule Deleted`. No NULLs in production data — unlike sibling CEPDailyAudit tables, no sentinel rows are written. (Tier 2 — SP_CEPDailyAudit) |
| 8 | Comments | varchar(max) | YES | Context for change events: `"Previous Name: {old}"`, `"Previous Description: {old}"`, `"Previous HedgeServerID: {old}"`, `"Previous Priority: {old}"`. NULL for `Activated`, `Deactivated`, `New Rule`, and `Rule Deleted` events. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | Application login of the CEP user who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` from the temporal history to capture identity even for deletion events. Note: values may contain trailing NULL bytes from the source system. (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | Exact timestamp of the change event. `SysStartTime` for attribute changes, activations, and new rules; `SysEndTime` for `Rule Deleted` events. (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at SP execution time. Not the business change time — use `ChangeTime` for event timing. (Tier 2 — SP_CEPDailyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP_CEPDailyAudit | @Date parameter | Direct assignment |
| RuleID | External_Etoro_CEP_Rules / History_Rules | RuleID | Passthrough |
| RuleName | External_Etoro_CEP_Rules / History_Rules | Name | Column rename |
| Description | External_Etoro_CEP_Rules / History_Rules | Description | Passthrough |
| HedgeServerID | External_Etoro_CEP_Rules / History_Rules | HedgeRuleActionTypeID | Column rename |
| Priority | External_Etoro_CEP_Rules / History_Rules | Priority | Passthrough |
| TypeOfChange | SP_CEPDailyAudit | — | Computed: 8 event types via LAG()-based comparison + UNION ALL |
| Comments | SP_CEPDailyAudit | — | Computed: CONCAT of previous attribute values |
| LoginName | External_Etoro_CEP_Rules / History_Rules | AppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) |
| ChangeTime | External_Etoro_CEP_Rules / History_Rules | SysStartTime / SysEndTime | SysStartTime for changes, SysEndTime for deletions |
| UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL load timestamp |

No Generic Pipeline mapping — CEP is an internal eToro system, not tracked in the Generic Pipeline.

### 5.2 ETL Pipeline

```
CEP Internal System
    → Dealing_staging.External_Etoro_CEP_Rules (current state)
    → Dealing_staging.External_Etoro_History_Rules (temporal history)
        → SP_CEPDailyAudit(@Date)
            — #RulesLog: UNION ALL current + history, LAG() over SysStartTime
            — #RulesAudit1: filter to rows with attribute changes or RN=1
            — #RuleChangesFinal: UNION ALL of 8 event type branches
            — DELETE + INSERT for @Date
            → Dealing_dbo.Dealing_CEPDailyAudit_Rules (1,052 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RuleID | Dealing_staging.External_Etoro_CEP_Rules | Source rule entity in CEP |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_CEPDailyAudit_CP | RuleID | CP-level audit references the parent rule |
| Dealing_CEPDailyAudit_CPToRule | RuleID | CP-to-Rule mapping audit references this rule |
| Dealing_CEPDailyAudit_Conditions | RuleID | Condition audit references the parent rule (via dimension chain) |
| Dealing_CEPDailyAudit_ConditionToCP | RuleID | Condition-to-CP mapping audit references the parent rule |
| V_Dealing_CEPDailyAudit_Rules_Last180Days | All | View over this table filtering to last 180 days |

---

## 7. Sample Queries

### 7.1 All rule changes on a specific date
```sql
SELECT Date, RuleID, RuleName, TypeOfChange, Comments, LoginName, ChangeTime
FROM   Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE  Date = '2026-04-16'
ORDER BY RuleID, ChangeTime;
```

### 7.2 History of a specific rule
```sql
SELECT Date, TypeOfChange, Comments, LoginName, ChangeTime
FROM   Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE  RuleID = 1294
ORDER BY Date DESC, ChangeTime DESC;
```

### 7.3 All hedge server reassignments in the last 90 days
```sql
SELECT Date, RuleID, RuleName, Comments AS PreviousHedgeServerID,
       HedgeServerID AS NewHedgeServerID, LoginName
FROM   Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE  Date >= DATEADD(DAY, -90, GETDATE())
  AND  TypeOfChange = 'HedgeServerID Change'
ORDER BY Date DESC, ChangeTime DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 (★★★★☆) | Batch: regen-harness*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4 | Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_Rules | Type: Table | Production Source: Dealing_staging CEP temporal tables via SP_CEPDailyAudit*
