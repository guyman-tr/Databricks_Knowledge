# Dictionary.ScheduledTaskReason

## 1. Business Meaning

**What it is**: A lookup table defining failure/outcome reasons for post-deposit scheduled tasks. When a task fails or completes with a specific condition, the reason is recorded for diagnostics and monitoring.

**Why it exists**: Post-deposit tasks (AppsFlyer, RabbitMQ FTD, Pixel, Mixpanel, DepositDR) can fail for various reasons — timeouts, internal errors, external service failures, or exhausted retry attempts. This table provides a standardized vocabulary for these outcomes, stored in `Billing.ScheduledTaskState.ReasonID` via `Billing.UpdateScheduledTaskState`.

**How it works**: When `Billing.UpdateScheduledTaskState` is called to update a task's state (typically to failure), an optional `@ReasonID` parameter specifies why. This enables monitoring systems to categorize and alert on failure patterns (e.g., repeated timeouts vs. external service outages).

---

## 2. Business Logic

### Failure/Outcome Reasons
| ID | Reason | Meaning |
|----|--------|---------|
| 1 | general | Generic unclassified failure |
| 2 | timeout | Task exceeded time limit — external service unresponsive |
| 3 | internal | Internal system error (application/database issue) |
| 4 | external | External service returned an error (AppsFlyer/Mixpanel API failure) |
| 5 | maxretry | Maximum retry attempts exhausted — task permanently failed |

### Escalation Pattern
```
Task fails → Reason: timeout (2) or external (4) → retry
    → Retries exhausted → Reason: maxretry (5) → permanent failure
    → Internal error → Reason: internal (3) → requires investigation
```

---

## 3. Data Overview

| ReasonID | Reason | Business Meaning |
|----------|--------|------------------|
| 1 | general | Unclassified failure |
| 2 | timeout | Time limit exceeded |
| 3 | internal | Internal system error |
| 4 | external | External service error |
| 5 | maxretry | All retries exhausted |

*5 rows — complete task failure reason enumeration*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **ReasonID** | int | NOT NULL | — | Primary key. Failure reason identifier: 1=general, 2=timeout, 3=internal, 4=external, 5=maxretry. | `MCP` |
| **Reason** | varchar(50) | NULL | — | Lowercase reason label for monitoring and alerting. Used in failure reporting dashboards. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | Column | Relationship | Business Meaning |
|-------------------|--------|--------------|------------------|
| Billing.ScheduledTaskState | ReasonID | Implicit FK | Records why a task entered its current state |
| Billing.UpdateScheduledTaskState | @ReasonID | Parameter | Sets the reason when updating task state |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Billing.ScheduledTaskState` — stores reason per deposit-task combination
- `Billing.UpdateScheduledTaskState` — sets reason during state transitions

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `ReasonID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Fill Factor | 95% |
| Row Count | 5 |

---

## 8. Sample Queries

```sql
-- Get all task failure reasons
SELECT  ReasonID, Reason
FROM    Dictionary.ScheduledTaskReason WITH (NOLOCK)
ORDER BY ReasonID;

-- Failure distribution by reason
SELECT  TR.Reason, COUNT(*) AS FailureCount
FROM    Billing.ScheduledTaskState TS WITH (NOLOCK)
JOIN    Dictionary.ScheduledTaskReason TR WITH (NOLOCK) ON TR.ReasonID = TS.ReasonID
WHERE   TS.TaskState = 2
GROUP BY TR.Reason
ORDER BY FailureCount DESC;

-- Tasks stuck after max retries
SELECT  TN.TaskName, TS.DepositID, TS.Created
FROM    Billing.ScheduledTaskState TS WITH (NOLOCK)
JOIN    Dictionary.ScheduledTaskName TN WITH (NOLOCK) ON TN.TaskID = TS.TaskID
WHERE   TS.ReasonID = 5
ORDER BY TS.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Task failure reasons are an operational monitoring feature of the billing scheduled task system.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (5 rows), codebase traced (Billing.ScheduledTaskState + UpdateScheduledTaskState)*
