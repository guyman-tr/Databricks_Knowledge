# Saga.StepStatusTypes

> Lookup table defining the possible lifecycle states for individual steps within a saga orchestration run.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

StepStatusTypes defines the complete set of lifecycle states for individual steps within a saga run. Each saga is composed of ordered steps that represent discrete operations in a distributed transaction. This table provides the canonical mapping from integer status values to their business meaning, enabling the saga orchestrator to track the progress of each step independently.

Without this table, the system would have no authoritative definition of step-level states. The step status drives the saga engine's decisions about whether to advance to the next step, retry a failed step, or escalate to saga-level rollback. Every procedure that creates, transitions, or queries saga steps depends on these values.

Steps are created by `Saga.InsertSagaStep`, which sets the initial StepStatusTypeId and simultaneously logs the status to `SagaStepStatuses`. Status transitions are performed by `Saga.InsertSagaStepStatus`, which updates `SagaSteps.StepStatusTypeId` and logs each transition. Nearly all saga query procedures return `StepStatusTypeId` as `StepStatus` alongside step data.

---

## 2. Business Logic

### 2.1 Step Lifecycle State Machine

**What**: The five step status types represent the complete state machine for an individual saga step's execution lifecycle.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- A step can begin as `Schedule` (5) if it is queued for future execution, or skip directly to `Start` (1) for immediate execution
- `Start` (1) means the step's operation request has been dispatched and is in progress
- If the step succeeds, it transitions to `Done` (4) - the saga engine can then advance to the next step
- If the step fails, it may transition to `Retry` (3) for transient errors before re-attempting
- If retry exhaustion occurs or a non-transient error happens, the step moves to `Failed` (2), which typically triggers the parent saga to enter Rollback status

**Diagram**:
```
[Schedule (5)] --execution begins--> [Start (1)] --success--> [Done (4)]
                                          |
                                          +--transient failure--> [Retry (3)] --re-attempt--> [Start (1)]
                                          |                            |
                                          |                            +--retry exhausted--> [Failed (2)]
                                          |
                                          +--non-transient failure--> [Failed (2)]

Active states: Schedule (5), Start (1), Retry (3)
Terminal states: Done (4), Failed (2)
Failed step -> parent saga transitions to Rollback (SagaStatusTypeId = 2)
```

---

## 3. Data Overview

| Id | Name | Meaning |
|----|------|---------|
| 1 | Start | Step execution is actively in progress - the operation request has been sent to the target service and a response is expected. |
| 2 | Failed | Step could not complete after all attempts. Typically triggers the parent saga to enter Rollback status (SagaStatusTypeId = 2). |
| 3 | Retry | Step encountered a transient error and is being re-attempted. The saga engine will transition it back to Start on the next attempt. |
| 4 | Done | Step completed successfully - its operation is committed. The saga engine can advance to the next step in sequence. |
| 5 | Schedule | Step is queued for future execution but has not yet started. Allows the saga engine to pre-plan steps before dispatching them. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | VERIFIED | Primary key identifying the step status type. Used as FK target by `SagaSteps.StepStatusTypeId` and `SagaStepStatuses.StepStatusTypeId`. Values: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. See [Step Status Type](../../_glossary.md#step-status-type) for full business definitions. |
| 2 | Name | varchar(64) | NO | - | VERIFIED | Human-readable label for the step status. Used in application code for display and logging. Maps 1:1 with Id values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Saga.SagaSteps | StepStatusTypeId | Implicit FK (Lookup) | Current lifecycle status of each saga step. Written on INSERT by InsertSagaStep, updated by InsertSagaStepStatus. |
| Saga.SagaStepStatuses | StepStatusTypeId | Implicit FK (Lookup) | Historical status transitions for saga steps. Each row records a point-in-time step status change. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaSteps | Table | StepStatusTypeId column references this lookup |
| Saga.SagaStepStatuses | Table | StepStatusTypeId column references this lookup |
| Saga.InsertSagaStep | Stored Procedure | Creates step with initial StepStatusTypeId and logs to SagaStepStatuses |
| Saga.InsertSagaStepStatus | Stored Procedure | Updates SagaSteps.StepStatusTypeId and logs transition to SagaStepStatuses |
| Saga.GetSagaRun | Stored Procedure | Returns StepStatusTypeId as StepStatus in result set |
| Saga.GetSagaRunsByStatus | Stored Procedure | Returns StepStatusTypeId as StepStatus in result set |
| Saga.GetAllAbandonedSagaRuns | Stored Procedure | Returns StepStatusTypeId as StepStatus in result set |
| Saga.GetSagaRunsForRecovery | Stored Procedure | Returns StepStatusTypeId as StepStatus in result set |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StepStatusTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_StepStatusTypes | PRIMARY KEY | Unique identity for each step status type. tinyint allows max 255 types (5 currently used). |

---

## 8. Sample Queries

### 8.1 List all step status types
```sql
SELECT Id, Name
FROM Saga.StepStatusTypes WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Count steps by status with human-readable labels
```sql
SELECT sst.Id, sst.Name, COUNT(ss.Id) AS StepCount
FROM Saga.StepStatusTypes sst WITH (NOLOCK)
LEFT JOIN Saga.SagaSteps ss WITH (NOLOCK) ON ss.StepStatusTypeId = sst.Id
GROUP BY sst.Id, sst.Name
ORDER BY sst.Id
```

### 8.3 Find all failed or retrying steps with saga context
```sql
SELECT sr.SagaKey, sr.SagaName, ss.StepIndex, sst.Name AS StepStatus, ss.Created
FROM Saga.SagaSteps ss WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = ss.SagaRunId
INNER JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sst.Id = ss.StepStatusTypeId
WHERE ss.StepStatusTypeId IN (2, 3) -- Failed, Retry
ORDER BY ss.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.StepStatusTypes | Type: Table | Source: WalletConversionDB/Saga/Tables/Saga.StepStatusTypes.sql*
