# dbo.UsersForEnrollment

> Batch operation table tracking customers queued for program enrollment processing, with a StatusID tracking whether enrollment has been processed (1) or completed (2).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

dbo.UsersForEnrollment is a batch operation table that tracks customers who are queued for enrollment in one or more optional programs (likely FPSL, crypto staking, etc.). The table contains ~375K customers with a simple two-state workflow: StatusID=1 (queued/pending, 96%) and StatusID=2 (completed, 4%).

This table likely supports a batch enrollment job that processes customers in bulk. The job reads StatusID=1 records, enrolls the customer in the applicable program via Apex.SaveUserProgramEnrolment or similar, then updates StatusID to 2. The table persists after processing for audit/reconciliation.

---

## 2. Business Logic

### 2.1 Two-State Processing Workflow

**What**: Simple batch processing tracker with queued and completed states.

**Columns/Parameters Involved**: `GCID`, `StatusID`

**Rules**:
- StatusID=0 (default): Newly inserted, not yet picked up
- StatusID=1: Queued for enrollment processing (~361K, 96%)
- StatusID=2: Enrollment completed (~14K, 4%)
- One row per customer (GCID is PK)

---

## 3. Data Overview

| GCID | StatusID | Meaning |
|------|----------|---------|
| 43062915 | 1 | Customer queued for enrollment processing. Has not yet been processed by the enrollment batch job. |
| (various) | 2 | Customer whose enrollment has been completed. Kept for audit/reconciliation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Primary key. One enrollment queue entry per customer. |
| 2 | StatusID | int | NO | 0 | CODE-BACKED | Processing status: 0=new (default), 1=queued for processing (~96% of rows), 2=enrollment completed (~4%). Not an FK to Dictionary.ApexStatus - this is a simple processing state internal to this table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

No objects reference this table. Used by batch jobs/scripts directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. Consumed by external batch processing.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UsersForEnrollment | CLUSTERED PK | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UsersForEnrollment | PRIMARY KEY | Clustered on GCID |
| (unnamed) | DEFAULT | StatusID defaults to 0 for new entries |

---

## 8. Sample Queries

### 8.1 Count by processing status

```sql
SELECT StatusID, COUNT(*) AS UserCount
FROM dbo.UsersForEnrollment WITH (NOLOCK)
GROUP BY StatusID ORDER BY StatusID;
```

### 8.2 Get unprocessed users

```sql
SELECT GCID FROM dbo.UsersForEnrollment WITH (NOLOCK)
WHERE StatusID = 1
ORDER BY GCID;
```

### 8.3 Cross-reference with Apex account data

```sql
SELECT e.GCID, e.StatusID AS EnrollStatus, d.ApexID, s.Name AS AccountStatus
FROM dbo.UsersForEnrollment e WITH (NOLOCK)
INNER JOIN Apex.ApexData d WITH (NOLOCK) ON d.GCID = e.GCID
INNER JOIN Dictionary.ApexStatus s WITH (NOLOCK) ON s.StatusID = d.StatusID
WHERE e.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.UsersForEnrollment | Type: Table | Source: USABroker/dbo/Tables/dbo.UsersForEnrollment.sql*
