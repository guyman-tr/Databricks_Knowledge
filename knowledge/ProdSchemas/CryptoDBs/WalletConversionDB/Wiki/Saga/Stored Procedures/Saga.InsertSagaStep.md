# Saga.InsertSagaStep

> Atomically creates a new step within a saga run, inserting both the step record and its initial status history entry in a single transaction with deduplication protection.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into Saga.SagaSteps + Saga.SagaStepStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertSagaStep is the step creation procedure - the entry point for adding a new discrete operation to a saga run. Each CryptoToFiatSaga consists of up to 11 ordered steps (validate, lock crypto, calculate fiat, execute conversion, credit fiat, etc.), and this procedure creates each one. It atomically inserts the step row into SagaSteps and the initial status row into SagaStepStatuses, all within a transaction.

This is one of the most critical write procedures in the saga system. Every step in every saga conversion flows through this procedure. The transactional guarantee ensures a step is either fully initialized (with step record + status history) or not created at all. The deduplication check prevents the same step from being created twice during recovery scenarios where the orchestrator may re-attempt step creation.

The procedure is called by the conversion worker application during saga execution. After a step completes, the response can be updated via `Saga.UpdateSagaStepResponse`, and the status can be transitioned via `Saga.InsertSagaStepStatus`.

---

## 2. Business Logic

### 2.1 Transactional Two-Table Insert with Deduplication

**What**: Creates SagaSteps row and SagaStepStatuses row in a single transaction, with idempotency guard.

**Columns/Parameters Involved**: `@SagaKey`, `@StepIndex`, `@Request`, `@Response`, `@StepStatusTypeId`

**Rules**:
1. BEGIN TRANSACTION
2. Look up @SagaRunId from SagaRuns WHERE SagaKey = @SagaKey (NOLOCK)
3. If @SagaRunId IS NULL -> RAISERROR 'Run "{sagaKey}" not found'
4. INSERT INTO SagaSteps WHERE NOT EXISTS (SELECT 1 FROM SagaSteps WHERE SagaRunId = @SagaRunId AND StepIndex = @StepIndex)
5. Get @SagaStepId = SCOPE_IDENTITY()
6. If @SagaStepId IS NULL -> RAISERROR 'Step "{index}" already exists in run "{sagaKey}"'
7. INSERT INTO SagaStepStatuses (SagaStepId, Created = GETUTCDATE(), StepStatusTypeId)
8. COMMIT TRANSACTION
- On error: ROLLBACK if @@trancount=1, COMMIT if @@trancount>1 (nested transaction support)

### 2.2 Step Deduplication

**What**: Prevents duplicate step creation for the same (SagaRunId, StepIndex) combination.

**Columns/Parameters Involved**: `@SagaKey`, `@StepIndex`

**Rules**:
- Uses NOT EXISTS check before INSERT (application-level dedup)
- SagaSteps has UNIQUE index on (SagaRunId, StepIndex) (database-level enforcement)
- Critical for recovery scenarios: if a worker crashes after creating a step but before recording success, the recovering worker can safely retry without creating duplicates
- Error message includes the SagaKey string and StepIndex for diagnostic clarity

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Business-level identifier of the parent saga run. Used to look up SagaRuns.Id via SagaKey. The procedure operates on the saga by its business key, not by internal Id. |
| 2 | @StepIndex | tinyint | NO | - | VERIFIED | Ordinal position of this step in the saga pipeline (1-11 for CryptoToFiatSaga). Determines execution order (forward) and compensation order (reverse for rollback). Part of unique constraint with SagaRunId. |
| 3 | @Request | varchar(max) | NO | - | VERIFIED | Serialized JSON input data for this step's operation. Contains StepStartTime, accumulated context from previous steps, and step-specific parameters (wallet IDs, conversion rates, etc.). Stored in SagaSteps.Request. |
| 4 | @Response | varchar(max) | NO | - | VERIFIED | Serialized JSON output of this step's execution (if immediately available). Contains the step result and data to pass to the next step. Can be NULL on initial insert and updated later via UpdateSagaStepResponse. Stored in SagaSteps.Response. |
| 5 | @StepStatusTypeId | tinyint | NO | - | VERIFIED | Initial status for the step. Values: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. See [Step Status Type](../../_glossary.md#step-status-type). Stored in both SagaSteps.StepStatusTypeId and the initial SagaStepStatuses row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | SELECT (lookup) | Reads SagaRuns.Id by SagaKey to establish the parent relationship |
| - | Saga.SagaSteps | INSERT target | Creates the step row with all step attributes |
| - | Saga.SagaStepStatuses | INSERT target | Creates the initial status history row for the new step |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.InsertSagaStep (procedure)
├── Saga.SagaRuns (table) - lookup by SagaKey
├── Saga.SagaSteps (table) - INSERT target + dedup check
└── Saga.SagaStepStatuses (table) - INSERT initial status
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT - looks up Id by SagaKey, validates saga exists |
| Saga.SagaSteps | Table | INSERT target + EXISTS check for deduplication |
| Saga.SagaStepStatuses | Table | INSERT target - initial step status history row |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | BEGIN/COMMIT/ROLLBACK | Ensures atomicity: step + status inserted together or not at all |
| Dedup guard | NOT EXISTS + SCOPE_IDENTITY check | Two-layer protection: query-level and identity-level |

---

## 8. Sample Queries

### 8.1 Create a new step for a saga
```sql
EXEC Saga.InsertSagaStep
    @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E',
    @StepIndex = 1,
    @Request = '{"StepStartTime":"2026-04-15T08:00:00Z","RootRequest":{"SourceWalletId":"abc123"}}',
    @Response = '{"result":"pending"}',
    @StepStatusTypeId = 1 -- Start
```

### 8.2 Create a scheduled step (not yet executing)
```sql
EXEC Saga.InsertSagaStep
    @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E',
    @StepIndex = 5,
    @Request = '{"StepStartTime":"2026-04-15T08:01:00Z"}',
    @Response = NULL,
    @StepStatusTypeId = 5 -- Schedule
```

### 8.3 Verify step was created with initial status
```sql
SELECT s.StepIndex, sst.Name AS StepStatus, s.Created, ss.Created AS StatusCreated
FROM Saga.SagaSteps s WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = s.SagaRunId
INNER JOIN Saga.SagaStepStatuses ss WITH (NOLOCK) ON ss.SagaStepId = s.Id
INNER JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sst.Id = ss.StepStatusTypeId
WHERE sr.SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
AND s.StepIndex = 1
ORDER BY ss.Created ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.InsertSagaStep | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.InsertSagaStep.sql*
