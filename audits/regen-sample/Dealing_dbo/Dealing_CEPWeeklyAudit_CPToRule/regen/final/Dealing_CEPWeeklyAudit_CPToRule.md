# Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule

> ~58,248-row weekly audit of **Compound Property (CP) ↔ Rule mapping** changes in the CEP hedging engine, tracking when CPs are added to, removed from, or have their boolean mapping (`IsTrue`) toggled on rules. Loaded by `SP_W_CEPWeeklyAudit` each **Sunday** from `Dealing_staging` temporal sources. History from **2021-09-26** to present.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP CompoundPropertyToRule temporal tables via `SP_W_CEPWeeklyAudit` |
| **Refresh** | Weekly (Sunday batch) |
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

This table records **weekly** changes to the **CP-to-Rule** mapping layer in the Client Execution Platform (CEP) hedging configuration. In the CEP hierarchy, **Rules** contain **Compound Properties (CPs)**, which in turn contain **Conditions**. This table sits at the **Rule ↔ CP** edge and captures when a CP is linked to a rule, unlinked, or has its boolean mapping state (`IsTrue`) changed.

**Scale:** ~58,248 rows spanning **2021-09-26 through 2026-04-19** (`FromDate`). Unlike sibling weekly audit tables that are dominated by no-change placeholder rows, this table has **very few placeholders** (56 rows with NULL `TypeOfChange`) — the vast majority are actual change events. The dominant event types are **CP Added to Rule** (34,418 rows, 59%) and **CP Removed from Rule** (23,411 rows, 40%), with a small number of boolean mapping toggles (363 rows combined).

**LoginName gaps:** `LoginName` (`AppLoginName` from source) is NULL in ~54% of rows. This is characteristic of temporal history rows where the application login was not captured at the time of the original event.

**Weekly grain:** Each row is keyed to `FromDate` (Monday) and `ToDate` (Sunday). The SP computes the week boundaries from the input date parameter and filters source changes by `SysStartTime` / `SysEndTime` falling within that window.

**Load pattern:** `SP_W_CEPWeeklyAudit` performs a **DELETE + INSERT** for each `(@weekStart, @weekEnd)` pair, ensuring idempotent reloads.

---

## 2. Business Logic

### 2.1 Change Type Classification

**What**: The SP classifies each CP-to-rule mapping event into one of four literal `TypeOfChange` values.
**Columns Involved**: `TypeOfChange`, `IsTrue`, `RuleID`, `CompoundPropertyID`
**Rules**:
- **`CP Added to Rule`** — first temporal row for a `(RuleID, CompoundPropertyID)` pair where `SysStartTime` falls in the week window (`RN=1`)
- **`CP Removed from Rule`** — last temporal row (`RN_desc=1`) where `SysEndTime` falls in the week window
- **`Mapping Changed from Not True to True`** — `Value` changed from 0→1 (`RN>1` and `Value <> PreviousValue`)
- **`Mapping Changed from True to Not True`** — `Value` changed from 1→0 (same condition, opposite direction)

### 2.2 Rule Context Denormalization

**What**: RuleName and HedgeServerID are resolved through a dimension-style join, not carried directly from the CPToRule source.
**Columns Involved**: `RuleName`, `HedgeServerID`
**Rules**:
- `#Dim_CPtoRule` is built from `#CPToRule_Log` JOIN `#RulesLog` (latest rule state, `RN_Desc=1`)
- The INSERT joins `#CPToRule_ChangesFinal` LEFT JOIN `#Dim_CPtoRule` on `CompoundPropertyID`
- `RuleID` comes directly from `#CPToRule_ChangesFinal` (the temporal source), while `RuleName` and `HedgeServerID` come from `#Dim_CPtoRule` (the resolved dimension)
- This means `RuleName` reflects the **latest** rule name, not necessarily the name at event time

### 2.3 CP Name Resolution

**What**: CP_Name is denormalized from the CP dimension, not from the CPToRule source directly.
**Columns Involved**: `CP_Name`, `CompoundPropertyID`
**Rules**:
- `#CPToRule_Log` joins `#CPLog` (latest CP state, `RN_Desc=1`) on `CompoundPropertyID` to resolve `Name` as `CP_Name`
- The name reflects the **latest known** CP name, which may differ from the name at the time of the mapping event

### 2.4 No-Change Placeholder Rows

**What**: The LEFT JOIN to `#FromDateToDate` produces a single placeholder row per processed week when no CPToRule changes occurred.
**Columns Involved**: All columns (core columns are NULL on placeholders)
**Rules**:
- Only 56 such rows exist across the full history — far fewer than sibling tables
- Filter with `WHERE TypeOfChange IS NOT NULL` for event-only analysis

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for ~58K audit rows. |
| **Clustered index** | **`FromDate` ASC** — week-start filtering is efficient. |
| **Scale** | Moderate — no special performance considerations required. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What CP mapping changes happened in a week? | `WHERE FromDate = @weekStart AND TypeOfChange IS NOT NULL` |
| Which CPs were removed from rules recently? | `WHERE TypeOfChange = 'CP Removed from Rule' AND FromDate >= @cutoff` |
| How often do boolean mapping toggles occur? | `WHERE TypeOfChange LIKE 'Mapping Changed%' GROUP BY YEAR(FromDate)` |
| All events for a specific rule | `WHERE RuleID = @rid AND TypeOfChange IS NOT NULL ORDER BY FromDate DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `Dealing_CEPWeeklyAudit_CP` | `FromDate + CompoundPropertyID` | Correlate CP mapping moves with CP lifecycle events (creates/renames/deletes) in the same week |
| `Dealing_CEPWeeklyAudit_Rules` | `FromDate + RuleID` | Correlate rule-level changes (activations, renames) with CP mapping moves |
| `Dealing_CEPWeeklyAudit_ConditionToCP` | `FromDate + CompoundPropertyID` | See condition membership changes alongside CP-to-rule moves |

### 3.4 Gotchas

- **`TypeOfChange` literals must be exact** — e.g. `'Mapping Changed from Not True to True'` (not `'Mapping changed...'`). Case and spacing matter.
- **`LoginName` is NULL in ~54% of rows** — do not assume attribution is always available; temporal history rows often lack `AppLoginName`.
- **`RuleName` reflects latest state** — resolved via a dimension join, not the name at event time. For historical rule names, join to `Dealing_CEPWeeklyAudit_Rules` on the same `FromDate`.
- **`IsTrue` column** is stored as `bit` but displayed as True/False. In the `#CPToRule_ChangesFinal`, it originates from the `Value` column in the CPToRule source. For placeholder rows, `IsTrue` is NULL.
- **`ToDate` is Sunday 00:00:00** — it is the upper boundary marker, not an inclusive end-of-day timestamp.
- **Fan-out across rules** — a single CP can appear in multiple rules; removal events may generate multiple rows for the same `CompoundPropertyID` if the CP was mapped to several rules simultaneously.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 2** | Inferred from ETL / writer procedure logic (`SP_W_CEPWeeklyAudit`) |
| **Tier 4** | ETL metadata (load timestamp) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | Start of the audit week (Monday 00:00:00) — computed as `DATEADD(DAY,1,DATEADD(WW,-1,@dd))` in the SP. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | End of the audit week (Sunday 00:00:00) — computed as `DATEADD(DAY,6,@weekStart)`. Not end-of-day; use as a week boundary marker. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | CEP Rule identifier from the CP-to-rule temporal source; NULL on no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | Denormalized rule display name resolved via `#Dim_CPtoRule` from the latest rule state (`#RulesLog` where `RN_Desc=1`); reflects current name, not necessarily the name at event time. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | HedgeServerID | int | YES | Hedge server / action type identifier resolved via `#Dim_CPtoRule` from `HedgeRuleActionTypeID` in the rules temporal source; NULL on placeholders. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | CompoundPropertyID | int | YES | Compound Property that was added to, removed from, or had its mapping toggled on a rule; NULL on no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | CP_Name | varchar(max) | YES | CP display name denormalized from the latest CP state (`#CPLog` where `RN_Desc=1`); name may differ from event-time name if the CP was renamed. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | IsTrue | bit | YES | Boolean mapping state from `CompoundPropertyToRule.Value`: True (1) = CP is active in the rule, False (0) = CP is inactive. For `CP Added to Rule` events, reflects the initial mapping state; for toggle events, reflects the new state after the change. NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | TypeOfChange | varchar(max) | YES | Event classification: `CP Added to Rule`, `CP Removed from Rule`, `Mapping Changed from Not True to True`, `Mapping Changed from True to Not True`; NULL for no-change placeholder rows (56 across full history). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | CEP application login (`AppLoginName`) for the mapping change; NULL on placeholder rows and frequently NULL (~54%) on event rows where temporal history lacks attribution. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | Source event timestamp: `SysStartTime` for add and value-change events, `SysEndTime` for removal events; NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | Row insert time in the warehouse via `GETDATE()` at SP execution — ETL metadata, not business event time. (Tier 4 — SP_W_CEPWeeklyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| FromDate | SP_W_CEPWeeklyAudit | @weekStart | Computed week boundary (Monday) |
| ToDate | SP_W_CEPWeeklyAudit | @weekEnd | Computed week boundary (Sunday) |
| RuleID | External_Etoro_CEP_CompoundPropertyToRule | RuleID | Passthrough via `#CPToRule_Log` |
| RuleName | External_Etoro_CEP_Rules | Name | Denormalized via `#Dim_CPtoRule` (latest state) |
| HedgeServerID | External_Etoro_CEP_Rules | HedgeRuleActionTypeID | Aliased via `#Dim_CPtoRule` (latest state) |
| CompoundPropertyID | External_Etoro_CEP_CompoundPropertyToRule | CompoundPropertyID | Passthrough via `#CPToRule_Log` |
| CP_Name | External_Etoro_CEP_CompoundProperties | Name | Denormalized via `#CPLog` (latest state) |
| IsTrue | External_Etoro_CEP_CompoundPropertyToRule | Value | Aliased from `Value` to `IsTrue` |
| TypeOfChange | SP_W_CEPWeeklyAudit | — | SP-derived from temporal add/remove/value-change semantics |
| LoginName | External_Etoro_CEP_CompoundPropertyToRule | AppLoginName | Passthrough |
| ChangeTime | External_Etoro_CEP_CompoundPropertyToRule | SysStartTime / SysEndTime | SysStartTime for adds/changes, SysEndTime for removals |
| UpdateDate | SP_W_CEPWeeklyAudit | GETDATE() | ETL load timestamp |

### 5.2 ETL Pipeline

```
Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule  (current)
Dealing_staging.External_Etoro_History_CompoundPropertyToRule  (temporal history)
    ↓
    #CPToRule_Log  (UNION ALL + JOIN #CPLog for CP_Name + LAG for PreviousValue)
    ↓
    #CPToRule_ChangesFinal  (week-filtered, TypeOfChange classified)
    ↓
Dealing_staging.External_Etoro_CEP_Rules / History
    ↓
    #RulesLog → #Dim_CPtoRule  (RuleID → RuleName, HedgeServerID)
    ↓
INSERT INTO Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule
    — #FromDateToDate LEFT JOIN #CPToRule_ChangesFinal LEFT JOIN #Dim_CPtoRule
    — DELETE + INSERT for (@weekStart, @weekEnd)
    — ~58,248 rows (2021-09-26 → 2026-04-19)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RuleID | Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule | Source rule identifier in the CP-to-rule mapping |
| CompoundPropertyID | Dealing_staging.External_Etoro_CEP_CompoundProperties | Source CP identifier |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule` | **Daily** counterpart — finer date grain for recent periods (from ~Dec 2023). |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | **Sibling** — CP lifecycle changes (creates, renames, deletes) in the same weekly job. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | **Sibling** — Rule-level changes in the same weekly job. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | **Sibling** — Condition-to-CP membership changes in the same weekly job. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | **Sibling** — Condition definition changes in the same weekly job. |

---

## 7. Sample Queries

### 7.1 CP mapping events in a recent week

```sql
SELECT
      FromDate
    , ToDate
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CP_Name
    , IsTrue
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule
WHERE FromDate = '2026-03-22'
  AND TypeOfChange IS NOT NULL
ORDER BY RuleID, CompoundPropertyID, ChangeTime;
```

### 7.2 Boolean mapping toggles over time

```sql
SELECT
      YEAR(FromDate) AS audit_year
    , TypeOfChange
    , COUNT(*) AS cnt
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule
WHERE TypeOfChange LIKE 'Mapping Changed%'
GROUP BY YEAR(FromDate), TypeOfChange
ORDER BY audit_year DESC, TypeOfChange;
```

### 7.3 CP-to-rule removals alongside CP lifecycle events in the same week

```sql
SELECT
      m.FromDate
    , m.CompoundPropertyID
    , m.CP_Name
    , m.RuleID
    , m.RuleName
    , m.TypeOfChange    AS CPToRule_Event
    , cp.TypeOfChange   AS CP_Event
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule AS m
LEFT JOIN Dealing_dbo.Dealing_CEPWeeklyAudit_CP AS cp
       ON cp.FromDate = m.FromDate
      AND cp.CompoundPropertyID = m.CompoundPropertyID
WHERE m.TypeOfChange = 'CP Removed from Rule'
  AND m.FromDate >= '2025-01-01'
ORDER BY m.FromDate DESC, m.CompoundPropertyID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Weekly CEP audit family*
*Tiers: 0 T1, 11 T2, 0 T3, 1 T4 | Writer: Dealing_dbo.SP_W_CEPWeeklyAudit*
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule | Type: Table | Source: Dealing_staging CEP CompoundPropertyToRule temporal*
