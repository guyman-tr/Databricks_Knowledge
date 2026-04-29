# Dealing_dbo.Dealing_CEPDailyAudit_NameLists

> Daily audit of **CEP Named List** lifecycle changes — creations, deletions, and CID membership modifications for the client-scoped configuration lists used in CEP hedging rule conditions. **281 rows** from **2023-12-19** through **2026-04-17**, written by **`SP_CEPDailyAudit`** via DELETE + INSERT per business date.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_NamedLists` + `External_Etoro_History_NamedLists` via `SP_CEPDailyAudit` |
| **Refresh** | Daily (Priority 0 — OpsDB / Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table records **Named List lifecycle events** in eToro's **CEP (Client Execution Platform)** hedging rule engine. Named Lists are configuration objects that hold sets of **client IDs (CIDs)** — rules reference these lists in conditions to include or exclude specific clients from hedging paths.

**What each row means:** On business date **`Date`**, a Named List was **created**, **deleted**, or had its **CID membership modified**. The table captures **list-level** events only — for **per-CID** granularity (which specific CIDs were added or removed), see sibling table **`Dealing_CEPDailyAudit_ListCIDMapping`**.

**Scale:** **281 rows** across **93 distinct dates** from **2023-12-19** through **2026-04-17**. **22 distinct Named Lists** observed. **Sparse** — rows appear only on days when list-level changes occur; many calendar days have zero rows.

**Dominant activity:** **`Change In CIDs`** events (270 of 281 rows, 96%) dominate, with the **CopyFunds** list (ID 36) being the most active (84 events). **`New Name List`** events account for the remaining 11 rows. **`Name List Deleted`** is a valid event type from SP logic but has not occurred in the current dataset.

**Load pattern:** **`Dealing_dbo.SP_CEPDailyAudit`** performs **DELETE + INSERT** for the supplied **`@Date`**. Daily refresh via OpsDB / Service Broker. SLA: typically next business day for date *D*.

**CEP hierarchy context:**
```
Rule
  └── Compound Property (CP)
        └── Condition
              └── references Named List  ← lifecycle changes audited here
                    └── CID memberships (see ListCIDMapping audit table)
```

---

## 2. Business Logic

### 2.1 Change Detection via Temporal Tables

**What**: The SP detects Named List changes by comparing successive system-time versions of the staging temporal tables.

**Columns Involved**: `TypeOfChange`, `ChangeTime`

**Rules**:
- **Start-date path** (`SysStartDate = @Date`): `RN = 1` → **`New Name List`** (first-ever temporal row for this list); else → **`Change In CIDs`**
- **End-date path** (`SysEndDate = @Date`, `SysEndTime < '9999-01-01'`): `RN_desc = 1` → **`Name List Deleted`** (final temporal row closed); else → **`Change In CIDs`**
- Both paths can produce rows for the same list on the same date if the list was modified and then deleted

### 2.2 LoginName Attribution

**What**: Ensures the responsible user is captured even for deletion events where the current row's login may be NULL.

**Columns Involved**: `LoginName`

**Rules**:
- Uses `COALESCE(AppLoginName, PreviousAppLoginName)` where `PreviousAppLoginName` is derived via `LEAD()` over `SysEndTime DESC`
- This pattern is shared across all CEPDailyAudit family tables

### 2.3 ChangeTime Semantics

**What**: Source event time varies by path.

**Columns Involved**: `ChangeTime`

**Rules**:
- Start-date path: `ChangeTime = SysStartTime` (when the temporal row became valid)
- End-date path: `ChangeTime = SysEndTime` (when the temporal row was closed)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for a very small audit table. |
| **Clustered index** | **`Date` ASC** — aligns with daily reload and `WHERE Date = @d` filters. |
| **Scale** | **281 rows** — no performance concerns; full scans are trivial. |

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What list changes happened on date X? | `WHERE Date = 'YYYY-MM-DD'` |
| History of a specific Named List | `WHERE NameListID = @id ORDER BY Date DESC` |
| All new list creations | `WHERE TypeOfChange = 'New Name List' ORDER BY Date DESC` |
| Most active lists by change volume | `GROUP BY NameListID, Name ORDER BY COUNT(*) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_CEPDailyAudit_ListCIDMapping | `NameListID + Date` | Per-CID detail for list membership changes |
| Dealing_CEPDailyAudit_Conditions | `Date` | Correlate condition changes that reference Named Lists |

### 3.4 Gotchas

- **Sparse table**: Many calendar dates have zero rows. Don't expect continuous daily data.
- **`Change In CIDs`** dominates (96% of rows) — this event fires on BOTH the start-date and end-date temporal paths, so a single CID add/remove can generate **two** list-level `Change In CIDs` rows on the same date.
- **`LoginName`** has **null-byte padding** in sampled data (trailing `\0` characters from the source `varchar` field). Apply `RTRIM` or `REPLACE(LoginName, CHAR(0), '')` when comparing or displaying.
- **`Name List Deleted`** is a valid `TypeOfChange` value from SP logic but has **zero occurrences** in the current dataset.
- This is one of **7 CEPDailyAudit tables**, all written by the same SP: CP, CPToRule, ConditionToCP, Conditions, ListCIDMapping, NameLists, Rules.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this Named List change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. Clustered index key. (Tier 2 — SP_CEPDailyAudit) |
| 2 | NameListID | int | YES | **Named List identifier** whose lifecycle or membership changed — corresponds to **`NamedListID`** from **`External_Etoro_CEP_NamedLists`**. 22 distinct lists observed. (Tier 2 — SP_CEPDailyAudit) |
| 3 | Name | varchar(max) | YES | **Human-readable list name** at the time of the event — passthrough from **`#NameLists_Log`** (latest temporal state). Examples: **`CopyFunds`**, **`New Abusers List - Stocks`**, **`EU Real Stocks HBC`**. (Tier 2 — SP_CEPDailyAudit) |
| 4 | TypeOfChange | varchar(max) | YES | **Event type** — one of: **`New Name List`** (list created, `RN=1`), **`Change In CIDs`** (CID membership modified), **`Name List Deleted`** (list removed, `RN_desc=1` + `SysEndDate=@Date`). Current data shows only the first two. (Tier 2 — SP_CEPDailyAudit) |
| 5 | LoginName | varchar(max) | YES | **CEP application user** who performed the change — **`COALESCE(AppLoginName, PreviousAppLoginName)`** from the temporal source via `LEAD()`. **Note:** sampled values contain null-byte padding. (Tier 2 — SP_CEPDailyAudit) |
| 6 | ChangeTime | datetime | YES | **Source timestamp** of the event — **`SysStartTime`** for creation/modification paths; **`SysEndTime`** for deletion paths. Not the ETL load time. (Tier 2 — SP_CEPDailyAudit) |
| 7 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** in the SP — **ETL metadata**, not the business event instant. (Tier 2 — SP_CEPDailyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP_CEPDailyAudit | @Date parameter | Set to SP input |
| NameListID | External_Etoro_CEP_NamedLists | NamedListID | Passthrough |
| Name | External_Etoro_CEP_NamedLists | Name | Passthrough via #NameLists_Log |
| TypeOfChange | SP_CEPDailyAudit | Derived | CASE on RN / RN_desc |
| LoginName | External_Etoro_CEP_NamedLists | AppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) |
| ChangeTime | External_Etoro_CEP_NamedLists | SysStartTime / SysEndTime | Start-path vs end-path selection |
| UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL load timestamp |

No Generic Pipeline mapping — CEP is an internal eToro system, not tracked in the Generic Pipeline.

### 5.2 ETL Pipeline

```
CEP Internal System (Named Lists configuration)
    ↓
Dealing_staging.External_Etoro_CEP_NamedLists  (current state)
Dealing_staging.External_Etoro_History_NamedLists  (temporal history)
    ↓
SP_CEPDailyAudit(@Date)
    — #NameLists_Log: UNION current + history, ROW_NUMBER(), LEAD() for PreviousAppLoginName
    — #NameLists_ChangesFinal: CASE on RN/RN_desc → TypeOfChange classification
    — DELETE + INSERT for @Date
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_NameLists  (281 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| NameListID | Dealing_staging.External_Etoro_CEP_NamedLists | Source Named List entity |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_CEPDailyAudit_ListCIDMapping | NameListID | Per-CID membership detail for lists tracked here |
| Dealing_CEPWeeklyAudit_NameLists | NameListID | Weekly rollup of the same event types |

---

## 7. Sample Queries

### 7.1 All list events on a business date

```sql
SELECT
      Date
    , NameListID
    , Name
    , TypeOfChange
    , REPLACE(LoginName, CHAR(0), '') AS LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_NameLists
WHERE Date = '2026-04-17'
ORDER BY ChangeTime;
```

### 7.2 History of a specific Named List

```sql
SELECT
      Date
    , TypeOfChange
    , REPLACE(LoginName, CHAR(0), '') AS LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_NameLists
WHERE NameListID = 36
ORDER BY Date DESC, ChangeTime DESC;
```

### 7.3 Most active lists by change volume

```sql
SELECT
      NameListID
    , Name
    , COUNT(*) AS EventCount
    , MIN(Date) AS FirstEvent
    , MAX(Date) AS LastEvent
FROM Dealing_dbo.Dealing_CEPDailyAudit_NameLists
GROUP BY NameListID, Name
ORDER BY EventCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.0/10 (★★★★☆) | Batch: regen-harness attempt 1*
*Tiers: 0 T1, 7 T2, 0 T3, 0 T4 | Elements: 8.5/10, Logic: 8.5/10, Relationships: 7.5/10, Sources: 6.0/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_NameLists | Type: Table | Production Source: Dealing_staging CEP NamedLists + history*
