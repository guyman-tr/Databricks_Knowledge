# Recurring.Alert_NotTakenPaymentExecutions

> Monitoring alert that detects payment executions stuck in Planned status after the scheduler sent them for processing, indicating the execution pipeline failed to pick them up.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of stuck executions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This alert detects execution pipeline failures: when the scheduler marks an execution as sent (Scheduler.Execution.ExecutionStatusId=3, Sent) but the payment execution remains in Planned status (PaymentExecution.StatusId=1). This means the scheduler dispatched the work but the recurring execution service never picked it up or failed silently.

Joins Scheduler.Execution to Recurring.PaymentExecution. Configurable time window (default: 30 minutes to 2 days). RETURN 1 if stuck executions found.

---

## 2. Business Logic

### 2.1 Stuck Execution Detection

**What**: Finds executions where the scheduler sent the job but the payment execution never progressed past Planned.

**Columns/Parameters Involved**: `@MinutsToAlert`, `@GapInDays`, Scheduler.Execution.`ExecutionStatusId`, PaymentExecution.`StatusId`

**Rules**:
- JOIN Scheduler.Execution ON PaymentExecutionId
- Scheduler.Execution.ExecutionStatusId = 3 (Sent) AND PaymentExecution.StatusId = 1 (Planned)
- Filters by Scheduler.Execution.ActualExecutionDate within time window
- Returns (StuckExecutions count, FirstStuckExecution ID)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinutsToAlert | int (IN) | NO | 30 | CODE-BACKED | Minutes threshold - executions sent more than N minutes ago that are still Planned. |
| 2 | @GapInDays | int (IN) | NO | 2 | CODE-BACKED | How many days back to search. |
| 3 | @FromDate | datetime (IN) | YES | NULL | CODE-BACKED | Override start of search window. |
| 4 | @ToDate | datetime (IN) | YES | NULL | CODE-BACKED | Override end of search window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecution | READER | Checks StatusId = 1 (Planned) |
| - | Scheduler.Execution | READER (Cross-Schema) | Checks ExecutionStatusId = 3 (Sent) and ActualExecutionDate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.Alert_NotTakenPaymentExecutions (procedure)
├── Recurring.PaymentExecution (table)
└── Scheduler.Execution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | INNER JOIN, filter StatusId=1 |
| Scheduler.Execution | Table | INNER JOIN on PaymentExecutionId, filter ExecutionStatusId=3 |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run with defaults
```sql
EXEC Recurring.Alert_NotTakenPaymentExecutions
```

### 8.2 Check with shorter threshold
```sql
EXEC Recurring.Alert_NotTakenPaymentExecutions @MinutsToAlert = 15
```

### 8.3 Equivalent ad-hoc query
```sql
SELECT COUNT(e.ExecutionId) AS StuckExecutions, MIN(e.ExecutionId) AS FirstStuck
FROM Scheduler.Execution e WITH (NOLOCK)
INNER JOIN Recurring.PaymentExecution pe WITH (NOLOCK) ON e.PaymentExecutionId = pe.PaymentExecutionId
WHERE e.ExecutionStatusId = 3 AND pe.StatusId = 1
  AND e.ActualExecutionDate BETWEEN DATEADD(DAY, -2, GETUTCDATE()) AND DATEADD(MINUTE, -30, GETUTCDATE())
HAVING COUNT(e.ExecutionId) > 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.Alert_NotTakenPaymentExecutions | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.Alert_NotTakenPaymentExecutions.sql*
