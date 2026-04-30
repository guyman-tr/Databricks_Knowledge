# Saga.GetSagaRunsByStatus

> Retrieves all saga runs matching a specific status with their steps, enabling status-based monitoring and batch processing.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: SagaRuns + SagaSteps filtered by SagaStatusTypeId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetSagaRunsByStatus retrieves all saga runs in a given status along with their step data. This is the base status-filter query used by the saga orchestrator and monitoring tools to find all sagas in a particular lifecycle state (e.g., all in-progress sagas, all failed sagas). Unlike more specific variants, this procedure returns ALL matching sagas without limits or additional filters.

Used for operational monitoring dashboards and batch processing scenarios where all sagas in a given state need to be enumerated.

---

## 2. Business Logic

### 2.1 Unbounded Status Query

**What**: Returns all sagas matching the status with no row limit - suitable for low-count statuses (Failed, ForceStop) but potentially large for Completed.

**Columns/Parameters Involved**: `@SagaStatusTypeId`

**Rules**:
- Filters SagaRuns WHERE SagaStatusTypeId = @SagaStatusTypeId
- LEFT JOINs SagaSteps for step data, ordered by StepIndex
- No row limit (unlike GetSagaRunsWithLimitsByStatus variants)
- No lease check (unlike GetAllSagaRunsWithLimitsByStatus variants)
- NOLOCK on both tables

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status to filter by. 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type). |

**Return Columns:** Same as Saga.GetSagaRun (Id, SagaName, SagaKey, Created, Status, CorrelationId, AdditionalData, StepIndex, Request, Response, StepCreated, StepStatus).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT (FROM) | Saga header data filtered by status |
| - | Saga.SagaSteps | SELECT (LEFT JOIN) | Step data joined by SagaRunId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsByStatus (procedure)
├── Saga.SagaRuns (table)
└── Saga.SagaSteps (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - filtered by SagaStatusTypeId |
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

### 8.1 Get all sagas in Start status
```sql
EXEC Saga.GetSagaRunsByStatus @SagaStatusTypeId = 1
```

### 8.2 Get all failed sagas
```sql
EXEC Saga.GetSagaRunsByStatus @SagaStatusTypeId = 4
```

### 8.3 Count sagas per status
```sql
SELECT SagaStatusTypeId, COUNT(*) AS Cnt FROM Saga.SagaRuns WITH (NOLOCK) GROUP BY SagaStatusTypeId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsByStatus | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetSagaRunsByStatus.sql*
