# Dealing_dbo.Dealing_CEPDailyAudit_NameLists

> Daily audit of **CEP Named List** lifecycle and **list-level CID membership summary** events — creation, deletion, and **Change In CIDs** rollups for lists used in hedging rules.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |
| **PII / sensitive context** | Indirect — Named Lists underpin CID-based targeting in CEP; no `CID` column in this table |

## 1. Business Meaning

This table tracks **Named List definition and lifecycle changes** in **CEP**. **Named Lists** are configuration objects used when **conditions** need to reference **groups of clients** (by **CID** membership). This table does **not** store individual **CIDs**, but it describes **which lists exist**, **how they are named**, and **when** list-level events occurred — in a family that **directly enables client-level routing**.

**PII / sensitivity:** Although there is **no `CID` column** here, **list names** and **list IDs** can reveal **operational or client-segment** intent and sit **upstream** of **`Dealing_CEPDailyAudit_ListCIDMapping`**, which **does** contain **CIDs**. Treat access and publication with **appropriate governance** (same **Dealing / Risk** audience as other **CEP audit** tables).

**What each row means:** On **`Date`**, one of: a **new** Named List was created; a Named List was **deleted**; or the list had a **membership update** summarized as **`Change In CIDs`**. The **per-client** adds/removes appear in **`ListCIDMapping`** for the same business dates when applicable.

**Why it matters:** **Named Lists** let Dealing **target** or **exclude** **specific client cohorts** in **hedging logic**. **Creation / deletion** and **membership churn** must be **auditable** for **compliance** and **operational forensics**.

**Scale (documented sample):** About **275 rows** from **2023-12-19** through **2026-01-26** — **very sparse** vs calendar days; **most days** have **no** list lifecycle events.

**Load pattern:** **`Dealing_dbo.SP_CEPDailyAudit`** — **DELETE + INSERT** for **`@Date`**. **Daily** schedule. **SLA:** typically **next business day**.

## 2. Business Logic

- **Sources:** **`Dealing_staging.External_Etoro_CEP_NamedLists`** (current) and **`External_Etoro_History_NamedLists`** (history).
- **Event typing (SP):**
  - **`SysStartDate = @Date`** with **row number = 1** → **`New Name List`**.
  - **`SysStartDate = @Date`** with **row number > 1** → **`Change In CIDs`** (list already existed; membership changed).
  - **`SysEndDate = @Date`** with **latest-row semantics** → **`Name List Deleted`**.
- **`Name` / `NameListID`:** From **Named Lists** external table paths in the SP.
- **`LoginName`:** **`COALESCE(AppLoginName, PreviousAppLoginName)`**.
- **`ChangeTime`:** **`SysStartTime`** or **`SysEndTime`** depending on event path.
- **`UpdateDate`:** **`GETDATE()`** — **ETL metadata**.
- **Companion:** For **`Change In CIDs`**, expect related **per-CID** rows in **`Dealing_CEPDailyAudit_ListCIDMapping`** for the **same** **`Date`** when CIDs actually moved — confirm with domain experts for **edge cases**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN`. |
| **Clustered index** | **`Date` ASC**. |
| **Scale** | **Very small** — performance tuning **not** required. |

### 3.2 Recommended patterns

- **`WHERE Date = @d`** for **daily** audit.
- **`WHERE NameListID = @id`** for **single-list** timelines across **many** dates.
- Filter **`TypeOfChange`** to isolate **creates**, **deletes**, vs **membership** summaries.

### 3.3 Freshness

- **Daily** batch; **sparse** row counts are **normal**. Validate health via **orchestration**, not **max(Date)** alone.

### 3.4 Gotchas

- **`Change In CIDs`** is a **list-level** signal — **detail** is in **`ListCIDMapping`**.
- **`Name`** reflects **SP resolution** timing — cross-check **rename** behavior with **domain** owners if **discrepancies** appear vs **CEP UI**.
- **Sensitivity** — **list names** may be **business-confidential** even without **CID** literals.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** of the Named List event — **`@Date`** for the SP run. (Tier 2 — SP_CEPDailyAudit) |
| 2 | NameListID | int | YES | **Identifier** of the **Named List** that changed. (Tier 2 — SP_CEPDailyAudit) |
| 3 | Name | varchar(max) | YES | **Human-readable list name** at the time of resolution in the SP. (Tier 2 — SP_CEPDailyAudit) |
| 4 | TypeOfChange | varchar(max) | YES | **`New Name List`**, **`Name List Deleted`**, **`Change In CIDs`** — exact SP literals. (Tier 2 — SP_CEPDailyAudit) |
| 5 | LoginName | varchar(max) | YES | **CEP user** who performed the change (`COALESCE` across temporal columns). (Tier 2 — SP_CEPDailyAudit) |
| 6 | ChangeTime | datetime | YES | **Source event timestamp** (`SysStartTime` / `SysEndTime` per path). (Tier 2 — SP_CEPDailyAudit) |
| 7 | UpdateDate | datetime | YES | **DWH load timestamp** from **`GETDATE()`** — **not** business time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow (see **`.lineage.md`**):

```
Dealing_staging.External_Etoro_CEP_NamedLists  (current)
Dealing_staging.External_Etoro_History_NamedLists  (history)
    ↓
SP_CEPDailyAudit(@Date)
    — RN / RN_desc logic → New Name List, Change In CIDs, Name List Deleted
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_NameLists  ← DELETE + INSERT for @Date
```

**Column lineage (summary):** `Date` ← `@Date`; `NameListID`, `Name`, `LoginName`, `ChangeTime` ← Named Lists external / history; `TypeOfChange` ← **RN** / **RN_desc** rules; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping` | **Per-CID** add/remove audit — **detail** for **`Change In CIDs`** events. |
| `Dealing_staging.External_Etoro_CEP_NamedLists` | **Current** list **definitions**. |
| `Dealing_staging.External_Etoro_History_NamedLists` | **Temporal** **history**. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists` | **Weekly rollup** sibling. |
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **CP** rules may **reference** lists in **conditions** — trace for **full** impact. |

## 7. Sample Queries

**7.1 — All Named List events on a date**

```sql
SELECT
      Date
    , NameListID
    , Name
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_NameLists
WHERE Date = '2026-01-26'
ORDER BY NameListID, ChangeTime;
```

**7.2 — List creations and deletions (exclude membership-only summaries)**

```sql
SELECT
      Date
    , NameListID
    , Name
    , TypeOfChange
    , LoginName
FROM Dealing_dbo.Dealing_CEPDailyAudit_NameLists
WHERE TypeOfChange IN ('New Name List', 'Name List Deleted')
ORDER BY Date DESC, NameListID;
```

**7.3 — Same-day join: list-level CID change vs per-CID mapping**

```sql
SELECT
      n.Date
    , n.NameListID
    , n.Name
    , n.TypeOfChange   AS NameLists_Event
    , m.TypeOfChange   AS ListCID_Event
    , m.CID
FROM Dealing_dbo.Dealing_CEPDailyAudit_NameLists AS n
LEFT JOIN Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping AS m
       ON m.NameListID = n.NameListID
      AND m.Date = n.Date
WHERE n.TypeOfChange = 'Change In CIDs'
  AND n.Date = '2026-01-15'
ORDER BY n.NameListID, m.CID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Batch: manual template reformat*  
*Tiers: 0 T1, 6 T2, 0 T3, 1 T4 | Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPDailyAudit_NameLists | Type: Table | Production Source: Dealing_staging CEP temporal tables*
