# Scheduler.UpdateExecutionsStatus

> Batch-updates the status of multiple executions, skipping any that are already in a terminal state (Done or Canceled), and returns the count of rows affected.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns @@ROWCOUNT indicating how many executions were updated |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.UpdateExecutionsStatus is a batch status-transition procedure that moves multiple executions to a new [ExecutionStatus](_glossary.md#execution-status) in a single call. It accepts a table-valued parameter (Scheduler.Ids TVP) containing the ExecutionIds to update and applies the specified @ExecutionStatus to all of them, with one critical guard: executions already in [Canceled](_glossary.md#execution-status) (4) or [Done](_glossary.md#execution-status) (6) status are skipped.

This terminal-state guard is essential for data integrity. Once an execution reaches Done (the payment was processed and the result recorded) or Canceled (the execution was deliberately stopped), its status must not be changed - doing so would corrupt the execution lifecycle and could lead to double-processing or incorrect reporting. The guard ensures that even if a batch contains a mix of in-progress and terminal executions, only the non-terminal ones are updated.

The procedure returns @@ROWCOUNT so the caller can verify how many executions were actually updated. If the returned count is less than the number of IDs provided, the difference represents executions that were already in a terminal state and were protected from the update.

---

## 2. Business Logic

### 2.1 Batch Status Transition with Terminal-State Guard

**What**: Updates ExecutionStatusId for a batch of executions while protecting terminal states from modification.

**Columns/Parameters Involved**: `@ExecutionIds` (Scheduler.Ids TVP), `@ExecutionStatus`, `ExecutionStatusId`

**Rules**:
- Updates ExecutionStatusId = @ExecutionStatus for all rows matching the TVP
- WHERE guard: ExecutionStatusId NOT IN (4, 6) prevents updating terminal states
  - 4 = Canceled (deliberately stopped)
  - 6 = Done (fully processed)
- All non-terminal statuses can be updated: 1=Planned, 2=WaitingForProcess, 3=Sent, 5=Failed
- No validation on the target @ExecutionStatus value - the caller is responsible for valid transitions
- Returns @@ROWCOUNT - count of actually updated rows
- If @@ROWCOUNT < count of IDs in TVP, some executions were in terminal state

### 2.2 TVP Batch Input

**What**: Accepts multiple ExecutionIds via the Scheduler.Ids table-valued parameter.

**Columns/Parameters Involved**: `@ExecutionIds` (Scheduler.Ids)

**Rules**:
- Uses the Scheduler.Ids TVP type (single Id column)
- Supports any number of ExecutionIds in a single call
- Enables efficient batch processing without multiple round-trips

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionIds | Scheduler.Ids (IN, TVP) | NO | - | VERIFIED | Table-valued parameter containing ExecutionId values to update. Uses the Scheduler.Ids type with a single Id column. |
| 2 | @ExecutionStatus | int (IN) | NO | - | VERIFIED | The target [Execution Status](_glossary.md#execution-status) to apply. 1=Planned, 2=WaitingForProcess, 3=Sent, 4=Canceled, 5=Failed, 6=Done. |
| 3 | (return) | int (OUT) | NO | - | CODE-BACKED | @@ROWCOUNT - the number of executions actually updated. May be less than the input count due to terminal-state protection. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionIds | Scheduler.Execution | PK parameter (batch) | Identifies executions to update via TVP |
| (UPDATE) | Scheduler.Execution | Direct Write | Updates ExecutionStatusId for non-terminal rows |
| @ExecutionIds | Scheduler.Ids | TVP Type | Uses the Scheduler.Ids table-valued type for batch input |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker transitions execution batches through lifecycle states |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.UpdateExecutionsStatus (procedure)
├── Scheduler.Execution (table)
└── Scheduler.Ids (TVP type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | WRITER - updates ExecutionStatusId for non-terminal executions |
| Scheduler.Ids | Table-Valued Type | INPUT - defines the shape of the @ExecutionIds batch parameter |

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

### 8.1 Mark a batch of executions as Sent (dispatched to billing provider)
```sql
DECLARE @Ids Scheduler.Ids;
INSERT INTO @Ids (Id) VALUES (856001), (856002), (856003);
EXEC Scheduler.UpdateExecutionsStatus @ExecutionIds = @Ids, @ExecutionStatus = 3;
```

### 8.2 Cancel a batch of planned executions
```sql
DECLARE @Ids Scheduler.Ids;
INSERT INTO @Ids (Id) VALUES (856010), (856011);
EXEC Scheduler.UpdateExecutionsStatus @ExecutionIds = @Ids, @ExecutionStatus = 4;
```

### 8.3 Verify which executions in a batch are in terminal state (would be skipped)
```sql
DECLARE @Ids Scheduler.Ids;
INSERT INTO @Ids (Id) VALUES (856001), (856002), (856003);

SELECT e.ExecutionId, e.ExecutionStatusId,
       CASE WHEN e.ExecutionStatusId IN (4, 6) THEN 'TERMINAL - would skip'
            ELSE 'Non-terminal - would update' END AS UpdateEligibility
FROM Scheduler.Execution e
WHERE e.ExecutionId IN (SELECT Id FROM @Ids);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.UpdateExecutionsStatus | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.UpdateExecutionsStatus.sql*
