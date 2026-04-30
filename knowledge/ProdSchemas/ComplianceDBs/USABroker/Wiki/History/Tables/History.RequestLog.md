# History.RequestLog

> System-versioned temporal history table that automatically stores previous versions of Apex.RequestLog rows when they are updated, providing a complete audit trail of Apex Clearing API request status progressions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) |

---

## 1. Business Meaning

History.RequestLog is the temporal history table for Apex.RequestLog. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.RequestLog is updated. Each row represents a previous state of an API request log entry, with BeginTime/EndTime defining when that version was active. This enables point-in-time queries and a full audit trail of every status transition and event ID advancement for every API request sent to Apex Clearing.

This table is critical for diagnosing stuck or failed account creation, update, and closure operations. When an Apex API request goes through its lifecycle - from NEW through processing states to COMPLETE or REJECTED - each status change generates a history row. By querying this table, operations teams can reconstruct the exact sequence and timing of events for any Apex request, identify where a request got stuck, and determine if retries occurred. The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) allows querying the state of any request log entry at any exact point in time.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.RequestLog are updated by Apex.SaveRequestLog via its MERGE pattern. PAGE compression is applied to reduce storage across the millions of historical request state transitions.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.RequestLog creates a historical record here.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all data columns

**Rules**:
- When an Apex.RequestLog row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.RequestLog gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Multiple history rows per RequestLogID/GCID are expected (one per status change or event ID advance)
- SaveRequestLog uses change detection: it only updates when StatusID, ApexLastEventID, UpdateEventMask, or LogID actually change, meaning only genuine transitions appear in history
- Temporal queries use `Apex.RequestLog FOR SYSTEM_TIME AS OF '2024-01-01'` to see request states at a specific time

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.RequestLog columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestLogID | int | NO | - | VERIFIED | Auto-incrementing surrogate key from the parent table. Identifies which request log entry this historical version belongs to. |
| 2 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.RequestLog.GCID at the time this version was active. |
| 3 | ApexRequestID | uniqueidentifier | YES | - | VERIFIED | The Apex Clearing request GUID at the time this version was active. Used to correlate with Apex's own event stream. |
| 4 | ApexLastEventID | int | YES | - | VERIFIED | The ID of the last Apex event processed AT THE TIME this version was active. Each advance of this value creates a new history row, recording the polling progression. |
| 5 | StatusID | int | NO | - | VERIFIED | The request processing status AT THE TIME this version was active. Uses Dictionary.ApexStatus values: 1=NEW through to 12=COMPLETE or 11=REJECTED. See [Apex Status](../_glossary.md#apex-status). The transition from one status to the next creates a new history row. |
| 6 | UpdateEventMask | int | NO | - | VERIFIED | Bitmask of which user data fields triggered this request at the time this version was active. See [User Data Updates Mask](../_glossary.md#user-data-updates-mask). |
| 7 | LogID | uniqueidentifier | YES | - | VERIFIED | Correlation ID linking to the application logging system at the time this version was active. |
| 8 | BeginTime | datetime2(7) | NO | - | VERIFIED | When this version became active (was originally written to Apex.RequestLog). Part of the temporal period. |
| 9 | EndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded by a newer version. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). |
| 10 | ModifyTypeID | int | YES | - | VERIFIED | The type of account operation (1=Create, 2=Update, 3=Close) at the time this version was active. See [Modify Type](../_glossary.md#modify-type). NULL for legacy records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.RequestLog | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.RequestLog |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.RequestLog | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RequestLog | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View complete request status history for a customer

```sql
SELECT RequestLogID, GCID, ApexRequestID, StatusID, ApexLastEventID,
       ModifyTypeID, UpdateEventMask, BeginTime, EndTime
FROM History.RequestLog WITH (NOLOCK)
WHERE GCID = 22055177
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - what was the request status at a specific moment

```sql
SELECT RequestLogID, GCID, ApexRequestID, StatusID, ApexLastEventID,
       ModifyTypeID, BeginTime, EndTime
FROM Apex.RequestLog
FOR SYSTEM_TIME AS OF '2024-06-15 10:00:00'
WHERE GCID = 22055177;
```

### 8.3 Find all status transitions for a request within a date range

```sql
SELECT RequestLogID, GCID, ApexRequestID, StatusID, ApexLastEventID,
       ModifyTypeID, BeginTime, EndTime
FROM Apex.RequestLog
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 22055177
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RequestLog | Type: Table | Source: USABroker/History/Tables/History.RequestLog.sql*
