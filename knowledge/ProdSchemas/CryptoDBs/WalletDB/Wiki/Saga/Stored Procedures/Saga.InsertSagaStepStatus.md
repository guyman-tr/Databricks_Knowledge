# Saga.InsertSagaStepStatus

> Transitions a saga step's status by atomically updating SagaSteps and inserting a history record into SagaStepStatuses using the OUTPUT clause.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: implicit (rows affected) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the step-level equivalent of `Saga.InsertSagaRunStatus`. It transitions a saga step's status by atomically updating the denormalized `StepStatusTypeId` on `Saga.SagaSteps` and inserting a history record into `Saga.SagaStepStatuses` via the OUTPUT clause.

Called by the saga coordinator after each step completes, fails, is scheduled for retry, or enters any new state. The procedure resolves the step by SagaKey + StepIndex (looking up SagaRunId first, then finding the specific step).

---

## 2. Business Logic

### 2.1 Atomic Step Status Transition

**What**: Updates current step status and writes history atomically.

**Columns/Parameters Involved**: `@SagaKey`, `@StepIndex`, `@StepStatusTypeId`

**Rules**:
- Resolves @SagaRunId from SagaRuns by @SagaKey
- Resolves @SagaStepId from SagaSteps by SagaRunId + StepIndex
- RAISERROR if run or step not found
- UPDATE SagaSteps SET StepStatusTypeId = @StepStatusTypeId
- OUTPUT @SagaStepId, GETUTCDATE(), @StepStatusTypeId INTO SagaStepStatuses
- No explicit transaction needed (OUTPUT provides atomicity)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Identifies the saga run. |
| 2 | @StepIndex | tinyint | NO | - | VERIFIED | Step position to update. |
| 3 | @StepStatusTypeId | tinyint | NO | - | VERIFIED | New step status: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. See [Step Status Type](../../_glossary.md#step-status-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | SELECT (lookup) | Resolves SagaKey to SagaRunId |
| - | Saga.SagaSteps | UPDATE + SELECT | Finds step by RunId+Index, updates status |
| OUTPUT | Saga.SagaStepStatuses | INSERT (via OUTPUT INTO) | Writes status history atomically |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.InsertSagaStepStatus (procedure)
├── Saga.SagaRuns (table) [SELECT - lookup]
├── Saga.SagaSteps (table) [UPDATE]
└── Saga.SagaStepStatuses (table) [OUTPUT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT - resolves SagaKey to SagaRunId |
| Saga.SagaSteps | Table | UPDATE - changes step status |
| Saga.SagaStepStatuses | Table | OUTPUT INTO - writes history |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

SET NOCOUNT ON. RAISERROR on missing run or step. Uses NOLOCK for lookups.

---

## 8. Sample Queries

### 8.1 Mark a step as Done
```sql
EXEC Saga.InsertSagaStepStatus
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @StepIndex = 3, @StepStatusTypeId = 4
```

### 8.2 Schedule a step for deferred execution
```sql
EXEC Saga.InsertSagaStepStatus
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @StepIndex = 5, @StepStatusTypeId = 5
```

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.InsertSagaStepStatus | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.InsertSagaStepStatus.sql*
