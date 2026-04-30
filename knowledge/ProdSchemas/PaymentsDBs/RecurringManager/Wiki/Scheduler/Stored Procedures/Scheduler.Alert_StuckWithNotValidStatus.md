# Scheduler.Alert_StuckWithNotValidStatus

> Monitoring procedure that detects executions stuck in non-terminal status (not Done or Canceled) for longer than expected after being picked up for processing, indicating a pipeline failure.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of stuck executions and the first stuck ExecutionId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.Alert_StuckWithNotValidStatus is a health-monitoring procedure that detects executions that were picked up for processing (ActualExecutionDate is set) but never reached a terminal state (Done=6 or Canceled=4). These "stuck" executions indicate a failure in the processing pipeline - the worker claimed the execution but never completed it, potentially due to crashes, timeouts, or downstream billing provider failures.

This procedure exists because the stamping mechanism in GetExecutionsToProcessWithLock moves executions from Planned to WaitingForProcess, but if the worker crashes after stamping, those executions remain in a non-terminal state indefinitely. Without this alert, stuck executions would be invisible and the affected users' recurring charges would silently fail.

Called on a monitoring schedule. The procedure looks back over a configurable date range for executions with ActualExecutionDate set but still in a non-terminal status after @MinutsToAlert minutes. Returns count and earliest stuck ExecutionId, with RETURN 0/1 for binary health check.

---

## 2. Business Logic

### 2.1 Stuck Execution Detection

**What**: Identifies executions that were claimed by a worker but never completed within the expected timeframe.

**Columns/Parameters Involved**: `@MinutsToAlert`, `@GapInDays`, `@FromDate`, `@ToDate`, `ActualExecutionDate`, `ExecutionStatusId`

**Rules**:
- An execution is "stuck" when: (1) ActualExecutionDate IS NOT NULL (was picked up), (2) ActualExecutionDate is between @FromDate and @ToDate (within the lookback window), (3) ExecutionStatusId NOT IN (6=Done, 4=Canceled)
- Default lookback: from 2 days ago to 30 minutes ago - gives executions 30 minutes to complete before alerting
- @FromDate/@ToDate can override the default window for custom investigations
- RETURN 0 = no stuck executions, RETURN 1 = alert condition

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinutsToAlert | int (IN) | NO | 30 | CODE-BACKED | Minutes to wait after an execution is picked up before considering it stuck. Default 30 minutes. Accounts for normal billing provider round-trip time. |
| 2 | @GapInDays | int (IN) | NO | 2 | CODE-BACKED | How many days back to look for stuck executions. Default 2 days. Limits the scan window to avoid checking very old records. |
| 3 | @FromDate | datetime (IN) | YES | NULL | CODE-BACKED | Optional override for the lookback start date. When NULL, defaults to DATEADD(DAY, -@GapInDays, GETUTCDATE()). |
| 4 | @ToDate | datetime (IN) | YES | NULL | CODE-BACKED | Optional override for the lookback end date. When NULL, defaults to DATEADD(MINUTE, -@MinutsToAlert, GETUTCDATE()). |
| 5 | StuckExecutions | int (OUTPUT) | - | - | CODE-BACKED | Count of executions in the lookback window that have not reached Done or Canceled status. |
| 6 | FirstStuckExecution | int (OUTPUT) | - | - | CODE-BACKED | Lowest ExecutionId among stuck executions for investigation starting point. |
| 7 | RETURN | int (RETURN) | - | - | CODE-BACKED | Binary health indicator: 0 = healthy, 1 = stuck executions detected. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | Scheduler.Execution | Direct Read | Queries Execution table filtering by ActualExecutionDate and ExecutionStatusId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by external monitoring systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.Alert_StuckWithNotValidStatus (procedure)
└── Scheduler.Execution (table)
    └── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | READER - queries for stuck executions by ActualExecutionDate and status |

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

### 8.1 Check for stuck executions with defaults
```sql
DECLARE @Result INT;
EXEC @Result = Scheduler.Alert_StuckWithNotValidStatus;
SELECT @Result AS AlertTriggered;
```

### 8.2 Custom lookback window for investigation
```sql
DECLARE @Result INT;
EXEC @Result = Scheduler.Alert_StuckWithNotValidStatus
    @FromDate = '2026-04-15 00:00:00',
    @ToDate = '2026-04-16 00:00:00';
```

### 8.3 Manually inspect what the alert would find
```sql
SELECT e.ExecutionId, es.Name AS Status, e.ActualExecutionDate, e.Stamp
FROM Scheduler.Execution e WITH (NOLOCK)
JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON e.ExecutionStatusId = es.ExecutionStatusID
WHERE e.ActualExecutionDate IS NOT NULL
  AND e.ActualExecutionDate BETWEEN DATEADD(DAY, -2, GETUTCDATE()) AND DATEADD(MINUTE, -30, GETUTCDATE())
  AND e.ExecutionStatusId NOT IN (4, 6);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.1/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.Alert_StuckWithNotValidStatus | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.Alert_StuckWithNotValidStatus.sql*
