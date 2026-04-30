# History.ApexData

> System-versioned temporal history table that automatically stores previous versions of Apex.ApexData rows when they are updated, providing a complete audit trail of account status changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) + 1 nonclustered (BeginTime, EndTime) |

---

## 1. Business Meaning

History.ApexData is the temporal history table for Apex.ApexData. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.ApexData is updated. Each row represents a previous state of an account record, with BeginTime/EndTime defining when that version was active. This enables point-in-time queries and full audit trails of every account status change.

This table is essential for regulatory compliance and operational debugging. Regulators may request the complete history of when an account's status changed (e.g., when it moved from PENDING to COMPLETE, or when it was RESTRICTED). The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) allows querying the state of any account at any point in time.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.ApexData are updated. The old version is moved here with the original BeginTime and an EndTime set to the update timestamp. PAGE compression is applied to reduce storage.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.ApexData creates a historical record here.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all data columns

**Rules**:
- When an Apex.ApexData row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.ApexData gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Multiple history rows per ApexID/GCID are expected (one per status change)
- Temporal queries use `Apex.ApexData FOR SYSTEM_TIME AS OF '2024-01-01'` to see the state at a specific time

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.ApexData columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApexID | varchar(8) | NO | - | VERIFIED | Apex Clearing account identifier. Same value as Apex.ApexData.ApexID at the time this version was active. |
| 2 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.ApexData.GCID. |
| 3 | StatusID | int | NO | - | VERIFIED | Account status AT THE TIME this version was active. See [Apex Status](_glossary.md#apex-status) for values. The transition from one StatusID to the next creates a new history row. |
| 4 | BeginTime | datetime2(0) | NO | - | VERIFIED | When this version became active (was originally written to Apex.ApexData). Part of the temporal period. |
| 5 | EndTime | datetime2(0) | NO | - | VERIFIED | When this version was superseded by a newer version. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime) for efficient temporal range queries. |
| 6 | UpdatedSync | bit | NO | - | VERIFIED | Sync flag value at the time this version was active. Tracks whether the trading platform had synced this version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.ApexData | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history for Apex.ApexData |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.ApexData | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ApexData | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |
| ix_History_ApexData | NONCLUSTERED | BeginTime ASC, EndTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View complete status history for an account

```sql
SELECT ApexID, GCID, StatusID, BeginTime, EndTime
FROM History.ApexData WITH (NOLOCK)
WHERE GCID = 19533157
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - what was the status on a specific date

```sql
SELECT ApexID, GCID, StatusID, BeginTime, EndTime
FROM Apex.ApexData
FOR SYSTEM_TIME AS OF '2023-06-15 00:00:00'
WHERE GCID = 19533157;
```

### 8.3 Find all status transitions for a date range

```sql
SELECT ApexID, GCID, StatusID, BeginTime, EndTime
FROM Apex.ApexData
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 19533157
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ApexData | Type: Table | Source: USABroker/History/Tables/History.ApexData.sql*
