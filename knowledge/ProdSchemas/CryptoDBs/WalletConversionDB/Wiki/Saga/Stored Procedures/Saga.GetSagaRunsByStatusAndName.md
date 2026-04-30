# Saga.GetSagaRunsByStatusAndName

> Retrieves active saga runs (Start or Rollback) filtered by saga name, providing targeted recovery candidates for a specific saga workflow type.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Active SagaRuns + SagaSteps filtered by status IN (1,2) and SagaName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetSagaRunsByStatusAndName retrieves saga runs that are in active states (Start or Rollback) for a specific saga workflow type. Despite accepting @SagaStatusTypeId and @SagaName as parameters, the procedure hardcodes the status filter to IN (1, 2) in a subquery, meaning it always returns only active sagas regardless of the @SagaStatusTypeId parameter value. The @SagaName parameter is applied as an outer filter.

This procedure is used by the saga orchestrator to find all active sagas of a given type that may need monitoring, continuation, or recovery. It effectively answers: "What CryptoToFiatSaga runs are currently in progress?"

---

## 2. Business Logic

### 2.1 Hardcoded Active Status Filter

**What**: Uses a subquery that pre-filters SagaRuns to status IN (1, 2) regardless of the @SagaStatusTypeId parameter.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `@SagaName`

**Rules**:
- Inner subquery: `SELECT ... FROM Saga.SagaRuns WHERE SagaStatusTypeId IN (1, 2)` - hardcoded to active states
- Outer WHERE: `SagaName = @SagaName` - applies the name filter on the subquery result
- The @SagaStatusTypeId parameter is declared but NOT used in the actual query logic
- LEFT JOIN SagaSteps for step data, ordered by StepIndex
- No row limit, no lease check

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | CODE-BACKED | Declared but NOT used in query logic. The procedure hardcodes status filter to IN (1, 2). Likely kept for interface compatibility. |
| 2 | @SagaName | varchar(256) | NO | - | VERIFIED | Saga workflow type to filter by. Applied as outer WHERE clause. Example: "CryptoToFiatSaga". |

**Return Columns:** Same as Saga.GetSagaRun (Id, SagaName, SagaKey, Created, Status, CorrelationId, AdditionalData, StepIndex, Request, Response, StepCreated, StepStatus).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT (subquery FROM) | Saga header data pre-filtered to active states |
| - | Saga.SagaSteps | SELECT (LEFT JOIN) | Step data joined by SagaRunId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsByStatusAndName (procedure)
├── Saga.SagaRuns (table)
└── Saga.SagaSteps (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM (subquery) - filtered to status IN (1,2) then by SagaName |
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

### 8.1 Get active CryptoToFiatSaga runs
```sql
EXEC Saga.GetSagaRunsByStatusAndName @SagaStatusTypeId = 1, @SagaName = 'CryptoToFiatSaga'
```

### 8.2 Direct equivalent query
```sql
SELECT sr.*, ss.StepIndex, ss.Request, ss.Response, ss.Created AS StepCreated, ss.StepStatusTypeId AS StepStatus
FROM Saga.SagaRuns sr WITH (NOLOCK)
LEFT JOIN Saga.SagaSteps ss WITH (NOLOCK) ON ss.SagaRunId = sr.Id
WHERE sr.SagaStatusTypeId IN (1, 2) AND sr.SagaName = 'CryptoToFiatSaga'
ORDER BY ss.StepIndex
```

### 8.3 Count active sagas by name
```sql
SELECT SagaName, COUNT(*) FROM Saga.SagaRuns WITH (NOLOCK) WHERE SagaStatusTypeId IN (1, 2) GROUP BY SagaName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsByStatusAndName | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetSagaRunsByStatusAndName.sql*
