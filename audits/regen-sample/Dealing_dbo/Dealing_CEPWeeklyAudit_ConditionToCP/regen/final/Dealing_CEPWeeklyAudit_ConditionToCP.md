# Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP

> ~9,903-row weekly audit of **condition-to-compound-property membership changes** in CEP — when a condition is **added to** or **removed from** a compound property, rolled up to a **Monday–Sunday** window (`FromDate` / `ToDate`). History from **2021-09-26** to present; loaded by `SP_W_CEPWeeklyAudit` each **Sunday**.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` + `External_Etoro_History_ConditionToCompoundProperty` via `SP_W_CEPWeeklyAudit` |
| **Refresh** | Weekly — **Sunday** run (Priority 0 — OpsDB / Service Broker) |
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

This table is the **weekly** audit trail for **condition-to-compound-property** membership changes inside the CEP rule engine. Conditions are the **atomic predicates** (property + operator + value) that make up compound properties, which in turn sit under rules. Each row records when a **condition was wired into or unwired from a CP** during a **Monday–Sunday** audit window.

**Scale:** ~9,903 rows across **~240 weeks** (2021-09-26 → 2026-04-19). The high row count relative to the 48 placeholder rows indicates **frequent condition-to-CP wiring activity**. `Condition Removed from CP` (6,814) significantly outnumbers `Condition Added To CP` (3,041), consistent with ongoing rule engine refinement where conditions are reorganized.

**Rule context fan-out:** The SP resolves rule context (`RuleID`, `RuleName`, `HedgeServerID`) via a **CP→Rule** dimension join. Since one CP can be wired to **multiple rules**, a single condition-to-CP event can produce **multiple rows** — one per rule that references the affected CP. This is intentional and mirrors the **daily** sibling's behavior.

**No-change weeks:** The `LEFT JOIN` to `#FromDateToDate` guarantees **at least one row per processed week**, even when no condition-to-CP changes occurred. These rows carry **NULL** `TypeOfChange`, `CompoundPropertyID`, `ConditionID`, etc. (48 such rows observed). Filter with **`WHERE TypeOfChange IS NOT NULL`** for real events.

**Historical coverage:** Weekly CEP audit tables were populated from **Sep 2021** onward. The **daily** counterpart (`Dealing_CEPDailyAudit_ConditionToCP`) begins **Dec 2023**; use **this** table for **pre-Dec-2023** condition-to-CP change history.

---

## 2. Business Logic

### 2.1 Event Classification

**What**: Each row represents one of two membership events or a no-change placeholder.
**Columns Involved**: `TypeOfChange`, `ConditionID`, `CompoundPropertyID`
**Rules**:
- `'Condition Added To CP'` — the condition's `SysStartTime` falls within the audit week AND `SysStartTime <> SysEndTime` (the record is not an instantaneous no-op)
- `'Condition Removed from CP'` — the condition's `SysEndTime` falls within the audit week, `SysEndTime < '9999-01-01'`, AND `SysStartTime <> SysEndTime`
- **NULL** — placeholder row for a week with no condition-to-CP changes (from `LEFT JOIN` to week spine)

### 2.2 Rule Context Resolution

**What**: Rule-level attributes are denormalized onto each event via a two-hop join.
**Columns Involved**: `RuleID`, `RuleName`, `HedgeServerID`
**Rules**:
- `CompoundPropertyID` → `#Dim_CPtoRule` (built from `#CPToRule_Log` joined to latest rule record in `#RulesLog` where `RN_Desc=1`)
- One CP can map to **multiple rules** → fan-out produces duplicate-looking rows with different `RuleID`/`RuleName`
- When the CP has no active rule mapping, `RuleID`, `RuleName`, `HedgeServerID` are **NULL** (~1,306 rows)

### 2.3 CP Name Resolution

**What**: CP_Name is denormalized from the compound properties log.
**Columns Involved**: `CP_Name`, `CompoundPropertyID`
**Rules**:
- `#ConditionToCP_Log` joins source data to `#CPLog` (latest CP name where `RN_Desc=1`) on `CompoundPropertyID`
- Uses underscore form `CP_Name` — consistent with `Dealing_CEPWeeklyAudit_CPToRule` but differs from `Dealing_CEPWeeklyAudit_CP.CPName` (no underscore)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for ~10K audit rows. |
| **Clustered index** | **`FromDate` ASC** — filter on `FromDate` for week-level predicates. |
| **Scale** | Small-to-moderate; no special optimization needed. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What condition-to-CP changes happened in a specific week? | `WHERE FromDate = @WeekStart AND TypeOfChange IS NOT NULL` |
| History of a specific condition's CP membership? | `WHERE ConditionID = @id AND TypeOfChange IS NOT NULL ORDER BY FromDate` |
| Which CPs had the most condition wiring activity? | `GROUP BY CompoundPropertyID, CP_Name` with `COUNT(*)` on non-NULL TypeOfChange |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `Dealing_CEPWeeklyAudit_Conditions` | `ConditionID + FromDate` | Pair **membership** moves with **definition** edits in the same week |
| `Dealing_CEPWeeklyAudit_CP` | `CompoundPropertyID + FromDate` | Relate condition wiring to **CP-level** events (renames, deletes) |
| `Dealing_CEPWeeklyAudit_CPToRule` | `CompoundPropertyID + FromDate` | See **CP-to-rule** mapping changes alongside condition membership |

### 3.4 Gotchas

- **Fan-out on RuleID**: A single condition-to-CP event can appear on **multiple rows** if the CP maps to multiple rules. Use `COUNT(DISTINCT ConditionID)` rather than `COUNT(*)` for true event counts.
- **NULL RuleID**: ~1,306 rows have NULL rule context — the CP was not mapped to any rule at resolution time. Do not treat these as data errors.
- **NULL TypeOfChange**: 48 rows are structural placeholders for weeks with no changes. Always filter `WHERE TypeOfChange IS NOT NULL` for event-centric reporting.
- **Column name**: `CP_Name` (with underscore) — differs from `Dealing_CEPWeeklyAudit_CP.CPName` (no underscore).
- **ToDate**: Stored as **Sunday 00:00:00** — not end-of-Sunday 23:59:59.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 2** | Inferred from ETL / writer procedure logic (`SP_W_CEPWeeklyAudit`) |
| **Tier 4** | ETL metadata (load timestamp) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | Week start — Monday 00:00:00 for the audit window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | Week end marker — Sunday 00:00:00 as derived in the SP (six days after FromDate), not 23:59:59. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | Parent rule ID resolved via CP→Rule dimension join (`#Dim_CPtoRule`); NULL when the CP has no active rule mapping (~13% of rows). Fan-out: one condition-to-CP event may yield multiple rows for different rules sharing the same CP. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | Human-readable rule name denormalized from the latest rule record (`RN_Desc=1` in `#RulesLog`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | HedgeServerID | int | YES | Hedge server / action type identifier from the parent rule context (`HedgeRuleActionTypeID` lineage via `#Dim_CPtoRule`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | CompoundPropertyID | int | YES | Compound property whose condition membership changed; NULL on no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | CP_Name | varchar(max) | YES | Compound property display name — note `CP_Name` (with underscore) here vs `CPName` (no underscore) in `Dealing_CEPWeeklyAudit_CP`. Resolved from latest CP record in `#CPLog` (`RN_Desc=1`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | ConditionID | int | YES | Condition that was added to or removed from the CP; NULL on no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | TypeOfChange | varchar(max) | YES | `Condition Added To CP` or `Condition Removed from CP`; NULL for no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | CEP application user (`AppLoginName` from source) attributed to the membership change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | Source event timestamp — `SysStartTime` for adds, `SysEndTime` for removes; NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | DWH insert time via `GETDATE()` at SP execution — not business event time. (Tier 4 — SP_W_CEPWeeklyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| FromDate | SP_W_CEPWeeklyAudit | @weekStart | `DATEADD(DAY,1,DATEADD(WW,-1,@dd))` |
| ToDate | SP_W_CEPWeeklyAudit | @weekEnd | `DATEADD(DAY,6,@weekStart)` |
| RuleID | External_Etoro_CEP/History_CompoundPropertyToRule → #Dim_CPtoRule | RuleID | CP→Rule dimension join |
| RuleName | External_Etoro_CEP/History_Rules → #RulesLog → #Dim_CPtoRule | Name | Latest rule name (RN_Desc=1) |
| HedgeServerID | External_Etoro_CEP/History_Rules → #RulesLog → #Dim_CPtoRule | HedgeRuleActionTypeID | Passthrough via dimension join |
| CompoundPropertyID | External_Etoro_CEP/History_ConditionToCompoundProperty | CompoundPropertyID | Direct passthrough |
| CP_Name | External_Etoro_CEP/History_CompoundProperties → #CPLog | Name | Latest CP name (RN_Desc=1) |
| ConditionID | External_Etoro_CEP/History_ConditionToCompoundProperty | ConditionID | Direct passthrough |
| TypeOfChange | SP_W_CEPWeeklyAudit | — | SP classification: add vs remove |
| LoginName | External_Etoro_CEP/History_ConditionToCompoundProperty | AppLoginName | Rename only |
| ChangeTime | External_Etoro_CEP/History_ConditionToCompoundProperty | SysStartTime / SysEndTime | SysStartTime for adds; SysEndTime for removes |
| UpdateDate | SP_W_CEPWeeklyAudit | GETDATE() | ETL load timestamp |

### 5.2 ETL Pipeline

```
Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty  (current)
Dealing_staging.External_Etoro_History_ConditionToCompoundProperty  (temporal history)
    ↓  UNION ALL
#ConditionToCP_Log  (+ JOIN #CPLog for CP_Name)
    ↓  Filter: SysStartTime / SysEndTime BETWEEN @weekStart AND @weekEnd
#ConditionToCP_ChangesFinal  (TypeOfChange classification)
    ↓  LEFT JOIN #Dim_CPtoRule (rule context: RuleID, RuleName, HedgeServerID)
    ↓  LEFT JOIN #FromDateToDate (week spine — guarantees placeholder rows)
    ↓  DELETE + INSERT for (@weekStart, @weekEnd)
Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP  (~9,903 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CompoundPropertyID | `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` | Current condition-to-CP source |
| CompoundPropertyID | `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` | Temporal history source |
| RuleID (via CP→Rule) | `Dealing_staging.External_Etoro_CEP/History_CompoundPropertyToRule` | Rule context resolution chain |
| CP_Name | `Dealing_staging.External_Etoro_CEP/History_CompoundProperties` | CP name resolution |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP` | **Daily** counterpart — finer date grain for periods after ~Dec 2023 |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | **Sibling** — condition **definition** changes in the same week (join on `ConditionID + FromDate`) |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | **Sibling** — CP-level entity events (renames, deletes) in the same week |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` | **Sibling** — CP-to-rule mapping changes in the same week |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | **Sibling** — rule-level changes in the same week |

---

## 7. Sample Queries

### 7.1 All condition-to-CP events for one audit week

```sql
SELECT
      FromDate
    , ToDate
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CP_Name
    , ConditionID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP
WHERE FromDate = '2026-04-19'
  AND TypeOfChange IS NOT NULL
ORDER BY CompoundPropertyID, ConditionID, ChangeTime;
```

### 7.2 Condition membership history for a specific CP

```sql
SELECT
      FromDate
    , ConditionID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP
WHERE CompoundPropertyID = @CompoundPropertyID
  AND TypeOfChange IS NOT NULL
ORDER BY FromDate DESC, ChangeTime DESC;
```

### 7.3 Condition-to-CP events alongside condition definition edits (same week)

```sql
SELECT
      m.FromDate
    , m.ConditionID
    , m.CompoundPropertyID
    , m.CP_Name
    , m.TypeOfChange     AS Membership_Event
    , c.TypeOfChange     AS Definition_Event
    , c.Property
    , c.Operator
    , c.Value
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP AS m
LEFT JOIN Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions AS c
       ON c.FromDate = m.FromDate
      AND c.ConditionID = m.ConditionID
WHERE m.FromDate = '2026-04-19'
  AND m.TypeOfChange IS NOT NULL
ORDER BY m.CompoundPropertyID, m.ConditionID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Weekly CEP audit family*
*Tiers: 0 T1, 11 T2, 0 T3, 1 T4 | Writer: Dealing_dbo.SP_W_CEPWeeklyAudit*
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP | Type: Table | Production Source: Dealing_staging CEP ConditionToCompoundProperty + history*
