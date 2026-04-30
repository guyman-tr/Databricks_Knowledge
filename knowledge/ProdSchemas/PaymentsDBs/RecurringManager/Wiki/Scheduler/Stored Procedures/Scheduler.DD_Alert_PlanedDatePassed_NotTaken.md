# Scheduler.DD_Alert_PlanedDatePassed_NotTaken

> Monitors for scheduled executions whose planned date has passed but remain unclaimed, returning a count and the earliest offender for DataDog alerting.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of unprocessed executions and the first unprocessed ExecutionId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.DD_Alert_PlanedDatePassed_NotTaken is an operational health-check procedure that detects executions stuck in the [Planned](_glossary.md#execution-status) state past their scheduled processing time. If an execution's PlannedDate has passed by more than the configured gap (default 2 hours) and it still has no Stamp (meaning no worker has claimed it), the system raises an alert through DataDog monitoring.

This procedure exists because the RecurringScheduler K8S worker is expected to claim and process executions before or shortly after their PlannedDate. If executions remain unclaimed for hours, it signals a worker outage, stuck processing pipeline, or capacity issue. Without this alert, customers could silently miss their scheduled recurring deposits or investments, causing both financial harm and trust erosion.

The procedure uses a NOLOCK hint for performance since it is a monitoring query and does not require transactional accuracy. It returns a single row with either zero (healthy) or the count of stuck executions plus the first (oldest) ExecutionId, formatted for DataDog's metric ingestion pattern. The OUTER APPLY against a dummy VALUES row ensures a result is always returned even when no stuck executions exist.

---

## 2. Business Logic

### 2.1 Stale Execution Detection

**What**: Identifies executions where PlannedDate has passed by more than @GapInHours, the execution is still in Planned status (1), and no worker has stamped it.

**Columns/Parameters Involved**: `PlannedDate`, `ExecutionStatusId`, `Stamp`, `@GapInHours`

**Rules**:
- PlannedDate must be older than GETUTCDATE() minus @GapInHours (default 2 hours)
- ExecutionStatusId must be 1 (Planned) - meaning no worker has begun processing it
- Stamp must be NULL - meaning no distributed lock has been acquired on the row
- All three conditions must be true simultaneously; a stamped execution in Planned status would not trigger the alert

### 2.2 DataDog Result Format

**What**: Returns a single-row result set compatible with DataDog custom metric ingestion.

**Columns/Parameters Involved**: `value` (count), `FirstUnprocessedExecution` (diagnostic ID)

**Rules**:
- Always returns exactly one row via the OUTER APPLY / dummy VALUES pattern
- If no stuck executions exist, returns value = 0 and FirstUnprocessedExecution = NULL
- If stuck executions exist, returns the total count and the MIN(ExecutionId) for investigation
- The MIN ExecutionId is the longest-waiting execution, useful for root-cause triage

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GapInHours | int (IN) | NO | 2 | CODE-BACKED | Number of hours past PlannedDate before an unclaimed execution is considered stuck. Default of 2 gives the worker reasonable headroom before alerting. |
| 2 | value | int (OUT) | NO | 0 | CODE-BACKED | Count of executions matching the stale criteria. A value of 0 means the system is healthy; any positive value triggers a DataDog alert. |
| 3 | FirstUnprocessedExecution | int (OUT) | YES | NULL | CODE-BACKED | The smallest ExecutionId among stuck executions. NULL when none are stuck. Useful for targeted investigation of the oldest blocked execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Scheduler.Execution | Direct Read | Scans for unclaimed executions past their planned date |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| DataDog monitoring | External | Scheduled DataDog synthetic or custom check that polls this SP on an interval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.DD_Alert_PlanedDatePassed_NotTaken (procedure)
└── Scheduler.Execution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | READER - scans for stuck Planned executions with NULL Stamp |

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

### 8.1 Run with default 2-hour gap threshold
```sql
EXEC Scheduler.DD_Alert_PlanedDatePassed_NotTaken;
```

### 8.2 Run with a tighter 30-minute gap for more aggressive alerting
```sql
EXEC Scheduler.DD_Alert_PlanedDatePassed_NotTaken @GapInHours = 1;
```

### 8.3 Manually inspect the executions this alert would flag
```sql
SELECT e.ExecutionId, e.PlanId, e.PlannedDate, e.ExecutionStatusId, e.Stamp
FROM Scheduler.Execution e WITH (NOLOCK)
WHERE e.PlannedDate < DATEADD(HOUR, -2, GETUTCDATE())
  AND e.ExecutionStatusId = 1
  AND e.Stamp IS NULL
ORDER BY e.ExecutionId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.DD_Alert_PlanedDatePassed_NotTaken | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.DD_Alert_PlanedDatePassed_NotTaken.sql*
