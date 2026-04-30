# Scheduler.Alert_PlanedDatePassed_NotTaken

> Monitoring procedure that detects executions whose PlannedDate has passed but have not been picked up for processing, indicating a potential scheduling backlog or worker failure.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of unprocessed executions and the first unprocessed ExecutionId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.Alert_PlanedDatePassed_NotTaken is a health-monitoring stored procedure that checks for executions that should have been processed but were not claimed by any worker instance. When a recurring execution's PlannedDate passes and it remains in Planned status (1) with no Stamp, it means the RecurringScheduler worker either missed it, is down, or is backlogged beyond the acceptable threshold.

This procedure exists to power alerting systems (e.g., Splunk, monitoring dashboards) that notify the operations team when the scheduling pipeline is falling behind. Without it, unprocessed executions could accumulate silently, causing missed recurring charges and degraded user experience.

Called on a monitoring schedule (e.g., every few minutes by an alerting framework). The procedure checks if any Planned executions have a PlannedDate older than @GapInHours hours ago and are still unclaimed (Stamp IS NULL). If found, it returns the count and the earliest ExecutionId for investigation. The RETURN value (0 or 1) provides a simple binary health check: 0 = healthy, 1 = alert.

---

## 2. Business Logic

### 2.1 Unprocessed Execution Detection

**What**: Identifies executions that are overdue for processing based on a configurable time gap.

**Columns/Parameters Involved**: `@GapInHours`, `PlannedDate`, `ExecutionStatusId`, `Stamp`

**Rules**:
- An execution is considered "unprocessed" when ALL three conditions are true: (1) PlannedDate is older than @GapInHours hours ago, (2) ExecutionStatusId = 1 (Planned), (3) Stamp IS NULL (unclaimed)
- Default gap is 2 hours - executions are expected to be picked up within 2 hours of their PlannedDate
- The HAVING COUNT > 0 ensures the result set is empty (no rows) when everything is healthy
- RETURN 0 = no unprocessed executions (healthy), RETURN 1 = alert condition

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GapInHours | int (IN) | NO | 2 | CODE-BACKED | Threshold in hours for how long past the PlannedDate an execution can remain unprocessed before triggering an alert. Default 2 hours. Larger values tolerate more latency; smaller values alert sooner. |
| 2 | UnprocessedExecutions | int (OUTPUT) | - | - | CODE-BACKED | Count of executions matching the alert criteria. Only returned when count > 0 (HAVING clause). Zero-count results produce no output rows - the caller checks @@ROWCOUNT or RETURN value. |
| 3 | FirstUnprocessedExecution | int (OUTPUT) | - | - | CODE-BACKED | The lowest ExecutionId among unprocessed executions (MIN). Provides a starting point for investigation. |
| 4 | RETURN | int (RETURN) | - | - | CODE-BACKED | Binary health indicator: 0 = all executions are being processed within the gap threshold, 1 = at least one execution is overdue. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | Scheduler.Execution | Direct Read | Queries Execution table filtering by PlannedDate, ExecutionStatusId, and Stamp |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely called by monitoring/alerting infrastructure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.Alert_PlanedDatePassed_NotTaken (procedure)
└── Scheduler.Execution (table)
    └── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | READER - queries for unprocessed executions |

### 6.2 Objects That Depend On This

No dependents found. Called by external monitoring systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check for unprocessed executions with default 2-hour gap
```sql
DECLARE @Result INT;
EXEC @Result = Scheduler.Alert_PlanedDatePassed_NotTaken;
SELECT @Result AS AlertTriggered; -- 0 = healthy, 1 = alert
```

### 8.2 Check with a custom 4-hour gap for less sensitive alerting
```sql
DECLARE @Result INT;
EXEC @Result = Scheduler.Alert_PlanedDatePassed_NotTaken @GapInHours = 4;
SELECT @Result AS AlertTriggered;
```

### 8.3 Manually inspect what the alert would find
```sql
SELECT COUNT(e.ExecutionId) AS UnprocessedExecutions, MIN(e.ExecutionId) AS FirstUnprocessedExecution
FROM Scheduler.Execution e WITH (NOLOCK)
WHERE e.PlannedDate < DATEADD(HOUR, -2, GETUTCDATE())
  AND e.ExecutionStatusId = 1
  AND e.Stamp IS NULL
HAVING COUNT(e.ExecutionId) > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.1/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.Alert_PlanedDatePassed_NotTaken | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.Alert_PlanedDatePassed_NotTaken.sql*
