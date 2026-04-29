# Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping

> Weekly audit of **CID ↔ Named List** membership changes in CEP — when a **client ID** is **added to** or **removed from** a **Name List**, aggregated to a **Monday–Sunday** window. **Contains PII (`CID`).**

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
| **Approx. row count** | ~1,047 |
| **Sample date range** | 2021-09-26 → 2026-03-01 (via `FromDate`) |
| **PII** | **Yes — `CID` (client identifier)** |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **weekly** counterpart to **`Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping`**. It records **which clients (`CID`) entered or left a CEP Named List** during each audit week. **Named lists** drive **list-based** conditions in rules (e.g. inclusion / exclusion sets). Among the **weekly** CEP audit siblings, this is the table that carries **direct client identifiers**.

**Weekly grain:** **`FromDate`** (Monday) and **`ToDate`** (Sunday) bound the reporting window. **`TypeOfChange` NULL** rows may appear as **scaffold / no-change** placeholders from the weekly join pattern — restrict to **`TypeOfChange IS NOT NULL`** for actual adds/removes.

**PII handling:** **`CID`** is a **customer key**. Apply **least privilege**, **masking**, and **aggregation** policies consistent with your **data governance** standard. Do not expose raw **`CID`** in unmanaged extracts or self-service tools without review.

**Historical depth:** Weekly history from **September 2021** supports investigations that predate the **daily** list-mapping audit’s typical start (around **December 2023** in documentation samples).

**Related engineering note:** Prior analysis flagged a **suspected self-join bug** in another branch of **`SP_W_CEPWeeklyAudit`** affecting **`Dealing_CEPWeeklyAudit_NameLists`** (`fdtd.ToDate = fdtd.ToDate`). The **ListCIDMapping** path uses a **separate CTE** (`#ListCIDMapping_ChangesFinal` in source review) and is **documented as logically correct** relative to that issue — still worth **validator review** if NameLists rows look wrong.

## 2. Business Logic

- **Sources:** `Dealing_staging.External_Etoro_CEP_ListCIDMappings` and `Dealing_staging.External_Etoro_History_ListCIDMappings`.
- **Change literals:** **`CID Added`** and **`CID Deleted`** — exact strings from **`SP_W_CEPWeeklyAudit`**.
- **List context:** **`NameListID`** and **`Name`** identify **which list** was edited at the time of the event.
- **Attribution:** **`LoginName`** is the **CEP application user**; **`ChangeTime`** is the **source event timestamp**; **`UpdateDate`** is **`GETDATE()`** **load metadata**.
- **No-change weeks:** Same **LEFT JOIN** family behavior as other weekly audit tables — **NULL `TypeOfChange`** is **not** a “unknown change” flag; it means **no classified event** for that row pattern in that week.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN`. |
| **Clustered index** | **`FromDate` ASC**. |
| **Scale** | ~1k rows in sampled stats — very small; still **PII-sensitive**. |

### 3.2 Recommended patterns

- **Always** apply **`WHERE TypeOfChange IS NOT NULL`** for **true membership deltas**.
- Prefer **`COUNT(DISTINCT CID)`** or **aggregates by list** over raw **`CID`** dumps when possible.
- Pair with **`Dealing_CEPWeeklyAudit_NameLists`** when investigating **list rename / structural** edits vs **per-client** membership moves.

### 3.3 Freshness

- Loaded on the **Sunday** weekly schedule with **`SP_W_CEPWeeklyAudit`**. Sample stats: **max `FromDate` 2026-03-01**, **ACTIVE**.

### 3.4 Gotchas

- **`CID`** is **PII** — log access and exports accordingly.
- **`TypeOfChange`** filters must match **`CID Added`** / **`CID Deleted`** **exactly**.
- Do not assume **`Name`** is stable forever — lists can be renamed; use **`NameListID`** as the **stable key** when reconciling long spans.

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
| 3 | NameListID | int | YES | **Named List** identifier whose membership changed. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | Name | varchar(max) | YES | **List display name** at the time of the change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | CID | bigint | YES | **Client identifier** added or removed — **PII**; restrict access and avoid unnecessary export. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | TypeOfChange | varchar(max) | YES | **`CID Added`** or **`CID Deleted`**; **NULL** for no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | LoginName | varchar(max) | YES | **CEP application user** performing the change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | ChangeTime | datetime | YES | **Source timestamp** of the list membership event. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** — not business event time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

**Upstream → writer → target**

```
Dealing_staging.External_Etoro_CEP_ListCIDMappings  (current)
Dealing_staging.External_Etoro_History_ListCIDMappings  (temporal history)
    ↓
Dealing_dbo.SP_W_CEPWeeklyAudit
    — #ListCIDMapping_ChangesFinal (weekly-specific CTE per code review notes)
    — FromDate / ToDate week boundaries
    — TypeOfChange: CID Added / CID Deleted
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping
```

**Column lineage (summary):** `FromDate` / `ToDate` ← weekly window; `NameListID`, `CID`, `ChangeTime`, `LoginName` ← list-CID external / history; `Name` ← list metadata resolution in SP; `TypeOfChange` ← SP classification; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping` | **Daily** membership audit — finer date grain for recent periods. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists` | **List-level** weekly changes (names/metadata) — sibling in **`SP_W_CEPWeeklyAudit`**. |
| `Dealing_staging.External_Etoro_CEP_ListCIDMappings` | **Current** list–CID links. |
| `Dealing_staging.External_Etoro_History_ListCIDMappings` | **Temporal history** of links. |

## 7. Sample Queries

**7.1 — Real adds/removes in one audit week (mask CID in production reporting)**

```sql
SELECT
      FromDate
    , ToDate
    , NameListID
    , Name
    , CID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping
WHERE FromDate = '2026-02-24'
  AND TypeOfChange IS NOT NULL
ORDER BY NameListID, ChangeTime;
```

**7.2 — Volume of adds per list over a year (aggregate — less PII surface)**

```sql
SELECT
      NameListID
    , Name
    , COUNT(*) AS Adds
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping
WHERE TypeOfChange = 'CID Added'
  AND FromDate >= '2025-01-01'
  AND FromDate < '2026-01-01'
GROUP BY NameListID, Name
ORDER BY Adds DESC;
```

**7.3 — Clients removed from a specific list (high sensitivity — run only with approval)**

```sql
SELECT
      FromDate
    , CID
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping
WHERE NameListID = @NameListID
  AND TypeOfChange = 'CID Deleted'
  AND FromDate >= '2025-06-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Weekly CEP audit family | **PII: CID***  
*Tiers: 0 T1, 8 T2, 0 T3, 1 T4 | Writer: Dealing_dbo.SP_W_CEPWeeklyAudit*  
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping | Type: Table | Source: Dealing_staging CEP temporal / external*
