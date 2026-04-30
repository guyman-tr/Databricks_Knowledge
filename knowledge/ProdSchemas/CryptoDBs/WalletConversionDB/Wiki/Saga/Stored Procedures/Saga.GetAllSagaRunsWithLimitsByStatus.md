# Saga.GetAllSagaRunsWithLimitsByStatus

> Retrieves a limited number of saga runs filtered by status that have an active lease (updated within 5 minutes), returning only sagas currently being processed by a healthy worker.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: TOP @Limit actively-leased SagaRuns + SagaSteps by status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAllSagaRunsWithLimitsByStatus finds saga runs that are both in a given status AND actively being processed (lease updated within 5 minutes). This distinguishes it from GetSagaRunsByStatus which returns all sagas regardless of lease freshness. By combining status filter with lease check, this procedure answers: "What sagas of status X are currently being worked on by a live worker?"

Used by monitoring dashboards and coordination logic to track currently-active saga processing.

---

## 2. Business Logic

### 2.1 Active Lease + Status + Limit

**What**: Combines status filter, active lease validation (5-minute window), and row limit.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `@Limit`

**Rules**:
- SELECT TOP (@Limit) from SagaRuns WHERE SagaStatusTypeId = @SagaStatusTypeId
- AND SagaKey IN (SELECT SagaKey FROM SagaLeaseTime WHERE LastUpdaed > DATEADD(MINUTE, -5, GETUTCDATE()))
- LEFT JOINs SagaSteps, ordered by StepIndex
- The 5-minute lease freshness window is shorter than the 1-hour abandonment window in GetAllAbandonedSagaRuns
- @Limit is tinyint (max 255)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status to filter by. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2 | @Limit | tinyint | NO | - | VERIFIED | Maximum number of saga runs to return. Max 255. |

**Return Columns:** Same as Saga.GetSagaRun.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT (FROM) | Filtered by status |
| - | Saga.SagaSteps | SELECT (LEFT JOIN) | Step data joined by SagaRunId |
| - | Saga.SagaLeaseTime | SELECT (IN subquery) | Active lease check (LastUpdaed within 5 min) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetAllSagaRunsWithLimitsByStatus (procedure)
├── Saga.SagaRuns (table)
├── Saga.SagaSteps (table)
└── Saga.SagaLeaseTime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - filtered by status and active lease |
| Saga.SagaSteps | Table | LEFT JOIN by SagaRunId |
| Saga.SagaLeaseTime | Table | IN subquery - active lease validation |

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

### 8.1 Get up to 10 actively-processed sagas in Start
```sql
EXEC Saga.GetAllSagaRunsWithLimitsByStatus @SagaStatusTypeId = 1, @Limit = 10
```

### 8.2 Get actively-processed rollback sagas
```sql
EXEC Saga.GetAllSagaRunsWithLimitsByStatus @SagaStatusTypeId = 2, @Limit = 50
```

### 8.3 Count actively-leased sagas by status
```sql
SELECT sr.SagaStatusTypeId, COUNT(*) AS ActiveCount
FROM Saga.SagaRuns sr WITH (NOLOCK)
WHERE sr.SagaKey IN (
    SELECT SagaKey FROM Saga.SagaLeaseTime WITH (NOLOCK)
    WHERE LastUpdaed > DATEADD(MINUTE, -5, GETUTCDATE())
)
GROUP BY sr.SagaStatusTypeId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetAllSagaRunsWithLimitsByStatus | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetAllSagaRunsWithLimitsByStatus.sql*
