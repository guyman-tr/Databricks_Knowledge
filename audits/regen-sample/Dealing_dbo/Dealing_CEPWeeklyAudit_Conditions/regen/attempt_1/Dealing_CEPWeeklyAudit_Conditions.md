# Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions

> ~12,661-row weekly audit of **CEP Condition** definition changes — property, operator, value edits, new conditions, and deletions — aggregated to a **Monday–Sunday** window (`FromDate` / `ToDate`), loaded from Dealing_staging temporal/external sources by `SP_W_CEPWeeklyAudit` each Sunday. History from **2021-09-26** to present.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables via `SP_W_CEPWeeklyAudit` |
| **Refresh** | Weekly (Sunday batch; OpsDB Priority 0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` ASC |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table captures **weekly** audit events for **CEP Conditions** — the atomic predicate objects in the Client Execution Platform hedging rule engine. Each condition defines a single test (e.g. `InstrumentID NotEqual 1714`) that participates in compound property bundles and ultimately in rules.

Each row describes a **change that occurred within the Monday–Sunday window** (`FromDate` / `ToDate`), including:
- **New conditions** being created
- **Condition deletions**
- **Property changes** (the attribute being tested, e.g. `InstrumentID` → `CountryID`)
- **Operator changes** (the comparison, e.g. `Equal` → `NotEqual`)
- **Value changes** (the threshold/match value)

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)
        └── Condition   ← definition changes audited here
              ├── Property   (what is being tested)
              ├── Operator   (how it is compared)
              └── Value      (threshold / match value)
```

**Scale:** ~12,661 rows from **2021-09-26** through **2026-04-19**. The most common Property is `InstrumentID` (~7,756 non-placeholder rows), followed by `InstrumentType` (~3,154). `NotEqual` is the dominant Operator (~8,639 non-placeholder rows).

**No-change weeks:** The SP uses a **LEFT JOIN** to a week-spine (`#FromDateToDate`), so **every** processed week can yield **at least one row** even when **no** condition changed. Those rows carry **NULL** `TypeOfChange`, `ConditionID`, etc. — only 58 such placeholder rows exist in the current dataset (far fewer than sibling tables), suggesting most weeks have at least one condition change.

**Rule context resolution:** `RuleID`, `RuleName`, and `HedgeServerID` are resolved through a multi-hop chain: Condition → ConditionToCP → CPToRule → Rules. The LEFT JOIN at each step means **535 non-placeholder rows** have NULL `RuleID` — these are conditions whose CP or rule association could not be resolved at write time.

**Historical coverage:** This weekly table was populated from **September 2021** onward. The **daily** counterpart (`Dealing_CEPDailyAudit_Conditions`) begins approximately **December 2023**; use this table for **pre-daily** history and for **weekly governance** summaries.

The writer SP is **`Dealing_dbo.SP_W_CEPWeeklyAudit`**, which uses **DELETE + INSERT** for the target week window. Data is sourced from `Dealing_staging.External_Etoro_CEP_Conditions` (current) and `External_Etoro_History_Conditions` (temporal history), with dictionary lookups for Property and Operator names.

---

## 2. Business Logic

### 2.1 Change Detection via LAG Comparison

**What**: The SP builds `#Conditions_Log` by unioning current and history condition records, then applies `LAG()` window functions partitioned by `ConditionID` ordered by `SysStartTime` to detect attribute changes.

**Columns Involved**: `Property`, `Operator`, `Value`, `PreviousProperty`, `PreviousOperator`, `PreviousValue`

**Rules**:
- Property change: `Property <> PreviousProperty AND PreviousProperty IS NOT NULL`
- Operator change: `Operator <> PreviousOperator AND PreviousOperator IS NOT NULL`
- Value change: `Value <> PreviousValue AND PreviousValue IS NOT NULL`
- All comparisons filter `WHERE SysStartTime BETWEEN @weekStart AND @weekEnd`

### 2.2 Lifecycle Events (New / Deleted)

**What**: New conditions and deletions are identified by row-number position within the condition's history.

**Columns Involved**: `ConditionID`, `RN` (first appearance), `RN_Desc` (last appearance), `SysStartTime`, `SysEndTime`

**Rules**:
- **New Condition**: `RN = 1 AND SysStartTime BETWEEN @weekStart AND @weekEnd` — first historical record falls within the audit week
- **Condition Deleted**: `RN = 1 AND SysEndTime BETWEEN @weekStart AND @weekEnd AND RN_Desc = 1` — note: uses both `RN = 1` and `RN_Desc = 1`, meaning single-record conditions whose `SysEndTime` falls in the week

### 2.3 Dictionary Resolution for Property and Operator

**What**: The SP resolves numeric IDs to human-readable names via dictionary lookups at the `#Conditions_Log` stage.

**Columns Involved**: `Property`, `Operator`

**Rules**:
- `Property` ← `External_Etoro_Dictionary_ConditionProperties.Name` joined on `PropertyID`
- `Operator` ← `External_Etoro_Dictionary_ConditionOperators.Name` joined on `OperatorID`
- These joins are INNER JOINs in `#Conditions_Log`, so conditions with unresolvable PropertyID or OperatorID are silently excluded

### 2.4 Rule Context Resolution

**What**: Rule context is added via a multi-hop LEFT JOIN chain, not directly from conditions data.

**Columns Involved**: `RuleID`, `RuleName`, `HedgeServerID`

**Rules**:
- `#Dim_ConditionRule`: joins `#ConditionToCP_Log` (ConditionID → CompoundPropertyID) to `#Dim_CPtoRule` (CompoundPropertyID → RuleID, RuleName, HedgeServerID)
- LEFT JOIN means conditions without a CP association or CPs without a rule association produce NULL rule context
- A condition attached to **multiple CPs** (and thus multiple rules) can produce **multiple rows** for one underlying change event

### 2.5 Previous-Value Comments

**What**: For attribute change events, the SP records the prior value in the `Comments` column.

**Columns Involved**: `Comments`, `TypeOfChange`

**Rules**:
- Property Change: `CONCAT('Previous Property: ', PreviousProperty)`
- Operator Change: `CONCAT('Previous Operator: ', PreviousOperator)`
- Value Change: `CONCAT('Previous Value: ', PreviousValue)`
- New Condition / Condition Deleted: `NULL`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for moderate audit volume (~12.7K rows). |
| **Clustered index** | `[FromDate]` ASC — primary filter for week selection. |
| **Scale** | Small by DWH standards; no special performance considerations. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What conditions changed this week? | `WHERE FromDate = @WeekStart AND TypeOfChange IS NOT NULL` |
| History of a specific condition | `WHERE ConditionID = @id AND TypeOfChange IS NOT NULL ORDER BY FromDate` |
| How many changes per event type over time? | `GROUP BY YEAR(FromDate), TypeOfChange` with `WHERE TypeOfChange IS NOT NULL` |
| Which rules had condition churn? | `GROUP BY RuleID, RuleName` with `WHERE TypeOfChange IS NOT NULL AND RuleID IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `Dealing_CEPWeeklyAudit_ConditionToCP` | `ConditionID + FromDate` | Link condition definition changes to CP membership changes in the same week |
| `Dealing_CEPWeeklyAudit_CP` | `FromDate` (week alignment) | Correlate condition changes with CP lifecycle events |
| `Dealing_CEPWeeklyAudit_Rules` | `RuleID + FromDate` | Get rule-level audit context alongside condition changes |

### 3.4 Gotchas

- **`TypeOfChange` NULL rows** are **structural placeholders** from the LEFT JOIN to `#FromDateToDate` — not "unknown changes." Always filter `WHERE TypeOfChange IS NOT NULL` for event-centric analysis.
- **`RuleID` NULL on real events**: 535 non-placeholder rows have NULL `RuleID` because the condition's CP or rule association could not be resolved in the weekly snapshot. Do not treat these as orphan data.
- **Fan-out across rules**: A condition attached to multiple CPs (via multiple rules) can appear as **multiple rows per change event** with different `RuleID` / `RuleName` / `HedgeServerID`. Deduplicate on `ConditionID + ChangeTime + TypeOfChange` if counting unique condition events.
- **LoginName null-byte padding**: Some `LoginName` values contain trailing null bytes (observed in live data as `jasonha\0\0\0...`). Use `RTRIM` or `REPLACE(LoginName, CHAR(0), '')` when comparing or displaying.
- **Condition Deleted filter**: The SP uses `RN = 1 AND RN_Desc = 1` for deletions, meaning only **single-record** conditions (first = last) are classified as deleted when their `SysEndTime` falls in the week. Multi-record conditions whose final record ends in the week would also be caught by `RN_Desc = 1`, but the `RN = 1` conjunction limits this — potential undercount of deletions for conditions with long change histories.
- **TypeOfChange values** are exact strings: `Property Change`, `Operator Change`, `Value Change`, `New Condition`, `Condition Deleted`.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_W_CEPWeeklyAudit)` |
| ★ | Tier 4 — ETL metadata | `(Tier 4 — SP_W_CEPWeeklyAudit)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | **Week start** — Monday 00:00:00 for the audit window, computed as `DATEADD(DAY,1,DATEADD(WW,-1,@dd))`. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | **Week end marker** — Sunday, computed as `DATEADD(DAY,6,@weekStart)`. Stored as 00:00:00, **not** end-of-day 23:59:59. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | CEP Rule associated with this condition via the Condition → ConditionToCP → CPToRule resolution chain; **NULL** on placeholder rows or when the condition's CP/rule association could not be resolved. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | Human-readable rule name denormalized from the rule resolution chain (latest name per `RN_Desc=1`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | HedgeServerID | int | YES | Hedge server / action type identifier from the rule context (`HedgeRuleActionTypeID` lineage via CPToRule → Rules chain). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | ConditionID | int | YES | CEP Condition identifier from source; **NULL** on no-change placeholder weeks (LEFT JOIN pattern). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | Property | varchar(max) | YES | Condition property name — the attribute being tested (e.g. `InstrumentID`, `InstrumentType`, `CountryID`, `CID`). Resolved from `External_Etoro_Dictionary_ConditionProperties.Name` via PropertyID join. 16 distinct values observed. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | Operator | varchar(max) | YES | Comparison operator name (e.g. `NotEqual`, `Equal`, `Contains`, `Greater Equal Than`, `Equal Smaller Than`, `SmallerThan`, `Greater Than`, `Not Contains`). Resolved from `External_Etoro_Dictionary_ConditionOperators.Name` via OperatorID join. 8 distinct values observed. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | Value | varchar(100) | YES | The condition's threshold or match value (e.g. instrument ID `1714`, leverage level). For **Value Change** events, holds the **new** value; the previous value appears in `Comments`. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | TypeOfChange | varchar(max) | YES | Event classification: `New Condition`, `Condition Deleted`, `Property Change`, `Operator Change`, `Value Change`; **NULL** for no-change placeholder rows from the outer join scaffolding. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | Comments | varchar(max) | YES | Previous-value context for attribute changes: `Previous Property: {old}`, `Previous Operator: {old}`, `Previous Value: {old}`; **NULL** for New Condition, Condition Deleted, and placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | LoginName | varchar(max) | YES | CEP application login (`AppLoginName`) from source conditions. May contain trailing null-byte padding in some rows (data quality note). **NULL** on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 13 | ChangeTime | datetime | YES | Source event timestamp: `SysStartTime` for change events (Property/Operator/Value/New); `SysEndTime` for Condition Deleted events. **NULL** on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 14 | UpdateDate | datetime | YES | DWH row insert time via `GETDATE()` at SP execution — not a business event timestamp. (Tier 4 — SP_W_CEPWeeklyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FromDate | SP_W_CEPWeeklyAudit | @weekStart | Computed Monday from @dd |
| ToDate | SP_W_CEPWeeklyAudit | @weekEnd | Computed Sunday from @weekStart |
| RuleID | External_Etoro_CEP_CompoundPropertyToRule | RuleID | Via Condition→CP→Rule chain |
| RuleName | External_Etoro_CEP_Rules | Name | Via chain, latest (RN_Desc=1) |
| HedgeServerID | External_Etoro_CEP_Rules | HedgeRuleActionTypeID | Aliased, via chain |
| ConditionID | External_Etoro_CEP_Conditions | ConditionID | Passthrough |
| Property | External_Etoro_Dictionary_ConditionProperties | Name | Dictionary lookup on PropertyID |
| Operator | External_Etoro_Dictionary_ConditionOperators | Name | Dictionary lookup on OperatorID |
| Value | External_Etoro_CEP_Conditions | Value | Passthrough |
| TypeOfChange | SP_W_CEPWeeklyAudit | — | Derived from LAG/RN logic |
| Comments | SP_W_CEPWeeklyAudit | — | CONCAT of previous values |
| LoginName | External_Etoro_CEP_Conditions | AppLoginName | Passthrough |
| ChangeTime | External_Etoro_CEP_Conditions | SysStartTime / SysEndTime | SysStartTime for changes, SysEndTime for deletes |
| UpdateDate | SP_W_CEPWeeklyAudit | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
Dealing_staging.External_Etoro_CEP_Conditions        (current)
Dealing_staging.External_Etoro_History_Conditions     (temporal history)
Dealing_staging.External_Etoro_Dictionary_ConditionProperties  (Property name lookup)
Dealing_staging.External_Etoro_Dictionary_ConditionOperators   (Operator name lookup)
    |
    v
#Conditions_Log  (UNION + JOIN dictionaries + LAG() for previous values)
    |
    v
#Conditions_ChangesFinal  (filtered to @weekStart–@weekEnd, classified by change type)
    |
    +-- LEFT JOIN #Dim_ConditionRule  (Condition → ConditionToCP → CPToRule → Rules)
    +-- LEFT JOIN #FromDateToDate     (placeholder row for empty weeks)
    |
    v
Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions  ← DELETE + INSERT for (@weekStart, @weekEnd)
    (~12,661 rows, 2021-09-26 → 2026-04-19)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ConditionID | `Dealing_staging.External_Etoro_CEP_Conditions` | Source condition definition |
| RuleID | `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | Rule-level weekly audit (same `FromDate`/`ToDate` convention) |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ConditionID | `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | Weekly condition-to-CP membership audit — join on `ConditionID + FromDate` for predicate context alongside membership changes |

### 6.3 Sibling Objects (same writer SP, same weekly job)

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` | **Daily** counterpart — finer date grain for periods after ~Dec 2023 |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | Rule-level weekly audit |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | Compound Property weekly audit |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` | CP-to-Rule mapping weekly audit |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | Condition-to-CP membership weekly audit |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists` | Named List weekly audit |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping` | CID-to-Named-List membership weekly audit |

---

## 7. Sample Queries

### 7.1 Real condition changes for one audit week

```sql
SELECT
      FromDate
    , ToDate
    , RuleID
    , RuleName
    , ConditionID
    , Property
    , Operator
    , Value
    , TypeOfChange
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions
WHERE FromDate = '2026-03-29'
  AND TypeOfChange IS NOT NULL
ORDER BY RuleID, ConditionID, ChangeTime;
```

### 7.2 Change type distribution by year

```sql
SELECT
      YEAR(FromDate)   AS audit_year
    , TypeOfChange
    , COUNT(*)         AS cnt
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions
WHERE TypeOfChange IS NOT NULL
GROUP BY YEAR(FromDate), TypeOfChange
ORDER BY audit_year DESC, TypeOfChange;
```

### 7.3 Condition definition changes with CP membership context (same week)

```sql
SELECT
      c.FromDate
    , c.ConditionID
    , c.Property
    , c.Operator
    , c.Value
    , c.TypeOfChange      AS DefinitionChange
    , m.TypeOfChange      AS MembershipChange
    , m.CompoundPropertyID
    , m.CP_Name
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions AS c
LEFT JOIN Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP AS m
       ON m.ConditionID = c.ConditionID
      AND m.FromDate = c.FromDate
WHERE c.TypeOfChange IS NOT NULL
  AND c.FromDate >= '2025-01-01'
ORDER BY c.FromDate DESC, c.ConditionID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.0/10 (★★★★☆) | Weekly CEP audit family*
*Tiers: 0 T1, 13 T2, 0 T3, 1 T4 | Elements: 8.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 5.5/10*
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions | Type: Table | Production Source: Dealing_staging CEP temporal / external via SP_W_CEPWeeklyAudit*
