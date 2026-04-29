# Dealing_dbo.Dealing_CEPDailyAudit_Conditions

> Daily audit of **CEP Condition** definition changes — ~3,193 rows from **2023-12-12** through **2026-03-20** tracking property, operator, and value edits plus creation/deletion events for the atomic predicates in the CEP hedging rule engine.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_Conditions` + `External_Etoro_History_Conditions` via `SP_CEPDailyAudit` |
| **Refresh** | Daily (Priority 0 — OpsDB / Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` ASC |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table records every **Condition definition change** in eToro's **Client Execution Platform (CEP)** hedging rule engine. **Conditions** are the **atomic predicates** — each defined by a **Property** (e.g. `InstrumentID`, `CID`, `CountryID`), an **Operator** (e.g. `Equal`, `NotEqual`, `Contains`), and a **Value** — that compose **Compound Properties (CPs)**, which in turn compose **Rules**.

**What each row means:** On business date **`Date`**, a condition's **property**, **operator**, or **value** was changed, or the condition was **created** or **deleted**. The table also resolves **rule context** (which rule ultimately uses this condition) via the `#Dim_ConditionRule` temp table in the SP.

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)
        └── Condition  ← audited HERE
              └── Property + Operator + Value
```

**Why it matters:** Conditions are the lowest-level building blocks of hedging rules. A single property or operator change can redirect how client trades are routed and hedged. This audit trail supports regulatory compliance, post-incident root-cause analysis, and governance oversight by the Dealing team.

**Scale:** ~3,193 rows across 184 distinct rules and 587 distinct conditions. Active pipeline — max date **2026-03-20**. Moderate volume; condition-level changes are more frequent than CP lifecycle events but less frequent than CP-to-Rule mapping changes.

**Load pattern:** `SP_CEPDailyAudit` — **DELETE + INSERT** for **`@Date`**. Daily batch; SLA: typically next business day.

---

## 2. Business Logic

### 2.1 Change Detection via LAG() on Temporal Tables

**What**: The SP detects condition definition changes by comparing successive system-time versions of conditions using `LAG()` over `SysStartTime`, partitioned by `ConditionID`.

**Columns Involved**: `Property`, `Operator`, `Value`, `TypeOfChange`, `Comments`

**Rules**:
- `Property Change` — condition's `PropertyID` resolves to a different `Name` vs prior version; `Comments` = `"Previous Property: {oldName}"`
- `Operator Change` — condition's `OperatorID` resolves to a different `Name`; `Comments` = `"Previous Operator: {oldName}"`
- `Value Change` — condition's `Value` differs from prior version; `Comments` = `"Previous Value: {oldValue}"`
- `New Condition` — `RN=1` (first temporal row for this `ConditionID`) and `SysStartDate = @Date`
- `Condition Deleted` — `RN=1` AND `RN_Desc=1` AND `SysStartDate = @Date` (single-version condition that appeared and ended same day)

### 2.2 Rule Context Resolution

**What**: Each condition is linked to rules through the ConditionToCP → CPToRule chain, resolved in `#Dim_ConditionRule`.

**Columns Involved**: `RuleID`, `RuleName`, `HedgeServerID`

**Rules**:
- LEFT JOIN from `#Conditions_ChangesFinal` to `#Dim_ConditionRule` on `ConditionID`
- A condition may belong to multiple CPs across multiple rules — fan-out creates multiple rows for the same `ConditionID` change (one per rule context)
- NULL `RuleID` is valid if the condition exists in a CP not yet mapped to any rule

### 2.3 Property and Operator Resolution

**What**: Raw `PropertyID` and `OperatorID` from the conditions table are resolved to human-readable names via dictionary JOINs in `#Conditions_Log`.

**Columns Involved**: `Property`, `Operator`

**Rules**:
- `Property` ← `External_Etoro_Dictionary_ConditionProperties.Name` joined on `PropertyID`
- `Operator` ← `External_Etoro_Dictionary_ConditionOperators.Name` joined on `OperatorID`
- Observed Property values: `InstrumentID`, `InstrumentType`, `RootHedgeServerID`, `CID`, `CountryID`, `TreeSizeUSD`, `ExchangeID`, `AccountType`, `AffiliateID`, `Leverage`
- Observed Operator values: `NotEqual`, `Equal`, `Contains`, `Greater Equal Than`, `Equal Smaller Than`, `SmallerThan`, `Greater Than`, `Not Contains`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for moderate-volume audit table with no natural join key. |
| **Clustered index** | **`Date` ASC** — primary access pattern is date-based slicing. |
| **Scale** | ~3,193 rows — no performance tuning required. |

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What condition changes happened on date X? | `WHERE Date = 'YYYY-MM-DD'` |
| History of a specific condition | `WHERE ConditionID = @id ORDER BY Date DESC, ChangeTime DESC` |
| All new conditions in a date range | `WHERE Date BETWEEN @start AND @end AND TypeOfChange = 'New Condition'` |
| Conditions changed for a specific rule | `WHERE RuleID = @id ORDER BY Date DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_CEPDailyAudit_ConditionToCP | `ConditionID + Date` | See which CP the condition belongs to |
| Dealing_CEPDailyAudit_CP | `CompoundPropertyID + Date` (via ConditionToCP) | Full CP context for condition changes |
| Dealing_CEPDailyAudit_Rules | `RuleID + Date` | Correlate condition changes with rule-level events |

### 3.4 Gotchas

- **Multiple rows per `ConditionID` per `Date`** are valid — a single edit session can change property, operator, AND value simultaneously, producing three rows (one per `TypeOfChange`).
- **Fan-out across rules** — if a condition belongs to a CP mapped to multiple rules, the same change appears once per rule context. Not all duplicates are errors.
- **`TypeOfChange` values** are exact strings from SP: `New Condition`, `Condition Deleted`, `Property Change`, `Operator Change`, `Value Change` — case and spacing matter.
- **`LoginName` contains trailing NUL bytes** — observed in sample data; `RTRIM` or `REPLACE(LoginName, CHAR(0), '')` when filtering.
- **`RuleID` can be NULL** — valid when the condition's CP is not yet mapped to any rule.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this condition change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** that ultimately uses this condition (resolved via condition → CP → rule chain in `#Dim_ConditionRule`). NULL if the condition's CP is not mapped to any rule. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** denormalized from `#Dim_ConditionRule` for readability alongside **`RuleID`**. (Tier 2 — SP_CEPDailyAudit) |
| 4 | HedgeServerID | int | YES | **Hedge server** associated with the rule — identifies which backend stack processes the rule containing this condition. From `#Dim_ConditionRule`. (Tier 2 — SP_CEPDailyAudit) |
| 5 | ConditionID | int | YES | **Unique identifier** of the condition that changed. The atomic predicate entity in the CEP hierarchy. (Tier 2 — SP_CEPDailyAudit) |
| 6 | Property | varchar(max) | YES | **Condition property name** — the attribute being tested (e.g. `InstrumentID`, `CID`, `CountryID`, `InstrumentType`, `RootHedgeServerID`). Resolved from `External_Etoro_Dictionary_ConditionProperties` via `PropertyID`. (Tier 2 — SP_CEPDailyAudit) |
| 7 | Operator | varchar(max) | YES | **Comparison operator** applied to the property (e.g. `Equal`, `NotEqual`, `Contains`, `Greater Equal Than`, `SmallerThan`, `Not Contains`). Resolved from `External_Etoro_Dictionary_ConditionOperators` via `OperatorID`. (Tier 2 — SP_CEPDailyAudit) |
| 8 | Value | varchar(100) | YES | **Comparison value** for the condition predicate — the right-hand side of the `Property Operator Value` expression (e.g. instrument IDs, country codes). (Tier 2 — SP_CEPDailyAudit) |
| 9 | TypeOfChange | varchar(max) | YES | **Event type** — one of: **`New Condition`**, **`Condition Deleted`**, **`Property Change`**, **`Operator Change`**, **`Value Change`**. (Tier 2 — SP_CEPDailyAudit) |
| 10 | Comments | varchar(max) | YES | **Prior-value context** for change events: `"Previous Property: {old}"`, `"Previous Operator: {old}"`, `"Previous Value: {old}"`. NULL for `New Condition` and `Condition Deleted`. (Tier 2 — SP_CEPDailyAudit) |
| 11 | LoginName | varchar(max) | YES | **CEP application user** who performed the change — `COALESCE(AppLoginName, PreviousAppLoginName)` from the temporal history to capture identity even for deletion events. (Tier 2 — SP_CEPDailyAudit) |
| 12 | ChangeTime | datetime | YES | **Source timestamp** of the change event — `SysStartTime` for property/operator/value changes and new conditions; `SysEndTime` for deletions. (Tier 2 — SP_CEPDailyAudit) |
| 13 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** in the SP — ETL metadata, **not** the business event timestamp. (Tier 2 — SP_CEPDailyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP_CEPDailyAudit | @Date | Direct assignment |
| RuleID, RuleName, HedgeServerID | #Dim_ConditionRule (via #ConditionToCP_Log → #CPToRule_Log → #RulesLog) | RuleID, Name, HedgeServerID | LEFT JOIN resolution |
| ConditionID | External_Etoro_CEP_Conditions + History | ConditionID | Passthrough |
| Property | External_Etoro_Dictionary_ConditionProperties | Name | JOIN on PropertyID |
| Operator | External_Etoro_Dictionary_ConditionOperators | Name | JOIN on OperatorID |
| Value | External_Etoro_CEP_Conditions + History | Value | Passthrough |
| TypeOfChange | SP_CEPDailyAudit | Derived | LAG() comparison classification |
| Comments | SP_CEPDailyAudit | Derived | CONCAT('Previous {X}: ', Previous{X}) |
| LoginName | External_Etoro_CEP_Conditions + History | COALESCE(AppLoginName, PreviousAppLoginName) | COALESCE |
| ChangeTime | External_Etoro_CEP_Conditions + History | SysStartTime / SysEndTime | Per event-type path |
| UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
[CEP System — Conditions temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_Conditions  (current)
Dealing_staging.External_Etoro_History_Conditions  (history)
    + External_Etoro_Dictionary_ConditionProperties (Property name)
    + External_Etoro_Dictionary_ConditionOperators (Operator name)
    ↓
SP_CEPDailyAudit(@Date)
    — UNION ALL current + history (WHERE SysStartTime<>SysEndTime)
    — JOIN dictionary tables for Property / Operator names
    — LAG() detects Property/Operator/Value changes
    — RN=1 + SysStartDate=@Date → New Condition
    — RN=1 + RN_Desc=1 + SysStartDate=@Date → Condition Deleted
    — LEFT JOIN #Dim_ConditionRule for rule context
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_Conditions  ← DELETE + INSERT for @Date
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ConditionID | Dealing_staging.External_Etoro_CEP_Conditions | Source condition entity |
| RuleID | Dealing_dbo.Dealing_CEPDailyAudit_Rules | Parent rule whose condition changed |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_dbo.V_Dealing_CEPDailyAudit_Conditions_Last180Days | All | View — `SELECT * WHERE Date >= GETDATE()-180` |
| Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP | ConditionID | CP membership changes for the same condition |

---

## 7. Sample Queries

### 7.1 All condition changes on a business date

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , ConditionID
    , Property
    , Operator
    , Value
    , TypeOfChange
    , Comments
    , REPLACE(LoginName, CHAR(0), '') AS LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE Date = '2026-03-20'
ORDER BY RuleID, ConditionID, ChangeTime;
```

### 7.2 Full timeline for a specific condition

```sql
SELECT
      Date
    , Property
    , Operator
    , Value
    , TypeOfChange
    , Comments
    , REPLACE(LoginName, CHAR(0), '') AS LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE ConditionID = 9157
ORDER BY Date, ChangeTime;
```

### 7.3 New conditions created in the last 30 days with rule context

```sql
SELECT
      Date
    , RuleName
    , ConditionID
    , Property
    , Operator
    , Value
    , REPLACE(LoginName, CHAR(0), '') AS LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE TypeOfChange = 'New Condition'
  AND Date >= DATEADD(DAY, -30, GETDATE())
ORDER BY Date DESC, ChangeTime DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 (★★★★☆) | Batch: regen-harness*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4 | Elements: 9/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_Conditions | Type: Table | Production Source: Dealing_staging CEP Conditions + history via SP_CEPDailyAudit*
