# Scheduler.Execution

> Tracks every individual payment execution attempt within a recurring plan, recording its lifecycle from initial scheduling through processing to completion or cancellation.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Table |
| **Key Identifier** | ExecutionId (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 10 (1 clustered PK + 8 nonclustered + 1 unique filtered) |

---

## 1. Business Meaning

Scheduler.Execution represents a single payment charge attempt within a recurring payment plan. Each row is one billing cycle event - for example, a user with a monthly $100 recurring deposit generates one Execution row per month. The table is the operational core of the RecurringScheduler service, tracking each execution from its creation (Planned) through its lifecycle to a terminal state (Done, Canceled, or Failed).

This table exists because recurring payments require granular tracking of every charge attempt. A Plan defines the schedule, but each actual charge needs its own record with timestamps, status tracking, optimistic locking (Stamp), and linkage to the broader payment execution system. Without this table, the system could not track which charges succeeded, which failed, which are in-flight, and which are still pending.

Executions are created by Scheduler.CreateOrGetExecution when the application determines the next charge is due. The RecurringScheduler worker picks up pending executions using Scheduler.GetExecutionsToProcessWithLock or Scheduler.SetStampForExecutionsWithLock, which atomically stamp them and transition them from Planned to WaitingForProcess. The executions are then dispatched to the billing provider via Azure Service Bus. As results return, Scheduler.UpdateExecutionsStatus advances the status to Done, Canceled, or Failed. The table is system-versioned with History.Execution for full audit trail.

---

## 2. Business Logic

### 2.1 Execution Status Lifecycle

**What**: Each execution progresses through a defined state machine from creation to terminal state.

**Columns/Parameters Involved**: `ExecutionStatusId`, `Stamp`, `ActualExecutionDate`

**Rules**:
- Status 1 (Planned): Initial state. Stamp IS NULL, ActualExecutionDate IS NULL. Execution is waiting for its PlannedDate to arrive
- Status 2 (WaitingForProcess): Transitional. Set atomically by GetExecutionsToProcessWithLock/SetStampForExecutionsWithLock. Stamp is set to a GUID, ActualExecutionDate set to GETUTCDATE()
- Status 3 (Sent): Execution has been dispatched to the billing provider
- Status 4 (Canceled): Terminal. Execution was canceled. UpdateExecutionsStatus refuses to update rows already in status 4 or 6
- Status 5 (Failed): Terminal. Execution encountered a processing error
- Status 6 (Done): Terminal. Execution completed - the billing result (success/decline) is in the Recurring schema
- See [Execution Status](_glossary.md#execution-status) for full definitions

**Diagram**:
```
[CreateOrGetExecution]
        |
        v
   1 (Planned) --[PlannedDate passes]--> [GetExecutionsToProcessWithLock]
        |                                           |
        |                               Sets Stamp + ActualExecutionDate
        |                                           |
        v                                           v
   4 (Canceled) <--[cancel]--    2 (WaitingForProcess) --[send]--> 3 (Sent)
                                                                      |
                                                           [billing result]
                                                              |       |
                                                              v       v
                                                        6 (Done)  5 (Failed)
```

### 2.2 Optimistic Locking via Stamp

**What**: The Stamp column implements distributed locking to prevent duplicate processing of the same execution across multiple worker instances.

**Columns/Parameters Involved**: `Stamp`, `ExecutionStatusId`, `ActualExecutionDate`

**Rules**:
- When Stamp IS NULL and ExecutionStatusId = 1 (Planned), the execution is available for processing
- GetExecutionsToProcessWithLock uses `UPDATE TOP (@BulkSize) ... SET Stamp = @Stamp WHERE Stamp IS NULL AND ExecutionStatusId = 1` to atomically claim a batch
- SetStampForExecutionsWithLock does the same (older version, similar logic) with configurable batch size
- The GUID Stamp value identifies which worker instance claimed the execution
- Multiple worker pods can safely compete for executions without double-processing
- Once stamped, the execution is "owned" by that processing batch

### 2.3 Execution Type Branching

**What**: Executions are classified as either regular Planned charges or Dunning (retry) attempts, determining which processing pipeline handles them.

**Columns/Parameters Involved**: `ExecutionTypeId`, `RecurringProgramTypeId`

**Rules**:
- ExecutionTypeId = 1 (Planned): A regular scheduled charge based on the plan's frequency
- ExecutionTypeId = 2 (Dunning): A retry attempt after a previous soft decline. Currently no Dunning executions exist in production
- GetExecutionsToProcessWithLock and SetStampForExecutionsWithLock both filter by @ExecutionTypeId, ensuring Recurring and Dunning jobs process only their own type
- RecurringProgramTypeId (1=RecurringDeposit, 2=RecurringInvestment) routes the execution result to the correct downstream handler. NULL for 52% of rows (legacy, added later)
- See [Execution Type](_glossary.md#execution-type) and [Recurring Program Type](_glossary.md#recurring-program-type) for full definitions

### 2.4 Version-Based Optimistic Concurrency

**What**: The VersionStamp column provides a secondary optimistic concurrency mechanism for planned date modifications.

**Columns/Parameters Involved**: `VersionStamp`, `PlannedDate`

**Rules**:
- Scheduler.UpdateExecutionPlannedDate sets both PlannedDate and VersionStamp when rescheduling an execution
- Scheduler.RevertExecution checks `WHERE VersionStamp LIKE @VersionStamp` before reverting - prevents reverting if another process has already modified the execution
- Only 0.6% of executions have a VersionStamp (used when the application reschedules an upcoming execution)
- VersionStamp is cleared (set to NULL) on revert, indicating the execution is back to its original schedule

---

## 3. Data Overview

| ExecutionId | PlanId | ExecType | ExecStatus | PlannedDate | Stamp | ProgramType | Meaning |
|-------------|--------|----------|------------|-------------|-------|-------------|---------|
| 859414 | 189836 | Planned | Planned | 2026-05-01 | NULL | RecurringInvestment | Newly created execution for a monthly investment plan - waiting for May 1 to arrive before processing |
| 859410 | 189832 | Planned | Planned | 2026-04-28 | NULL | RecurringInvestment | Execution with a VersionStamp set - indicates the planned date was rescheduled by the application |
| 859412 | 189834 | Planned | Planned | 2026-04-28 | NULL | RecurringDeposit | A recurring deposit (not investment) execution - routed to the deposit processing pipeline |
| ~mid | ~mid | Planned | Done | ~past | {GUID} | NULL | A completed execution from a legacy period when RecurringProgramTypeId was not yet populated |
| ~early | ~early | Planned | Canceled | ~past | NULL | NULL | A canceled execution - never processed (Stamp remained NULL), likely canceled when the parent plan was terminated |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionId | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. ~856K rows exist. Referenced in GetExecutionByPaymentExecution, GetExecutionsForPlan, UpdateExecutionPlannedDate, RevertExecution, and alert procedures. |
| 2 | PlanId | int | NO | - | VERIFIED | FK to Scheduler.Plan.PlanId. Links this execution to its parent schedule. Indexed with ExecutionStatusId and ExecutionTypeId for efficient lookups. Each plan generates one execution per billing cycle. |
| 3 | PaymentExecutionId | int | NO | - | VERIFIED | Cross-schema FK to the payment execution record in the Recurring schema. One-to-one relationship per execution attempt. Used by GetExecutionByPaymentExecution for reverse lookups. The unique filtered index UQ_Scheduler_Execution ensures only one active (status=1) execution exists per PaymentExecutionId + ExecutionTypeId combination. |
| 4 | PlannedDate | datetime | NO | - | VERIFIED | UTC timestamp of when this execution should be processed. Set during creation based on the plan's frequency, start date, and charging day. Used by GetExecutionsToProcessWithLock's WHERE clause (`PlannedDate < GETUTCDATE()`) to pick up due executions. Can be modified by UpdateExecutionPlannedDate when rescheduling. |
| 5 | ExecutionTypeId | int | NO | - | VERIFIED | Classification of execution attempt: 1=Planned (regular scheduled charge), 2=Dunning (retry after soft decline). Currently 100% of rows are Planned. Filtered by GetExecutionsToProcessWithLock and SetStampForExecutionsWithLock. See [Execution Type](_glossary.md#execution-type). (Dictionary.ExecutionType) |
| 6 | ExecutionStatusId | int | NO | - | VERIFIED | Lifecycle state: 1=Planned (1.9%), 2=WaitingForProcess, 3=Sent (0.01%), 4=Canceled (12.6%), 5=Failed (0.003%), 6=Done (85.4%). Heavily indexed across 5 indexes. UpdateExecutionsStatus refuses to update rows in status 4 or 6 (terminal states). See [Execution Status](_glossary.md#execution-status). (Dictionary.ExecutionStatus) |
| 7 | CreateDate | datetime | NO | - | CODE-BACKED | UTC timestamp of when the execution record was created, set to GETDATE() in CreateOrGetExecution. Distinct from PlannedDate (when it should run) and ActualExecutionDate (when it was actually picked up). |
| 8 | Stamp | uniqueidentifier | YES | - | VERIFIED | Distributed lock token. NULL = unclaimed and available for processing. Set to a GUID by GetExecutionsToProcessWithLock/SetStampForExecutionsWithLock to claim ownership. Prevents duplicate processing across multiple RecurringScheduler worker pods. 14.5% NULL (unclaimed: Planned + Canceled-before-processing). |
| 9 | ActualExecutionDate | datetime | YES | - | VERIFIED | UTC timestamp of when the execution was actually picked up for processing (not when the charge completed). Set to GETUTCDATE() simultaneously with Stamp by the lock procedures. NULL = not yet processed (7%). Indexed for alert queries that detect stuck executions. |
| 10 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning row start time. Automatically managed by SQL Server temporal tables. |
| 11 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end time. 9999-12-31 = current version. Previous versions stored in History.Execution. |
| 12 | RecurringProgramTypeId | int | YES | - | CODE-BACKED | Program classification: 1=RecurringDeposit, 2=RecurringInvestment. NULL for 52% of rows (legacy - column added after initial launch). Routes execution results to the correct downstream handler. See [Recurring Program Type](_glossary.md#recurring-program-type). (Dictionary.RecurringProgramType) |
| 13 | VersionStamp | nvarchar(100) | YES | - | CODE-BACKED | Optimistic concurrency token for planned date modifications. Set by UpdateExecutionPlannedDate, checked by RevertExecution before reverting. NULL for 99.4% of rows. Non-NULL indicates the execution's PlannedDate was rescheduled and the VersionStamp identifies the modification version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlanId | Scheduler.Plan | Implicit FK | Links execution to its parent schedule - each execution belongs to exactly one plan |
| ExecutionTypeId | Dictionary.ExecutionType | Implicit Lookup | Classifies as Planned (1) or Dunning (2) |
| ExecutionStatusId | Dictionary.ExecutionStatus | Implicit Lookup | Tracks lifecycle state from Planned through Done/Canceled |
| RecurringProgramTypeId | Dictionary.RecurringProgramType | Implicit Lookup | Routes to RecurringDeposit (1) or RecurringInvestment (2) handler |
| PaymentExecutionId | Recurring.PaymentExecution | Implicit FK (cross-schema) | Links to the payment execution record in the Recurring schema |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Execution | (system) | System-versioning | Stores previous row versions on UPDATE for temporal audit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.Execution (table)
└── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Plan | Table | PlanId references Plan.PlanId - each execution belongs to a plan |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Alert_PlanedDatePassed_NotTaken | Stored Procedure | READER - detects unprocessed executions past their PlannedDate |
| Scheduler.Alert_StuckWithNotValidStatus | Stored Procedure | READER - detects executions stuck in non-terminal status |
| Scheduler.CreateOrGetExecution | Stored Procedure | WRITER - creates new execution if PaymentExecutionId doesn't exist |
| Scheduler.DD_Alert_PlanedDatePassed_NotTaken | Stored Procedure | READER - DataDog variant of unprocessed execution alert |
| Scheduler.DD_Alert_StuckWithNotValidStatus | Stored Procedure | READER - DataDog variant of stuck execution alert |
| Scheduler.GetExecutionByPaymentExecution | Stored Procedure | READER - retrieves execution by PaymentExecutionId |
| Scheduler.GetExecutionsForPlan | Stored Procedure | READER - retrieves executions for a plan with optional status filter |
| Scheduler.GetExecutionsToProcessWithLock | Stored Procedure | MODIFIER - atomically stamps and claims executions for processing |
| Scheduler.GetLastExecutionForPlan | Stored Procedure | READER - gets most recent execution for a plan by type |
| Scheduler.GetPlansWithLastAndNextExecutions | Stored Procedure | READER - JOINs to Plan to show last/next executions |
| Scheduler.RevertExecution | Stored Procedure | MODIFIER - reverts PlannedDate with optimistic concurrency check |
| Scheduler.SetStampForExecutionsWithLock | Stored Procedure | MODIFIER - stamps executions for processing (older variant) |
| Scheduler.UpdateExecutionPlannedDate | Stored Procedure | MODIFIER - reschedules execution with VersionStamp |
| Scheduler.UpdateExecutionsStatus | Stored Procedure | MODIFIER - batch status update for completed executions |
| History.Execution | Table | System-versioned history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Scheduler_Execution | CLUSTERED PK | ExecutionId ASC | - | - | Active |
| IX_Scheduler_Execution_ExecutionStatusId_ActualExecutionDate | NC | ExecutionStatusId, ActualExecutionDate | - | - | Active |
| IX_Scheduler_Execution_ExecutionTypeId_ExecutionStatusId_Stamp_PlannedDate_Inc | NC | ExecutionTypeId, ExecutionStatusId, Stamp, PlannedDate | ActualExecutionDate | - | Active |
| IX_Scheduler_Execution_PlanId_ExecutionStatusId | NC | PlanId, ExecutionStatusId | - | - | Active |
| IX_Scheduler_Execution_PlanId_ExecutionTypeId | NC | PlanId, ExecutionTypeId | - | - | Active |
| IX_SchedulerExecution_ActualExecutionDate | NC | ActualExecutionDate | - | - | Active |
| IX_SchedulerExecution_ExecutionStatusId_Stamp | NC | ExecutionStatusId, Stamp, PlannedDate | - | - | Active |
| IX_SchedulerExecution_ExecutionTypeId | NC | ExecutionTypeId | PlanId, PaymentExecutionId, PlannedDate, ExecutionStatusId, CreateDate, Stamp, ActualExecutionDate | - | Active |
| IX_SchedulerExecution_PaymentExecutionId | NC | PaymentExecutionId | - | - | Active |
| UQ_Scheduler_Execution_PaymentExecutionId_ExecutionTypeId_ExecutionStatusId | UNIQUE NC | PaymentExecutionId, ExecutionTypeId, ExecutionStatusId | - | ExecutionStatusId = 1 | Active |

The unique filtered index UQ_...ExecutionStatusId ensures at most one Planned (status=1) execution exists per PaymentExecutionId+ExecutionTypeId combination, preventing duplicate scheduling.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Scheduler_Execution | PRIMARY KEY | Unique ExecutionId |
| DF_SysStartTime | DEFAULT | SysStartTime = GETUTCDATE() |
| DF_SysEndTime | DEFAULT | SysEndTime = 9999-12-31 23:59:59.9999999 |

---

## 8. Sample Queries

### 8.1 Find executions due for processing (what GetExecutionsToProcessWithLock targets)
```sql
SELECT TOP 100 e.ExecutionId, e.PlanId, e.PaymentExecutionId, e.PlannedDate, e.ExecutionTypeId
FROM Scheduler.Execution e WITH (NOLOCK)
WHERE e.PlannedDate < GETUTCDATE()
  AND e.Stamp IS NULL
  AND e.ExecutionTypeId = 1 -- Planned
  AND e.ExecutionStatusId = 1 -- Planned status
ORDER BY e.PlannedDate;
```

### 8.2 View execution history for a plan with status names
```sql
SELECT e.ExecutionId, e.PlannedDate, es.Name AS Status, et.Name AS ExecType,
       e.ActualExecutionDate, e.Stamp, rpt.Name AS ProgramType
FROM Scheduler.Execution e WITH (NOLOCK)
JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON e.ExecutionStatusId = es.ExecutionStatusID
JOIN Dictionary.ExecutionType et WITH (NOLOCK) ON e.ExecutionTypeId = et.ExecutionTypeId
LEFT JOIN Dictionary.RecurringProgramType rpt WITH (NOLOCK) ON e.RecurringProgramTypeId = rpt.RecurringProgramTypeID
WHERE e.PlanId = 189836
ORDER BY e.ExecutionId DESC;
```

### 8.3 Detect stuck executions (what Alert_StuckWithNotValidStatus checks)
```sql
SELECT e.ExecutionId, e.PlanId, es.Name AS Status, e.ActualExecutionDate
FROM Scheduler.Execution e WITH (NOLOCK)
JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON e.ExecutionStatusId = es.ExecutionStatusID
WHERE e.ActualExecutionDate IS NOT NULL
  AND e.ActualExecutionDate < DATEADD(MINUTE, -30, GETUTCDATE())
  AND e.ExecutionStatusId NOT IN (4, 6) -- Not Canceled, Not Done
ORDER BY e.ActualExecutionDate;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Scheduler](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891789/Recurring+Scheduler) | Confluence | Worker service processes executions via cron schedule, publishes to Azure Service Bus, owned by MIMO US |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 14 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.Execution | Type: Table | Source: RecurringManager/Scheduler/Tables/Scheduler.Execution.sql*
