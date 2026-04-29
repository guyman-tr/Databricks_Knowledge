# Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP

> Daily audit of **Condition-to-Compound Property mapping changes** in the CEP hedging rule engine — ~6,604 rows from **2023-12-12** through **2026-04-19** across 175 distinct dates, tracking when conditions are added to or removed from CPs. Written by **SP_CEPDailyAudit**.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` + `External_Etoro_History_ConditionToCompoundProperty` via `SP_CEPDailyAudit` |
| **Refresh** | Daily (Priority 0 — OpsDB / Service Broker) |
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

This table records every **condition-to-compound property (CP) mapping change** in eToro's **CEP (Client Execution Platform)** hedging rule engine. In the CEP hierarchy, **conditions** are the atomic logic units (property + operator + value) that sit inside **compound properties (CPs)**, which in turn are grouped into **rules**. This table tracks the **wiring** between conditions and CPs — when a condition is **attached to** or **detached from** a CP.

**What each row means:** On business date **`Date`**, a condition identified by **`ConditionID`** was either **added to** or **removed from** the compound property **`CompoundPropertyID`** (named **`CP_Name`**). The parent rule context (**`RuleID`**, **`RuleName`**, **`HedgeServerID`**) is resolved via a CP-to-Rule dimension chain and may be **NULL** when the CP is not yet mapped to any rule.

**Why it matters:** Condition-to-CP mapping changes alter **which logic clauses** are active within a CP — directly affecting how hedging rules evaluate client trades. This audit trail supports **governance**, **post-incident investigation**, and **regulatory compliance** by the Dealing team.

**Scale:** ~6,604 rows. Activity is **bursty** — the top date (2026-04-19) accounts for 5,052 rows (a bulk cleanup), while most dates have fewer than 100 rows. **88%** of events are **removals** (5,812) vs **12%** additions (792). **LoginName** is NULL in ~63% of rows, likely reflecting system-driven or bulk operations where the temporal `AppLoginName` was not populated.

**Load pattern:** **`SP_CEPDailyAudit`** performs **DELETE + INSERT** for the supplied **`@Date`**. Daily batch. SLA: typically next business day for date *D*.

---

## 2. Business Logic

### 2.1 Change Detection via Temporal Tables

**What**: The SP detects condition-to-CP mapping changes by comparing system-time versioned records from the staging external tables.

**Columns Involved**: `CompoundPropertyID`, `ConditionID`, `TypeOfChange`, `ChangeTime`

**Rules**:
- **`Condition Added To CP`** — condition mapped to CP today: `SysStartDate = @Date` AND `SysStartTime <> SysEndTime`
- **`Condition Removed from CP`** — condition unmapped from CP today: `SysEndDate = @Date` AND `SysEndTime < '9999-01-01'` AND `SysStartTime <> SysEndTime`
- The `SysStartTime <> SysEndTime` filter excludes zero-duration artifacts from temporal tables

### 2.2 Rule Context Resolution (LEFT JOIN)

**What**: Each condition-to-CP row is enriched with the parent rule context via a dimension chain.

**Columns Involved**: `RuleID`, `RuleName`, `HedgeServerID`

**Rules**:
- `#ConditionToCP_ChangesFinal` LEFT JOINs `#Dim_CPtoRule` on `CompoundPropertyID`
- `#Dim_CPtoRule` is built from `#CPToRule_Log` JOIN `#RulesLog` — resolving the latest rule for each CP
- **NULL** values for `RuleID`/`RuleName`/`HedgeServerID` indicate the CP is not currently mapped to any rule (orphan CP or pending wiring)

### 2.3 LoginName Attribution

**What**: Captures the CEP user who made the mapping change, even for removal events.

**Columns Involved**: `LoginName`

**Rules**:
- Uses `COALESCE(AppLoginName, PreviousAppLoginName)` from temporal source — `LEAD()` over `SysEndTime DESC` provides the previous login when the current is NULL
- High NULL rate (~63%) observed in sampled data — suggests system-driven bulk operations

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for a small audit table with no natural hash key. |
| **Clustered index** | **`Date` ASC** — align filters to **`Date`** for efficient seeks. |
| **Scale** | ~6,604 rows — no special tuning needed. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What condition-to-CP changes happened on date X? | `WHERE Date = 'YYYY-MM-DD'` |
| Full history of a specific condition's CP assignments | `WHERE ConditionID = @id ORDER BY Date, ChangeTime` |
| All additions to a specific CP | `WHERE CompoundPropertyID = @cpid AND TypeOfChange = 'Condition Added To CP'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_CEPDailyAudit_Conditions | `ConditionID + Date` | Correlate condition definition changes with mapping changes on the same day |
| Dealing_CEPDailyAudit_CP | `CompoundPropertyID + Date` | See CP lifecycle events alongside condition mapping changes |
| Dealing_CEPDailyAudit_Rules | `RuleID + Date` | View rule-level changes on the same day |
| Dealing_CEPDailyAudit_CPToRule | `CompoundPropertyID + Date` | Correlate CP-to-Rule mapping changes with condition-to-CP changes |

### 3.4 Gotchas

- **Bursty activity** — a single date can account for thousands of rows (e.g. 2026-04-19 has 5,052 rows from a bulk cleanup). Don't assume uniform daily volumes.
- **RuleID / RuleName / HedgeServerID can be NULL** — the LEFT JOIN to `#Dim_CPtoRule` means orphan CPs (not yet mapped to a rule) will have NULL rule context. ~18% of rows have NULL `RuleID`.
- **LoginName NULL is common** (~63%) — system-driven or bulk operations may not populate the temporal `AppLoginName`.
- **TypeOfChange values are fixed literals** — match exact case and spacing: `'Condition Added To CP'`, `'Condition Removed from CP'`.
- **No sentinel rows** — unlike some sibling tables, this table only writes rows when actual mapping changes occur.
- This is one of 7 CEPDailyAudit tables, all written by the same SP.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this condition-to-CP mapping change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** containing the compound property involved in this mapping change — resolved via the **CP-to-Rule dimension chain** in the SP. **NULL** when the CP is not mapped to any rule (~18% of rows). (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** denormalized from the latest rule state for reporting alongside **`RuleID`**. **NULL** when `RuleID` is NULL. (Tier 2 — SP_CEPDailyAudit) |
| 4 | HedgeServerID | int | YES | **Hedge server** associated with the parent rule — identifies which hedging backend stack processes the rule. **NULL** when `RuleID` is NULL. (Tier 2 — SP_CEPDailyAudit) |
| 5 | CompoundPropertyID | int | YES | **Identifier** of the **Compound Property** that the condition was added to or removed from. (Tier 2 — SP_CEPDailyAudit) |
| 6 | CP_Name | varchar(max) | YES | **Name of the Compound Property** at the time of the change — resolved from the latest CP name via `#CPLog`. (Tier 2 — SP_CEPDailyAudit) |
| 7 | ConditionID | int | YES | **Identifier** of the **condition** that was added to or removed from the CP. (Tier 2 — SP_CEPDailyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | **Event type**: **`Condition Added To CP`** or **`Condition Removed from CP`**. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | **CEP application user** who performed the mapping change (**`COALESCE(AppLoginName, PreviousAppLoginName)`** from temporal history). **NULL** in ~63% of rows (system-driven operations). (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | **Source timestamp** of the mapping event — **`SysStartTime`** for additions, **`SysEndTime`** for removals. (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | **DWH load timestamp** via **`GETDATE()`** in the SP — **not** the business event time. (Tier 2 — SP_CEPDailyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP_CEPDailyAudit | @Date | Direct assignment |
| RuleID | #Dim_CPtoRule (CPToRule_Log → RulesLog) | RuleID | LEFT JOIN on CompoundPropertyID |
| RuleName | #Dim_CPtoRule (RulesLog) | Name | Denormalized from latest rule state |
| HedgeServerID | #Dim_CPtoRule (RulesLog) | HedgeRuleActionTypeID | Aliased as HedgeServerID |
| CompoundPropertyID | External_Etoro_CEP_ConditionToCompoundProperty | CompoundPropertyID | Passthrough |
| CP_Name | #CPLog (latest by CP) | Name | Latest CP name |
| ConditionID | External_Etoro_CEP_ConditionToCompoundProperty | ConditionID | Passthrough |
| TypeOfChange | SP_CEPDailyAudit | — | SP-derived event classification |
| LoginName | External_Etoro_CEP_ConditionToCompoundProperty / History | AppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) |
| ChangeTime | External_Etoro_CEP_ConditionToCompoundProperty / History | SysStartTime / SysEndTime | SysStartTime for adds; SysEndTime for removes |
| UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
[CEP System — ConditionToCompoundProperty temporal table]
    |
    v
Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty  (current)
Dealing_staging.External_Etoro_History_ConditionToCompoundProperty  (history)
    |  JOIN #CPLog (CP name)
    |  LEFT JOIN #Dim_CPtoRule (Rule context via CPToRule → Rules chain)
    v
SP_CEPDailyAudit(@Date)
    — SysStartDate / SysEndDate logic → Condition Added To CP / Condition Removed from CP
    |
    v
Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP  ← DELETE + INSERT for @Date (~6,604 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CompoundPropertyID | Dealing_CEPDailyAudit_CP | CP whose condition membership changed |
| ConditionID | Dealing_CEPDailyAudit_Conditions | Condition definition that was mapped/unmapped |
| RuleID | Dealing_CEPDailyAudit_Rules | Parent rule (via CP-to-Rule chain) |
| CompoundPropertyID | Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty | Source mapping entity |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_CEPWeeklyAudit_ConditionToCP | ConditionID / CompoundPropertyID | Weekly rollup of same events (if exists) |

---

## 7. Sample Queries

### 7.1 All condition-to-CP changes on a specific date

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CP_Name
    , ConditionID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP
WHERE Date = '2026-04-19'
ORDER BY CompoundPropertyID, ConditionID, ChangeTime;
```

### 7.2 Condition additions to a specific CP over time

```sql
SELECT
      Date
    , ConditionID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP
WHERE CompoundPropertyID = @CPID
  AND TypeOfChange = 'Condition Added To CP'
ORDER BY Date DESC, ChangeTime DESC;
```

### 7.3 Same-day join: condition mapping + condition definition changes

```sql
SELECT
      m.Date
    , m.CompoundPropertyID
    , m.CP_Name
    , m.ConditionID
    , m.TypeOfChange   AS MappingEvent
    , c.TypeOfChange   AS DefinitionEvent
    , c.Property
    , c.Operator
    , c.Value
    , m.LoginName
FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP AS m
LEFT JOIN Dealing_dbo.Dealing_CEPDailyAudit_Conditions AS c
       ON c.ConditionID = m.ConditionID
      AND c.Date = m.Date
WHERE m.Date = '2026-03-31'
ORDER BY m.CompoundPropertyID, m.ConditionID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 (★★★★☆) | Batch: regen-harness attempt 1*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4 | Elements: 9/10, Logic: 8.5/10, Relationships: 8/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP | Type: Table | Production Source: Dealing_staging CEP temporal tables via SP_CEPDailyAudit*
