# Saga.GetSagaRunsWithLimitsByStatus

> Retrieves a limited number of saga runs filtered by status and saga name, providing paginated access for batch processing of sagas in a specific state.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: TOP @Limit SagaRuns + SagaSteps filtered by status and name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetSagaRunsWithLimitsByStatus is the row-limited variant of GetSagaRunsByStatus, adding both a @SagaName filter and a @Limit cap. This prevents the query from returning unbounded result sets when processing sagas in high-volume statuses (e.g., thousands of Completed sagas). The worker processes @Limit sagas at a time, then re-queries for the next batch.

Used by the saga orchestrator for batch processing - process N sagas of a given status and type, then fetch the next N.

---

## 2. Business Logic

### 2.1 Bounded Status + Name Query

**What**: Returns at most @Limit sagas matching a status and name, without lease checking.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `@SagaName`, `@Limit`

**Rules**:
- SELECT TOP (@Limit) from SagaRuns WHERE SagaStatusTypeId AND SagaName
- LEFT JOIN SagaSteps, ordered by StepIndex
- No lease check (unlike GetAllSagaRunsWithLimitsByStatus)
- @Limit is tinyint (max 255 sagas per call)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status to filter by. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2 | @SagaName | varchar(256) | NO | - | VERIFIED | Saga workflow type to filter by. Example: "CryptoToFiatSaga". |
| 3 | @Limit | tinyint | NO | - | VERIFIED | Maximum number of saga runs to return. Caps the result set for batch processing. Max 255. |

**Return Columns:** Same as Saga.GetSagaRun.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT (FROM) | Filtered by status and name with TOP limit |
| - | Saga.SagaSteps | SELECT (LEFT JOIN) | Step data joined by SagaRunId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsWithLimitsByStatus (procedure)
├── Saga.SagaRuns (table)
└── Saga.SagaSteps (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - filtered by status and name, TOP limited |
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

### 8.1 Get up to 10 active CryptoToFiatSaga runs
```sql
EXEC Saga.GetSagaRunsWithLimitsByStatus @SagaStatusTypeId = 1, @SagaName = 'CryptoToFiatSaga', @Limit = 10
```

### 8.2 Get up to 5 failed sagas for review
```sql
EXEC Saga.GetSagaRunsWithLimitsByStatus @SagaStatusTypeId = 4, @SagaName = 'CryptoToFiatSaga', @Limit = 5
```

### 8.3 Equivalent direct query
```sql
SELECT TOP 10 sr.*, ss.StepIndex, ss.Request, ss.Response, ss.Created AS StepCreated, ss.StepStatusTypeId AS StepStatus
FROM Saga.SagaRuns sr WITH (NOLOCK)
LEFT JOIN Saga.SagaSteps ss WITH (NOLOCK) ON ss.SagaRunId = sr.Id
WHERE sr.SagaStatusTypeId = 1 AND sr.SagaName = 'CryptoToFiatSaga'
ORDER BY ss.StepIndex
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsWithLimitsByStatus | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetSagaRunsWithLimitsByStatus.sql*
