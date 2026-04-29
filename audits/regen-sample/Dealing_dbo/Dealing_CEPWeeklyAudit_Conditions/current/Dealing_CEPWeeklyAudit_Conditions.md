# Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions

> Weekly audit of **CEP Condition definition** changes — edits to the atomic **Property**, **Operator**, and **Value** that make up each condition, rolled up to a **Monday–Sunday** window.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal / external tables + condition dictionaries |
| **Refresh** | Weekly (Sunday batch; OpsDB Priority 0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **Approx. row count** | ~12,333 |
| **Sample date range** | 2021-09-26 → 2026-03-01 (via `FromDate`) |
| **PII** | No |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **weekly** counterpart to **`Dealing_dbo.Dealing_CEPDailyAudit_Conditions`**. Each row describes a **change to an atomic CEP condition** during an audit week: **property**, **operator**, or **value** edits, **new condition** creation, or **condition deletion**. Conditions are the **predicates** that sit under **Compound Properties** and **Rules** in the CEP hedging configuration.

**Weekly grain:** Rows are keyed to **`FromDate`** (Monday) and **`ToDate`** (Sunday). As with other weekly CEP audit siblings, the load can produce rows where **`TypeOfChange` is NULL** to represent **weeks with no change** for a given join path — use **`WHERE TypeOfChange IS NOT NULL`** for event-only extracts.

**Volume signal:** On the order of **tens of thousands** of rows across **~230 weeks** implies **material ongoing tuning** of rule logic (especially **value** adjustments). That is **expected** for an active rules engine; compare to the **daily** table when you need **finer-than-week** timing.

**Why it matters:** Mis-set thresholds or wrong operators drive **silent** behavior changes. This audit preserves **who** changed **what**, **when**, and (via **`Comments`**) often the **prior** value for before/after reasoning.

## 2. Business Logic

- **Sources:** `Dealing_staging.External_Etoro_CEP_Conditions` and `Dealing_staging.External_Etoro_History_Conditions`, joined in **`SP_W_CEPWeeklyAudit`** with **dictionary** resolution:
  - **`External_Etoro_Dictionary_ConditionProperties`** → readable **`Property`** names.
  - **`External_Etoro_Dictionary_ConditionOperators`** → readable **`Operator`** names.
- **Change taxonomy (weekly, same family as daily):** `Property Change`, `Operator Change`, `Value Change`, `New Condition`, `Condition Deleted` — all emitted as **`TypeOfChange`** literals from the SP.
- **`Comments`:** For change rows, carries **previous value** context (e.g. previous property/operator/value text). May be **NULL** for pure create/delete paths depending on SP branch.
- **Rule context:** **`RuleID`**, **`RuleName`**, **`HedgeServerID`** are resolved through the **ConditionToCP + CPToRule** style chain in the weekly job (analogous to daily), so **one condition edit** can still **fan out** if multiple rules share the wiring path the SP explodes.
- **`Value`:** Stored as **`varchar(100)`** in Synapse — treat as **opaque predicate literal** unless you parse by **`Property`** semantics in consuming code.
- **`UpdateDate`:** **`GETDATE()`** in the SP — **ETL metadata** only.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN`. |
| **Clustered index** | **`FromDate` ASC** — primary slice for “which week?”. |
| **Scale** | Moderate row count — still small enough for ad hoc analytics without special tuning. |

### 3.2 Recommended patterns

- **`WHERE FromDate BETWEEN @start AND @end`** for multi-week studies; add **`AND TypeOfChange IS NOT NULL`** for real events.
- Investigate **`Comments`** side-by-side with **`Property` / `Operator` / `Value`** for **before/after** narratives.
- Join to **`Dealing_CEPWeeklyAudit_ConditionToCP`** on **`ConditionID` + FromDate** to relate **definition edits** to **CP membership** moves in the same week.

### 3.3 Freshness

- **Sunday** batch via **`Dealing_dbo.SP_W_CEPWeeklyAudit`**. Sample documentation window showed **max `FromDate` 2026-03-01** and **ACTIVE** load health.

### 3.4 Gotchas

- **`Property` / `Operator`** are **already resolved names** at ETL time — not raw enum IDs in this table.
- **High row count vs daily** is largely **longer history** (from **2021**) rather than implying the weekly table is “busier” per calendar day.
- **`TypeOfChange`** strings must match **exactly** in filters (case and spacing).

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_W_CEPWeeklyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | **Monday** — start of the weekly audit window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | **Sunday** — end of the weekly audit window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | **Parent rule** ID resolved via weekly **ConditionToCP → CPToRule** style chain. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | **Rule display name**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | HedgeServerID | int | YES | **Hedge server** for the rule context. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | ConditionID | int | YES | **Condition** that was created, deleted, or had definition fields changed. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | Property | varchar(max) | YES | **Attribute under test** — resolved from **`External_Etoro_Dictionary_ConditionProperties`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | Operator | varchar(max) | YES | **Comparison operator** — resolved from **`External_Etoro_Dictionary_ConditionOperators`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | Value | varchar(100) | YES | **Threshold or target literal** for the predicate. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | TypeOfChange | varchar(max) | YES | One of **`Property Change`**, **`Operator Change`**, **`Value Change`**, **`New Condition`**, **`Condition Deleted`**; **NULL** for no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | Comments | varchar(max) | YES | **Previous value** context such as `"Previous Property: …"`, `"Previous Operator: …"`, `"Previous Value: …"` when applicable. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | LoginName | varchar(max) | YES | **CEP application user** for the change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 13 | ChangeTime | datetime | YES | **Source timestamp** of the condition event. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 14 | UpdateDate | datetime | YES | **DWH insert time** from **`GETDATE()`** — not business time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

**Upstream → writer → target**

```
Dealing_staging.External_Etoro_CEP_Conditions  (current)
Dealing_staging.External_Etoro_History_Conditions  (temporal history)
Dealing_staging.External_Etoro_Dictionary_ConditionProperties
Dealing_staging.External_Etoro_Dictionary_ConditionOperators
    ↓
Dealing_dbo.SP_W_CEPWeeklyAudit
    — weekly FromDate / ToDate windowing
    — dictionary joins for Property / Operator labels
    — TypeOfChange + Comments from temporal diff semantics
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions
```

**Column lineage (summary):** `FromDate` / `ToDate` ← weekly boundaries; `ConditionID`, `Value`, `ChangeTime`, `LoginName` ← conditions external / history; `Property` / `Operator` ← dictionary tables; `RuleID`, `RuleName`, `HedgeServerID` ← exploded rule context; `TypeOfChange`, `Comments` ← SP logic; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` | **Daily** definition audit — higher **date** resolution for recent periods. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | **Membership** changes for the same **`ConditionID`** in the same week. |
| `Dealing_staging.External_Etoro_Dictionary_ConditionProperties` | **Property** name resolution. |
| `Dealing_staging.External_Etoro_Dictionary_ConditionOperators` | **Operator** name resolution. |

## 7. Sample Queries

**7.1 — All non-null definition events in a week**

```sql
SELECT
      FromDate
    , ToDate
    , ConditionID
    , Property
    , Operator
    , Value
    , TypeOfChange
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions
WHERE FromDate = '2026-02-24'
  AND TypeOfChange IS NOT NULL
ORDER BY ChangeTime, ConditionID;
```

**7.2 — Value changes with previous value text**

```sql
SELECT
      FromDate
    , ConditionID
    , Property
    , Operator
    , Value
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions
WHERE TypeOfChange = 'Value Change'
  AND FromDate >= '2025-06-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

**7.3 — New conditions in a quarter with rule context**

```sql
SELECT
      c.FromDate
    , c.ConditionID
    , c.Property
    , c.Operator
    , c.Value
    , c.RuleID
    , c.RuleName
    , c.LoginName
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions AS c
WHERE c.TypeOfChange = 'New Condition'
  AND c.FromDate >= '2025-01-01'
  AND c.FromDate < '2025-04-01'
ORDER BY c.FromDate, c.ConditionID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Weekly CEP audit family*  
*Tiers: 0 T1, 13 T2, 0 T3, 1 T4 | Writer: Dealing_dbo.SP_W_CEPWeeklyAudit*  
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions | Type: Table | Source: Dealing_staging CEP temporal / external + dictionaries*
