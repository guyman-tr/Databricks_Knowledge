# History.State

> System-versioned temporal history table that automatically stores previous versions of Apex.State rows when they are updated, providing a complete audit trail of every workflow state transition in the Apex account processing engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) + 3 nonclustered (EndTime/BeginTime, GCID, ApexStateID+GCID) |

---

## 1. Business Meaning

History.State is the temporal history table for Apex.State. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.State is updated. Each row represents a previous workflow state for a customer's Apex account processing, with BeginTime/EndTime defining when the customer was in that state. This enables point-in-time queries and a complete reconstruction of every state transition a customer has ever passed through.

This table is the definitive record of how every account moved through the Apex integration state machine. The 47-state machine spans account creation (states 1-10), updates (11-19), Sketch CIP investigations (20-35), affiliated approvals (36-37), restrictions (38-39), closures (41-45), and special approvals (46-47). Compliance investigations, customer service escalations, and operational debugging all rely on this history to reconstruct exactly when a customer entered each state, how long they remained there, and why (via the Comment column). The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) enables precise point-in-time queries.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.State are updated by Apex.SaveState. The old version is moved here with the original BeginTime and an EndTime set to the transition timestamp. Four additional indexes support high-volume lookups by GCID and ApexStateID. PAGE compression is applied to reduce storage.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.State creates a historical record here, capturing each state machine transition.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, `GCID`, `ApexStateID`, `Comment`

**Rules**:
- When an Apex.State row is updated, the OLD values are inserted here with EndTime = transition timestamp
- The current row in Apex.State gets BeginTime = transition timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Multiple history rows per GCID are expected - one for every state transition the customer has undergone
- The difference between EndTime and BeginTime on any history row shows how long the customer spent in that state
- Temporal queries use `Apex.State FOR SYSTEM_TIME AS OF '2024-01-01'` to see which state any customer was in at a specific time

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.State columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.State.GCID at the time this version was active. Indexed by ix_History_State_GCID for efficient per-customer history retrieval. |
| 2 | ApexStateID | int | NO | - | VERIFIED | The workflow state the customer was in AT THE TIME this version was active. 47 possible values spanning creation, update, investigation, restriction, closure, and special approval workflows. See [State (Apex State)](../_glossary.md#state-apex-state). The transition from one ApexStateID to the next creates a new history row. Indexed with GCID by ix_History_State_GCID_ApexStateID. |
| 3 | Comment | nvarchar(4000) | YES | - | VERIFIED | Context text for the state at the time this version was active. Contains error messages, investigation details, or processing notes as they existed when this state version was recorded. NULL for normal success states. |
| 4 | BeginTime | datetime2(7) | NO | - | VERIFIED | When this state version became active (when the customer entered this state). Part of the temporal period. The difference EndTime - BeginTime shows time spent in this state. |
| 5 | EndTime | datetime2(7) | NO | - | VERIFIED | When this state version was superseded (when the customer transitioned to the next state). Part of the temporal period. Clustered index key (EndTime, BeginTime). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.State | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.State |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.State | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_State | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |
| ix_History_State | NONCLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |
| ix_History_State_GCID | NONCLUSTERED | GCID ASC | - | - | Active |
| ix_History_State_GCID_ApexStateID | NONCLUSTERED | ApexStateID ASC, GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Applied to clustered and ix_History_State; reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View complete state transition history for a customer

```sql
SELECT GCID, ApexStateID, Comment, BeginTime, EndTime,
       DATEDIFF(SECOND, BeginTime, EndTime) AS SecondsInState
FROM History.State WITH (NOLOCK)
WHERE GCID = 20708
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - what state was a customer in on a specific date

```sql
SELECT GCID, ApexStateID, Comment, BeginTime, EndTime
FROM Apex.State
FOR SYSTEM_TIME AS OF '2024-06-15 00:00:00'
WHERE GCID = 20708;
```

### 8.3 Find all state transitions within a date range for a customer

```sql
SELECT GCID, ApexStateID, Comment, BeginTime, EndTime
FROM Apex.State
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 20708
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.State | Type: Table | Source: USABroker/History/Tables/History.State.sql*
