# Scheduler.GetExecutionByPaymentExecution

> Retrieves a single scheduler execution record by its corresponding PaymentExecutionId, bridging the Scheduler and Recurring schemas.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns a single Execution row matching the PaymentExecutionId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.GetExecutionByPaymentExecution is a lookup procedure that retrieves a scheduler execution record using the PaymentExecutionId - the foreign key that links a scheduler-level execution to its corresponding payment execution in the Recurring schema. This is the primary cross-schema lookup path when the calling application has a PaymentExecutionId and needs to find the scheduler's view of that execution.

This procedure serves correlation workflows where downstream systems (payment processing, billing callbacks, status updates) reference the PaymentExecutionId and need to resolve it back to the scheduler's execution record. For example, when the billing provider returns a result for a PaymentExecution, the system needs to update the corresponding Scheduler.Execution record - this procedure provides that lookup.

The query is a straightforward single-table SELECT with no joins, filters, or locking hints. It returns all columns from Scheduler.Execution for the matching PaymentExecutionId, including the [Stamp](_glossary.md#execution-status) (distributed lock GUID), [ExecutionStatusId](_glossary.md#execution-status), and [ExecutionTypeId](_glossary.md#execution-type). Note that it does not include RecurringProgramTypeId in the output, unlike some other execution-reading procedures.

---

## 2. Business Logic

### 2.1 PaymentExecutionId Lookup

**What**: Retrieves the scheduler execution record by its payment-level execution identifier.

**Columns/Parameters Involved**: `@PaymentExecutionId`, `Scheduler.Execution.PaymentExecutionId`

**Rules**:
- Exact match on PaymentExecutionId - returns all columns for the matching execution
- PaymentExecutionId should be unique per execution (enforced by unique filtered index on the table)
- Returns zero rows if no execution exists for the given PaymentExecutionId
- Does not use NOLOCK - reads with default isolation level for data consistency
- Does not return RecurringProgramTypeId (unlike GetExecutionsForPlan and other readers)
- Returns VersionStamp, which is used for optimistic concurrency control

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentExecutionId | int (IN) | NO | - | VERIFIED | The payment execution identifier from the Recurring schema. Used to look up the corresponding scheduler-level execution record. |
| 2 | ExecutionId | int (OUT) | NO | - | CODE-BACKED | Primary key of the scheduler execution record. |
| 3 | PlanId | int (OUT) | NO | - | CODE-BACKED | FK to Scheduler.Plan - identifies which recurring schedule this execution belongs to. |
| 4 | PaymentExecutionId | int (OUT) | YES | - | CODE-BACKED | The payment-level execution ID that was used as the lookup key. |
| 5 | PlannedDate | datetime2 (OUT) | NO | - | CODE-BACKED | The scheduled UTC date when this execution was meant to be processed. |
| 6 | ExecutionTypeId | int (OUT) | NO | - | CODE-BACKED | 1=Planned, 2=Dunning. See [Execution Type](_glossary.md#execution-type). |
| 7 | ExecutionStatusId | int (OUT) | NO | - | CODE-BACKED | Current lifecycle state. See [Execution Status](_glossary.md#execution-status). 1=Planned, 2=WaitingForProcess, 3=Sent, 4=Canceled, 5=Failed, 6=Done. |
| 8 | CreateDate | datetime (OUT) | NO | - | CODE-BACKED | UTC timestamp when the execution record was originally created. |
| 9 | Stamp | uniqueidentifier (OUT) | YES | - | CODE-BACKED | Distributed lock GUID. NULL means unclaimed; non-NULL means a worker owns this execution. |
| 10 | ActualExecutionDate | datetime (OUT) | YES | - | CODE-BACKED | UTC timestamp when a worker actually picked up this execution for processing. NULL if not yet claimed. |
| 11 | VersionStamp | nvarchar (OUT) | YES | - | CODE-BACKED | Optimistic concurrency token used by RevertExecution and UpdateExecutionPlannedDate for conflict detection. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Scheduler.Execution | Direct Read | Reads execution by PaymentExecutionId |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker looks up scheduler execution when processing payment execution callbacks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.GetExecutionByPaymentExecution (procedure)
└── Scheduler.Execution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | READER - looks up execution by PaymentExecutionId |

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

### 8.1 Look up a scheduler execution for a known PaymentExecutionId
```sql
EXEC Scheduler.GetExecutionByPaymentExecution @PaymentExecutionId = 859999;
```

### 8.2 Verify the status of a specific payment execution in the scheduler
```sql
DECLARE @PayExecId INT = 850001;
EXEC Scheduler.GetExecutionByPaymentExecution @PaymentExecutionId = @PayExecId;
```

### 8.3 Cross-reference: find the execution and then inspect its plan
```sql
-- Step 1: Get the execution
SELECT e.ExecutionId, e.PlanId, e.ExecutionStatusId, e.PlannedDate
FROM Scheduler.Execution e
WHERE e.PaymentExecutionId = 859999;

-- Step 2: Get the plan for that execution
SELECT p.*
FROM Scheduler.[Plan] p
WHERE p.PlanId = (SELECT e.PlanId FROM Scheduler.Execution e WHERE e.PaymentExecutionId = 859999);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.GetExecutionByPaymentExecution | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.GetExecutionByPaymentExecution.sql*
