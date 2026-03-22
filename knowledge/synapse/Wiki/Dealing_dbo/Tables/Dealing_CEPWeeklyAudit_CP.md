# Dealing_dbo.Dealing_CEPWeeklyAudit_CP

> Weekly audit of **Compound Property (CP)** changes in CEP — new CPs, renames, and deletions — stored with a **Monday–Sunday** week range (`FromDate` / `ToDate`). The job runs on **Sunday**; history reaches back to **Sep 2021**, well before the **daily** audit family (**Dec 2023**).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_CompoundProperties` + `External_Etoro_History_CompoundProperties` |
| **Refresh** | Weekly — **Sunday** run (Priority 0 — OpsDB / Service Broker); data typically usable **Monday** |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **weekly** audit trail for **compound property** lifecycle and **name** changes inside the CEP rule engine. Unlike **daily** tables that key on a single **`Date`**, each logical week is represented by **`FromDate`** (week **Monday**, midnight) and **`ToDate`** (week **Sunday**, midnight as stored in the SP — **not** end-of-day **23:59:59**).

**Historical coverage:** Weekly CEP audit tables were populated from **Sep 2021** onward. The **daily** **`Dealing_CEPDailyAudit_CP`** family begins **Dec 2023**; use **this** table for **pre-Dec-2023** CP change history and for a **coarser** weekly governance lens.

**No-change weeks:** The SP **`LEFT JOIN`s** a week spine (**`#FromDateToDate`**) so **every** processed week yields **at least one row** even when **no** CP changed. Those rows carry **NULL** **`TypeOfChange`**, **`CompoundPropertyID`**, etc. Filter **`WHERE TypeOfChange IS NOT NULL`** for **real** events only.

**Why it matters:** CPs sit **under** rules and **above** conditions; renaming or deleting a CP affects **which human-readable configuration** analysts see and can correlate to hedging behavior. The weekly grain is useful when **daily noise** is unnecessary or when reviewing **legacy** periods.

**Scale (documented sample):** On the order of **~641 rows** from **2021-09-26** through **2026-03-01**. **No PII** in the documented semantics.

## 2. Business Logic

- **Writer:** `Dealing_dbo.SP_W_CEPWeeklyAudit(@dd)` — computes **`@weekStart`** (**Monday**) and **`@weekEnd`** (**Sunday**) from the input date, then **DELETE + INSERT** for that week window into this table.
- **Sources:** **`External_Etoro_CEP_CompoundProperties`** (current) and **`External_Etoro_History_CompoundProperties`** (temporal history).
- **Temporal filter:** Change timestamps **`BETWEEN @weekStart AND @weekEnd`** (see SP for exact boundary treatment).
- **`RuleID` / `RuleName` / `HedgeServerID`:** Resolved via **`#Dim_CPtoRule`** / CP-to-rule log style joins — may be **NULL** on **placeholder** rows or when context is absent in the weekly path.
- **`CPName`:** Weekly column name is **`CPName`** (**no** underscore) — the **daily** table uses **`CP_Name`**; mind this when **unioning** or **cross-comparing**.
- **`TypeOfChange`:** **`New Compound Property`**, **`Name Change`**, **`Compound Property Deleted`** (from SP logic) — **NULL** for **no-change** placeholder rows.
- **`Comments`:** For **`Name Change`**, **`Previous Name: {old}`** pattern.
- **`UpdateDate`:** **`GETDATE()`** — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — fine at **hundreds** of weekly rows in sample. |
| **Clustered index** | **`FromDate` ASC** — filter on **`FromDate`** (week start) for predictable scans. |
| **Scale** | Small — no special performance playbook required. |

### 3.2 Recommended patterns

- **`WHERE FromDate = @WeekStartMonday`** to pull **one** audit week (knowing **`ToDate`** is the paired Sunday marker).
- **`WHERE FromDate BETWEEN @Start AND @End`** for **multi-week** reviews.
- **`WHERE TypeOfChange IS NOT NULL`** to drop **placeholder** “no change” rows.

### 3.3 Freshness

- **Weekly Sunday** execution; treat **`max(FromDate)`** near the **most recent completed week** as health signal (documented sample **2026-03-01** week start).

### 3.4 Gotchas

- **`ToDate`** is stored as **Sunday 00:00:00** — do **not** assume **inclusive end-of-Sunday** without adjusting predicates.
- **Column name drift** — **`CPName`** vs daily **`CP_Name`**.
- **Do not** interpret **NULL** **`TypeOfChange`** rows as “silent deletes” — they are **structural placeholders** for empty weeks.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_W_CEPWeeklyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | **Week start** — **Monday 00:00:00** for the audit window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | **Week end marker** — **Sunday 00:00:00** as derived in the SP (**six** days after **`FromDate`** in the documented logic), **not** **23:59:59**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | **Rule** associated with the CP context when resolved; **NULL** on **no-change** placeholders or when not resolved. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | **Denormalized rule name** for the **`RuleID`** context. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | CompoundPropertyID | int | YES | **CP** identifier that changed — **NULL** on **no-change** weeks. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | CPName | varchar(max) | YES | **CP display name** — weekly column name (**`CPName`**) differs from **daily** **`CP_Name`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | HedgeServerID | int | YES | **Hedge server** of the parent rule context when present. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | **`New Compound Property`**, **`Name Change`**, **`Compound Property Deleted`**, or **NULL** for **placeholder** rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | Comments | varchar(max) | YES | **`Previous Name: …`** text for **`Name Change`**; otherwise **NULL**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | **CEP application login** for the change — **NULL** on **no-change** weeks. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | **Source event timestamp** — **NULL** on **no-change** weeks. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** — **ETL metadata**. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow from lineage artifact:

```
Dealing_staging.External_Etoro_CEP_CompoundProperties  (current)
Dealing_staging.External_Etoro_History_CompoundProperties  (history)
    ↓
SP_W_CEPWeeklyAudit(@dd)
    — @weekStart = Monday, @weekEnd = Sunday
    — ChangeTime BETWEEN @weekStart AND @weekEnd
    — LEFT JOIN #FromDateToDate guarantees one row per week (nullable if no changes)
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_CP  ← DELETE + INSERT for (@weekStart, @weekEnd)
```

**Column lineage (summary):** `FromDate` / `ToDate` ← **SP week boundaries**; CP fields ← **`#CPChangesFinal` / `#CPLog`**; rule context ← **`#Dim_CPtoRule`**; `TypeOfChange` / `Comments` ← **SP derivation**; `UpdateDate` ← **`GETDATE()`**.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **Daily** counterpart (**`Date`** grain, **Dec 2023+**). |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` | **Weekly** **CP↔rule** mapping changes — same **`FromDate`/`ToDate`** convention. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | **Weekly** condition-level changes in the same engine. |
| `Dealing_staging.External_Etoro_CEP_CompoundProperties` | **Current** CP **source**. |
| `Dealing_staging.External_Etoro_History_CompoundProperties` | **Temporal history** **source**. |

## 7. Sample Queries

**7.1 — Real CP changes for one audit week**

```sql
SELECT
      FromDate
    , ToDate
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CPName
    , TypeOfChange
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP
WHERE FromDate = '2026-03-01'   -- illustrative week key (align with sampled max FromDate)
  AND TypeOfChange IS NOT NULL
ORDER BY ChangeTime, CompoundPropertyID;
```

**7.2 — CP renames across a multi-month window**

```sql
SELECT
      FromDate
    , CompoundPropertyID
    , CPName
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP
WHERE TypeOfChange = 'Name Change'
  AND FromDate >= '2025-01-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

**7.3 — Weekly CP events alongside CP-to-rule events (same week)**

```sql
SELECT
      cp.FromDate
    , cp.CompoundPropertyID
    , cp.TypeOfChange   AS CP_Event
    , m.TypeOfChange    AS CPToRule_Event
    , m.RuleID
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP AS cp
LEFT JOIN Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule AS m
       ON m.FromDate = cp.FromDate
      AND m.CompoundPropertyID = cp.CompoundPropertyID
WHERE cp.FromDate = '2026-03-01'
  AND cp.TypeOfChange IS NOT NULL
ORDER BY cp.CompoundPropertyID, m.RuleID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Batch: CEP audit wiki reformat*  
*Tiers: 0 T1, 11 T2, 0 T3, 1 T4 | Elements: 8.0/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_CP | Type: Table | Production Source: Dealing_staging CEP CompoundProperties + history*
