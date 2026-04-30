# Dictionary.ExecutionStatus

> Lookup table tracking the lifecycle state of a scheduled execution record in the Scheduler schema, from initial planning through processing to final resolution.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ExecutionStatusID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ExecutionStatus defines the six lifecycle states that a scheduled execution passes through in the Scheduler schema. Each execution record in Scheduler.Execution transitions through these states as it moves from being scheduled, to being picked up for processing, to being sent to the billing provider, and finally to completion or failure.

This status is critical to the scheduler's lock-based processing model. The Scheduler.SetStampForExecutionsWithLock procedure stamps Planned executions (Status=1) to transition them to WaitingForProcess, and Scheduler.GetExecutionsToProcessWithLock picks up and locks WaitingForProcess executions for the worker. This prevents duplicate processing of the same execution by multiple worker instances.

ExecutionStatus tracks the processing pipeline state, while ExecutionResultStatus (separate table) records the provider's verdict, and PaymentExecutionStatus tracks the broader end-to-end journey. A "Done" ExecutionStatus (6) does not imply payment success - it means processing completed, and the result is recorded in ExecutionResultStatus.

---

## 2. Business Logic

### 2.1 Scheduler Lock-Based Processing Pipeline

**What**: Executions flow through a lock-based state machine ensuring exactly-once processing by the scheduler workers.

**Columns/Parameters Involved**: `ExecutionStatusID`, `Name`

**Rules**:
- Planned (1) is the initial state for all new executions - not yet eligible for processing
- WaitingForProcess (2) means the execution has been stamped/locked and is queued for a worker
- Sent (3) means the execution has been dispatched to the billing provider
- Done (6) means processing completed (success or decline recorded separately in ExecutionResultStatus)
- Canceled (4) and Failed (5) are terminal states that short-circuit the pipeline

**Diagram**:
```
Planned (1) --> WaitingForProcess (2) --> Sent (3) --> Done (6)
    |                                       |
    +----------> Canceled (4)               +---> Failed (5)
```

---

## 3. Data Overview

| ExecutionStatusID | Name | Meaning |
|---|---|---|
| 1 | Planned | Execution scheduled for a future date. SetStampForExecutionsWithLock stamps these when PlannedDate < GETUTCDATE() to transition to WaitingForProcess. |
| 2 | WaitingForProcess | Stamped and queued for worker pickup. GetExecutionsToProcessWithLock locks and retrieves these for processing. |
| 3 | Sent | Dispatched to billing provider (Worldpay/Checkout). Awaiting provider response. |
| 4 | Canceled | Canceled before processing - e.g., plan was stopped or user opted out. Terminal state. |
| 5 | Failed | Processing encountered an error preventing completion. Terminal state. |
| 6 | Done | Processing completed. Actual outcome (Success/SoftDecline/HardDecline) recorded in ExecutionResultStatus. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionStatusID | int | NO | - | VERIFIED | Primary key identifying the execution lifecycle state. 1=Planned, 2=WaitingForProcess, 3=Sent, 4=Canceled, 5=Failed, 6=Done. Heavily indexed on Scheduler.Execution for query performance. See [Execution Status](../../_glossary.md#execution-status) for full definitions. (Dictionary.ExecutionStatus) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the status. Values: "Planned", "WaitingForProcess", "Sent", "Canceled", "Failed", "Done". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduler.Execution | ExecutionStatusId | Implicit FK | Tracks the current lifecycle state of each scheduled execution. Multiple indexes include ExecutionStatusId for query performance. |
| History.Execution | ExecutionStatusId | Implicit FK | Archived execution records retain their final status for audit trail. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | ExecutionStatusId column references this table's values for lifecycle tracking |
| History.Execution | Table | Archived executions retain ExecutionStatusId for audit |
| Scheduler.SetStampForExecutionsWithLock | Stored Procedure | Filters by ExecutionStatusId=1 (Planned) to stamp executions for processing |
| Scheduler.GetExecutionsToProcessWithLock | Stored Procedure | Filters by ExecutionStatusId to pick up work for processing |
| Scheduler.RevertExecution | Stored Procedure | Reverts execution status to an earlier state |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ExecutionStatus | CLUSTERED PK | ExecutionStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_ExecutionStatus | PRIMARY KEY | Ensures each status has a unique integer identifier |

---

## 8. Sample Queries

### 8.1 List all execution statuses
```sql
SELECT ExecutionStatusID, Name
FROM Dictionary.ExecutionStatus WITH (NOLOCK)
ORDER BY ExecutionStatusID
```

### 8.2 Count executions by status
```sql
SELECT es.Name AS ExecutionStatus, COUNT(*) AS ExecutionCount
FROM Scheduler.Execution e WITH (NOLOCK)
INNER JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON e.ExecutionStatusId = es.ExecutionStatusID
GROUP BY es.Name
ORDER BY ExecutionCount DESC
```

### 8.3 Find executions stuck in a non-terminal state
```sql
SELECT e.ExecutionId, e.PlanId, e.PlannedDate, es.Name AS Status
FROM Scheduler.Execution e WITH (NOLOCK)
INNER JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON e.ExecutionStatusId = es.ExecutionStatusID
WHERE e.ExecutionStatusId IN (1, 2, 3) -- Planned, WaitingForProcess, Sent
  AND e.PlannedDate < DATEADD(DAY, -1, GETUTCDATE())
ORDER BY e.PlannedDate
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Manager](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891833) | Confluence | Architecture: RecurringManager service processes executions via Worker + API pattern |
| [Recurring Scheduler](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891789) | Confluence | Architecture: RecurringScheduler is the dedicated worker that drives execution state transitions |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 3 analyzed (references) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ExecutionStatus | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.ExecutionStatus.sql*
