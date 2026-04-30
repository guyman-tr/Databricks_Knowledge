# Scheduler.DD_Alert_StuckWithNotValidStatus

> Detects executions that have been picked up for processing but remain stuck in a non-terminal status, returning a count and earliest offender for DataDog alerting.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of stuck executions and the first stuck ExecutionId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.DD_Alert_StuckWithNotValidStatus is an operational health-check procedure that detects executions which have been picked up (ActualExecutionDate is set) but have not reached a terminal state within the expected time window. Unlike DD_Alert_PlanedDatePassed_NotTaken which watches for unclaimed work, this procedure monitors work that is in-flight but appears stuck - the execution was claimed by a worker but never completed.

This alert is critical because an execution that has been picked up but not finalized to [Done](_glossary.md#execution-status) (6) or [Canceled](_glossary.md#execution-status) (4) indicates a processing failure in the RecurringScheduler worker or a downstream system. The customer's money movement is in limbo - neither completed nor properly failed. This could mean a worker crashed mid-processing, a message was lost, or an external billing provider never responded.

The procedure checks a configurable time window: it looks at executions whose ActualExecutionDate falls between @FromDate (default 2 days ago) and @ToDate (default 30 minutes ago). The lower bound prevents scanning ancient history, while the upper bound gives freshly-claimed executions reasonable time to complete. It uses NOLOCK for monitoring performance and returns results in DataDog's expected format.

---

## 2. Business Logic

### 2.1 Stuck Execution Detection

**What**: Identifies executions that were claimed by a worker (ActualExecutionDate is set) but remain in a non-terminal status after the expected processing window.

**Columns/Parameters Involved**: `ActualExecutionDate`, `ExecutionStatusId`, `@MinutsToAlert`, `@GapInDays`, `@FromDate`, `@ToDate`

**Rules**:
- ActualExecutionDate must NOT be NULL - the execution was picked up by a worker
- ActualExecutionDate must fall BETWEEN @FromDate and @ToDate
- @FromDate defaults to GETUTCDATE() minus @GapInDays (default 2 days) - ignores older history
- @ToDate defaults to GETUTCDATE() minus @MinutsToAlert (default 30 minutes) - gives recent claims time to finish
- ExecutionStatusId must NOT be 6 (Done) or 4 (Canceled) - these are terminal states
- Any status other than Done/Canceled with an ActualExecutionDate in the window is considered "stuck"
- Stuck statuses include: 1=Planned, 2=WaitingForProcess, 3=Sent, 5=Failed

### 2.2 DataDog Result Format

**What**: Returns a single-row result set compatible with DataDog custom metric ingestion.

**Columns/Parameters Involved**: `value` (count), `FirstStuckExecution` (diagnostic ID)

**Rules**:
- Always returns exactly one row via the OUTER APPLY / dummy VALUES pattern
- If no stuck executions exist, returns value = 0 and FirstStuckExecution = NULL
- If stuck executions exist, returns the total count and the MIN(ExecutionId) for investigation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinutsToAlert | int (IN) | NO | 30 | CODE-BACKED | Minutes before current UTC time to use as the upper bound. Executions claimed more recently than this are not yet considered stuck - they may still be processing normally. |
| 2 | @GapInDays | int (IN) | NO | 2 | CODE-BACKED | Number of days back from current UTC time to use as the lower bound. Limits the scan window so older historical records are not flagged. |
| 3 | @FromDate | datetime (IN) | YES | NULL | CODE-BACKED | Explicit lower bound override. When NULL, defaults to GETUTCDATE() minus @GapInDays. Allows callers to specify a custom scan window. |
| 4 | @ToDate | datetime (IN) | YES | NULL | CODE-BACKED | Explicit upper bound override. When NULL, defaults to GETUTCDATE() minus @MinutsToAlert. Allows callers to specify a custom scan window. |
| 5 | value | int (OUT) | NO | 0 | CODE-BACKED | Count of stuck executions within the time window. Zero means healthy; any positive value triggers a DataDog alert. |
| 6 | FirstStuckExecution | int (OUT) | YES | NULL | CODE-BACKED | The smallest ExecutionId among stuck executions. NULL when none are stuck. Used for targeted investigation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Scheduler.Execution | Direct Read | Scans for executions with ActualExecutionDate set but non-terminal status |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| DataDog monitoring | External | Scheduled DataDog synthetic or custom check that polls this SP on an interval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.DD_Alert_StuckWithNotValidStatus (procedure)
└── Scheduler.Execution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | READER - scans for executions stuck in non-terminal status after being claimed |

### 6.2 Objects That Depend On This

No database dependents. Called by DataDog monitoring infrastructure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run with default parameters (30-minute grace, 2-day lookback)
```sql
EXEC Scheduler.DD_Alert_StuckWithNotValidStatus;
```

### 8.2 Run with a tighter 15-minute grace period and 1-day lookback
```sql
EXEC Scheduler.DD_Alert_StuckWithNotValidStatus
    @MinutsToAlert = 15,
    @GapInDays = 1;
```

### 8.3 Manually inspect the stuck executions this alert would flag
```sql
SELECT e.ExecutionId, e.PlanId, e.ExecutionStatusId, e.ActualExecutionDate, e.Stamp
FROM Scheduler.Execution e WITH (NOLOCK)
WHERE e.ActualExecutionDate IS NOT NULL
  AND e.ActualExecutionDate BETWEEN DATEADD(DAY, -2, GETUTCDATE())
                                AND DATEADD(MINUTE, -30, GETUTCDATE())
  AND e.ExecutionStatusId NOT IN (4, 6)
ORDER BY e.ExecutionId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.DD_Alert_StuckWithNotValidStatus | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.DD_Alert_StuckWithNotValidStatus.sql*
