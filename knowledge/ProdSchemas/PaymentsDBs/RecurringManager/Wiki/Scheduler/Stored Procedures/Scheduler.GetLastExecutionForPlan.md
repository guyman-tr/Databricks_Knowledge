# Scheduler.GetLastExecutionForPlan

> Retrieves the single most recent execution for a plan filtered by execution type, used to determine scheduling state and calculate the next due date.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 1 Execution row (most recent by ExecutionId) for the specified PlanId and ExecutionTypeId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.GetLastExecutionForPlan retrieves the most recent execution record for a given plan and [execution type](_glossary.md#execution-type). By selecting TOP 1 ordered by ExecutionId DESC, it returns the latest execution - which may be the currently active one or the most recently completed one. This is a key building block for the scheduling engine's date-calculation logic.

The RecurringScheduler application needs to know the last execution's PlannedDate and status to calculate when the next execution should occur. For example, if the last planned execution for a monthly plan was on March 1, the next one should be April 1. By filtering on ExecutionTypeId, the caller can separately track the last regular charge (1=Planned) vs. the last dunning retry (2=Dunning), which follow independent scheduling cadences.

The procedure returns the full execution record including temporal columns (SysStartTime, SysEndTime) from the system-versioned Scheduler.Execution table and the RecurringProgramTypeId. This is one of the few procedures that exposes the system-versioning columns, which can be useful for auditing when the record was last modified.

---

## 2. Business Logic

### 2.1 Most Recent Execution Lookup

**What**: Returns the single newest execution for a plan and execution type combination.

**Columns/Parameters Involved**: `@PlanId`, `@ExecutionTypeId`, `ExecutionId`

**Rules**:
- Filters by exact match on PlanId AND ExecutionTypeId
- Returns TOP (1) ordered by ExecutionId DESC - the most recently created execution
- ExecutionTypeId separates planned (1) and dunning (2) execution chains
- Returns zero rows if no executions exist for the given plan/type combination
- Includes SysStartTime and SysEndTime temporal columns from the system-versioned table
- No NOLOCK hint - reads with default isolation level
- Does not filter by ExecutionStatusId - returns the latest regardless of status

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanId | int (IN) | NO | - | VERIFIED | FK to Scheduler.Plan.PlanId. The recurring plan to look up. |
| 2 | @ExecutionTypeId | int (IN) | NO | - | VERIFIED | Filters by [Execution Type](_glossary.md#execution-type). 1=Planned (regular), 2=Dunning (retry). Separates the two execution chains for independent tracking. |
| 3 | ExecutionId | int (OUT) | NO | - | CODE-BACKED | Primary key of the most recent matching execution. |
| 4 | PlanId | int (OUT) | NO | - | CODE-BACKED | FK to Scheduler.Plan - matches @PlanId. |
| 5 | PaymentExecutionId | int (OUT) | YES | - | CODE-BACKED | Cross-schema link to the Recurring schema's payment execution. |
| 6 | PlannedDate | datetime2 (OUT) | NO | - | CODE-BACKED | The scheduled UTC date for this execution. Used by the caller to calculate the next execution date. |
| 7 | ExecutionTypeId | int (OUT) | NO | - | CODE-BACKED | Matches @ExecutionTypeId. 1=Planned, 2=Dunning. |
| 8 | ExecutionStatusId | int (OUT) | NO | - | CODE-BACKED | Current lifecycle state. See [Execution Status](_glossary.md#execution-status). 1=Planned, 2=WaitingForProcess, 3=Sent, 4=Canceled, 5=Failed, 6=Done. |
| 9 | CreateDate | datetime (OUT) | NO | - | CODE-BACKED | UTC timestamp when the execution was created. |
| 10 | Stamp | uniqueidentifier (OUT) | YES | - | CODE-BACKED | Distributed lock GUID. NULL = unclaimed. |
| 11 | ActualExecutionDate | datetime (OUT) | YES | - | CODE-BACKED | UTC timestamp when a worker actually picked up the execution. |
| 12 | SysStartTime | datetime2 (OUT) | NO | - | CODE-BACKED | System-versioning start timestamp - when this version of the row became current. |
| 13 | SysEndTime | datetime2 (OUT) | NO | - | CODE-BACKED | System-versioning end timestamp - max datetime2 for current rows. |
| 14 | RecurringProgramTypeId | int (OUT) | YES | - | CODE-BACKED | 1=RecurringDeposit, 2=RecurringInvestment. See [Recurring Program Type](_glossary.md#recurring-program-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PlanId | Scheduler.Plan | FK parameter | Identifies the plan whose last execution is requested |
| (SELECT) | Scheduler.Execution | Direct Read | Reads the most recent execution for the plan/type combination |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker queries last execution to calculate the next execution date |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.GetLastExecutionForPlan (procedure)
└── Scheduler.Execution (table)
    └── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | READER - retrieves the most recent execution by PlanId and ExecutionTypeId |

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

### 8.1 Get the last planned execution for a plan
```sql
EXEC Scheduler.GetLastExecutionForPlan @PlanId = 189836, @ExecutionTypeId = 1;
```

### 8.2 Get the last dunning execution for a plan
```sql
EXEC Scheduler.GetLastExecutionForPlan @PlanId = 189836, @ExecutionTypeId = 2;
```

### 8.3 Manually check last execution with status label
```sql
SELECT TOP 1 e.ExecutionId, e.PlannedDate, e.ExecutionStatusId, es.Name AS StatusName
FROM Scheduler.Execution e
JOIN Dictionary.ExecutionStatus es ON e.ExecutionStatusId = es.ExecutionStatusID
WHERE e.PlanId = 189836 AND e.ExecutionTypeId = 1
ORDER BY e.ExecutionId DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.GetLastExecutionForPlan | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.GetLastExecutionForPlan.sql*
