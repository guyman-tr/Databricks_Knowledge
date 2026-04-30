# Scheduler.SetStampForExecutionsWithLock

> Claims unclaimed due executions by stamping them with a distributed lock GUID and transitioning them to WaitingForProcess, returning the count of rows affected.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns @@ROWCOUNT indicating how many executions were claimed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.SetStampForExecutionsWithLock is a batch-stamping procedure that claims unclaimed due executions for a processing worker. It is functionally similar to GetExecutionsToProcessWithLock but returns only the count of claimed rows (@@ROWCOUNT) instead of the full execution records. This makes it suitable for the "stamp first, fetch later" pattern where the worker stamps a batch and then retrieves the stamped rows in a separate query.

This procedure was the original locking mechanism (created March 2021) before GetExecutionsToProcessWithLock was introduced with its atomic claim-and-return pattern. The Stamp column on Scheduler.Execution acts as a distributed lock - when a worker writes its GUID into the Stamp column, it claims exclusive ownership of those executions. The procedure also transitions the execution status from [Planned](_glossary.md#execution-status) (1) to [WaitingForProcess](_glossary.md#execution-status) (2) and records the ActualExecutionDate.

The procedure supports a configurable @BulkSize (default 10000, added July 2024) to control how many executions a single worker claims per call. Only executions whose PlannedDate is in the past, with a NULL Stamp, matching the specified ExecutionTypeId, and in Planned (1) status are eligible for claiming.

---

## 2. Business Logic

### 2.1 Batch Claim with Distributed Lock

**What**: Stamps unclaimed due executions with a worker's GUID, transitioning them from Planned to WaitingForProcess.

**Columns/Parameters Involved**: `@Stamp`, `@ExecutionTypeId`, `@BulkSize`, `Stamp`, `ActualExecutionDate`, `ExecutionStatusId`, `PlannedDate`

**Rules**:
- UPDATE sets: Stamp = @Stamp, ActualExecutionDate = GETUTCDATE(), ExecutionStatusId = 2 (WaitingForProcess)
- WHERE clause requires ALL of:
  - PlannedDate < GETUTCDATE() (execution is due or overdue)
  - Stamp IS NULL (not yet claimed)
  - ExecutionTypeId = @ExecutionTypeId (matches the processing pipeline)
  - ExecutionStatusId = 1 (Planned status only)
- UPDATE TOP (ISNULL(@BulkSize, 10000)) - defaults to 10000 if @BulkSize is NULL
- Returns only @@ROWCOUNT (number of rows claimed), not the execution details
- A return value of 0 means no work was available to claim

### 2.2 Comparison with GetExecutionsToProcessWithLock

**What**: Differences between this procedure and the newer GetExecutionsToProcessWithLock.

**Columns/Parameters Involved**: N/A

**Rules**:
- SetStampForExecutionsWithLock returns only the count; GetExecutionsToProcessWithLock returns the claimed rows via OUTPUT
- SetStampForExecutionsWithLock defaults to 10000 bulk size; GetExecutionsToProcessWithLock defaults to 2000
- SetStampForExecutionsWithLock uses ISNULL for NULL-safe default; GetExecutionsToProcessWithLock requires @BulkSize
- Both use identical WHERE conditions and UPDATE logic
- SetStampForExecutionsWithLock is the older implementation (March 2021); GetExecutionsToProcessWithLock is the newer, preferred approach

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Stamp | uniqueidentifier (IN) | NO | - | VERIFIED | The worker's unique GUID used to claim executions. Written to the Stamp column to establish distributed ownership. |
| 2 | @ExecutionTypeId | int (IN) | NO | - | VERIFIED | Filters by [Execution Type](_glossary.md#execution-type). 1=Planned (regular), 2=Dunning (retry). |
| 3 | @BulkSize | int (IN) | YES | NULL | CODE-BACKED | Maximum number of executions to claim. NULL defaults to 10000 via ISNULL. Added in July 2024 update. |
| 4 | (return) | int (OUT) | NO | - | CODE-BACKED | @@ROWCOUNT - the number of executions that were successfully claimed. Zero means no work available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE) | Scheduler.Execution | Direct Write | Stamps rows and transitions status from Planned to WaitingForProcess |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker claims batches of due executions for processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.SetStampForExecutionsWithLock (procedure)
└── Scheduler.Execution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | WRITER - stamps rows to claim ownership and transitions ExecutionStatusId from 1 to 2 |

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

### 8.1 Claim planned executions with a new worker stamp
```sql
DECLARE @WorkerStamp UNIQUEIDENTIFIER = NEWID();
EXEC Scheduler.SetStampForExecutionsWithLock
    @Stamp = @WorkerStamp,
    @ExecutionTypeId = 1;
-- Returns the count of claimed rows
```

### 8.2 Claim a limited batch of dunning executions
```sql
DECLARE @WorkerStamp UNIQUEIDENTIFIER = NEWID();
EXEC Scheduler.SetStampForExecutionsWithLock
    @Stamp = @WorkerStamp,
    @ExecutionTypeId = 2,
    @BulkSize = 500;
```

### 8.3 After stamping, fetch the claimed executions
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

*Generated: 2026-04-16 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.SetStampForExecutionsWithLock | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.SetStampForExecutionsWithLock.sql*
