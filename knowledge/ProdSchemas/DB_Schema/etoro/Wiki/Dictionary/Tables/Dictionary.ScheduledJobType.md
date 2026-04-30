# Dictionary.ScheduledJobType

## 1. Business Meaning

**What it is**: A lookup table classifying BackOffice scheduled jobs by their execution mechanism. Each type represents a different way the job scheduler invokes the job — via HTTP API call, message queue, or internal direct execution.

**Why it exists**: eToro's BackOffice scheduler supports multiple invocation patterns for automated tasks. Jobs can call external APIs, enqueue work items for asynchronous processing, or execute internal methods directly. This classification determines how the scheduler dispatches each job and which infrastructure path the execution follows.

**How it works**: When defining a scheduled job in `BackOffice.ScheduledJob`, the `ScheduledJobTypeID` is set to indicate the execution mechanism. The job scheduler reads this type to determine whether to make an HTTP call (ApiJob), publish to a queue (InQueueJob), or call an internal method directly (InternalJob). The job's `Uri`, `MethodName`, and `Parameters` columns are interpreted differently based on the type.

---

## 2. Business Logic

### Job Execution Mechanisms
| ID | Type | Meaning |
|----|------|---------|
| 1 | ApiJob | Executes via HTTP API call — the `Uri` field contains the endpoint, `MethodName` is the API action |
| 2 | InQueueJob | Publishes a message to a processing queue — work is executed asynchronously by a queue consumer |
| 3 | InternalJob | Executes an internal method directly — the `MethodName` is called within the scheduler process |

---

## 3. Data Overview

| ScheduledJobTypeID | ScheduledJobType | Business Meaning |
|-------------------|-----------------|------------------|
| 1 | ApiJob | HTTP API-based job invocation |
| 2 | InQueueJob | Queue-based async job invocation |
| 3 | InternalJob | Direct internal method invocation |

*3 rows — complete job execution type enumeration*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **ScheduledJobTypeID** | int | NOT NULL | — | Primary key. Job type identifier: 1=ApiJob, 2=InQueueJob, 3=InternalJob. | `MCP` |
| **ScheduledJobType** | varchar(50) | NULL | — | Human-readable label for the job execution mechanism. Used in job configuration UI and monitoring. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| BackOffice.ScheduledJob | ScheduledJobTypeID | FK_BackOffice.ScheduledJob_Dictionary.ScheduledJobType | Each scheduled job definition has an execution type |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `BackOffice.ScheduledJob` — scheduled job definitions with explicit FK

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `ScheduledJobTypeID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Row Count | 3 |

---

## 8. Sample Queries

```sql
-- Get all job types
SELECT  ScheduledJobTypeID, ScheduledJobType
FROM    Dictionary.ScheduledJobType WITH (NOLOCK)
ORDER BY ScheduledJobTypeID;

-- Count active jobs by type
SELECT  JT.ScheduledJobType, COUNT(*) AS ActiveJobs
FROM    BackOffice.ScheduledJob J WITH (NOLOCK)
JOIN    Dictionary.ScheduledJobType JT WITH (NOLOCK) ON JT.ScheduledJobTypeID = J.ScheduledJobTypeID
WHERE   J.IsActive = 1
GROUP BY JT.ScheduledJobType;

-- List all API jobs with their URIs
SELECT  J.JobName, J.Uri, J.MethodName, J.Cron
FROM    BackOffice.ScheduledJob J WITH (NOLOCK)
WHERE   J.ScheduledJobTypeID = 1 AND J.IsActive = 1
ORDER BY J.JobName;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. The BackOffice scheduler is an internal job orchestration system.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (3 rows), codebase traced (1 FK consumer: BackOffice.ScheduledJob)*
