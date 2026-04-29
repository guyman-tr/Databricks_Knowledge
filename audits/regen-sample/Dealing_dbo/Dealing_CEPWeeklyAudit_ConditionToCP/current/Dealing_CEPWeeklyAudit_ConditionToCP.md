# Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP

> Weekly audit of **Condition-to-Compound Property (CP)** mapping changes in CEP — when atomic rule conditions are added to or removed from a CP’s condition bundle, aggregated to a **Monday–Sunday** window.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal / external tables |
| **Refresh** | Weekly (Sunday batch; OpsDB Priority 0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **Approx. row count** | ~4,514 |
| **Sample date range** | 2021-09-26 → 2026-03-01 (via `FromDate`) |
| **PII** | No |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **weekly** counterpart to **`Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP`**. It records **which CEP conditions were linked to or unlinked from a Compound Property (CP)** during each audit week. **`ConditionID` + `CP_Name` (and `CompoundPropertyID`)** identifies the membership edge that changed; **`RuleID` / `RuleName` / `HedgeServerID`** place that CP in **rule** context.

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)
        └── Condition   ← ConditionToCP membership audited here
```

**Weekly grain:** Each row is tied to **`FromDate`** (week start, Monday) and **`ToDate`** (week end, Sunday). The ETL uses a **LEFT JOIN** pattern that can emit **placeholder rows** with **`TypeOfChange` NULL** for weeks with **no** membership change for a given key path. For analysis, **`WHERE TypeOfChange IS NOT NULL`** restricts to real events.

**Why it matters:** Membership edits change **which atomic predicates** participate in a CP bundle — a common root cause when hedging or routing behaves differently than expected. Weekly history extends **back to September 2021**, roughly **two years earlier** than the daily audit table’s typical window, which helps long-horizon investigations.

**Load pattern:** **`Dealing_dbo.SP_W_CEPWeeklyAudit`** loads this table together with sibling weekly CEP audit tables from **`Dealing_staging`** externals and temporal history. Refresh aligns to the **Sunday** weekly job.

## 2. Business Logic

- **Sources:** `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` (current) and `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` (temporal history).
- **Change typing:** The SP classifies rows as **`Condition Added To CP`** or **`Condition Removed from CP`** from temporal validity boundaries aggregated to the week; exact predicates mirror the weekly SP logic (SysStart/SysEnd style semantics rolled to **`FromDate` / `ToDate`**).
- **Rule context:** **`RuleID`**, **`RuleName`**, **`HedgeServerID`** are resolved through the same **CP-to-rule** style dimension chain used in the daily pipeline (weekly build in **`SP_W_CEPWeeklyAudit`**). A CP attached to **multiple rules** can still produce **multiple rows** for one underlying membership change.
- **No-change weeks:** Expect **`TypeOfChange` NULL** rows from the outer join scaffolding — **not** application nulls; filter them out for change-only reporting.
- **`UpdateDate`:** Set in the SP with **`GETDATE()`** — **DWH load metadata**, not the CEP business timestamp (use **`ChangeTime`** for source time).

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for modest audit volume. |
| **Clustered index** | **`FromDate` ASC** — aligns with “which week?” filters. |
| **Scale** | Low thousands of rows — routine filters on week or change type are inexpensive. |

### 3.2 Recommended patterns

- Filter **`WHERE FromDate = @weekStart`** (Monday) **or** a **`FromDate` range** for multi-week reviews.
- Always consider **`AND TypeOfChange IS NOT NULL`** when counting **events** rather than **scaffold rows**.
- Join to **`Dealing_CEPWeeklyAudit_Conditions`** on **`ConditionID`** (and overlapping week) for **Property / Operator / Value** semantics.
- Compare to **`Dealing_CEPDailyAudit_ConditionToCP`** when you need **calendar-day** precision for recent periods.

### 3.3 Freshness

- Treated as **ACTIVE** in documentation sampling (**max `FromDate` 2026-03-01** in the captured stats). New weeks appear after each **Sunday** successful run of **`SP_W_CEPWeeklyAudit`**.

### 3.4 Gotchas

- **`TypeOfChange`** literals are **exact** (spacing and casing): **`Condition Added To CP`**, **`Condition Removed from CP`**.
- **Fan-out across rules** can duplicate logical membership events — validate with **`RuleID`** when deduplicating.
- **Do not** interpret **`ToDate`** alone as “change happened at end of Sunday” without reading **`ChangeTime`** — **`ToDate`** bounds the **audit window**.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_W_CEPWeeklyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | **Start of the audit week (Monday)** — lower bound of the weekly window written by **`SP_W_CEPWeeklyAudit`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | **End of the audit week (Sunday)** — upper bound of the weekly window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | **CEP Rule** whose CP gained or lost the condition — from weekly CP-to-rule resolution in the SP. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | **Human-readable rule name** denormalized for reporting. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | HedgeServerID | int | YES | **Hedge server** associated with the rule context. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | CompoundPropertyID | int | YES | **Compound Property** that gained or lost the **condition**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | CP_Name | varchar(max) | YES | **CP display name** for analyst-friendly output. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | ConditionID | int | YES | **Condition** added to or removed from the CP — join to **weekly conditions audit** for predicate detail. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | TypeOfChange | varchar(max) | YES | **`Condition Added To CP`** or **`Condition Removed from CP`**; **NULL** for **no-change** placeholder weeks from the outer join pattern. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | **CEP application user** attributed to the change (temporal / login resolution per SP). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | **Source-system timestamp** of the membership event (add vs remove path per SP). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | **Row insert time** in the warehouse via **`GETDATE()`** in the SP — not the business event time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

**Upstream → writer → target**

```
Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty  (current)
Dealing_staging.External_Etoro_History_ConditionToCompoundProperty  (temporal history)
    ↓
Dealing_dbo.SP_W_CEPWeeklyAudit
    — weekly aggregation to FromDate / ToDate (Monday–Sunday)
    — CP / rule context joins (weekly analog to daily CP-to-rule resolution)
    — TypeOfChange derived from temporal add/remove semantics
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP
```

**Column lineage (summary):** `FromDate` / `ToDate` ← weekly window boundaries from the SP; `CompoundPropertyID`, `ConditionID`, `LoginName`, `ChangeTime` ← condition-to-CP external / history; `RuleID`, `RuleName`, `HedgeServerID` ← CP-to-rule chain in weekly build; `CP_Name` ← CP naming resolution; `TypeOfChange` ← SP classification; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP` | **Daily** audit of the same event family — use for day-level drill-down on recent history. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | **Condition definition** changes — predicate semantics for **`ConditionID`**. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | **CP-level** weekly audit — sibling entity in the same weekly job. |
| `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` | **Current** condition-to-CP links. |
| `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` | **Temporal history** of links. |

## 7. Sample Queries

**7.1 — Real membership changes in one audit week**

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
WHERE FromDate = '2026-02-24'   -- example Monday
  AND TypeOfChange IS NOT NULL
ORDER BY RuleID, CompoundPropertyID, ChangeTime;
```

**7.2 — Removals over a multi-month window**

```sql
SELECT
      FromDate
    , ToDate
    , ConditionID
    , CompoundPropertyID
    , CP_Name
    , RuleID
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP
WHERE TypeOfChange = 'Condition Removed from CP'
  AND FromDate >= '2025-10-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

**7.3 — Weekly removal plus condition definition context**

```sql
SELECT
      m.FromDate
    , m.ToDate
    , m.ConditionID
    , m.TypeOfChange      AS MembershipChange
    , c.Property
    , c.Operator
    , c.Value
    , c.TypeOfChange      AS DefinitionChange
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP AS m
LEFT JOIN Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions AS c
       ON c.ConditionID = m.ConditionID
      AND c.FromDate = m.FromDate
WHERE m.TypeOfChange = 'Condition Removed from CP'
  AND m.FromDate >= '2025-01-01'
ORDER BY m.FromDate DESC, m.ConditionID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★★☆) | Weekly CEP audit family*  
*Tiers: 0 T1, 11 T2, 0 T3, 1 T4 | Writer: Dealing_dbo.SP_W_CEPWeeklyAudit*  
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP | Type: Table | Source: Dealing_staging CEP temporal / external*
