# Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping

> 537-row daily audit of **per-CID membership changes** in CEP Named Lists — records every **CID Added** and **CID Deleted** event from **2023-12-19** through **2026-04-17**, covering **20 distinct lists** and **451 distinct CIDs**. Written by `SP_CEPDailyAudit` from `Dealing_staging` CEP temporal tables.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_ListCIDMappings` + `External_Etoro_History_ListCIDMappings` via `SP_CEPDailyAudit` |
| **Refresh** | Daily (Priority 0 — OpsDB / Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` ASC |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |
| **PII** | Yes — `CID` column contains customer identifiers |

---

## 1. Business Meaning

This table records **individual CID additions to and removals from CEP Named Lists**. Named Lists are configuration objects in the **Client Execution Platform (CEP)** hedging rule engine that allow conditions to target **groups of clients by CID**. When a CID is added to or removed from a Named List, this table captures the event at per-CID granularity.

**CEP hierarchy context:**

```
Rule
  └── Compound Property (CP)
        └── Condition
              └── references Named List  ← list-level events in NameLists table
                    └── CID membership   ← per-CID events HERE
```

**Relationship to sibling:** **`Dealing_CEPDailyAudit_NameLists`** captures **list-level lifecycle** events (`New Name List`, `Name List Deleted`, `Change In CIDs`). This table is the **detail companion** — when NameLists shows a `Change In CIDs` event, the individual CID adds/removes for that date appear here.

**Scale:** **537 rows** across **89 distinct dates** — very sparse vs calendar days. **CopyFunds** (NameListID 36) accounts for ~37% of all events (200 rows). Most lists see only occasional membership changes.

**PII note:** The `CID` column contains **customer identifiers** (bigint). Treat access and publication with appropriate governance — same Dealing/Risk audience as other CEP audit tables.

**Load pattern:** `SP_CEPDailyAudit` performs **DELETE + INSERT** for the supplied `@Date`. Daily refresh. **SLA:** typically next business day for date *D*.

**LoginName coverage:** ~85% of rows have NULL or empty `LoginName`, suggesting most CID membership changes are system-driven (automated list management) rather than manual user actions.

---

## 2. Business Logic

### 2.1 CID Membership Change Detection

**What**: The SP detects when a CID is added to or removed from a Named List by examining system-time temporal records.

**Columns Involved**: `CID`, `NameListID`, `TypeOfChange`, `ChangeTime`

**Rules**:
- **`CID Added`** — `SysStartDate = @Date` on the ListCIDMappings temporal record (CID membership began on this date)
- **`CID Deleted`** — `SysEndTime < '9999-01-01'` AND `SysEndDate = @Date` (CID membership ended on this date)
- Records where `SysStartTime = SysEndTime` are excluded (zero-duration temporal artifacts)

### 2.2 List Name Resolution

**What**: The SP resolves the human-readable list name by joining to the NameLists temporal log.

**Columns Involved**: `ListName`, `NameListID`

**Rules**:
- `#ListCIDMapping_Log` joins to `#NameLists_Log` (latest-row: `RN_Desc=1`) on `NamedListID` to get `Name`
- The DDL column `ListName` receives the SP's `Name` column via positional INSERT

### 2.3 Login Attribution

**What**: The SP captures the CEP application user responsible for the change, with fallback to the previous temporal record's login.

**Columns Involved**: `LoginName`

**Rules**:
- Uses `COALESCE(AppLoginName, PreviousAppLoginName)` where `PreviousAppLoginName` is derived via `LEAD(AppLoginName, 1) OVER (PARTITION BY NamedListID, CID ORDER BY SysEndTime DESC)`
- In practice, ~85% of rows have empty LoginName — suggesting automated / system-driven membership changes

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for a small audit table. |
| **Clustered index** | **`Date` ASC** — align filters to `Date` for index seeks. |
| **Scale** | **537 rows** — no performance concerns. |

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which CIDs were added/removed from a list on date X? | `WHERE Date = 'YYYY-MM-DD' AND NameListID = @id` |
| Full membership change history for a specific CID | `WHERE CID = @cid ORDER BY Date DESC` |
| All CID deletions from a list in a date range | `WHERE NameListID = @id AND TypeOfChange = 'CID Deleted' AND Date BETWEEN @start AND @end` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_CEPDailyAudit_NameLists | `NameListID + Date` | Correlate list-level events (lifecycle) with per-CID detail |
| Dealing_CEPDailyAudit_Rules | `Date` | See rule-level changes on the same day as CID membership changes |

### 3.4 Gotchas

- **Sparse table** — only 89 of ~850+ calendar dates have rows. Don't expect continuous daily data.
- **LoginName mostly empty** — ~85% of rows have NULL/empty LoginName. Do not assume every change has user attribution.
- **LoginName padding** — some `LoginName` values contain trailing null-byte padding (observed in sampled data). Use `RTRIM` or `LTRIM` if comparing.
- **CID is PII** — treat as sensitive data; restrict downstream publishing.
- **ListName vs Name** — the DDL column is `ListName` but the SP inserts `Name` from the NameLists log. They represent the same value.
- This is one of 7 CEPDailyAudit tables, all written by the same SP: CP, CPToRule, ConditionToCP, Conditions, ListCIDMapping, NameLists, Rules.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this CID membership change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. Clustered index key. (Tier 2 — SP_CEPDailyAudit) |
| 2 | NameListID | int | YES | **Identifier** of the **Named List** whose CID membership changed. Corresponds to `NamedListID` in the staging temporal tables. (Tier 2 — SP_CEPDailyAudit) |
| 3 | ListName | varchar(max) | YES | **Human-readable name** of the Named List at the time of the event — resolved via JOIN to `#NameLists_Log` (latest row: `RN_Desc=1`) on `NamedListID`. (Tier 2 — SP_CEPDailyAudit) |
| 4 | CID | bigint | YES | **Customer identifier** that was added to or removed from the Named List. **PII** — treat as sensitive. (Tier 2 — SP_CEPDailyAudit) |
| 5 | TypeOfChange | varchar(max) | YES | **Event type**: **`CID Added`** (membership began on this date) or **`CID Deleted`** (membership ended on this date). (Tier 2 — SP_CEPDailyAudit) |
| 6 | LoginName | varchar(max) | YES | **CEP application user** who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` from the temporal history. **NULL or empty** for ~85% of rows (system-driven changes). (Tier 2 — SP_CEPDailyAudit) |
| 7 | ChangeTime | datetime | YES | **Source timestamp** of the membership change — **`SysStartTime`** for `CID Added` events; **`SysEndTime`** for `CID Deleted` events. (Tier 2 — SP_CEPDailyAudit) |
| 8 | UpdateDate | datetime | YES | **DWH load timestamp** via **`GETDATE()`** in the SP — **not** the business event time. (Tier 2 — SP_CEPDailyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP_CEPDailyAudit | @Date | Direct assignment |
| NameListID | External_Etoro_CEP_ListCIDMappings | NamedListID | Passthrough (renamed) |
| ListName | External_Etoro_CEP_NamedLists | Name | JOIN via #NameLists_Log on NamedListID |
| CID | External_Etoro_CEP_ListCIDMappings | CID | Passthrough |
| TypeOfChange | SP_CEPDailyAudit | Derived | SysStartDate=@Date → CID Added; SysEndDate=@Date → CID Deleted |
| LoginName | External_Etoro_CEP_ListCIDMappings | AppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) |
| ChangeTime | External_Etoro_CEP_ListCIDMappings | SysStartTime / SysEndTime | SysStartTime for adds; SysEndTime for deletes |
| UpdateDate | SP_CEPDailyAudit | GETDATE() | ETL metadata |

No Generic Pipeline mapping — CEP is an internal eToro system, not tracked in the Generic Pipeline.

### 5.2 ETL Pipeline

```
[CEP System — ListCIDMappings temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_ListCIDMappings  (current)
Dealing_staging.External_Etoro_History_ListCIDMappings  (history)
    ↓ JOIN #NameLists_Log (for list name resolution)
SP_CEPDailyAudit(@Date)
    — SysStartDate = @Date → CID Added
    — SysEndDate = @Date (SysEndTime < 9999) → CID Deleted
    — COALESCE(AppLoginName, PreviousAppLoginName) for user attribution
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping  ← DELETE + INSERT for @Date
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| NameListID | Dealing_CEPDailyAudit_NameLists | Parent list lifecycle audit — list-level events for the same NameListID |
| NameListID | Dealing_staging.External_Etoro_CEP_ListCIDMappings | Source entity — current CID-to-list membership |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_CEPDailyAudit_NameLists | NameListID | List-level `Change In CIDs` events reference per-CID detail here |

---

## 7. Sample Queries

### 7.1 All CID membership changes on a specific date

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
WHERE Date = '2026-04-17'
ORDER BY NameListID, ChangeTime;
```

### 7.2 CID removal history for a specific list

```sql
SELECT
      Date
    , CID
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping
WHERE NameListID = 36
  AND TypeOfChange = 'CID Deleted'
ORDER BY Date DESC, ChangeTime DESC;
```

### 7.3 Same-day join: list-level event with per-CID detail

```sql
SELECT
      n.Date
    , n.NameListID
    , n.Name         AS ListName
    , n.TypeOfChange AS NameLists_Event
    , m.CID
    , m.TypeOfChange AS ListCID_Event
    , m.ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_NameLists AS n
LEFT JOIN Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping AS m
       ON m.NameListID = n.NameListID
      AND m.Date = n.Date
WHERE n.TypeOfChange = 'Change In CIDs'
  AND n.Date = '2026-01-26'
ORDER BY n.NameListID, m.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.0/10 (★★★★☆) | Batch: regen-harness attempt 1*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4 | Elements: 8.5/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 6.0/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping | Type: Table | Production Source: Dealing_staging CEP ListCIDMappings + NamedLists temporal tables*
