# Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping

> ~1,057-row weekly audit of **CID-to-Named-List membership** changes in the CEP rule engine, tracking when individual customer IDs are added to or removed from Named Lists. Loaded from `Dealing_staging` temporal/external sources by `SP_W_CEPWeeklyAudit` each Sunday. Data range: 2021-09-26 to 2026-04-25.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_ListCIDMappings` + `External_Etoro_History_ListCIDMappings` via `SP_W_CEPWeeklyAudit` |
| **Refresh** | Weekly (Sunday) |
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

This table records **per-CID membership changes** on **CEP Named Lists** at **weekly** granularity. Named Lists are collections of customer IDs referenced by CEP rule conditions (e.g. "CopyFunds", "Real Stock Abusers", "Big Clients") — when a CID is **added to** or **removed from** a list during a Monday-through-Sunday window, it appears here as a row.

It is the **CID-level detail companion** to `Dealing_CEPWeeklyAudit_NameLists`, which tracks **list-level** lifecycle events (creation, deletion, CID-set changes). This table answers **which specific CIDs** changed, while NameLists answers **what happened to the list as a whole**.

**Weekly grain:** Each row is keyed to `FromDate` (Monday) and `ToDate` (Sunday). The ETL uses a **LEFT JOIN** pattern that emits **placeholder rows** with all columns NULL except `FromDate`, `ToDate`, and `UpdateDate` for weeks with **no CID membership changes**. In the current dataset, 113 of 1,057 rows are such placeholders.

**Scale and composition:** ~1,057 rows across ~240 weeks (Sep 2021 to Apr 2026). 30 distinct Named Lists observed, 629 distinct CIDs. The largest list by change volume is **CopyFunds** (NameListID 36, 272 events), followed by **EU Real Stocks HBC** (83, 140 events) and **Portfolio Offerings** (67, 118 events). 864 rows are `CID Added`, 80 are `CID Deleted`, and 113 are no-change placeholders.

**LoginName population:** `LoginName` (mapped from `AppLoginName`) is NULL or empty in ~92% of rows. This is consistent with the source `ListCIDMappings` tables — CID membership changes often lack an application login attribution in the temporal history.

**Historical coverage:** Weekly audit tables were populated from **Sep 2021** onward. The **daily** audit family (`Dealing_CEPDailyAudit_*`) begins approximately **Dec 2023**; use this table for **pre-Dec-2023** CID membership history and for a **coarser** weekly governance lens.

---

## 2. Business Logic

### 2.1 CID Membership Events

**What**: Each non-placeholder row records a single CID being added to or removed from a Named List during the audit week.
**Columns Involved**: `NameListID`, `ListName`, `CID`, `TypeOfChange`, `ChangeTime`
**Rules**:
- `TypeOfChange = 'CID Added'` — the CID's `SysStartTime` falls within the `@weekStart` to `@weekEnd` window
- `TypeOfChange = 'CID Deleted'` — the CID's `SysEndTime` falls within the window AND `SysEndTime < '9999-01-01'`
- One CID can appear multiple times in the same week if it is added to and removed from different lists, or if the same membership is toggled

### 2.2 No-Change Placeholder Rows

**What**: Weeks with no CID membership changes still produce a row due to the `LEFT JOIN #FromDateToDate` pattern.
**Columns Involved**: `FromDate`, `ToDate`, `UpdateDate` (all others NULL)
**Rules**:
- `TypeOfChange IS NULL` indicates a placeholder row — **not** a "silent delete"
- Filter with `WHERE TypeOfChange IS NOT NULL` for event-only reporting
- 113 of 1,057 rows (~11%) are placeholders

### 2.3 Named List Resolution

**What**: `ListName` is resolved by joining `#ListCIDMapping_Log` to `#NameLists_Log` on `NamedListID`, using the most recent version of each list name (`RN_desc = 1`).
**Columns Involved**: `NameListID`, `ListName`
**Rules**:
- The name reflects the **latest known** list name, not necessarily the name at the time of the CID change
- If a list was renamed, historical rows still carry the current name

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for ~1K audit rows |
| **Clustered index** | `[FromDate]` ASC — efficient for week-based filtering |
| **Scale** | Small table; no special performance considerations |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which CIDs changed on a specific list this week? | `WHERE FromDate = @WeekStart AND NameListID = @id AND TypeOfChange IS NOT NULL` |
| Full membership change history for a CID | `WHERE CID = @cid AND TypeOfChange IS NOT NULL ORDER BY FromDate` |
| Count of add/delete events by list over time | `GROUP BY NameListID, ListName, TypeOfChange WHERE TypeOfChange IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `Dealing_CEPWeeklyAudit_NameLists` | `FromDate + NameListID` | Correlate CID-level changes with list-level events (creation, deletion) in the same week |

### 3.4 Gotchas

- **Placeholder rows**: `TypeOfChange IS NULL` rows are structural artifacts from the LEFT JOIN — always filter for event-only analysis
- **LoginName sparsity**: ~92% of rows have NULL/empty LoginName — do not assume login attribution is available for CID membership changes
- **ListName is latest-version**: The name is resolved from the most recent `#NameLists_Log` entry, not the historical name at `ChangeTime`
- **No NameListID on placeholders**: All columns except `FromDate`, `ToDate`, and `UpdateDate` are NULL on placeholder rows

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
| 2 | ToDate | datetime | YES | End of the audit week (Sunday 00:00:00); six days after `FromDate` as computed in the SP, **not** end-of-day 23:59:59. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | NameListID | int | YES | CEP Named List identifier from the source `ListCIDMappings` tables; NULL on no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | ListName | varchar(max) | YES | Named List display name resolved via JOIN to `#NameLists_Log` on `NamedListID` (latest version); NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | CID | bigint | YES | Customer ID that was added to or removed from the Named List; NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | TypeOfChange | varchar(max) | YES | `CID Added` or `CID Deleted`; NULL for no-change placeholder rows from the LEFT JOIN pattern. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | LoginName | varchar(max) | YES | Application login from `AppLoginName` in the source `ListCIDMappings` tables; NULL in ~92% of rows — CID membership changes frequently lack login attribution. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | ChangeTime | datetime | YES | Source event timestamp: `SysStartTime` for `CID Added` events, `SysEndTime` for `CID Deleted` events; NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | UpdateDate | datetime | YES | Row load time: `GETDATE()` at SP execution. (Tier 4 — SP_W_CEPWeeklyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| FromDate | SP_W_CEPWeeklyAudit | `@weekStart` | Computed Monday boundary |
| ToDate | SP_W_CEPWeeklyAudit | `@weekEnd` | Computed Sunday boundary |
| NameListID | External_Etoro_*_ListCIDMappings | NamedListID | Passthrough (positional rename) |
| ListName | External_Etoro_*_NamedLists | Name | JOIN on NamedListID, latest version |
| CID | External_Etoro_*_ListCIDMappings | CID | Passthrough |
| TypeOfChange | SP_W_CEPWeeklyAudit | — | Derived: `CID Added` / `CID Deleted` |
| LoginName | External_Etoro_*_ListCIDMappings | AppLoginName | Passthrough (positional rename) |
| ChangeTime | External_Etoro_*_ListCIDMappings | SysStartTime / SysEndTime | SysStartTime for adds, SysEndTime for deletes |
| UpdateDate | SP_W_CEPWeeklyAudit | `GETDATE()` | ETL load timestamp |

### 5.2 ETL Pipeline

```
Dealing_staging.External_Etoro_CEP_ListCIDMappings  (current)
Dealing_staging.External_Etoro_History_ListCIDMappings  (temporal history)
Dealing_staging.External_Etoro_CEP_NamedLists  (list name resolution)
Dealing_staging.External_Etoro_History_NamedLists  (list name resolution)
    |
    v
#ListCIDMapping_Log  (UNION ALL current + history, JOIN #NameLists_Log for Name)
    |
    v
#ListCIDMapping_ChangesFinal  (SysStartTime in week → 'CID Added', SysEndTime in week → 'CID Deleted')
    |
    v
SP_W_CEPWeeklyAudit — LEFT JOIN #FromDateToDate → DELETE + INSERT for (@weekStart, @weekEnd)
    |
    v
Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping  (~1,057 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| NameListID | `Dealing_staging.External_Etoro_CEP_ListCIDMappings` | Source of CID-to-list mapping data |
| NameListID | `Dealing_staging.External_Etoro_History_ListCIDMappings` | Temporal history of CID-to-list mappings |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists` | Sibling — list-level lifecycle events; join on `FromDate` + `NameListID` for list-level context |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | Sibling — rule-level changes in the same weekly audit family |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | Sibling — compound property changes in the same weekly audit family |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | Sibling — condition definition changes in the same weekly audit family |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | Sibling — condition-to-CP mapping changes |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` | Sibling — CP-to-rule mapping changes |

---

## 7. Sample Queries

### 7.1 CID membership changes for one audit week (real events only)

```sql
SELECT
      FromDate
    , ToDate
    , NameListID
    , ListName
    , CID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping
WHERE FromDate = '2026-04-12'
  AND TypeOfChange IS NOT NULL
ORDER BY NameListID, ChangeTime;
```

### 7.2 Full membership history for a specific CID

```sql
SELECT
      FromDate
    , ToDate
    , NameListID
    , ListName
    , TypeOfChange
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping
WHERE CID = @CID
  AND TypeOfChange IS NOT NULL
ORDER BY FromDate DESC, ChangeTime DESC;
```

### 7.3 CID-level events correlated with list-level events in the same week

```sql
SELECT
      m.FromDate
    , m.NameListID
    , m.ListName
    , m.CID
    , m.TypeOfChange   AS CID_Event
    , nl.TypeOfChange  AS List_Event
    , m.ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping AS m
LEFT JOIN Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists AS nl
       ON nl.FromDate = m.FromDate
      AND nl.NameListID = m.NameListID
WHERE m.FromDate = '2026-03-22'
  AND m.TypeOfChange IS NOT NULL
ORDER BY m.NameListID, m.ChangeTime;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 8 T2, 0 T3, 1 T4 | Elements: 9/9, Logic: 8.0/10, Relationships: 7.5/10, Sources: 6.0/10*
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping | Type: Table | Production Source: Dealing_staging CEP ListCIDMappings + history*
