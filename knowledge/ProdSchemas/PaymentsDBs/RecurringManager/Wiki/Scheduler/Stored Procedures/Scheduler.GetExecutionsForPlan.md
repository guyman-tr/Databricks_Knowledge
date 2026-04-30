# Scheduler.GetExecutionsForPlan

> Retrieves the most recent executions for a given plan, optionally filtered by execution status, supporting plan-level execution history and diagnostics.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns up to @TakeLast Execution rows for the specified PlanId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.GetExecutionsForPlan retrieves the execution history for a specific recurring payment plan. It returns the most recent executions (ordered by ExecutionId descending) up to a configurable limit, with an optional filter by [ExecutionStatus](_glossary.md#execution-status). This is the primary procedure for viewing what has happened - and what is scheduled to happen - for a particular plan.

This procedure supports several use cases: customer support agents reviewing a user's recurring payment history, the application displaying execution history in a user-facing dashboard, and diagnostic workflows investigating why a plan's executions behaved unexpectedly. The optional status filter allows callers to focus on specific lifecycle stages - for example, showing only Planned (1) executions to display upcoming charges, or only Failed (5) executions to investigate problems.

The procedure uses ISNULL(@ExecutionStatus, e.ExecutionStatusId) as a pattern to make the status filter optional: when @ExecutionStatus is NULL, the WHERE clause becomes a tautology (e.ExecutionStatusId = e.ExecutionStatusId) and all statuses are returned. Results are ordered by ExecutionId DESC (most recent first) and limited by @TakeLast (default 1000).

---

## 2. Business Logic

### 2.1 Plan Execution History Retrieval

**What**: Returns the most recent executions for a plan with optional status filtering.

**Columns/Parameters Involved**: `@PlanId`, `@ExecutionStatus`, `@TakeLast`, `ExecutionId`

**Rules**:
- Filters by exact PlanId match
- When @ExecutionStatus is NULL, returns executions in all statuses
- When @ExecutionStatus is provided, returns only executions matching that status (1=Planned, 2=WaitingForProcess, 3=Sent, 4=Canceled, 5=Failed, 6=Done)
- Results ordered by ExecutionId DESC - newest first
- TOP (@TakeLast) limits result set size, default 1000 rows
- No NOLOCK hint - reads with default isolation for consistency
- Returns RecurringProgramTypeId (1=RecurringDeposit, 2=RecurringInvestment)
- Does not return VersionStamp or system-versioning temporal columns

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanId | int (IN) | NO | - | VERIFIED | FK to Scheduler.Plan.PlanId. Identifies the recurring plan whose execution history is requested. |
| 2 | @ExecutionStatus | int (IN) | YES | NULL | CODE-BACKED | Optional filter by [Execution Status](_glossary.md#execution-status). NULL returns all statuses. 1=Planned, 2=WaitingForProcess, 3=Sent, 4=Canceled, 5=Failed, 6=Done. |
| 3 | @TakeLast | int (IN) | NO | 1000 | CODE-BACKED | Maximum number of rows to return. Caps the result set to prevent unbounded queries on plans with very long execution histories. |
| 4 | ExecutionId | int (OUT) | NO | - | CODE-BACKED | Primary key of the execution record. Results are sorted by this column descending. |
| 5 | PlanId | int (OUT) | NO | - | CODE-BACKED | FK to Scheduler.Plan - will match @PlanId for all returned rows. |
| 6 | PaymentExecutionId | int (OUT) | YES | - | CODE-BACKED | Cross-schema link to the Recurring schema's payment execution record. |
| 7 | PlannedDate | datetime2 (OUT) | NO | - | CODE-BACKED | Scheduled UTC date for this execution. |
| 8 | ExecutionTypeId | int (OUT) | NO | - | CODE-BACKED | 1=Planned, 2=Dunning. See [Execution Type](_glossary.md#execution-type). |
| 9 | ExecutionStatusId | int (OUT) | NO | - | CODE-BACKED | Current lifecycle state. See [Execution Status](_glossary.md#execution-status). |
| 10 | CreateDate | datetime (OUT) | NO | - | CODE-BACKED | UTC timestamp when the execution was created. |
| 11 | Stamp | uniqueidentifier (OUT) | YES | - | CODE-BACKED | Distributed lock GUID. NULL = unclaimed. |
| 12 | ActualExecutionDate | datetime (OUT) | YES | - | CODE-BACKED | UTC timestamp when a worker picked up the execution. |
| 13 | RecurringProgramTypeId | int (OUT) | YES | - | CODE-BACKED | 1=RecurringDeposit, 2=RecurringInvestment. See [Recurring Program Type](_glossary.md#recurring-program-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PlanId | Scheduler.Plan | FK parameter | Filters executions by the specified plan |
| (SELECT) | Scheduler.Execution | Direct Read | Reads execution rows for the given plan |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker retrieves execution history for plan management |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.GetExecutionsForPlan (procedure)
└── Scheduler.Execution (table)
    └── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | READER - retrieves executions filtered by PlanId and optional status |

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

### 8.1 Get the last 10 executions for a plan regardless of status
```sql
EXEC Scheduler.GetExecutionsForPlan @PlanId = 189836, @TakeLast = 10;
```

### 8.2 Get only planned (upcoming) executions for a plan
```sql
EXEC Scheduler.GetExecutionsForPlan @PlanId = 189836, @ExecutionStatus = 1;
```

### 8.3 Get failed executions for a plan to investigate processing issues
```sql
EXEC Scheduler.GetExecutionsForPlan @PlanId = 189836, @ExecutionStatus = 5;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.GetExecutionsForPlan | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.GetExecutionsForPlan.sql*
