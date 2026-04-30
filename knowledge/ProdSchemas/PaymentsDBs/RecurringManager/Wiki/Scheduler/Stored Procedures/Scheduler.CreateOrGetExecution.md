# Scheduler.CreateOrGetExecution

> Idempotently creates a new execution record for a payment execution or returns the existing one if already created, ensuring no duplicate scheduling for the same payment cycle.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns the Execution record (existing or newly created) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.CreateOrGetExecution is the primary WRITER procedure for the Scheduler.Execution table. When the RecurringScheduler application determines that a new billing cycle is due for a plan, it calls this procedure with the execution details. The procedure first checks if a record already exists for the given PaymentExecutionId - if yes, it returns the existing record; if no, it creates a new one and returns it.

This idempotent pattern is critical because the RecurringScheduler worker may restart or retry during execution creation. Without the EXISTS check, duplicate execution records could be created for the same billing cycle, leading to double-charges. The procedure guarantees exactly-once creation semantics at the database level.

Called by the RecurringScheduler application when generating the next execution for a plan. The application calculates the PlannedDate based on the plan's frequency and charging day, then passes all parameters. The procedure inserts with CreateDate = GETDATE(), Stamp = NULL, and ActualExecutionDate = NULL, placing the execution in Planned (1) status ready for the next processing cycle.

---

## 2. Business Logic

### 2.1 Idempotent Upsert Pattern

**What**: Ensures exactly one execution exists per PaymentExecutionId, preventing duplicate charges.

**Columns/Parameters Involved**: `@PaymentExecutionId`, `ExecutionId`

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM Execution WHERE PaymentExecutionId = @PaymentExecutionId) THEN INSERT
- The check + insert is NOT wrapped in a transaction - relies on the unique filtered index UQ_Scheduler_Execution for concurrency safety
- Always returns TOP 1 execution for the PaymentExecutionId regardless of whether insert occurred
- WARNING comment in code: "ON WORKING ON DUNNING SHOULD ADD FILTER BY ExecutionTypeId and ExecutionStatusId" - indicates the current check may need refinement when Dunning is implemented

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanId | int (IN) | NO | - | VERIFIED | FK to Scheduler.Plan.PlanId identifying which recurring schedule this execution belongs to. |
| 2 | @PaymentExecutionId | int (IN) | NO | - | VERIFIED | Cross-schema identifier for the payment execution in the Recurring schema. Used as the idempotency key - if an execution already exists for this PaymentExecutionId, no insert occurs. |
| 3 | @PlannedDate | datetime2 (IN) | NO | - | CODE-BACKED | The calculated UTC date when this execution should be processed. Derived by the application from the plan's frequency, start date, and charging day. |
| 4 | @ExecutionTypeId | int (IN) | NO | - | VERIFIED | 1=Planned (regular charge), 2=Dunning (retry). See [Execution Type](_glossary.md#execution-type). Currently commented out of the EXISTS check - will need adding for Dunning support. |
| 5 | @ExecutionStatusId | int (IN) | NO | - | CODE-BACKED | Initial status for the execution. Typically 1 (Planned). See [Execution Status](_glossary.md#execution-status). |
| 6 | @RecurringProgramTypeId | int (IN) | NO | - | CODE-BACKED | 1=RecurringDeposit, 2=RecurringInvestment. Routes the execution to the correct downstream handler. See [Recurring Program Type](_glossary.md#recurring-program-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PlanId | Scheduler.Plan | FK parameter | Links the new execution to its parent plan |
| (INSERT/SELECT) | Scheduler.Execution | Direct Write/Read | Creates new execution rows and reads existing ones |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by RecurringScheduler application.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.CreateOrGetExecution (procedure)
└── Scheduler.Execution (table)
    └── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | WRITER/READER - inserts new execution or reads existing one |

### 6.2 Objects That Depend On This

No dependents found. Called by RecurringScheduler application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create a new planned execution for a recurring deposit
```sql
EXEC Scheduler.CreateOrGetExecution
    @PlanId = 189836,
    @PaymentExecutionId = 859999,
    @PlannedDate = '2026-06-01T14:00:00',
    @ExecutionTypeId = 1,
    @ExecutionStatusId = 1,
    @RecurringProgramTypeId = 1;
```

### 8.2 Idempotent retry - returns existing record without duplicate insert
```sql
-- Calling again with same PaymentExecutionId returns the existing record
EXEC Scheduler.CreateOrGetExecution
    @PlanId = 189836,
    @PaymentExecutionId = 859999,
    @PlannedDate = '2026-06-01T14:00:00',
    @ExecutionTypeId = 1,
    @ExecutionStatusId = 1,
    @RecurringProgramTypeId = 1;
```

### 8.3 Verify the execution was created correctly
```sql
SELECT e.*, es.Name AS StatusName, et.Name AS TypeName
FROM Scheduler.Execution e WITH (NOLOCK)
JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON e.ExecutionStatusId = es.ExecutionStatusID
JOIN Dictionary.ExecutionType et WITH (NOLOCK) ON e.ExecutionTypeId = et.ExecutionTypeId
WHERE e.PaymentExecutionId = 859999;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.CreateOrGetExecution | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.CreateOrGetExecution.sql*
