# Dictionary.ScheduledTaskName

## 1. Business Meaning

**What it is**: A lookup table identifying post-deposit scheduled tasks that run after a deposit is processed. Each entry represents a specific integration or notification pipeline that must execute as part of deposit completion.

**Why it exists**: When a deposit is processed by the billing system, several downstream tasks must execute — sending data to AppsFlyer for attribution, publishing FTD (First Time Deposit) events to RabbitMQ, firing tracking pixels, sending events to Mixpanel, and processing deposit dispute resolution. This table names each of those tasks so the `Billing.ScheduledTaskState` table can track their execution per deposit.

**How it works**: The `Billing.ScheduledTaskState` table has a composite key of `(DepositID, TaskID)`. When a deposit is created (via `Billing.DepositAdd`), task state records are initialized for each applicable task. Billing procedures like `Billing.GetScheduledTaskAppsFlyerEntities`, `Billing.GetScheduledTaskRabbitMqFtdEntities`, `Billing.GetScheduledTaskPixelEntities`, etc., query for deposits where their specific TaskID has `TaskState = 0` (new/pending) to find work items.

---

## 2. Business Logic

### Post-Deposit Task Types
| ID | Task | Purpose |
|----|------|---------|
| 1 | AppsFlyer | Send deposit event to AppsFlyer for mobile attribution/conversion tracking |
| 2 | RabbitMqFtd | Publish First Time Deposit event to RabbitMQ for downstream consumers |
| 3 | DepositPixel | Fire conversion tracking pixel for marketing/advertising attribution |
| 4 | MixPanel | Send deposit event to Mixpanel for product analytics |
| 5 | DepositDR | Process deposit dispute resolution workflow |

### Task Execution Flow
```
Billing.DepositAdd → creates Billing.ScheduledTaskState rows (TaskState=0)
    → Billing.GetScheduledTask{Name}Entities → finds pending tasks (TaskState=0)
    → External system processes event
    → Billing.UpdateScheduledTaskState → sets TaskState=1 (success) or 2 (failure)
```

---

## 3. Data Overview

| TaskID | TaskName | Business Meaning |
|--------|----------|------------------|
| 1 | AppsFlyer | Mobile attribution deposit event |
| 2 | RabbitMqFtd | First Time Deposit message queue event |
| 3 | DepositPixel | Marketing conversion pixel firing |
| 4 | MixPanel | Product analytics deposit event |
| 5 | DepositDR | Deposit dispute resolution processing |

*5 rows — all post-deposit scheduled task types*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **TaskID** | int | NOT NULL | — | Primary key. Scheduled task identifier: 1=AppsFlyer, 2=RabbitMqFtd, 3=DepositPixel, 4=MixPanel, 5=DepositDR. Used as part of composite key in `Billing.ScheduledTaskState`. | `MCP+CODE` |
| **TaskName** | varchar(50) | NULL | — | Human-readable task name identifying the external integration or processing pipeline. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | Column | Relationship | Business Meaning |
|-------------------|--------|--------------|------------------|
| Billing.ScheduledTaskState | TaskID | Implicit FK | Tracks task execution state per deposit |
| Billing.GetScheduledTaskAppsFlyerEntities | TaskID | WHERE clause | Finds pending AppsFlyer tasks (TaskID=1) |
| Billing.GetScheduledTaskRabbitMqFtdEntities | TaskID | WHERE clause | Finds pending RabbitMQ FTD tasks (TaskID=2) |
| Billing.GetScheduledTaskPixelEntities | TaskID | WHERE clause | Finds pending pixel tasks (TaskID=3) |
| Billing.GetScheduledTaskMixpanelEventEntities | TaskID | WHERE clause | Finds pending Mixpanel tasks (TaskID=4) |
| Billing.GetScheduledTaskDepositEntities | TaskID | WHERE clause | Finds pending deposit DR tasks |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Billing.ScheduledTaskState` — per-deposit task tracking
- 6+ Billing procedures — per-task entity retrieval

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `TaskID` (clustered, page compressed) |
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
-- Get all scheduled task types
SELECT  TaskID, TaskName
FROM    Dictionary.ScheduledTaskName WITH (NOLOCK)
ORDER BY TaskID;

-- Count pending tasks by type
SELECT  TN.TaskName, COUNT(*) AS PendingCount
FROM    Billing.ScheduledTaskState TS WITH (NOLOCK)
JOIN    Dictionary.ScheduledTaskName TN WITH (NOLOCK) ON TN.TaskID = TS.TaskID
WHERE   TS.TaskState = 0
GROUP BY TN.TaskName;

-- Find failed tasks with reasons
SELECT  TN.TaskName, TR.Reason, COUNT(*) AS FailedCount
FROM    Billing.ScheduledTaskState TS WITH (NOLOCK)
JOIN    Dictionary.ScheduledTaskName TN WITH (NOLOCK) ON TN.TaskID = TS.TaskID
LEFT JOIN Dictionary.ScheduledTaskReason TR WITH (NOLOCK) ON TR.ReasonID = TS.ReasonID
WHERE   TS.TaskState = 2
GROUP BY TN.TaskName, TR.Reason;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Post-deposit task scheduling is a billing infrastructure feature supporting marketing attribution and event distribution.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (5 rows), codebase traced (6+ procedure consumers, Billing.ScheduledTaskState relationship mapped)*
