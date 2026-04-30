# Saga.GetSagaRunsForRecovery

> Retrieves all saga runs eligible for recovery (status Start or Rollback) for a specific saga type, used by the recovery service to find sagas that may need intervention.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Recoverable SagaRuns + SagaSteps filtered by status IN (1,2) and SagaName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetSagaRunsForRecovery finds all saga runs that are in active (non-terminal) states for a given saga type. It uses local variables `@SagaStartStatus = 1` and `@SagaRollbackStatus = 2` to clearly express the intent: find sagas that have started but not completed, or are in rollback. These are the only sagas that can benefit from recovery.

Unlike GetSagaRunsByStatusAndName, this procedure uses explicit named variables for the status values rather than hardcoded literals, making the business intent clearer. It does not check lease freshness - all active sagas are returned regardless of whether they are actively being processed.

Used by the recovery service to enumerate all candidates for potential intervention or restart.

---

## 2. Business Logic

### 2.1 Recovery Candidate Selection

**What**: Returns all sagas in Start (1) or Rollback (2) status for a given saga name.

**Columns/Parameters Involved**: `@SagaName`, `@SagaStartStatus`, `@SagaRollbackStatus`

**Rules**:
- Declares `@SagaStartStatus = 1` and `@SagaRollbackStatus = 2` as named constants
- Filters: `SagaStatusTypeId = @SagaStartStatus OR SagaStatusTypeId = @SagaRollbackStatus`
- Also filters by SagaName = @SagaName for workflow-type targeting
- LEFT JOIN SagaSteps for step data, ordered by StepIndex
- No row limit, no lease check - all matching sagas returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaName | varchar(256) | NO | - | VERIFIED | Saga workflow type to filter by. Example: "CryptoToFiatSaga". Combined with the active status filter to find recoverable sagas. |

**Return Columns:** Same as Saga.GetSagaRun (Id, SagaName, SagaKey, Created, Status, CorrelationId, AdditionalData, StepIndex, Request, Response, StepCreated, StepStatus).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT (FROM) | Saga header data filtered to active statuses and saga name |
| - | Saga.SagaSteps | SELECT (LEFT JOIN) | Step data joined by SagaRunId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsForRecovery (procedure)
├── Saga.SagaRuns (table)
└── Saga.SagaSteps (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - filtered by status (1,2) and SagaName |
| Saga.SagaSteps | Table | LEFT JOIN by SagaRunId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all recoverable CryptoToFiatSaga runs
```sql
EXEC Saga.GetSagaRunsForRecovery @SagaName = 'CryptoToFiatSaga'
```

### 8.2 Count recoverable sagas
```sql
SELECT COUNT(*) FROM Saga.SagaRuns WITH (NOLOCK)
WHERE SagaStatusTypeId IN (1, 2) AND SagaName = 'CryptoToFiatSaga'
```

### 8.3 Recoverable sagas with age
```sql
SELECT SagaKey, Created, DATEDIFF(MINUTE, Created, GETUTCDATE()) AS AgeMinutes
FROM Saga.SagaRuns WITH (NOLOCK)
WHERE SagaStatusTypeId IN (1, 2) AND SagaName = 'CryptoToFiatSaga'
ORDER BY Created ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsForRecovery | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetSagaRunsForRecovery.sql*
