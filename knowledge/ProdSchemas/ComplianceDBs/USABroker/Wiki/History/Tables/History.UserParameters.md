# History.UserParameters

> System-versioned temporal history table that automatically stores previous versions of Apex.UserParameters rows when they are updated, providing a complete audit trail of the cumulative pending-update bitmask state for each customer.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) + 1 nonclustered (EndTime, BeginTime) |

---

## 1. Business Meaning

History.UserParameters is the temporal history table for Apex.UserParameters. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.UserParameters is updated. Each row represents a previous state of a customer's cumulative pending-update bitmask record, with BeginTime/EndTime defining when that version was active. This enables point-in-time queries and a complete audit trail of every change to the UpdatesMask accumulation and clearing cycle.

Apex.UserParameters acts as a change queue, accumulating field-change bitmask values from customer data modifications until the system is ready to send an update request to Apex Clearing. Each time a field changes, its bit is ORed into UpdatesMask. When the update request is sent and processed, the mask is cleared back to 0. This history table records every step of that cycle, making it possible to reconstruct exactly what pending changes existed at any point in time. This is valuable for diagnosing update workflow issues, investigating why certain fields were or were not included in a given Apex API call, and producing a timeline of pending-change accumulation. The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) enables precise point-in-time queries.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.UserParameters are updated by Apex.SaveUserParametersUpdatesMask. PAGE compression is applied to reduce storage.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.UserParameters creates a historical record here, capturing each accumulation step and clearing of the pending-update mask.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, `GCID`, `UpdatesMask`

**Rules**:
- When an Apex.UserParameters row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.UserParameters gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Multiple history rows per GCID are expected - one for each OR accumulation of a new field bit, and one for each mask clearing after a successful Apex update request
- UpdatesMask=0 in a history row indicates the mask was cleared (update was sent to Apex); a non-zero mask indicates an intermediate accumulation state
- Temporal queries use `Apex.UserParameters FOR SYSTEM_TIME AS OF '2024-01-01'` to see what pending changes were queued at any specific time

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.UserParameters columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.UserParameters.GCID at the time this version was active. |
| 2 | UpdatesMask | int | YES | - | VERIFIED | Cumulative bitmask of pending user data field changes AT THE TIME this version was active. Uses Dictionary.UserDataUpdatesMask values. NULL or 0 means the mask had been cleared (all pending changes were sent to Apex). A non-zero value records an intermediate state with outstanding pending changes. See [User Data Updates Mask](../_glossary.md#user-data-updates-mask). |
| 3 | BeginTime | datetime2(7) | NO | - | VERIFIED | When this version became active (was originally written to Apex.UserParameters). Part of the temporal period. |
| 4 | EndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded by a newer version. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.UserParameters | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.UserParameters |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserParameters | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_UserParameters | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |
| ix_History_UserParameters | NONCLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Applied to clustered and ix_History_UserParameters; reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View the complete pending-mask accumulation and clearing history for a customer

```sql
SELECT GCID, UpdatesMask, BeginTime, EndTime,
       DATEDIFF(SECOND, BeginTime, EndTime) AS SecondsInState
FROM History.UserParameters WITH (NOLOCK)
WHERE GCID = 85152
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - what pending changes were queued for a customer on a specific date

```sql
SELECT GCID, UpdatesMask, BeginTime, EndTime
FROM Apex.UserParameters
FOR SYSTEM_TIME AS OF '2024-06-15 00:00:00'
WHERE GCID = 85152;
```

### 8.3 Find all pending-mask changes within a date range for a customer

```sql
SELECT GCID, UpdatesMask, BeginTime, EndTime
FROM Apex.UserParameters
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 85152
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.UserParameters | Type: Table | Source: USABroker/History/Tables/History.UserParameters.sql*
