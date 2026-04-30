# Dictionary.ScheduledTaskState

## 1. Business Meaning

**What it is**: A lookup table defining the execution states for post-deposit scheduled tasks. Tracks whether a task for a given deposit is new, in-process, completed, failed, or excluded from processing.

**Why it exists**: The billing system tracks multiple post-deposit tasks (AppsFlyer, RabbitMQ FTD, Pixel, Mixpanel, DepositDR) per deposit in `Billing.ScheduledTaskState`. Each task transitions through states as it's picked up, processed, and completed. This dictionary provides the state vocabulary. The PK column name (`PostDepositTaskStateID`) reveals the original design — these are specifically post-deposit task states.

**How it works**: When a deposit is created, task state rows are initialized at state 0 (new). Worker processes query for `TaskState = 0` to find pending work. Tasks move to `3` (inprocess) during execution, then to `1` (success) or `2` (failure) upon completion. State `4` (noprocess) marks tasks that should be skipped (e.g., deposit doesn't qualify for pixel tracking).

---

## 2. Business Logic

### Task States
| ID | Name | Meaning |
|----|------|---------|
| 0 | new | Task created, waiting to be picked up |
| 1 | success | Task completed successfully |
| 2 | failure | Task failed (reason stored in ScheduledTaskReason) |
| 3 | inprocess | Task currently being processed by a worker |
| 4 | noprocess | Task skipped — deposit doesn't qualify for this task |

### State Transitions
```
new (0) → inprocess (3) → success (1)
                         → failure (2) [with ReasonID]
new (0) → noprocess (4) [task not applicable for this deposit]
```

### Index Optimization
The `Billing.ScheduledTaskState` table has a filtered nonclustered index and a filtered columnstore index both targeting `TaskState = 0`, reflecting that the most common query pattern is finding pending tasks. The columnstore index is further filtered to `TaskID = 1` (AppsFlyer), indicating it's the highest-volume task.

---

## 3. Data Overview

| PostDepositTaskStateID | Name | Business Meaning |
|------------------------|------|------------------|
| 0 | new | Pending — waiting for processing |
| 1 | success | Completed successfully |
| 2 | failure | Failed (reason tracked separately) |
| 3 | inprocess | Currently being processed |
| 4 | noprocess | Skipped — not applicable |

*5 rows — complete post-deposit task state enumeration*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **PostDepositTaskStateID** | int | NOT NULL | — | Primary key. Task execution state: 0=new, 1=success, 2=failure, 3=inprocess, 4=noprocess. The PK name reveals its origin as a post-deposit tracking feature. Maps to `Billing.ScheduledTaskState.TaskState`. | `MCP+CODE` |
| **Name** | varchar(20) | NULL | — | Lowercase state label used in monitoring and diagnostic queries. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | Column | Relationship | Business Meaning |
|-------------------|--------|--------------|------------------|
| Billing.ScheduledTaskState | TaskState | Implicit FK (no DDL constraint) | Tracks task execution state per deposit |
| Billing.UpdateScheduledTaskState | @TaskState | Parameter | Updates task state during processing |
| Billing.DeleteScheduledTaskState | — | Procedure | Cleans up completed/failed task records |
| Billing.GetScheduledTask*Entities | TaskState | WHERE clause (=0) | 6+ procedures query for pending tasks |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Billing.ScheduledTaskState` — per-deposit task state tracking
- `Billing.UpdateScheduledTaskState` — state transition procedure
- `Billing.DeleteScheduledTaskState` — cleanup procedure
- 6+ `Billing.GetScheduledTask*Entities` procedures — pending task retrieval

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `PostDepositTaskStateID` (clustered, page compressed) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Fill Factor | 95% |
| Compression | PAGE |
| Row Count | 5 |

---

## 8. Sample Queries

```sql
-- Get all task states
SELECT  PostDepositTaskStateID, Name
FROM    Dictionary.ScheduledTaskState WITH (NOLOCK)
ORDER BY PostDepositTaskStateID;

-- Task state distribution across all deposits
SELECT  TS2.Name AS TaskState, COUNT(*) AS TaskCount
FROM    Billing.ScheduledTaskState TS WITH (NOLOCK)
JOIN    Dictionary.ScheduledTaskState TS2 WITH (NOLOCK) ON TS2.PostDepositTaskStateID = TS.TaskState
GROUP BY TS2.Name
ORDER BY TaskCount DESC;

-- Find deposits with all tasks completed successfully
SELECT  DepositID
FROM    Billing.ScheduledTaskState WITH (NOLOCK)
GROUP BY DepositID
HAVING  MIN(TaskState) = 1 AND MAX(TaskState) = 1;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Post-deposit task state management is a billing infrastructure feature for tracking marketing attribution and event distribution pipelines.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (5 rows), codebase traced (Billing.ScheduledTaskState + 8 procedure consumers, index optimization documented)*
