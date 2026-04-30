# History.BackOfficeFTDPoolManager

> Audit trail for First Time Depositor (FTD) pool manager assignments: records every change to a customer's FTD relationship manager (BackOffice.Customer.FTDPoolManagerID), capturing who changed it, when, the new manager assigned, and a free-text comment. Active January 2009 to July 2010; inactive since.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PoolManagerHistoryID (PK, INT IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK, NONCLUSTERED on ChangedBy) |

---

## 1. Business Meaning

History.BackOfficeFTDPoolManager is the change-history table for the FTD (First Time Depositor) pool manager assignment feature. In eToro's early platform (2009-2010), new depositing customers were assigned to a "pool manager" - a sales or relationship manager responsible for onboarding and following up with first-time depositors. The active record of each customer's current pool manager was stored in `BackOffice.Customer.FTDPoolManagerID`. Whenever that assignment changed, `BackOffice.SetFTDPoolManager` wrote one row to this table recording: the customer affected (CID), who authorized the change (ChangedBy - a BackOffice manager), the new pool manager assigned (PoolManagerID), when the change occurred (Occurred), and a mandatory comment explaining the reason.

**FTD pool management** was a key CRM function in the early eToro model: customers who had just made their first deposit were distributed across a pool of relationship managers who would contact and guide them. The assignment history here reveals both the scale of the early onboarding operation (47 distinct pool managers handling 32,691 customers across 2009-2010) and the re-assignment activity as customers were moved between managers.

**Legacy status**: The newest record is July 12, 2010. This feature appears to have been discontinued when eToro's customer management model changed. `BackOffice.Customer.FTDPoolManagerID` may still exist as a column but assignments are no longer tracked here. No stored procedures or views reference this table other than the original writer.

**Scale**: 48,257 rows. 32,691 distinct customers. 25 managers made changes. 47 distinct pool managers were assigned. Average of roughly 1.5 assignment changes per customer, suggesting moderate re-assignment activity.

---

## 2. Business Logic

### 2.1 FTD Pool Manager Assignment Change Path

**What**: Records atomic changes to a customer's FTD pool manager with full before/after traceability.

**Columns/Parameters Involved**: `CID`, `ChangedBy`, `PoolManagerID`, `Comment`, `Occurred`

**Rules**:
- Executed only through `BackOffice.SetFTDPoolManager(@CID, @ChangedBy, @Comment, @NewManagerID)`
- The procedure runs in a transaction:
  1. `UPDATE BackOffice.Customer SET FTDPoolManagerID = @NewManagerID WHERE CID = @CID`
  2. `INSERT History.BackOfficeFTDPoolManager (ChangedBy, Occurred, Comment, CID, PoolManagerID) VALUES (...)` with `GETDATE()` for timestamp
  3. Either both succeed (COMMIT) or both rollback (RAISERROR 60000)
- `PoolManagerID` is the NEW assigned manager (no old value stored - to reconstruct previous assignment, look at the prior row for the same CID ordered by Occurred)
- `Comment` is `NOT NULL VARCHAR(255)` - a free-text reason field, mandatory for every change
- `Occurred` uses `GETDATE()` (local server time), NOT UTC - consistent with other BackOffice audit tables
- `PoolManagerID` is nullable in DDL but no NULLs exist in practice (0 NULL rows in 48,257 records) - unassignment was not used

**Diagram**:
```
BackOffice admin tool
   |
   BackOffice.SetFTDPoolManager(@CID=12345, @ChangedBy=85, @Comment='Reassigned - capacity', @NewManagerID=215)
   |
   BEGIN TRANSACTION
   UPDATE BackOffice.Customer SET FTDPoolManagerID=215 WHERE CID=12345
   INSERT History.BackOfficeFTDPoolManager (85, GETDATE(), 'Reassigned - capacity', 12345, 215)
   COMMIT
   |
   History row: {CID=12345, ChangedBy=85, PoolManagerID=215, Occurred=NOW, Comment='Reassigned - capacity'}
```

### 2.2 Reconstructing Full Assignment History for a Customer

**What**: To see the complete sequence of pool manager assignments for a customer, query ordered by Occurred.

**Rules**:
- Each row gives the new PoolManagerID at that point in time
- The PoolManagerID in row N was active from row N's Occurred until row N+1's Occurred
- The PoolManagerID in the latest row was the final assignment (until July 2010 when the feature was discontinued)
- No "old value" column - derive the previous manager from the preceding row for the same CID

### 2.3 Activity Distribution

**What**: All activity concentrated in 2009-2010.

| Year | Changes | Unique Customers |
|------|---------|-----------------|
| 2009 | 32,615 | 22,695 |
| 2010 | 15,642 | 12,010 |

2009 represents peak FTD pool management activity as eToro grew rapidly. Activity declined in 2010 and stopped entirely in mid-July 2010.

---

## 3. Data Overview

48,257 rows, January 2009 to July 2010. 32,691 distinct customers. 47 distinct pool managers. 25 managers authorized changes. Zero NULL PoolManagerID values. Table is frozen (no new data since July 2010).

| PoolManagerHistoryID | CID | ChangedBy | PoolManagerID | Occurred | Comment | Meaning |
|---|---|---|---|---|---|---|
| 1 | 12345 | 85 | 85 | 2009-01-05 | (reason text) | Customer 12345 assigned to pool manager 85, change authorized by manager 85. |
| (typical) | (any) | 85 | 215 | 2009-x | (reason) | PoolManagerID=85 was the most active pool manager (10,035 assignments covering 9,724 customers - 21% of all assignments). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PoolManagerHistoryID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-generated IDENTITY, NOT FOR REPLICATION (independent sequence per replica). Clustered PK on HISTORY filegroup. |
| 2 | ChangedBy | int | NO | - | CODE-BACKED | ManagerID of the BackOffice manager who authorized and executed the pool manager change. FK to BackOffice.Manager. 25 distinct values in data. Indexed by HBPM_CHANGER (nonclustered) for fast lookup of all changes made by a given manager. |
| 3 | Occurred | datetime | NO | - | CODE-BACKED | Local server timestamp of the assignment change (GETDATE(), NOT UTC). Marks when BackOffice.SetFTDPoolManager executed. Not UTC - correlate with UTC-based tables by accounting for server timezone. |
| 4 | Comment | varchar(255) | NO | - | CODE-BACKED | Mandatory free-text reason for the pool manager change. Written by the BackOffice user executing the assignment. Provides audit context for why the reassignment occurred (e.g., capacity balancing, customer request, manager departure). |
| 5 | CID | int | NO | - | CODE-BACKED | Customer ID of the customer whose FTD pool manager was changed. FK to BackOffice.Customer(CID). 32,691 distinct customers in data. The live assignment is stored in BackOffice.Customer.FTDPoolManagerID. |
| 6 | PoolManagerID | int | YES | - | CODE-BACKED | The NEW pool manager assigned to this customer (BackOffice.Manager.ManagerID). FK to BackOffice.Manager. Nullable in DDL but never NULL in practice (0 NULLs). 47 distinct pool managers. Top: ManagerID=85 (10,035 assignments, 9,724 customers), ManagerID=215 (3,895 assignments), ManagerID=63 (3,056 assignments). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer | FK (FK_BCST_BOPM) | The customer whose FTD pool manager assignment changed. |
| ChangedBy | BackOffice.Manager | FK (FK_BMNG_BOPM_CHANGER) | The BackOffice manager who made the change. |
| PoolManagerID | BackOffice.Manager | FK (FK_BMNG_BOPM_POOLM) | The new pool manager assigned to the customer. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.SetFTDPoolManager | INSERT | Writer | Sole writer - inserts one row per FTD pool manager change within a transaction that also updates BackOffice.Customer. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BackOfficeFTDPoolManager (table)
  - leaf node: no code-level dependencies
  - written by: BackOffice.SetFTDPoolManager
  - read by: (none discovered)
```

### 6.1 Objects This Depends On

No FK constraints enforced in this direction (FKs are on outgoing references).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SetFTDPoolManager | Stored Procedure | Writer - sole writer, atomically updates BackOffice.Customer and inserts history row in one transaction |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOfficeFTDPoolManager | CLUSTERED PK | PoolManagerHistoryID ASC | - | - | Active |
| HBPM_CHANGER | NONCLUSTERED | ChangedBy ASC | - | - | Active |

**HBPM_CHANGER index**: Supports fast lookup of all changes made by a specific BackOffice manager. Useful for auditing a manager's activity history (e.g., "all customers reassigned by manager X"). No index on CID - queries by customer require a scan, though the small table size (48K rows) makes this fast.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOfficeFTDPoolManager | PRIMARY KEY CLUSTERED | PoolManagerHistoryID |
| FK_BCST_BOPM | FOREIGN KEY | CID -> BackOffice.Customer(CID) |
| FK_BMNG_BOPM_CHANGER | FOREIGN KEY | ChangedBy -> BackOffice.Manager(ManagerID) |
| FK_BMNG_BOPM_POOLM | FOREIGN KEY | PoolManagerID -> BackOffice.Manager(ManagerID) |
| NOT FOR REPLICATION on PoolManagerHistoryID | Identity option | Independent IDENTITY per replica |

---

## 8. Sample Queries

### 8.1 Full assignment history for a customer
```sql
SELECT
    PoolManagerHistoryID,
    Occurred,
    ChangedBy,
    PoolManagerID,
    Comment
FROM History.BackOfficeFTDPoolManager WITH (NOLOCK)
WHERE CID = @CID
ORDER BY Occurred ASC;
```

### 8.2 All assignments by a specific BackOffice manager
```sql
SELECT
    b.CID,
    b.PoolManagerID,
    b.Occurred,
    b.Comment
FROM History.BackOfficeFTDPoolManager b WITH (NOLOCK)
WHERE b.ChangedBy = @ManagerID
ORDER BY b.Occurred DESC;
-- HBPM_CHANGER index used for ChangedBy filter
```

### 8.3 Pool manager workload summary
```sql
SELECT
    PoolManagerID,
    COUNT(*) AS TotalAssignments,
    COUNT(DISTINCT CID) AS UniqueCustomers,
    MIN(Occurred) AS FirstAssignment,
    MAX(Occurred) AS LastAssignment
FROM History.BackOfficeFTDPoolManager WITH (NOLOCK)
GROUP BY PoolManagerID
ORDER BY TotalAssignments DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.9/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BackOfficeFTDPoolManager | Type: Table | Source: etoro/etoro/History/Tables/History.BackOfficeFTDPoolManager.sql*
