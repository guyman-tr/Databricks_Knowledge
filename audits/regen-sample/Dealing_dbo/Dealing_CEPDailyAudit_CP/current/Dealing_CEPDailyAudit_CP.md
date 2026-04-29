# Dealing_dbo.Dealing_CEPDailyAudit_CP

> Daily audit trail of **Compound Property (CP)** lifecycle changes in the CEP hedging rule engine — captures creations, renames, and deletions of CPs that control hedging behavior.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Daily (Priority 0 — OpsDB/Service Broker) |
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

This table records every **Compound Property (CP) lifecycle event** in eToro's CEP (Client Execution Platform) hedging rule engine. CPs are groupings of conditions used within CEP Rules — they act as logical "clauses" that can be reused across multiple hedging rules. When a CP is created, renamed, or deleted, one row is written for that business date.

**Source and lineage**: Data flows from `Dealing_staging.External_Etoro_CEP_CompoundProperties` (current state) and `External_Etoro_History_CompoundProperties` (temporal history). The writer SP `SP_CEPDailyAudit` uses `LAG()` window functions over system-time versioned records to detect changes, then classifies each event by type.

**Freshness**: Runs daily. Data available next business day. Active pipeline — max date 2026-03-09. Sparse table (314 rows since Dec 2023) because rows only appear on days when CP changes actually occur.

**Why it matters**: CEP rules control how eToro routes and hedges client positions. Changes to CPs can materially affect hedging behavior. This audit trail supports regulatory compliance, post-incident investigation, and governance oversight by the Dealing team.

---

## 2. Business Logic

### 2.1 Change Detection via Temporal Tables

**What**: The SP detects CP changes by comparing successive system-time versions of the staging temporal tables using `LAG()` over `SysStartTime`.

**Columns Involved**: `TypeOfChange`, `ChangeTime`, `LoginName`, `Comments`

**Rules**:
- `New Compound Property` — CP created today (new row in current table, no prior history)
- `Name Change` — CP renamed (Comments stores `"Previous Name: {oldName}"`)
- `Compound Property Deleted` — CP removed from CEP (row disappears from current, appears in history with SysEndTime)
- `LoginName` uses `COALESCE(AppLoginName, PreviousAppLoginName)` to capture the responsible user even for deletion events

### 2.2 Sentinel Row Pattern

**What**: The SP always writes at least one row per processed date, even if no CP changes occurred that day.

**Rules**:
- On days with no changes, a sentinel row with NULL `TypeOfChange`, `CompoundPropertyID`, etc. is written
- Filter with `WHERE TypeOfChange IS NOT NULL` for actual change events only

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `Date`. Very small table (~314 rows). No performance concerns. Always filter on `Date` for the most common access pattern.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What CP changes happened on date X? | `WHERE Date = 'YYYY-MM-DD' AND TypeOfChange IS NOT NULL` |
| Who made a specific CP change? | `WHERE CompoundPropertyID = @id AND TypeOfChange IS NOT NULL ORDER BY Date DESC` |
| All CP renames in a date range | `WHERE Date BETWEEN @start AND @end AND TypeOfChange = 'Name Change'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_CEPDailyAudit_CPToRule | `CompoundPropertyID + Date` | Correlate CP changes with Rule-mapping changes on the same day |
| Dealing_CEPDailyAudit_Rules | `RuleID + Date` | See which Rule was affected by this CP change |

### 3.4 Gotchas

- **Sparse table**: Many calendar dates have zero rows (no CP changes). Don't expect continuous daily data.
- **Sentinel rows**: Always filter `WHERE TypeOfChange IS NOT NULL` to exclude placeholder rows.
- This is one of 7 CEPDailyAudit tables, all written by the same SP: CP, CPToRule, ConditionToCP, Conditions, ListCIDMapping, NameLists, Rules.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date on which this CP change occurred. Clustered index key. NULL on sentinel rows (no changes detected). (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | ID of the CEP Rule this Compound Property is associated with (via CP-to-Rule mapping). NULL if the CP change is not linked to a rule (e.g., standalone CP creation). (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | Name of the associated CEP Rule. Denormalized from the Rule dimension for query convenience. (Tier 2 — SP_CEPDailyAudit) |
| 4 | CompoundPropertyID | int | YES | Unique identifier of the Compound Property that changed. NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 5 | CPName | varchar(max) | YES | Name of the Compound Property at the time of the change. (Tier 2 — SP_CEPDailyAudit) |
| 6 | HedgeServerID | int | YES | Hedge server associated with this Rule. Identifies which hedging server processes the parent rule. (Tier 2 — SP_CEPDailyAudit) |
| 7 | TypeOfChange | varchar(max) | YES | Change event type. Values: `New Compound Property`, `Name Change`, `Compound Property Deleted`. NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 8 | Comments | varchar(max) | YES | Context for `Name Change` events: `"Previous Name: {oldName}"`. NULL for creation/deletion events and sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | Application login of the user who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` from the temporal history to capture identity even for deletion events. NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | Exact timestamp of the change event (SysStartTime or SysEndTime from the temporal record). NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at SP execution time. Not the business change time. [UNVERIFIED] (Tier 4 — inferred) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All columns | Dealing_staging CEP temporal tables | Various | LAG()-based change detection |

No Generic Pipeline mapping — CEP is an internal eToro system, not tracked in the Generic Pipeline.

### 5.2 ETL Pipeline

```
CEP Internal System
    → Dealing_staging.External_Etoro_CEP_CompoundProperties (current state)
    → Dealing_staging.External_Etoro_History_CompoundProperties (temporal history)
        → SP_CEPDailyAudit (LAG() change detection)
            → Dealing_dbo.Dealing_CEPDailyAudit_CP
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RuleID | Dealing_CEPDailyAudit_Rules | Parent rule whose CP configuration changed |
| CompoundPropertyID | Dealing_staging.External_Etoro_CEP_CompoundProperties | Source CP entity |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_CEPDailyAudit_CPToRule | CompoundPropertyID | CP-to-Rule mapping changes reference the same CP |
| V_Dealing_CEPDailyAudit_CP_Last180Days | All | View over this table for last 180 days |

---

## 7. Sample Queries

### 7.1 All CP changes on a specific date
```sql
SELECT Date, CompoundPropertyID, CPName, TypeOfChange, LoginName, ChangeTime
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE  Date = '2026-03-01'
  AND  TypeOfChange IS NOT NULL
ORDER BY ChangeTime;
```

### 7.2 History of a specific Compound Property
```sql
SELECT Date, TypeOfChange, Comments, LoginName, ChangeTime
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE  CompoundPropertyID = 42
  AND  TypeOfChange IS NOT NULL
ORDER BY Date DESC;
```

### 7.3 All CP renames in the last 30 days
```sql
SELECT Date, CompoundPropertyID, CPName, Comments AS PreviousName, LoginName
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE  Date >= DATEADD(DAY, -30, GETDATE())
  AND  TypeOfChange = 'Name Change'
ORDER BY Date DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Batch: 7 (redo)*
*Tiers: 0 T1, 10 T2, 0 T3, 1 T4 | Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_CP | Type: Table | Production Source: Dealing_staging CEP tables*
