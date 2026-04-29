# Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping

> Daily audit of **CID ↔ Named List** membership changes in CEP — each row is an **add** or **remove** of a **client ID** from a **Named List** used in hedging rule conditions.

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
| **PII** | **Yes — `CID` (client identifier)** |

## 1. Business Meaning

This table tracks **CID-to–Named List mapping changes** in the **Client Execution Platform (CEP)**. **Named Lists** are configuration objects holding **sets of client IDs (CIDs)** that rules can reference — for example, **include** or **exclude** specific clients from a hedging path.

**PII:** The **`CID`** column is a **direct client identifier**. This is the **CEP Daily Audit** table family member with **explicit PII**. Apply **data governance**, **access controls**, and **masking** policies consistent with **client-level** DWH objects.

**What each row means:** On business date **`Date`**, a **CID** was **added to** or **removed from** a **Named List**. Together with **`Dealing_CEPDailyAudit_NameLists`**, it forms the audit trail for **client-scoped** CEP configuration.

**Why it matters:** List membership changes can **change hedging or routing** for **individual clients**. Typical uses:

- **Compliance** — when was client **X** added or removed from list **Y**?
- **Client services** — explain behavior tied to **list membership**.
- **Risk / Dealing oversight** — review **who** changed **which** list and **when**.

**Activity note (documented sample):** About **532 rows** from **2023-12-19** through **2026-01-26**. **Sparse** activity is **expected** — the SP writes rows **only on days** when membership changes occur; many calendar days may have **zero** rows. **Last row date** lagging the documentation date does **not** by itself imply pipeline failure.

**Load pattern:** **`Dealing_dbo.SP_CEPDailyAudit`** — **DELETE + INSERT** for **`@Date`**. **Daily** batch (OpsDB / Service Broker). **SLA:** typically **next business day**.

## 2. Business Logic

- **Sources:** **`Dealing_staging.External_Etoro_CEP_ListCIDMappings`** (current) and **`External_Etoro_History_ListCIDMappings`** (temporal history).
- **Add vs remove:** When temporal **`SysStartDate = @Date`** → **`CID Added`**; when **`SysEndDate = @Date`** and the row is **closed** (non-sentinel end) → **`CID Deleted`** — see SP for exact **`SysEndTime`** handling.
- **`ListName`:** Resolved from **`#NameLists_Log`** (latest name by list id) — may reflect **current** naming even if the list was **renamed** after the mapping event; analysts should cross-check **`NameLists`** audit for **rename** history.
- **`LoginName`:** **`COALESCE(AppLoginName, PreviousAppLoginName)`** — **CEP user** performing the change.
- **`ChangeTime`:** **`SysStartTime`** / **`SysEndTime`** depending on add vs remove path.
- **`UpdateDate`:** **`GETDATE()`** — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN`. |
| **Clustered index** | **`Date` ASC** — primary slice for **daily** audit pulls. |
| **Scale** | **Hundreds** of rows in documented history — **full scans** on **`CID`** filters are still **cheap**, but **always apply PII policies** before exporting results. |

### 3.2 Recommended patterns

- **`WHERE Date = @d`** for **daily** reconciliation.
- **`WHERE CID = @cid`** for **client-centric** history (**governed** access only).
- Join **`NameListID`** / **`ListName`** to **`Dealing_CEPDailyAudit_NameLists`** on **`Date`** when correlating **list-level** events with **per-CID** rows.

### 3.3 Freshness

- Pipeline **runs daily**; **row count** grows only on **change days**. Use **OpsDB / job** status — not row **recency** alone — to confirm health.

### 3.4 Gotchas

- **`TypeOfChange`** values: **`CID Added`**, **`CID Deleted`** — **exact** string match.
- **Low row volume** vs calendar span is **normal**.
- **PII** — never use this table in **self-service** extracts without **approval**.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** of the CID mapping change — **`@Date`** for the SP partition. (Tier 2 — SP_CEPDailyAudit) |
| 2 | NameListID | int | YES | **Named List** identifier whose membership changed. (Tier 2 — SP_CEPDailyAudit) |
| 3 | ListName | varchar(max) | YES | **Human-readable list name** (from **`#NameLists_Log`**) for analyst-friendly reporting. (Tier 2 — SP_CEPDailyAudit) |
| 4 | CID | bigint | YES | **Client ID** added or removed — **PII**; join to **customer / account** dimensions only under **governance**. (Tier 2 — SP_CEPDailyAudit) |
| 5 | TypeOfChange | varchar(max) | YES | **`CID Added`** or **`CID Deleted`**. (Tier 2 — SP_CEPDailyAudit) |
| 6 | LoginName | varchar(max) | YES | **CEP application user** who performed the add/remove. (Tier 2 — SP_CEPDailyAudit) |
| 7 | ChangeTime | datetime | YES | **Exact source timestamp** of the mapping event. (Tier 2 — SP_CEPDailyAudit) |
| 8 | UpdateDate | datetime | YES | **DWH load time** via **`GETDATE()`** — **not** business event time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow (detail in **`.lineage.md`**):

```
[CEP System — ListCIDMappings temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_ListCIDMappings  (current)
Dealing_staging.External_Etoro_History_ListCIDMappings  (history)
    ↓ JOIN #NameLists_Log (list name)
SP_CEPDailyAudit(@Date)
    — SysStartDate / SysEndDate logic → CID Added / CID Deleted
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping  ← DELETE + INSERT for @Date
```

**Column lineage (summary):** `Date` ← `@Date`; `NameListID`, `CID`, `LoginName`, `ChangeTime` ← list-CID external / history; `ListName` ← **`#NameLists_Log`**; `TypeOfChange` ← temporal classification; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_NameLists` | **List definition** and **list-level** **`Change In CIDs`** events — companion to **per-CID** rows here. |
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **CP** configuration may **reference** Named Lists in **conditions** — trace upward for **full rule** context. |
| `Dealing_staging.External_Etoro_CEP_ListCIDMappings` | **Current** membership **source**. |
| `Dealing_staging.External_Etoro_History_ListCIDMappings` | **Temporal** **history** **source**. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping` | **Weekly rollup** of the same events. |

## 7. Sample Queries

**7.1 — All list membership changes on a date (PII — restricted use)**

```sql
SELECT
      Date
    , NameListID
    , ListName
    , CID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping
WHERE Date = '2026-01-26'
ORDER BY ListName, TypeOfChange, ChangeTime;
```

**7.2 — History for one client across lists (PII — governed access only)**

```sql
SELECT
      Date
    , ListName
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping
WHERE CID = @CID
ORDER BY Date DESC, ChangeTime DESC;
```

**7.3 — Count adds vs deletes by list over a period**

```sql
SELECT
      ListName
    , TypeOfChange
    , COUNT(*) AS EventCount
FROM Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping
WHERE Date >= '2025-01-01'
GROUP BY ListName, TypeOfChange
ORDER BY ListName, TypeOfChange;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Batch: manual template reformat*  
*Tiers: 0 T1, 7 T2, 0 T3, 1 T4 | Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping | Type: Table | Production Source: Dealing_staging CEP temporal tables*
