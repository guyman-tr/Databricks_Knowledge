# Scheduler.UpdateExecutionPlannedDate

> Reschedules an execution to a new planned date while applying an optimistic concurrency version stamp, returning the updated execution record.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns the updated Execution row with the new PlannedDate and VersionStamp |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.UpdateExecutionPlannedDate reschedules an existing execution to a new PlannedDate and applies a VersionStamp for optimistic concurrency tracking. This is the primary mechanism for adjusting when an execution will be processed - for example, when the scheduling engine calculates that a charge date falls on a weekend or holiday and needs to shift it to the nearest business day.

The VersionStamp parameter serves as a concurrency marker that the caller writes when rescheduling. Unlike RevertExecution (which checks the existing VersionStamp before acting), this procedure unconditionally sets the new VersionStamp and PlannedDate. The VersionStamp is then used as a guard by RevertExecution if the rescheduling needs to be undone - only the holder of the matching VersionStamp can revert the change.

The procedure updates by ExecutionId (primary key) without additional guards on the current state, meaning it will reschedule the execution regardless of its current status. The OUTPUT clause returns the full execution record (including RecurringProgramTypeId and VersionStamp) so the caller can confirm the update was applied. Note that Stamp and ActualExecutionDate are not included in the OUTPUT, unlike some other execution-returning procedures.

---

## 2. Business Logic

### 2.1 Execution Rescheduling with Version Stamp

**What**: Updates the PlannedDate and sets a VersionStamp on the execution for concurrency tracking.

**Columns/Parameters Involved**: `@ExecutionId`, `@PlannedDate`, `@VersionStamp`, `PlannedDate`, `VersionStamp`

**Rules**:
- Updates by ExecutionId (primary key lookup)
- Sets PlannedDate = @PlannedDate (the new scheduled date)
- Sets VersionStamp = @VersionStamp (the concurrency token)
- No precondition checks on current ExecutionStatusId, PlannedDate, or VersionStamp
- The caller is expected to verify the execution is in an appropriate state before rescheduling
- OUTPUT returns ExecutionId, PlanId, PaymentExecutionId, PlannedDate, ExecutionTypeId, ExecutionStatusId, CreateDate, RecurringProgramTypeId, VersionStamp
- Does NOT return Stamp or ActualExecutionDate in the OUTPUT
- The VersionStamp written here becomes the guard condition for Scheduler.RevertExecution

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionId | int (IN) | NO | - | VERIFIED | Primary key of the execution to reschedule. |
| 2 | @PlannedDate | datetime2 (IN) | NO | - | VERIFIED | The new scheduled date for the execution. Replaces the previous PlannedDate. |
| 3 | @VersionStamp | nvarchar(100) (IN) | NO | - | VERIFIED | Concurrency token written to the execution. Used by RevertExecution as a guard to prevent stale reversions. |
| 4 | ExecutionId | int (OUT) | NO | - | CODE-BACKED | PK of the updated execution. |
| 5 | PlanId | int (OUT) | NO | - | CODE-BACKED | FK to Scheduler.Plan. |
| 6 | PaymentExecutionId | int (OUT) | YES | - | CODE-BACKED | Cross-schema link to the Recurring schema. |
| 7 | PlannedDate | datetime2 (OUT) | NO | - | CODE-BACKED | The newly set date - will match @PlannedDate. |
| 8 | ExecutionTypeId | int (OUT) | NO | - | CODE-BACKED | 1=Planned, 2=Dunning. See [Execution Type](_glossary.md#execution-type). |
| 9 | ExecutionStatusId | int (OUT) | NO | - | CODE-BACKED | Current lifecycle state (not modified by this procedure). See [Execution Status](_glossary.md#execution-status). |
| 10 | CreateDate | datetime (OUT) | NO | - | CODE-BACKED | UTC timestamp when the execution was originally created. |
| 11 | RecurringProgramTypeId | int (OUT) | YES | - | CODE-BACKED | 1=RecurringDeposit, 2=RecurringInvestment. See [Recurring Program Type](_glossary.md#recurring-program-type). |
| 12 | VersionStamp | nvarchar (OUT) | YES | - | CODE-BACKED | The newly set concurrency token - will match @VersionStamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionId | Scheduler.Execution | PK parameter | Identifies the execution to reschedule |
| (UPDATE/OUTPUT) | Scheduler.Execution | Direct Write/Read | Updates PlannedDate and VersionStamp, returns updated row |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker reschedules executions when date adjustments are needed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.UpdateExecutionPlannedDate (procedure)
└── Scheduler.Execution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | WRITER/READER - updates PlannedDate and VersionStamp, returns the updated row |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.RevertExecution | Procedure | Uses the VersionStamp set by this procedure as a guard for reverting the change |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Reschedule an execution to a new date
```sql
EXEC Scheduler.UpdateExecutionPlannedDate
    @ExecutionId = 856001,
    @PlannedDate = '2026-05-03T14:00:00',
    @VersionStamp = 'v1-weekend-shift-20260501';
```

### 8.2 Reschedule and then revert the change
```sql
-- Step 1: Reschedule
EXEC Scheduler.UpdateExecutionPlannedDate
    @ExecutionId = 856001,
    @PlannedDate = '2026-05-03T14:00:00',
    @VersionStamp = 'v1-weekend-shift-20260501';

-- Step 2: Revert using the same VersionStamp
EXEC Scheduler.RevertExecution
    @ExecutionId = 856001,
    @PlannedDate = '2026-05-01T14:00:00',
    @VersionStamp = 'v1-weekend-shift-20260501';
```

### 8.3 Check current PlannedDate and VersionStamp for an execution
```sql
SELECT ExecutionId, PlannedDate, VersionStamp, ExecutionStatusId
FROM Scheduler.Execution
WHERE ExecutionId = 856001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.UpdateExecutionPlannedDate | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.UpdateExecutionPlannedDate.sql*
