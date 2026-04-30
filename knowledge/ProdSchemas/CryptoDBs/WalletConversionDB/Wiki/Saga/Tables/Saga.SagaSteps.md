# Saga.SagaSteps

> Stores each discrete operation step within a saga run, including its execution order, serialized request/response payloads, and current status, forming the detailed execution record of the distributed transaction.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (PK + 2 NC) |

---

## 1. Business Meaning

SagaSteps stores the individual operations that make up each saga run. A CryptoToFiatSaga typically consists of 11 ordered steps, each representing a discrete operation in the conversion pipeline (e.g., validate, lock crypto, calculate fiat amount, execute conversion, credit fiat, etc.). Each step carries its own request and response JSON payloads, status, and timestamp.

Without this table, the saga orchestrator would have no record of which steps have been executed, what data was passed between them, or where the process stands. The step data is essential for both forward execution (knowing what step to run next) and rollback (knowing which compensation steps to invoke in reverse order).

Steps are created by `Saga.InsertSagaStep`, which validates the saga exists, checks for duplicate step indexes, inserts the step, and logs the initial status to SagaStepStatuses - all in a single transaction. Step responses can be updated by `Saga.UpdateSagaStepResponse` after an async operation completes. Nearly all saga query procedures (GetSagaRun, GetSagaRunsByStatus, etc.) LEFT JOIN to SagaSteps to return the full saga with its steps.

---

## 2. Business Logic

### 2.1 Step Pipeline Chaining

**What**: Steps execute in StepIndex order, with each step's Response feeding into the next step's Request, forming a data pipeline.

**Columns/Parameters Involved**: `StepIndex`, `Request`, `Response`, `SagaRunId`

**Rules**:
- Steps are uniquely identified within a saga by (SagaRunId, StepIndex) - enforced by a unique index
- StepIndex is a tinyint (0-255), with CryptoToFiatSaga using indexes 1-11
- Step N's Response JSON contains data that appears in Step N+1's Request JSON (pipeline chaining pattern)
- Request contains the StepStartTime and the accumulated context needed for that step's operation
- Response contains the result of the step's execution plus data to pass forward
- Both Request and Response are varchar(max) to accommodate variable JSON payload sizes

### 2.2 Step Deduplication

**What**: InsertSagaStep prevents duplicate step creation within the same saga run using an existence check.

**Columns/Parameters Involved**: `SagaRunId`, `StepIndex`

**Rules**:
- Before INSERT, checks `WHERE NOT EXISTS (SELECT 1 FROM SagaSteps WHERE SagaRunId = @SagaRunId AND StepIndex = @StepIndex)`
- If the step already exists, raises error: 'Step "{index}" already exists in run "{sagaKey}"'
- The unique index IX_Saga_SagaSteps__SagaRunId_StepIndex enforces this at the database level
- This prevents re-execution of steps during recovery scenarios

### 2.3 Step Completion Rate by Pipeline Position

**What**: Step counts decrease at higher indexes, showing the natural attrition in the conversion pipeline.

**Columns/Parameters Involved**: `StepIndex`

**Rules**:
- Step 1: 17,042 (every saga starts)
- Steps 2-4: 17,036 (nearly all progress through early steps)
- Step 5+: 16,122 (some sagas fail or roll back before reaching later steps)
- Up to Step 11 in a complete CryptoToFiatSaga execution

---

## 3. Data Overview

| Id | SagaRunId | StepIndex | StepStatusTypeId | Created | Meaning |
|----|-----------|-----------|------------------|---------|---------|
| 180963 | 17042 | 11 | 4 (Done) | 2026-04-15 08:00:26 | Final step of saga 17042, completed successfully. Request/Response contain the accumulated conversion context. |
| 180960 | 17042 | 8 | 4 (Done) | 2026-04-15 07:59:21 | Mid-pipeline step with FiatTransactionData including CryptoToFiatRate. Each step takes 1-60 seconds. |
| 180959 | 17042 | 7 | 4 (Done) | 2026-04-15 07:59:19 | Another mid-pipeline step - Request and Response both contain FiatTransactionData, showing data pass-through enrichment. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate primary key. Referenced by SagaStepStatuses.SagaStepId for step-level status history. |
| 2 | SagaRunId | bigint | NO | - | VERIFIED | Foreign key to Saga.SagaRuns.Id identifying which saga run this step belongs to. Looked up by InsertSagaStep from SagaRuns via SagaKey. Part of unique index with StepIndex. |
| 3 | StepIndex | tinyint | NO | - | VERIFIED | Zero-based ordinal position of this step in the saga pipeline. CryptoToFiatSaga uses indexes 1-11. Determines execution order (forward) and compensation order (reverse for rollback). Part of unique constraint with SagaRunId. |
| 4 | Request | varchar(max) | YES | - | VERIFIED | Serialized JSON containing the input data for this step's operation. Includes StepStartTime, accumulated context from previous steps, and step-specific parameters (e.g., wallet IDs, conversion rates). Set on INSERT by InsertSagaStep. |
| 5 | Response | varchar(max) | YES | - | VERIFIED | Serialized JSON containing the output of this step's execution. Includes results and data to pass to the next step. Initially set on INSERT; can be updated later by UpdateSagaStepResponse for async operations. |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the step row was created. Set to GETUTCDATE() by InsertSagaStep. |
| 7 | StepStatusTypeId | tinyint | NO | - | VERIFIED | Current lifecycle status of this step. Values: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. See [Step Status Type](../../_glossary.md#step-status-type). Set on INSERT by InsertSagaStep, updated by InsertSagaStepStatus. Implicit FK to Saga.StepStatusTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaRunId | Saga.SagaRuns | Implicit FK | Links each step to its parent saga run via SagaRuns.Id |
| StepStatusTypeId | Saga.StepStatusTypes | Implicit FK (Lookup) | Current step lifecycle status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Saga.SagaStepStatuses | SagaStepId | Implicit FK | Status transition history for each step |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaStepStatuses | Table | SagaStepId references SagaSteps.Id |
| Saga.InsertSagaStep | Stored Procedure | WRITER - creates step row with status |
| Saga.InsertSagaStepStatus | Stored Procedure | MODIFIER - updates StepStatusTypeId |
| Saga.UpdateSagaStepResponse | Stored Procedure | MODIFIER - updates Response column |
| Saga.GetSagaRun | Stored Procedure | READER - LEFT JOIN to return steps with saga |
| Saga.GetSagaRunsByStatus | Stored Procedure | READER - LEFT JOIN for steps |
| Saga.GetAllAbandonedSagaRuns | Stored Procedure | READER - LEFT JOIN for steps |
| Saga.GetSagaRunsForRecovery | Stored Procedure | READER - LEFT JOIN for steps |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaSteps | CLUSTERED | Id ASC | - | - | Active |
| IX_Saga_SagaSteps__SagaRunId_StepIndex | UNIQUE NC | SagaRunId ASC, StepIndex ASC | - | - | Active |
| IX_SagaSteps_Id_Inc | NC | SagaRunId ASC | StepIndex, Request, Response, Created, StepStatusTypeId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SagaSteps | PRIMARY KEY | Identity-based PK. DATA_COMPRESSION = PAGE. |
| IX_Saga_SagaSteps__SagaRunId_StepIndex | UNIQUE | Prevents duplicate step indexes within the same saga run. Business rule: each step position executes exactly once. |

---

## 8. Sample Queries

### 8.1 Get all steps for a saga run with status labels
```sql
SELECT ss.StepIndex, sst.Name AS StepStatus, ss.Created,
       LEFT(ss.Request, 200) AS RequestPreview, LEFT(ss.Response, 200) AS ResponsePreview
FROM Saga.SagaSteps ss WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = ss.SagaRunId
INNER JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sst.Id = ss.StepStatusTypeId
WHERE sr.SagaKey = @SagaKey
ORDER BY ss.StepIndex ASC
```

### 8.2 Find the failing step in rollback sagas
```sql
SELECT sr.SagaKey, ss.StepIndex, sst.Name AS StepStatus, ss.Created,
       LEFT(ss.Response, 300) AS FailureResponse
FROM Saga.SagaSteps ss WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = ss.SagaRunId
INNER JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sst.Id = ss.StepStatusTypeId
WHERE sr.SagaStatusTypeId = 2
AND ss.StepStatusTypeId = 2
ORDER BY ss.Created DESC
```

### 8.3 Step completion pipeline analysis
```sql
SELECT StepIndex, COUNT(*) AS TotalSteps,
       SUM(CASE WHEN StepStatusTypeId = 4 THEN 1 ELSE 0 END) AS Completed,
       SUM(CASE WHEN StepStatusTypeId = 2 THEN 1 ELSE 0 END) AS Failed
FROM Saga.SagaSteps WITH (NOLOCK)
GROUP BY StepIndex
ORDER BY StepIndex
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaSteps | Type: Table | Source: WalletConversionDB/Saga/Tables/Saga.SagaSteps.sql*
