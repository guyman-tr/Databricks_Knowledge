# Saga.StepStatusTypes

> Lookup table defining the lifecycle states of an individual step within a distributed saga workflow.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

This table defines the finite set of states that a single saga step can occupy during its execution. Each saga run consists of multiple ordered steps (e.g., AML check, travel rule verification, balance credit), and each step independently tracks its own status as it progresses from initiation through success, failure, or retry.

Without this table, the system could not determine which specific step within a saga is currently executing, has failed, or is being retried. This granularity is essential for saga recovery: when a saga is restarted after a pod crash or transient failure, the coordinator reads each step's status to determine exactly where to resume execution rather than re-running the entire saga from the beginning.

Step statuses are written by `Saga.InsertSagaStep` (initial creation) and `Saga.InsertSagaStepStatus` (subsequent transitions). They are read by the various `Get*SagaRuns*` procedures that return saga details including per-step status information for monitoring and debugging.

---

## 2. Business Logic

### 2.1 Step Lifecycle State Machine

**What**: Each saga step progresses through defined status transitions independently of the overall saga state.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- Status 1 (Start): Step execution has begun; the step's action is in progress
- Status 2 (Failed): Step execution failed; the saga coordinator will decide whether to retry or trigger saga rollback
- Status 3 (Retry): Step is being retried after a transient failure (e.g., timeout, temporary service unavailability)
- Status 4 (Done): Step completed successfully; the saga coordinator advances to the next step
- Status 5 (Schedule): Step is scheduled for deferred execution (e.g., polling steps that check external service results at timed intervals)
- A step in Schedule state typically transitions to Start when the scheduled time arrives, then to Done or Failed

**Diagram**:
```
[5: Schedule] --timer fires--> [1: Start] --success--> [4: Done]
                                   |
                                   +--transient fail--> [3: Retry] --retry--> [1: Start]
                                   |
                                   +--permanent fail--> [2: Failed]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|----|------|---------|
| 1 | Start | Step is actively executing its action (e.g., calling an AML service, submitting a blockchain transaction). The saga coordinator monitors steps in this state for timeout. |
| 2 | Failed | Step execution failed permanently. The saga coordinator evaluates whether to attempt recovery or begin saga-level rollback based on the failure type and saga configuration. |
| 3 | Retry | Step encountered a transient failure (e.g., network timeout, service temporarily unavailable) and is queued for retry. The saga framework applies exponential backoff before re-attempting the step. |
| 4 | Done | Step completed successfully. The saga coordinator reads this status to know it can advance to the next step in the pipeline. The step's Response column contains the output data. |
| 5 | Schedule | Step is scheduled for future execution, typically used for polling steps (e.g., waiting for Travel Rule approval at 60-second intervals, or checking C2P completion at 30-second intervals per Confluence architecture docs). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | VERIFIED | Primary key and step status identifier. Used as the FK value in `Saga.SagaSteps.StepStatusTypeId` and `Saga.SagaStepStatuses.StepStatusTypeId`. Values: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. See [Step Status Type](../../_glossary.md#step-status-type). |
| 2 | Name | varchar(64) | NO | - | VERIFIED | Human-readable label for the step lifecycle state. Used in operational monitoring and debugging logs to show per-step progress without requiring a JOIN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Saga.SagaSteps | StepStatusTypeId | Implicit FK (Lookup) | Current lifecycle state of the individual saga step |
| Saga.SagaStepStatuses | StepStatusTypeId | Implicit FK (Lookup) | Historical status entry recording a specific step state transition event |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaSteps | Table | StepStatusTypeId references this lookup for current step state |
| Saga.SagaStepStatuses | Table | StepStatusTypeId references this lookup for step status history |
| Saga.InsertSagaStep | Stored Procedure | Sets initial StepStatusTypeId on step creation and inserts into SagaStepStatuses |
| Saga.InsertSagaStepStatus | Stored Procedure | Inserts step status transition with StepStatusTypeId and updates SagaSteps.StepStatusTypeId |
| Saga.GetSagaRun | Stored Procedure | Reads StepStatusTypeId from SagaSteps to return per-step status |
| Saga.GetSagaRunsByStatus | Stored Procedure | Reads StepStatusTypeId alongside saga run data |
| Saga.GetAllAbandonedSagaRuns | Stored Procedure | Reads StepStatusTypeId to show step progress for abandoned sagas |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StepStatusTypes | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all step status types
```sql
SELECT Id, Name
FROM Saga.StepStatusTypes WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Find saga steps currently in Retry state
```sql
SELECT ss.Id AS StepId, ss.SagaRunId, ss.StepIndex, sst.Name AS StepStatus, ss.Created
FROM Saga.SagaSteps ss WITH (NOLOCK)
JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON ss.StepStatusTypeId = sst.Id
WHERE ss.StepStatusTypeId = 3
ORDER BY ss.Created DESC
```

### 8.3 Step status distribution for a specific saga run
```sql
SELECT sst.Name AS StepStatus, ss.StepIndex, ss.Created
FROM Saga.SagaSteps ss WITH (NOLOCK)
JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON ss.StepStatusTypeId = sst.Id
WHERE ss.SagaRunId = @SagaRunId
ORDER BY ss.StepIndex ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | Saga step composition: polling steps use timed intervals (60s for TR approval, 30s for C2P completion), confirming the Schedule status type's role in deferred step execution |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.StepStatusTypes | Type: Table | Source: WalletDB/Saga/Tables/Saga.StepStatusTypes.sql*
