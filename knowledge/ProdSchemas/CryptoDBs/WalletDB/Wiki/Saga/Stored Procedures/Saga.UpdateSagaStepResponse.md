# Saga.UpdateSagaStepResponse

> Updates a saga step's Response column with the execution output after the step completes, enabling subsequent steps to use the result.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: BIT UpdateStatus (1=updated, 0=not found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure updates the Response column on a saga step after its execution completes. The saga pipeline pattern works by passing each step's output as the next step's input context. This procedure stores the step's execution result so it can be read when the saga resumes or when investigating the saga's execution history.

The procedure resolves the step by SagaKey + StepIndex using a subquery to SagaRuns for the SagaRunId lookup, then updates the specific step's Response column.

---

## 2. Business Logic

No complex business logic. Single UPDATE with subquery-based step resolution.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Identifies the saga run. |
| 2 | @StepIndex | tinyint | NO | - | VERIFIED | Step position whose response to update. |
| 3 | @Response | varchar(max) | NO | - | CODE-BACKED | JSON output payload from step execution. Stored for pipeline continuity and debugging. |
| 4 | UpdateStatus (output) | bit | - | - | CODE-BACKED | 1 = step found and updated, 0 = step not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | SELECT (subquery) | Resolves SagaKey to SagaRunId |
| - | Saga.SagaSteps | UPDATE | Updates Response column |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.UpdateSagaStepResponse (procedure)
├── Saga.SagaRuns (table) [SELECT - subquery]
└── Saga.SagaSteps (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT - resolves SagaKey to Id |
| Saga.SagaSteps | Table | UPDATE - sets Response column |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

SET NOCOUNT ON. Uses NOLOCK for SagaRuns subquery.

---

## 8. Sample Queries

### 8.1 Set a step's response
```sql
EXEC Saga.UpdateSagaStepResponse
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @StepIndex = 3,
    @Response = '{"result":"approved","amlScore":0.1}'
```

### 8.2 N/A
N/A.

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.UpdateSagaStepResponse | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.UpdateSagaStepResponse.sql*
