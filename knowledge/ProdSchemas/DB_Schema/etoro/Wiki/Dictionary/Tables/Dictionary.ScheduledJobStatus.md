# Dictionary.ScheduledJobStatus

## 1. Business Meaning

**What it is**: A lookup table defining the execution status of BackOffice scheduled jobs. Each value represents a state in the job execution lifecycle — running, completed, or failed.

**Why it exists**: eToro's BackOffice scheduler runs automated tasks (API calls, queue processing, internal jobs) on cron schedules. Each execution is logged in `BackOffice.ScheduledJobHistory` with a status ID from this table, enabling monitoring dashboards to track job health and alerting on failures.

**How it works**: When a scheduled job starts, a history record is created with `StatusID = 1` (Running). Upon completion, the status is updated to `2` (Completed) or `3` (Failed) with optional exception details. The `BackOffice.ScheduledJobHistory` table has an explicit FK to this lookup.

---

## 2. Business Logic

### Job Execution States
| ID | Status | Meaning |
|----|--------|---------|
| 1 | Running | Job is currently executing |
| 2 | Completed | Job finished successfully |
| 3 | Failed | Job encountered an error (exception logged in history) |

### Lifecycle Flow
```
Running (1) → Completed (2) [success]
Running (1) → Failed (3) [error — exception stored in ScheduledJobHistory.Exception]
```

---

## 3. Data Overview

| ScheduledJobStatusID | ScheduledJobStatusName | Business Meaning |
|---------------------|----------------------|------------------|
| 1 | Running | Job currently executing |
| 2 | Completed | Job finished successfully |
| 3 | Failed | Job encountered an error |

*3 rows — complete job execution status enumeration*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **ScheduledJobStatusID** | int | NOT NULL | — | Primary key. Job execution status: 1=Running, 2=Completed, 3=Failed. | `MCP` |
| **ScheduledJobStatusName** | varchar(50) | NOT NULL | — | Human-readable status label for monitoring dashboards and job history reports. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| BackOffice.ScheduledJobHistory | StatusID | FK_BackOffice.ScheduledJob_Dictionary.ScheduledJobStatus | Each job execution record has an execution status |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `BackOffice.ScheduledJobHistory` — job execution history with explicit FK

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `ScheduledJobStatusID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Row Count | 3 |

---

## 8. Sample Queries

```sql
-- Get all job statuses
SELECT  ScheduledJobStatusID, ScheduledJobStatusName
FROM    Dictionary.ScheduledJobStatus WITH (NOLOCK)
ORDER BY ScheduledJobStatusID;

-- Recent job failures with exception details
SELECT  JH.JobHistoryID, J.JobName, JH.StartDate, JH.EndDate, JH.Exception
FROM    BackOffice.ScheduledJobHistory JH WITH (NOLOCK)
JOIN    BackOffice.ScheduledJob J WITH (NOLOCK) ON J.JobID = JH.JobID
WHERE   JH.StatusID = 3
ORDER BY JH.StartDate DESC;

-- Job execution summary by status
SELECT  S.ScheduledJobStatusName, COUNT(*) AS ExecutionCount
FROM    BackOffice.ScheduledJobHistory JH WITH (NOLOCK)
JOIN    Dictionary.ScheduledJobStatus S WITH (NOLOCK) ON S.ScheduledJobStatusID = JH.StatusID
GROUP BY S.ScheduledJobStatusName;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. The scheduled job framework is an internal BackOffice infrastructure component.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (3 rows), codebase traced (1 FK consumer: BackOffice.ScheduledJobHistory)*
