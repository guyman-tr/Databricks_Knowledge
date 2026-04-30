# Saga.InsertSagaStepStatus

> Atomically transitions a saga step to a new status, updating the current state in SagaSteps and logging the transition to SagaStepStatuses via OUTPUT clause for audit trail integrity.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Saga.SagaSteps + inserts into Saga.SagaStepStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertSagaStepStatus is the step status transition procedure - the mechanism by which individual saga steps move through their lifecycle (Start -> Done, Start -> Failed -> Retry -> Start -> Done, etc.). It atomically updates the current status in SagaSteps AND logs the transition to SagaStepStatuses using an OUTPUT clause, ensuring the history is always in sync with the current state.

This is the step-level equivalent of `Saga.InsertSagaRunStatus` (which handles saga-level transitions). Every step status change in every saga flows through this procedure. The saga orchestrator calls it when a step completes, fails, is retried, or is scheduled. With SagaStepStatuses averaging ~6.4 entries per step (1.16M rows / 181K steps), this procedure is called frequently during saga execution.

The procedure identifies the target step via a two-hop lookup: @SagaKey -> SagaRuns.Id -> SagaSteps.Id (by SagaRunId + StepIndex). This allows the application to use the business-level SagaKey rather than internal database IDs.

---

## 2. Business Logic

### 2.1 Atomic Status Update + History Logging via OUTPUT

**What**: Uses OUTPUT clause to simultaneously update SagaSteps.StepStatusTypeId and INSERT into SagaStepStatuses.

**Columns/Parameters Involved**: `@SagaKey`, `@StepIndex`, `@StepStatusTypeId`

**Rules**:
1. Look up @SagaRunId from SagaRuns WHERE SagaKey = @SagaKey (NOLOCK)
2. If @SagaRunId IS NULL -> RAISERROR 'Run "{sagaKey}" not found' and RETURN
3. Look up @SagaStepId from SagaSteps WHERE SagaRunId = @SagaRunId AND StepIndex = @StepIndex (NOLOCK)
4. If not found -> RAISERROR 'Step "{index}" not found in run "{sagaKey}"' and RETURN
5. UPDATE SagaSteps SET StepStatusTypeId = @StepStatusTypeId WHERE Id = @SagaStepId
6. OUTPUT @SagaStepId, GETUTCDATE(), @StepStatusTypeId INTO SagaStepStatuses
- No explicit transaction wrapper needed - the UPDATE + OUTPUT is atomic
- No validation that the new status is a valid transition from the current status - the application layer enforces the state machine

### 2.2 Two-Hop Step Identification

**What**: Locates the target step using SagaKey (business key) and StepIndex rather than internal database IDs.

**Columns/Parameters Involved**: `@SagaKey`, `@StepIndex`

**Rules**:
- Hop 1: SagaKey -> SagaRuns.Id (via unique index on SagaKey)
- Hop 2: SagaRuns.Id + StepIndex -> SagaSteps.Id (via unique index on SagaRunId + StepIndex)
- Both lookups use NOLOCK for non-blocking reads
- This pattern is consistent with InsertSagaStep and UpdateSagaStepResponse, all of which identify steps via SagaKey + StepIndex

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Business-level identifier of the parent saga run. Used in first hop to look up SagaRuns.Id. |
| 2 | @StepIndex | tinyint | NO | - | VERIFIED | Ordinal position of the step to transition (1-11 for CryptoToFiatSaga). Used in second hop with SagaRunId to find SagaSteps.Id. |
| 3 | @StepStatusTypeId | tinyint | NO | - | VERIFIED | New status to assign to the step. Values: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. See [Step Status Type](../../_glossary.md#step-status-type). Written to both SagaSteps.StepStatusTypeId (UPDATE) and SagaStepStatuses (INSERT via OUTPUT). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | SELECT (lookup) | Hop 1: reads SagaRuns.Id by SagaKey |
| @StepIndex | Saga.SagaSteps | SELECT (lookup) + UPDATE | Hop 2: reads SagaSteps.Id by SagaRunId + StepIndex, then UPDATEs StepStatusTypeId |
| OUTPUT | Saga.SagaStepStatuses | INSERT (via OUTPUT) | Logs the transition atomically with the status update |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.InsertSagaStepStatus (procedure)
├── Saga.SagaRuns (table) - lookup by SagaKey (hop 1)
├── Saga.SagaSteps (table) - lookup + UPDATE (hop 2)
└── Saga.SagaStepStatuses (table) - INSERT via OUTPUT
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT - looks up Id by SagaKey (hop 1) |
| Saga.SagaSteps | Table | SELECT + UPDATE - finds step by SagaRunId+StepIndex, updates StepStatusTypeId |
| Saga.SagaStepStatuses | Table | INSERT (via OUTPUT) - logs status transition history |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OUTPUT atomicity | UPDATE...OUTPUT INTO | Ensures status update and history logging happen as one operation |
| Validation | RAISERROR + RETURN | Validates saga run and step exist before attempting the update |

---

## 8. Sample Queries

### 8.1 Transition a step to Done
```sql
EXEC Saga.InsertSagaStepStatus
    @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E',
    @StepIndex = 3,
    @StepStatusTypeId = 4 -- Done
```

### 8.2 Mark a step as Failed
```sql
EXEC Saga.InsertSagaStepStatus
    @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E',
    @StepIndex = 5,
    @StepStatusTypeId = 2 -- Failed
```

### 8.3 Verify the transition was recorded in both tables
```sql
-- Current status in SagaSteps
SELECT s.StepIndex, s.StepStatusTypeId, sst.Name AS CurrentStatus
FROM Saga.SagaSteps s WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = s.SagaRunId
INNER JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sst.Id = s.StepStatusTypeId
WHERE sr.SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
AND s.StepIndex = 3

-- History in SagaStepStatuses
SELECT ss.Id, sst.Name AS Status, ss.Created
FROM Saga.SagaStepStatuses ss WITH (NOLOCK)
INNER JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sst.Id = ss.StepStatusTypeId
WHERE ss.SagaStepId = (
    SELECT s.Id FROM Saga.SagaSteps s WITH (NOLOCK)
    INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = s.SagaRunId
    WHERE sr.SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E' AND s.StepIndex = 3
)
ORDER BY ss.Created ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.InsertSagaStepStatus | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.InsertSagaStepStatus.sql*
