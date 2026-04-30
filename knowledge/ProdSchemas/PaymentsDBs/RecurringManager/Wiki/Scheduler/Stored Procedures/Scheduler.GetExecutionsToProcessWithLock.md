# Scheduler.GetExecutionsToProcessWithLock

> Atomically claims a batch of due executions by stamping them with a lock GUID and transitioning them to WaitingForProcess, returning the claimed rows for immediate processing.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns up to @BulkSize Execution rows that were just claimed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.GetExecutionsToProcessWithLock is the core work-distribution procedure for the RecurringScheduler K8S worker. It implements a claim-and-return pattern: in a single atomic UPDATE with OUTPUT, it stamps unclaimed due executions with a worker's unique GUID, transitions them from [Planned](_glossary.md#execution-status) (1) to [WaitingForProcess](_glossary.md#execution-status) (2), sets the ActualExecutionDate to the current UTC time, and returns the claimed rows to the caller for immediate processing.

This procedure solves the distributed worker problem - multiple RecurringScheduler pods may be running simultaneously, and each must claim a distinct batch of work without double-processing. The Stamp column acts as a distributed lock: only rows where Stamp IS NULL can be claimed. Once a worker stamps a row with its GUID, no other worker will pick it up. The @ExecutionTypeId parameter ensures that regular recurring processing (1=Planned) and dunning retry processing (2=Dunning) claim separate batches.

The UPDATE TOP (@BulkSize) pattern limits how many executions a single worker claims per call, preventing one pod from monopolizing all available work. The default bulk size is 2000. Only executions whose PlannedDate is in the past (due or overdue) are eligible. The OUTPUT clause returns the full execution record so the caller can immediately begin processing without a second round-trip to the database.

---

## 2. Business Logic

### 2.1 Atomic Claim-and-Return

**What**: Claims unclaimed due executions in a single atomic operation that combines UPDATE and OUTPUT.

**Columns/Parameters Involved**: `@Stamp`, `@ExecutionTypeId`, `@BulkSize`, `Stamp`, `ActualExecutionDate`, `ExecutionStatusId`, `PlannedDate`

**Rules**:
- UPDATE sets: Stamp = @Stamp, ActualExecutionDate = GETUTCDATE(), ExecutionStatusId = 2 (WaitingForProcess)
- WHERE clause requires ALL of:
  - PlannedDate < GETUTCDATE() (execution is due)
  - Stamp IS NULL (not yet claimed by any worker)
  - ExecutionTypeId = @ExecutionTypeId (matches the processing type)
  - ExecutionStatusId = 1 (Planned status only)
- UPDATE TOP (@BulkSize) caps the batch at 2000 rows by default
- OUTPUT INSERTED returns the updated rows directly - no second SELECT needed
- The atomic UPDATE+OUTPUT prevents race conditions between concurrent workers
- Returns RecurringProgramTypeId so the worker can route to the correct handler (1=RecurringDeposit, 2=RecurringInvestment)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Stamp | uniqueidentifier (IN) | NO | - | VERIFIED | The worker's unique GUID used to claim executions. Each worker instance generates a new GUID per batch. Written to the Stamp column to establish distributed ownership. |
| 2 | @ExecutionTypeId | int (IN) | NO | - | VERIFIED | Filters by [Execution Type](_glossary.md#execution-type). 1=Planned (regular recurring), 2=Dunning (retry). Ensures planned and dunning processing pipelines claim separate batches. |
| 3 | @BulkSize | int (IN) | NO | 2000 | CODE-BACKED | Maximum number of executions to claim in this batch. Controls work distribution across pods. |
| 4 | ExecutionId | int (OUT) | NO | - | CODE-BACKED | Primary key of the claimed execution. |
| 5 | PlanId | int (OUT) | NO | - | CODE-BACKED | FK to Scheduler.Plan - the recurring plan this execution belongs to. |
| 6 | PaymentExecutionId | int (OUT) | YES | - | CODE-BACKED | Cross-schema link to the Recurring schema's payment execution. |
| 7 | PlannedDate | datetime2 (OUT) | NO | - | CODE-BACKED | The originally scheduled UTC date. Always in the past for claimed rows. |
| 8 | ExecutionTypeId | int (OUT) | NO | - | CODE-BACKED | Will match @ExecutionTypeId. 1=Planned, 2=Dunning. |
| 9 | ExecutionStatusId | int (OUT) | NO | - | CODE-BACKED | Always 2 (WaitingForProcess) in the output since the UPDATE just set it. |
| 10 | CreateDate | datetime (OUT) | NO | - | CODE-BACKED | UTC timestamp when the execution was originally created. |
| 11 | Stamp | uniqueidentifier (OUT) | NO | - | CODE-BACKED | Will match @Stamp in the output - confirms the lock was applied. |
| 12 | ActualExecutionDate | datetime (OUT) | NO | - | CODE-BACKED | Just set to GETUTCDATE() by the UPDATE - records when the execution was claimed. |
| 13 | RecurringProgramTypeId | int (OUT) | YES | - | CODE-BACKED | 1=RecurringDeposit, 2=RecurringInvestment. See [Recurring Program Type](_glossary.md#recurring-program-type). Routes the execution to the correct downstream handler. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE/OUTPUT) | Scheduler.Execution | Direct Write/Read | Claims and returns execution rows in a single atomic operation |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker calls this to claim batches of due executions for processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.GetExecutionsToProcessWithLock (procedure)
└── Scheduler.Execution (table)
    └── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | WRITER/READER - atomically claims rows by setting Stamp, ActualExecutionDate, and ExecutionStatusId, returning claimed rows via OUTPUT |

### 6.2 Objects That Depend On This

No database dependents. Called by RecurringScheduler application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Claim a batch of planned executions for the recurring processing pipeline
```sql
DECLARE @WorkerStamp UNIQUEIDENTIFIER = NEWID();
EXEC Scheduler.GetExecutionsToProcessWithLock
    @Stamp = @WorkerStamp,
    @ExecutionTypeId = 1,
    @BulkSize = 500;
```

### 8.2 Claim a batch of dunning (retry) executions
```sql
DECLARE @WorkerStamp UNIQUEIDENTIFIER = NEWID();
EXEC Scheduler.GetExecutionsToProcessWithLock
    @Stamp = @WorkerStamp,
    @ExecutionTypeId = 2,
    @BulkSize = 100;
```

### 8.3 Verify which executions were claimed by a specific worker stamp
```sql
DECLARE @WorkerStamp UNIQUEIDENTIFIER = '12345678-1234-1234-1234-123456789ABC';
SELECT e.ExecutionId, e.PlanId, e.PlannedDate, e.ActualExecutionDate, e.ExecutionStatusId
FROM Scheduler.Execution e
WHERE e.Stamp = @WorkerStamp
ORDER BY e.ExecutionId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.GetExecutionsToProcessWithLock | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.GetExecutionsToProcessWithLock.sql*
