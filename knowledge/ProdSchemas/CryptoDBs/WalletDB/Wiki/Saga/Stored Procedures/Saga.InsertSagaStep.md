# Saga.InsertSagaStep

> Atomically creates a new saga step record and its initial status entry within a transaction, with duplicate prevention and saga existence validation.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: implicit (SCOPE_IDENTITY or error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a new step record for a saga run. Each saga step represents one unit of work in the multi-step pipeline (e.g., AML check, travel rule verification). The procedure atomically inserts into both `Saga.SagaSteps` (the step itself) and `Saga.SagaStepStatuses` (the initial status history) within an explicit transaction.

The procedure validates: (1) the saga run exists (by SagaKey lookup), and (2) the step doesn't already exist for this run+index combination (WHERE NOT EXISTS). Both validations use RAISERROR on failure. This prevents duplicate steps from being created if the saga coordinator retries after a transient failure.

---

## 2. Business Logic

### 2.1 Atomic Step Creation with Validation

**What**: Creates step + initial status with duplicate prevention.

**Columns/Parameters Involved**: `@SagaKey`, `@StepIndex`, `@Request`, `@Response`, `@StepStatusTypeId`

**Rules**:
- Resolves @SagaRunId from SagaRuns by @SagaKey
- If SagaKey not found: RAISERROR 'Run not found'
- INSERT INTO SagaSteps WHERE NOT EXISTS (SagaRunId + StepIndex)
- If step already exists: RAISERROR 'Step already exists in run'
- INSERT INTO SagaStepStatuses with the initial status
- All within BEGIN TRANSACTION / COMMIT

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Identifies the parent saga run. Resolved to SagaRunId via lookup. |
| 2 | @StepIndex | tinyint | NO | - | VERIFIED | 1-based step position in the pipeline. Must be unique within the saga run. |
| 3 | @Request | varchar(max) | NO | - | CODE-BACKED | JSON input payload for this step's execution. |
| 4 | @Response | varchar(max) | NO | - | CODE-BACKED | JSON output payload. May be populated at creation or updated later via UpdateSagaStepResponse. |
| 5 | @StepStatusTypeId | tinyint | NO | - | VERIFIED | Initial step status: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. See [Step Status Type](../../_glossary.md#step-status-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | SELECT (lookup) | Resolves SagaKey to SagaRunId |
| - | Saga.SagaSteps | INSERT INTO | Creates the step record |
| - | Saga.SagaStepStatuses | INSERT INTO | Creates the initial status history |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.InsertSagaStep (procedure)
├── Saga.SagaRuns (table) [SELECT - lookup]
├── Saga.SagaSteps (table) [INSERT INTO]
└── Saga.SagaStepStatuses (table) [INSERT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT - resolves SagaKey to SagaRunId |
| Saga.SagaSteps | Table | INSERT INTO (with duplicate check) |
| Saga.SagaStepStatuses | Table | INSERT INTO (initial status) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Explicit transaction. TRY/CATCH. RAISERROR on missing run or duplicate step. Uses NOLOCK for lookups.

---

## 8. Sample Queries

### 8.1 Create step 1 for a saga
```sql
EXEC Saga.InsertSagaStep
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @StepIndex = 1,
    @Request = '{"CorrelationId":"f08f...","Transaction":{...}}',
    @Response = NULL,
    @StepStatusTypeId = 1
```

### 8.2 N/A
N/A.

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.InsertSagaStep | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.InsertSagaStep.sql*
