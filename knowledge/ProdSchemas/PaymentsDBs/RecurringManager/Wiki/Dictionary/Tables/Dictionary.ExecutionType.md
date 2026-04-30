# Dictionary.ExecutionType

> Lookup table classifying whether a scheduled execution is a regular planned charge (Planned) or a dunning retry attempt following a previous soft decline (Dunning).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ExecutionTypeId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ExecutionType classifies the origin of a scheduled execution: whether it is a regular Planned charge based on the plan's frequency schedule, or a Dunning retry created after a previous execution was soft-declined by the billing provider. This is a core branching dimension in the scheduler - many stored procedures accept @ExecutionTypeId to filter which processing path an execution follows.

This distinction exists because planned and dunning executions follow different scheduling rules, may have different batch sizes, and are processed by separate job types (JobType.Recurring vs JobType.Dunning). The scheduler needs to know the execution's origin to apply the correct processing logic and to avoid mixing regular charges with retry attempts.

ExecutionTypeId is stored on Scheduler.Execution records and is passed as a parameter to most scheduler stored procedures. It is heavily indexed on the Execution table for efficient filtering and is used in composite unique constraints to prevent duplicate executions.

---

## 2. Business Logic

### 2.1 Planned vs Dunning Execution Paths

**What**: The system maintains two distinct execution paths - regular scheduled charges and retry attempts - each with its own processing rules and scheduling cadence.

**Columns/Parameters Involved**: `ExecutionTypeId`, `Name`

**Rules**:
- Planned (1) executions are created by the scheduler based on the plan's Frequency (Weekly/BiWeekly/Monthly)
- Dunning (2) executions are created when a previous execution returns SoftDecline from the billing provider
- Scheduler.GetPlansWithLastAndNextExecutions specifically filters ExecutionTypeId=1 to show only planned execution history
- Scheduler.CreateOrGetExecution accepts @ExecutionTypeId to create the correct type
- Maps 1:1 to JobType: Recurring jobs create Planned executions, Dunning jobs create Dunning executions

**Diagram**:
```
Plan Frequency Trigger         SoftDecline Response
        |                              |
        v                              v
Planned Execution (1)         Dunning Execution (2)
        |                              |
        v                              v
  Recurring Job               Dunning Job
  (JobType=1)                 (JobType=2)
```

---

## 3. Data Overview

| ExecutionTypeId | Name | Meaning |
|---|---|---|
| 1 | Planned | A regularly scheduled execution based on the plan's frequency - the normal charge cycle. Created automatically when a plan's next execution date arrives. |
| 2 | Dunning | A retry execution created after a soft-declined attempt. Part of the payment recovery process, scheduled according to dunning rules rather than the plan's frequency. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionTypeId | int | NO | - | VERIFIED | Primary key identifying the execution type. 1=Planned (regular scheduled charge), 2=Dunning (retry after soft decline). Core branching parameter for scheduler stored procedures. See [Execution Type](../../_glossary.md#execution-type) for full definitions. (Dictionary.ExecutionType) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the execution type. Values: "Planned", "Dunning". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduler.Execution | ExecutionTypeId | Implicit FK | Classifies each execution as Planned or Dunning. Multiple indexes include this column. Part of unique constraint UQ_Scheduler_Execution_PaymentExecutionId_ExecutionTypeId_ExecutionStatusId. |
| History.Execution | ExecutionTypeId | Implicit FK | Archived executions retain their type for audit trail |
| Scheduler.CreateOrGetExecution | @ExecutionTypeId | Parameter | Input parameter determining which type of execution to create |
| Scheduler.GetExecutionsToProcessWithLock | @ExecutionTypeId | Parameter | Filters processing batch by execution type |
| Scheduler.SetStampForExecutionsWithLock | @ExecutionTypeId | Parameter | Stamps only executions of the specified type |
| Scheduler.GetLastExecutionForPlan | @ExecutionTypeId | Parameter | Retrieves last execution of a specific type for a plan |
| Scheduler.GetPlansWithLastAndNextExecutions | (inline filter) | Hardcoded | Filters ExecutionTypeId=1 (Planned) for showing plan execution history |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | ExecutionTypeId column classifies execution origin |
| History.Execution | Table | Archived execution type for audit |
| Scheduler.CreateOrGetExecution | Stored Procedure | @ExecutionTypeId parameter for creation |
| Scheduler.GetExecutionsToProcessWithLock | Stored Procedure | @ExecutionTypeId parameter for batch filtering |
| Scheduler.SetStampForExecutionsWithLock | Stored Procedure | @ExecutionTypeId parameter for stamping |
| Scheduler.GetLastExecutionForPlan | Stored Procedure | @ExecutionTypeId parameter for type-specific lookup |
| Scheduler.GetPlansWithLastAndNextExecutions | Stored Procedure | Hardcoded filter ExecutionTypeId=1 |
| Scheduler.GetExecutionByPaymentExecution | Stored Procedure | Reads ExecutionTypeId |
| Scheduler.GetExecutionsForPlan | Stored Procedure | Reads ExecutionTypeId |
| Scheduler.RevertExecution | Stored Procedure | Reads ExecutionTypeId |
| Scheduler.UpdateExecutionPlannedDate | Stored Procedure | Reads ExecutionTypeId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ExecutionType | CLUSTERED PK | ExecutionTypeId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_ExecutionType | PRIMARY KEY | Ensures each execution type has a unique integer identifier |

---

## 8. Sample Queries

### 8.1 List all execution types
```sql
SELECT ExecutionTypeId, Name
FROM Dictionary.ExecutionType WITH (NOLOCK)
ORDER BY ExecutionTypeId
```

### 8.2 Count executions by type
```sql
SELECT et.Name AS ExecutionType, COUNT(*) AS ExecutionCount
FROM Scheduler.Execution e WITH (NOLOCK)
INNER JOIN Dictionary.ExecutionType et WITH (NOLOCK) ON e.ExecutionTypeId = et.ExecutionTypeId
GROUP BY et.Name
```

### 8.3 Find dunning executions for a specific plan
```sql
SELECT e.ExecutionId, e.PlannedDate, e.ExecutionStatusId, et.Name AS ExecutionType
FROM Scheduler.Execution e WITH (NOLOCK)
INNER JOIN Dictionary.ExecutionType et WITH (NOLOCK) ON e.ExecutionTypeId = et.ExecutionTypeId
WHERE e.PlanId = @PlanId AND e.ExecutionTypeId = 2 -- Dunning
ORDER BY e.PlannedDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Business flow: Plan execution and dunning are separate processing paths with distinct scheduling jobs |
| [Recurring Scheduler](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891789) | Confluence | Architecture: RecurringScheduler worker drives both Planned and Dunning execution processing |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.9/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 7 analyzed (references) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ExecutionType | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.ExecutionType.sql*
