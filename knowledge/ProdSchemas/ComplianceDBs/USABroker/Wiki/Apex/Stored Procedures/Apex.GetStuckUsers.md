# Apex.GetStuckUsers

> Identifies customers whose Apex account processing appears stuck - accounts in active processing states with stale request logs and unsynced data, used for operational monitoring and recovery.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns stuck user list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GetStuckUsers finds customers whose Apex account processing may be stuck. It identifies accounts that are in active processing states (not in terminal states like Canceled, Error, Rejected, Complete, NotApplicable, NotExists, Restricted, Closed), have unsynchronized data (UpdatedSync=0), and whose most recent request was submitted before a specified cutoff date.

This is an operational monitoring procedure used to detect accounts that have fallen out of the normal processing flow and need manual intervention or retry.

---

## 2. Business Logic

### 2.1 Stuck User Detection Criteria

**What**: Cross-references ApexData status, RequestLog recency, and sync flag to identify accounts that stopped processing.

**Columns/Parameters Involved**: `ApexData.StatusID`, `ApexData.UpdatedSync`, `RequestLog.BeginTime`, `RequestLog.ApexRequestID`

**Rules**:
- Account must be in a non-terminal status: NOT IN (9=Canceled, 10=Error, 11=Rejected, 12=Complete, 13=NotApplicable, 14=NotExists, 15=Restricted, 16=Closed)
- UpdatedSync must be 0 (data not yet synced to trading platform)
- Most recent RequestLog entry (by RequestLogID DESC) must have BeginTime before @StartingFromDate
- Excludes requests with empty GUID (00000000-...) as those are placeholder records
- Results ordered by GCID DESC (newest customers first)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartingFromDate | datetime2(7) | NO | - | CODE-BACKED | Cutoff date for request staleness. Only accounts whose last request was submitted BEFORE this date are considered stuck. Allows filtering by how long the request has been idle. |

**Returns**: ApexRequestID, GCID, StatusID for each stuck customer.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.ApexData | Read | Filters by StatusID and UpdatedSync |
| - | Apex.RequestLog | Read | CROSS APPLY for most recent request per customer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.GetStuckUsers (procedure)
├── Apex.ApexData (table)
└── Apex.RequestLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.ApexData | Table | Read - filters by status and sync flag |
| Apex.RequestLog | Table | CROSS APPLY - gets most recent request |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find users stuck for more than 24 hours

```sql
EXEC Apex.GetStuckUsers @StartingFromDate = '2026-04-13';
```

### 8.2 Find users stuck for more than a week

```sql
EXEC Apex.GetStuckUsers @StartingFromDate = '2026-04-07';
```

### 8.3 Check with current time minus 1 hour

```sql
DECLARE @cutoff DATETIME2(7) = DATEADD(HOUR, -1, GETUTCDATE());
EXEC Apex.GetStuckUsers @StartingFromDate = @cutoff;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GetStuckUsers | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.GetStuckUsers.sql*
