# History.UserDataUpdates

> System-versioned temporal history table that automatically stores previous versions of Apex.UserDataUpdates rows when they are updated, providing a complete audit trail of user data change events and their bitmask values.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) |

---

## 1. Business Meaning

History.UserDataUpdates is the temporal history table for Apex.UserDataUpdates. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.UserDataUpdates is updated. Each row represents a previous state of a user data change event record, with BeginTime/EndTime defining when that version was active. This enables point-in-time queries and a complete audit trail of every modification to the UpdatesMask value on any given update event.

While Apex.UserDataUpdates is itself an append-only change log of user data modification events, each individual row can still be updated (for example, if the bitmask is amended or the record is corrected). Those updates produce history rows here. In practice this table primarily serves as a safety net and audit record, ensuring that even the change-log table's own mutations are tracked. The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) allows querying the exact state of any update event record at any point in time.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.UserDataUpdates are updated. PAGE compression is applied to reduce storage.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.UserDataUpdates creates a historical record here.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all data columns

**Rules**:
- When an Apex.UserDataUpdates row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.UserDataUpdates gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- The parent table Apex.UserDataUpdates is predominantly insert-only; updates are rare but tracked when they occur
- The UpdatesMask bitmask uses Dictionary.UserDataUpdatesMask values (see [User Data Updates Mask](../_glossary.md#user-data-updates-mask)); any change to that mask on an existing row generates a history entry here
- Temporal queries use `Apex.UserDataUpdates FOR SYSTEM_TIME AS OF '2024-01-01'` to inspect the state of any update event at a specific time

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.UserDataUpdates columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserDataUpdatesId | int | NO | - | VERIFIED | Auto-incrementing surrogate key from the parent table. Identifies which update event record this historical version belongs to. |
| 2 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.UserDataUpdates.GCID at the time this version was active. |
| 3 | UpdatesMask | int | NO | - | VERIFIED | Bitmask encoding which user data fields were modified AT THE TIME this version was active. Uses Dictionary.UserDataUpdatesMask values: 1=Disclosures, 2=Name, 4=DateOfBirth, 8=CitizenshipCountry, 16=SSN, 32=BirthCountry, 64=PhoneNumber, 128=HomeAddress, 256=Email, 512=PermanentResident, 1024=TrustedContact, 2048=MailingAddress, 4096=Instructions. See [User Data Updates Mask](../_glossary.md#user-data-updates-mask). |
| 4 | BeginTime | datetime2(7) | NO | - | VERIFIED | When this version became active (was originally written to Apex.UserDataUpdates). Part of the temporal period. |
| 5 | EndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded by a newer version. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.UserDataUpdates | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.UserDataUpdates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserDataUpdates | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_UserDataUpdates | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View history of a specific update event record

```sql
SELECT UserDataUpdatesId, GCID, UpdatesMask, BeginTime, EndTime
FROM History.UserDataUpdates WITH (NOLOCK)
WHERE GCID = 22055177
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - what was the update mask for a specific event on a given date

```sql
SELECT UserDataUpdatesId, GCID, UpdatesMask, BeginTime, EndTime
FROM Apex.UserDataUpdates
FOR SYSTEM_TIME AS OF '2024-06-15 00:00:00'
WHERE GCID = 22055177;
```

### 8.3 Find all update events for a customer within a date range

```sql
SELECT UserDataUpdatesId, GCID, UpdatesMask, BeginTime, EndTime
FROM Apex.UserDataUpdates
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 22055177
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.UserDataUpdates | Type: Table | Source: USABroker/History/Tables/History.UserDataUpdates.sql*
