# Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule

> Weekly audit of **compound-property-to-rule** mapping changes in CEP — when a CP is **added** or **removed** from a rule, or when the **`IsTrue`** polarity (**must evaluate true** vs **not true**) flips. Written by the same **Sunday** weekly job as other **`CEPWeeklyAudit_***` tables; history from **Sep 2021** predates the **daily** family (**Dec 2023**).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` + `External_Etoro_History_CompoundPropertyToRule` |
| **Refresh** | Weekly — **Sunday** run (Priority 0 — OpsDB / Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table records **how CPs are wired into rules** over **weekly** windows. Each **real** event row describes **attachment**, **detachment**, or a **boolean polarity** change (**`IsTrue`**) for a **`CompoundPropertyID`** under a **`RuleID`**. The grain is **`FromDate` / `ToDate`** (**Monday** / **Sunday** markers) rather than a single calendar **`Date`**.

**Volume note:** In the documented sample this is the **largest** **CEPWeeklyAudit** table (**~51,076 rows** over **2021-09-26 → 2026-03-01**), mirroring the pattern in the **daily** family where **CP-to-rule** churn is typically **highest**. Frequent Dealing configuration tuning can produce **many** mapping rows per week.

**Overlap with daily:** For periods **after Dec 2023**, **`Dealing_CEPDailyAudit_CPToRule`** offers **per-day** detail; this **weekly** table remains a **rollup** and carries **only** weekly history for **pre-daily** eras.

**No-change weeks:** As with other weekly CEP audit tables, **`LEFT JOIN`** logic can emit **placeholder** rows with **`TypeOfChange IS NULL`** — always filter when you need **true** mapping events.

**Why it matters:** Incorrect or volatile **CP-to-rule** wiring is a common explanation for **“the rule looked right but hedged wrong”** incidents. This audit preserves **who** changed **what** and **when** at the **mapping** grain.

## 2. Business Logic

- **Writer:** `Dealing_dbo.SP_W_CEPWeeklyAudit(@dd)` — shared with all **weekly** CEP audit targets; **DELETE + INSERT** per computed week.
- **Sources:** **`External_Etoro_CEP_CompoundPropertyToRule`** and **`External_Etoro_History_CompoundPropertyToRule`**.
- **Event windows:** **`SysStartTime`** in the week → **add / value change** style paths; **`SysEndTime`** in the week with **`RN_desc = 1`** → **removal** style path (see SP for exact classification).
- **`TypeOfChange` values** (documented): **`CP Added to Rule`**, **`CP Removed from Rule`**, **`Mapping Changed from Not True to True`**, **`Mapping Changed from True to Not True`** — **NULL** for **no-change** placeholders.
- **`IsTrue`:** **`bit`** — **1** means the CP must evaluate **true** inside the rule bundle polarity; **0** means **not true** — identical **business meaning** to the **daily** sibling.
- **`CP_Name`:** Uses **underscore** form here (**`CP_Name`**) unlike **`Dealing_CEPWeeklyAudit_CP.CPName`** — intentional **cross-table naming inconsistency** to flag for analysts.
- **`UpdateDate`:** **`GETDATE()`** — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — acceptable at **tens of thousands** of rows for audit-style filters. |
| **Clustered index** | **`FromDate` ASC** — primary filter for **week** selection. |
| **Scale** | Moderate — still **small** by DWH standards; avoid **full scans** only if you add broad analytics without predicates. |

### 3.2 Recommended patterns

- **`WHERE FromDate = @WeekStart AND TypeOfChange IS NOT NULL`** for a **clean** weekly event list.
- **`WHERE CompoundPropertyID = @cp`** across **`ORDER BY FromDate`** for **CP-centric** history (weekly grain).
- Join **`Dealing_CEPWeeklyAudit_Rules`** on **`RuleID` + week** for **rule-name** stability checks when needed.

### 3.3 Freshness

- **Weekly Sunday** batch; compare **`max(FromDate)`** to the latest **completed** business week (documented sample **2026-03-01**).

### 3.4 Gotchas

- **High row counts** are **often normal** — mapping churn is **structurally frequent** in CEP.
- **Duplicate-looking** rows across **`RuleID`** may reflect **legitimate** repeated adjustments — validate with **`ChangeTime`** and **`TypeOfChange`**.
- Do not confuse **`CP_Name`** here with **`CPName`** in **`Dealing_CEPWeeklyAudit_CP`**.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_W_CEPWeeklyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | **Week start** (**Monday 00:00:00**) for the audit bucket. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | **Week end marker** (**Sunday**) paired with **`FromDate`** per SP derivation. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | **CEP Rule** receiving the mapping change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | **Human-readable rule name** denormalized onto the event. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | HedgeServerID | int | YES | **Hedge server** context for the rule (**from dimension join path** in SP). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | CompoundPropertyID | int | YES | **Compound property** participating in the mapping. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | CP_Name | varchar(max) | YES | **CP name** — note **`CP_Name`** here vs **`CPName`** in **`Dealing_CEPWeeklyAudit_CP`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | IsTrue | bit | YES | **Polarity** — **1** = must evaluate **true**, **0** = **not true** in rule logic. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | TypeOfChange | varchar(max) | YES | **`CP Added to Rule`**, **`CP Removed from Rule`**, **`Mapping Changed from Not True to True`**, **`Mapping Changed from True to Not True`**, or **NULL** for placeholders. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | **CEP application user** attributed to the change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | **Source temporal timestamp** for the mapping event. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | **`GETDATE()`** at SP run — **load metadata**, not business time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow from lineage artifact:

```
Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule
Dealing_staging.External_Etoro_History_CompoundPropertyToRule
    ↓
SP_W_CEPWeeklyAudit(@dd) — @weekStart to @weekEnd window
    — SysStartTime BETWEEN @weekStart AND @weekEnd → Added/ValueChange
    — SysEndTime BETWEEN @weekStart AND @weekEnd AND RN_desc=1 → Removed
    — LEFT JOIN #FromDateToDate → always one row per week
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule  ← DELETE + INSERT for week
```

**Column lineage (summary):** `FromDate` / `ToDate` ← **week parameters**; `RuleID`, mapping keys, `IsTrue`, timestamps ← **CP-to-rule** externals / history and **`#CPToRule_Log`**; `RuleName`, `HedgeServerID`, `CP_Name` ← **SP staging tables**; `TypeOfChange` ← **derivation**; `UpdateDate` ← **`GETDATE()`**.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule` | **Daily** mapping audit (**Dec 2023+**) — finer grain for recent periods. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | **Weekly CP** entity changes — same week keys. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | **Weekly rule** shell changes — join on **`RuleID`** + week. |
| `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` | **Current** mapping **source**. |
| `Dealing_staging.External_Etoro_History_CompoundPropertyToRule` | **Temporal history** **source**. |

## 7. Sample Queries

**7.1 — All mapping events for one audit week (real rows only)**

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
WHERE FromDate = '2026-03-01'
  AND TypeOfChange IS NOT NULL
ORDER BY RuleID, CompoundPropertyID, ChangeTime;
```

**7.2 — Polarity flips (True ↔ Not True) in the last year of weeks**

```sql
SELECT
      FromDate
    , RuleID
    , CompoundPropertyID
    , CP_Name
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule
WHERE TypeOfChange IN (
        'Mapping Changed from Not True to True'
      , 'Mapping Changed from True to Not True'
    )
  AND FromDate >= '2025-01-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

**7.3 — CP-centric weekly history**

```sql
SELECT
      FromDate
    , RuleID
    , RuleName
    , TypeOfChange
    , IsTrue
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule
WHERE CompoundPropertyID = @CompoundPropertyID
  AND TypeOfChange IS NOT NULL
ORDER BY FromDate, ChangeTime;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★★☆) | Batch: CEP audit wiki reformat*  
*Tiers: 0 T1, 11 T2, 0 T3, 1 T4 | Elements: 7.8/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule | Type: Table | Production Source: Dealing_staging CEP CompoundPropertyToRule + history*
