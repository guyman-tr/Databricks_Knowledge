# Scheduler.RevertExecution

> Reverts an execution's planned date and clears its version stamp using optimistic concurrency, allowing a previously rescheduled execution to be moved back to its original date.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns the updated Execution row if the version stamp matches |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.RevertExecution restores an execution's PlannedDate to a specified value and clears the VersionStamp, effectively undoing a previous date change. This is the "undo" counterpart to Scheduler.UpdateExecutionPlannedDate - where UpdateExecutionPlannedDate moves an execution to a new date and sets a VersionStamp, RevertExecution moves it back and clears the stamp.

This procedure is needed when the scheduling engine determines that a previously rescheduled execution should return to its original date. For example, if an execution was rescheduled due to a weekend/holiday adjustment but the underlying condition changed (e.g., a calendar correction), the system can revert the execution to the original PlannedDate. The VersionStamp acts as an optimistic concurrency token - the procedure only performs the update if the current VersionStamp matches the expected value, preventing stale reversions.

The procedure uses a LIKE comparison on VersionStamp (not exact equality), which provides some flexibility in matching. It clears VersionStamp to NULL on successful revert, indicating the execution is back in its base state. The OUTPUT clause returns the full execution record so the caller can confirm the reversion was applied and see the current state of the row.

---

## 2. Business Logic

### 2.1 Optimistic Concurrency Revert

**What**: Updates the PlannedDate and clears VersionStamp only if the current VersionStamp matches the expected value.

**Columns/Parameters Involved**: `@ExecutionId`, `@PlannedDate`, `@VersionStamp`, `VersionStamp`, `PlannedDate`

**Rules**:
- WHERE clause requires: ExecutionId = @ExecutionId AND VersionStamp LIKE @VersionStamp
- Uses LIKE (not =) for the VersionStamp comparison, allowing pattern matching
- Sets PlannedDate = @PlannedDate (the date to revert to)
- Sets VersionStamp = NULL (clears the concurrency token, returning to base state)
- If VersionStamp does not match, the UPDATE affects zero rows and OUTPUT returns nothing
- The caller detects a concurrency conflict by checking for an empty result set
- OUTPUT returns the full execution record including RecurringProgramTypeId and VersionStamp (which will be NULL)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionId | int (IN) | NO | - | VERIFIED | Primary key of the execution to revert. Identifies the specific execution row. |
| 2 | @PlannedDate | datetime2 (IN) | NO | - | VERIFIED | The date to revert the execution to. Typically the original PlannedDate before rescheduling occurred. |
| 3 | @VersionStamp | nvarchar(100) (IN) | NO | - | VERIFIED | The expected VersionStamp for optimistic concurrency. The update only proceeds if the current VersionStamp matches this value (via LIKE). |
| 4 | ExecutionId | int (OUT) | NO | - | CODE-BACKED | PK of the reverted execution. Present only if the update succeeded. |
| 5 | PlanId | int (OUT) | NO | - | CODE-BACKED | FK to Scheduler.Plan. |
| 6 | PaymentExecutionId | int (OUT) | YES | - | CODE-BACKED | Cross-schema link to the Recurring schema. |
| 7 | PlannedDate | datetime2 (OUT) | NO | - | CODE-BACKED | The reverted PlannedDate - will match @PlannedDate. |
| 8 | ExecutionTypeId | int (OUT) | NO | - | CODE-BACKED | 1=Planned, 2=Dunning. See [Execution Type](_glossary.md#execution-type). |
| 9 | ExecutionStatusId | int (OUT) | NO | - | CODE-BACKED | Current lifecycle state. See [Execution Status](_glossary.md#execution-status). Not modified by this procedure. |
| 10 | CreateDate | datetime (OUT) | NO | - | CODE-BACKED | UTC timestamp when the execution was originally created. |
| 11 | Stamp | uniqueidentifier (OUT) | YES | - | CODE-BACKED | Distributed lock GUID. Not modified by this procedure. |
| 12 | ActualExecutionDate | datetime (OUT) | YES | - | CODE-BACKED | UTC timestamp when the execution was claimed. Not modified by this procedure. |
| 13 | RecurringProgramTypeId | int (OUT) | YES | - | CODE-BACKED | 1=RecurringDeposit, 2=RecurringInvestment. See [Recurring Program Type](_glossary.md#recurring-program-type). |
| 14 | VersionStamp | nvarchar (OUT) | YES | - | CODE-BACKED | Will be NULL after revert - the concurrency token is cleared. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionId | Scheduler.Execution | PK parameter | Identifies the execution to revert |
| (UPDATE/OUTPUT) | Scheduler.Execution | Direct Write/Read | Updates PlannedDate and clears VersionStamp, returns updated row |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker reverts execution dates when rescheduling needs to be undone |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.RevertExecution (procedure)
└── Scheduler.Execution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | WRITER/READER - reverts PlannedDate and clears VersionStamp with optimistic concurrency check |

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

### 8.1 Revert an execution to its original planned date
```sql
EXEC Scheduler.RevertExecution
    @ExecutionId = 856001,
    @PlannedDate = '2026-05-01T14:00:00',
    @VersionStamp = 'v2-reschedule-abc123';
```

### 8.2 Attempt revert with a stale version stamp (returns no rows)
```sql
-- This will return empty if the VersionStamp has changed since the caller read it
EXEC Scheduler.RevertExecution
    @ExecutionId = 856001,
    @PlannedDate = '2026-05-01T14:00:00',
    @VersionStamp = 'stale-stamp-value';
```

### 8.3 Check current VersionStamp before attempting a revert
```sql
SELECT ExecutionId, PlannedDate, VersionStamp
FROM Scheduler.Execution
WHERE ExecutionId = 856001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.RevertExecution | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.RevertExecution.sql*
