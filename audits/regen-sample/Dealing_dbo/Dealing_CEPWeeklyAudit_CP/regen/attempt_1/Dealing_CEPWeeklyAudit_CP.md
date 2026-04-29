# Dealing_dbo.Dealing_CEPWeeklyAudit_CP

> ~1,365-row weekly audit of **CEP Compound Property (CP) definition** changes — creation, deletion, and name edits — aggregated to a **Monday–Sunday** window from September 2021 to present, loaded by `SP_W_CEPWeeklyAudit` each Sunday.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables via `SP_W_CEPWeeklyAudit` |
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

This table captures **weekly** audit events for **CEP Compound Properties (CPs)** — the mid-level grouping objects in the Client Execution Platform hedging configuration that sit between **Rules** and **Conditions**. Each row describes a **change to a CP** (creation, deletion, or name edit) that occurred within the **Monday–Sunday** window (`FromDate` / `ToDate`).

The table holds **~1,365 rows** across **234 distinct weeks** (2021-09-26 → 2026-04-25), covering **730 distinct CPs** and **403 distinct rules**. It is the **weekly** counterpart to `Dealing_CEPDailyAudit_CP` (daily granularity from approximately December 2023). For **September 2021 through late 2023**, this weekly table may be the **only** Synapse-native audit of CP-level changes.

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)   ← this table audits changes here
        └── Condition
```

**Rule context:** Each CP row is enriched with `RuleID`, `RuleName`, and `HedgeServerID` via a dimension join (`#Dim_CPtoRule`) resolved at ETL time. A CP attached to **multiple rules** can produce **multiple rows** for one underlying change. CPs with **no rule mapping** will show **NULL** for `RuleID`, `RuleName`, and `HedgeServerID` (observed in sample data — 79 NULL-change placeholder rows, plus orphaned CPs).

**No-change weeks:** The SP uses a **LEFT JOIN** on `#FromDateToDate` that can emit **placeholder rows** with **NULL `TypeOfChange`** for weeks with no CP changes. Use **`WHERE TypeOfChange IS NOT NULL`** for event-only extracts.

**LoginName population:** **989 of 1,365 rows** have **NULL `LoginName`**. This is expected — `AppLoginName` from the source may be NULL for deletion events and certain history rows.

---

## 2. Business Logic

### 2.1 Change Type Classification

**What**: The SP classifies CP lifecycle events into three categories.
**Columns Involved**: `TypeOfChange`, `Comments`
**Rules**:
- **`New Compound Property`** (355 rows): `RN=1` in temporal history AND `DATEDIFF(MINUTE, ValidFrom, ChangeTime) <= 60` — the CP was first observed within the audit week.
- **`Name Change`** (204 rows): `NameChange=1` flag set when `Name <> PreviousName AND PreviousName IS NOT NULL` — the CP was renamed. `Comments` carries `Previous Name: {old_name}`.
- **`Compound Property Deleted`** (727 rows): `RN_Desc=1` AND `SysEndTime` falls within the audit week — the CP's last temporal record ended in this week.
- **NULL** (79 rows): No-change placeholder from the LEFT JOIN pattern — the week had no CP events.

### 2.2 Rule Context Enrichment

**What**: Each CP change is enriched with the parent rule context at ETL time.
**Columns Involved**: `RuleID`, `RuleName`, `HedgeServerID`
**Rules**:
- Resolved via `#Dim_CPtoRule` — joins `#CPToRule_Log` (latest `RN_Desc=1` mapping) with `#RulesLog` (latest `RN_Desc=1` rule).
- A CP with **no active rule mapping** produces NULL rule context columns.
- A CP mapped to **multiple rules** fans out into multiple rows.

### 2.3 ChangeTime Derivation

**What**: The event timestamp is derived from temporal system columns.
**Columns Involved**: `ChangeTime`
**Rules**:
- `CASE WHEN SysEndTime > '3000-01-01' THEN SysStartTime ELSE SysEndTime END` — active records use `SysStartTime`, closed/deleted records use `SysEndTime`.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for moderate audit volume (~1.4K rows). |
| **Clustered index** | `[FromDate]` ASC — primary filter for week selection. |
| **Scale** | Small — routine queries are inexpensive. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What CP changes happened in a given week? | `WHERE FromDate = @weekStart AND TypeOfChange IS NOT NULL` |
| History of a specific CP? | `WHERE CompoundPropertyID = @cp ORDER BY FromDate` |
| CP creation/deletion trend? | `GROUP BY YEAR(FromDate), TypeOfChange` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `Dealing_CEPWeeklyAudit_Rules` | `RuleID + FromDate` | Rule-level shell changes in the same week |
| `Dealing_CEPWeeklyAudit_CPToRule` | `CompoundPropertyID + FromDate` | CP-to-rule mapping changes in the same week |
| `Dealing_CEPWeeklyAudit_ConditionToCP` | `CompoundPropertyID + FromDate` | Condition membership changes under this CP |

### 3.4 Gotchas

- **NULL `TypeOfChange`** rows are scaffolding, not "unknown change" — always filter `IS NOT NULL` for event analysis.
- **NULL `RuleID`** does not mean "orphan" in all cases — the LEFT JOIN to `#Dim_CPtoRule` produces NULLs when the CP had no rule mapping at snapshot time.
- **`CPName`** uses the name **at the time of the change event** — not the current name. For name-change rows, `Comments` has the previous name.
- **Fan-out**: one CP deletion can appear as multiple rows if the CP was mapped to multiple rules — deduplicate on `CompoundPropertyID + FromDate + TypeOfChange` when counting distinct events.
- **LoginName** is NULL for ~72% of rows — do not assume completeness for attribution analysis.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 2** | Inferred from ETL / writer procedure logic (`SP_W_CEPWeeklyAudit`) |
| **Tier 4** | ETL metadata (load timestamp) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | Start of the audit week (Monday 00:00:00). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | End of the audit week (Sunday 00:00:00). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | CEP Rule associated with the CP via `#Dim_CPtoRule` dimension join; NULL when the CP has no active rule mapping at snapshot time. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | Human-readable rule name denormalized from the latest rule snapshot (`RN_Desc=1` in `#RulesLog`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | CompoundPropertyID | int | YES | Compound Property that was created, deleted, or renamed; NULL for no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | CPName | varchar(max) | YES | CP display name at the time of the change event. For name-change rows, this is the **new** name; the previous name appears in `Comments`. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | HedgeServerID | int | YES | Hedge server / action type identifier from the rule context dimension (`HedgeRuleActionTypeID` lineage via `#Dim_CPtoRule`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | Event type: `New Compound Property`, `Name Change`, `Compound Property Deleted`; NULL for no-change placeholder weeks from the LEFT JOIN pattern. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | Comments | varchar(max) | YES | Previous-value context: `Previous Name: {old_name}` for name changes; NULL for new CP, deleted CP, and placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | CEP application user (`AppLoginName`) for the change. NULL for ~72% of rows — deletions and certain history paths do not carry login attribution. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | Event timestamp derived as `CASE WHEN SysEndTime>'3000-01-01' THEN SysStartTime ELSE SysEndTime END` from temporal source columns. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | Row load time: `GETDATE()` at SP execution — DWH metadata, not business event time. (Tier 4 — SP_W_CEPWeeklyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| FromDate | SP_W_CEPWeeklyAudit | `@weekStart` | `DATEADD(DAY,1,DATEADD(WW,-1,@dd))` |
| ToDate | SP_W_CEPWeeklyAudit | `@weekEnd` | `DATEADD(DAY,6,@weekStart)` |
| RuleID | External_Etoro_CEP/History_CompoundPropertyToRule | `RuleID` | Via `#Dim_CPtoRule` dimension join |
| RuleName | External_Etoro_CEP/History_Rules | `Name` | Denormalized via `#Dim_CPtoRule` → `#RulesLog` |
| CompoundPropertyID | External_Etoro_CEP/History_CompoundProperties | `CompoundPropertyID` | Passthrough |
| CPName | External_Etoro_CEP/History_CompoundProperties | `Name` | Passthrough aliased as CPName |
| HedgeServerID | External_Etoro_CEP/History_Rules | `HedgeRuleActionTypeID` | Aliased via `#Dim_CPtoRule` |
| TypeOfChange | SP_W_CEPWeeklyAudit | SP logic | Derived from temporal diff semantics |
| Comments | SP_W_CEPWeeklyAudit | SP logic | `CONCAT('Previous Name: ', PreviousName)` or NULL |
| LoginName | External_Etoro_CEP/History_CompoundProperties | `AppLoginName` | Passthrough |
| ChangeTime | External_Etoro_CEP/History_CompoundProperties | `SysStartTime` / `SysEndTime` | CASE expression on temporal validity |
| UpdateDate | SP_W_CEPWeeklyAudit | `GETDATE()` | ETL load timestamp |

### 5.2 ETL Pipeline

```
Dealing_staging.External_Etoro_CEP_CompoundProperties          (current)
Dealing_staging.External_Etoro_History_CompoundProperties       (temporal history)
Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule       (CP-to-rule mapping)
Dealing_staging.External_Etoro_History_CompoundPropertyToRule    (temporal mapping)
Dealing_staging.External_Etoro_CEP_Rules                        (rule definitions)
Dealing_staging.External_Etoro_History_Rules                    (temporal rules)
    |
    v
Dealing_dbo.SP_W_CEPWeeklyAudit(@dd)
    — #CPLog: UNION ALL current + history, LAG for PreviousName, NameChange flag
    — #CPChangesFinal: New/NameChange/Deleted classification + week window filter
    — #Dim_CPtoRule: rule context (RuleID, RuleName, HedgeServerID) from latest mapping
    — LEFT JOIN #FromDateToDate for no-change placeholder rows
    — DELETE + INSERT for week key (FromDate + ToDate)
    |
    v
Dealing_dbo.Dealing_CEPWeeklyAudit_CP  (~1,365 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RuleID | `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | Rule-level weekly audit (same `RuleID` + week) |
| CompoundPropertyID | `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` | CP-to-rule mapping weekly audit |
| CompoundPropertyID | `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | Condition membership weekly audit under this CP |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | Daily counterpart — higher date resolution for periods after ~Dec 2023 |
| `Dealing_staging.External_Etoro_CEP_CompoundProperties` | Current-state external source |
| `Dealing_staging.External_Etoro_History_CompoundProperties` | Temporal history source |

---

## 7. Sample Queries

### 7.1 All CP events in a specific audit week

```sql
SELECT
      FromDate
    , ToDate
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CPName
    , HedgeServerID
    , TypeOfChange
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP
WHERE FromDate = '2026-04-19'
  AND TypeOfChange IS NOT NULL
ORDER BY RuleID, CompoundPropertyID, ChangeTime;
```

### 7.2 CP creation and deletion trend by year

```sql
SELECT
      YEAR(FromDate) AS audit_year
    , TypeOfChange
    , COUNT(*) AS cnt
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP
WHERE TypeOfChange IS NOT NULL
GROUP BY YEAR(FromDate), TypeOfChange
ORDER BY audit_year DESC, TypeOfChange;
```

### 7.3 Name changes with previous name context

```sql
SELECT
      FromDate
    , CompoundPropertyID
    , CPName          AS NewName
    , Comments        AS PreviousNameContext
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP
WHERE TypeOfChange = 'Name Change'
  AND FromDate >= '2025-01-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Weekly CEP audit family*
*Tiers: 0 T1, 11 T2, 0 T3, 1 T4 | Writer: Dealing_dbo.SP_W_CEPWeeklyAudit*
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_CP | Type: Table | Source: Dealing_staging CEP temporal / external*
