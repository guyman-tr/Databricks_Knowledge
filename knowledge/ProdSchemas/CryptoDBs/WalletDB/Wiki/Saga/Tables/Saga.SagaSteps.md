# Saga.SagaSteps

> Individual step execution records within a saga run, storing the request/response payloads and current status for each step in the multi-step distributed transaction pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 3 NC (UNIQUE SagaRunId+StepIndex, SagaRunId with INCLUDE, StepIndex) |

---

## 1. Business Meaning

This table records every individual step executed within a saga run. Each saga consists of a sequentially ordered pipeline of steps (e.g., travel rule check, AML verification, balance credit), and this table stores one row per step with its request input, response output, and current execution status. With approximately 935K rows, it averages about 9 steps per saga run.

The table serves dual purposes: it provides the saga coordinator with the state needed to resume execution after interruptions (which step to run next, what input to pass), and it provides operations teams with detailed per-step diagnostic data when investigating saga issues. The JSON request/response payloads capture the full context of each step's execution.

Steps are created by `Saga.InsertSagaStep`, which atomically inserts the step record and its initial status entry in `Saga.SagaStepStatuses`. Step status updates (e.g., marking a step as Done after completion) are performed by `Saga.InsertSagaStepStatus`, which also updates the denormalized `StepStatusTypeId` on this table. Step responses are updated by `Saga.UpdateSagaStepResponse` after execution completes.

---

## 2. Business Logic

### 2.1 Sequential Step Pipeline

**What**: Each saga run executes steps in strict sequential order, identified by StepIndex.

**Columns/Parameters Involved**: `SagaRunId`, `StepIndex`, `StepStatusTypeId`

**Rules**:
- StepIndex is 1-based and strictly sequential within a saga run (enforced by UNIQUE index on SagaRunId+StepIndex)
- Steps execute in order: step N must complete (StepStatusTypeId=4, Done) before step N+1 begins
- ExternalReceiveTransactionSaga has 11 steps (per Confluence: TR check, TX notify, AML, travel rule handling)
- Step count varies by saga: some sagas stop at step 5 (shorter sagas), some continue through step 11
- Step 1 exists for all 102K sagas; step 6+ drops to ~73K (about 28K sagas complete in 5 steps)

### 2.2 Step Request/Response Pattern

**What**: Each step stores its input (Request) and output (Response) as JSON payloads.

**Columns/Parameters Involved**: `Request`, `Response`, `StepStatusTypeId`

**Rules**:
- Request is set at step creation by `InsertSagaStep` - contains the input data for the step's action
- Response is initially NULL and updated by `UpdateSagaStepResponse` after step execution
- Both are varchar(max) to accommodate variable-size JSON payloads
- The saga coordinator reads the previous step's Response to compose the next step's Request (pipeline pattern)
- On failure, the Response may contain error details for debugging

### 2.3 Step Status Distribution

**What**: Step status reflects the outcome of individual step execution.

**Columns/Parameters Involved**: `StepStatusTypeId`

**Rules**:
- 99.4% of steps are Done (StepStatusTypeId=4) - successfully completed
- 0.6% are in Retry (StepStatusTypeId=3) - transient failure being retried
- 273 are in Start (StepStatusTypeId=1) - currently executing or stuck
- 4 are in Schedule (StepStatusTypeId=5) - deferred for future execution (polling steps)
- No Failed (StepStatusTypeId=2) step records exist separately - step failure triggers saga-level rollback
- See [Step Status Type](../../_glossary.md#step-status-type)

---

## 3. Data Overview

| Id | SagaRunId | StepIndex | StepStatusTypeId | Meaning |
|----|-----------|-----------|------------------|---------|
| 935386 | 102230 | 11 | 4 (Done) | Final step (step 11) of saga 102230, completed at 10:07:21. This is the last step in the ExternalReceiveTransactionSaga pipeline. |
| 935383 | 102230 | 8 | 4 (Done) | Step 8 of the same saga. Created at 10:06:21, about 60 seconds after step 7. Steps 8-11 executed in rapid succession (~30ms between them). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY | CODE-BACKED | Auto-incrementing primary key. Provides global chronological ordering of step creation across all saga runs. |
| 2 | SagaRunId | bigint | NO | - | VERIFIED | References `Saga.SagaRuns.Id`. Groups all steps belonging to the same saga run. Part of UNIQUE constraint with StepIndex ensuring one record per step per saga. |
| 3 | StepIndex | tinyint | NO | - | VERIFIED | 1-based sequential position of this step within the saga pipeline. Combined with SagaRunId in a UNIQUE index. ExternalReceiveTransactionSaga uses steps 1-11 per Confluence architecture. The saga coordinator uses StepIndex to determine execution order and resume point after interruptions. |
| 4 | Request | varchar(max) | YES | - | CODE-BACKED | JSON payload containing the input data for this step's execution. Set by `Saga.InsertSagaStep` at step creation. Contains the serialized saga context data including correlation IDs, transaction details, and any state accumulated from previous steps. |
| 5 | Response | varchar(max) | YES | - | CODE-BACKED | JSON payload containing the output/result of this step's execution. Initially NULL at step creation, updated by `Saga.UpdateSagaStepResponse` after the step completes. Contains execution results, service responses, or error details. Fed as input context to subsequent steps. |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the step was created by `Saga.InsertSagaStep`. Set to GETUTCDATE(). Used to calculate per-step execution duration and identify timing bottlenecks in the pipeline. |
| 7 | StepStatusTypeId | tinyint | NO | - | VERIFIED | Current execution status of this step. Denormalized from the latest `Saga.SagaStepStatuses` entry. Values: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. Updated by `Saga.InsertSagaStepStatus`. See [Step Status Type](../../_glossary.md#step-status-type). (Saga.StepStatusTypes) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaRunId | Saga.SagaRuns | Implicit FK | Links this step to the parent saga run |
| StepStatusTypeId | Saga.StepStatusTypes | Implicit FK (Lookup) | Current execution status: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Saga.SagaStepStatuses | SagaStepId | Implicit FK | Status history entries for this step's lifecycle |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.SagaSteps (table)
├── Saga.SagaRuns (table) [implicit FK - SagaRunId]
│   └── Saga.SagaStatusTypes (table) [implicit FK - SagaStatusTypeId]
└── Saga.StepStatusTypes (table) [implicit FK - StepStatusTypeId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | Implicit FK - SagaRunId references the parent saga run |
| Saga.StepStatusTypes | Table | Implicit FK - StepStatusTypeId references the step status lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaStepStatuses | Table | SagaStepId references this table for step status history |
| Saga.InsertSagaStep | Stored Procedure | WRITER - creates step record and initial status |
| Saga.InsertSagaStepStatus | Stored Procedure | MODIFIER - updates StepStatusTypeId (denormalized status) |
| Saga.UpdateSagaStepResponse | Stored Procedure | MODIFIER - updates Response column after step execution |
| Saga.GetSagaRun | Stored Procedure | READER - retrieves all steps for a saga run |
| Saga.GetSagaRunsByStatus | Stored Procedure | READER - retrieves steps alongside saga run data |
| Saga.GetAllAbandonedSagaRuns | Stored Procedure | READER - reads step status for abandoned saga diagnostics |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaSteps | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Saga_SagaSteps__SagaRunId_StepIndex | NC UNIQUE | SagaRunId ASC, StepIndex ASC | - | - | Active |
| IX_SagaSteps_Id_Inc | NC | SagaRunId ASC | StepIndex, Request, Response, Created, StepStatusTypeId | - | Active |
| IX_SagaSteps_StepIndex | NC | StepIndex ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key and unique index.

---

## 8. Sample Queries

### 8.1 All steps for a saga run with status names
```sql
SELECT ss.StepIndex, sst.Name AS StepStatus, ss.Created,
       LEFT(ss.Request, 100) AS RequestPreview, LEFT(ss.Response, 100) AS ResponsePreview
FROM Saga.SagaSteps ss WITH (NOLOCK)
JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON ss.StepStatusTypeId = sst.Id
WHERE ss.SagaRunId = @SagaRunId
ORDER BY ss.StepIndex ASC
```

### 8.2 Steps currently in Retry or Start state (potentially stuck)
```sql
SELECT ss.Id, ss.SagaRunId, ss.StepIndex, sst.Name AS StepStatus, ss.Created,
       sr.SagaName, DATEDIFF(MINUTE, ss.Created, GETUTCDATE()) AS MinutesSinceCreation
FROM Saga.SagaSteps ss WITH (NOLOCK)
JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON ss.StepStatusTypeId = sst.Id
JOIN Saga.SagaRuns sr WITH (NOLOCK) ON ss.SagaRunId = sr.Id
WHERE ss.StepStatusTypeId IN (1, 3)
ORDER BY ss.Created ASC
```

### 8.3 Step timing analysis for a saga
```sql
SELECT ss.StepIndex, ss.Created,
       DATEDIFF(MILLISECOND, LAG(ss.Created) OVER (ORDER BY ss.StepIndex), ss.Created) AS DurationMs,
       sst.Name AS StepStatus
FROM Saga.SagaSteps ss WITH (NOLOCK)
JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON ss.StepStatusTypeId = sst.Id
WHERE ss.SagaRunId = @SagaRunId
ORDER BY ss.StepIndex ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | Step pipeline composition: ExternalReceiveTransactionSaga has 11 shared "lego block" steps (TR prerequisites, TX notify, AML, travel rule). AutoC2PSagaFactory extends to 17 steps. Steps are interface-based and reusable across saga types. |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaSteps | Type: Table | Source: WalletDB/Saga/Tables/Saga.SagaSteps.sql*
