# Saga.GetAllAbandonedSagaRuns

> Retrieves all saga runs in Start status whose lease has expired (not updated in the last hour), identifying sagas that are stuck and need recovery intervention.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Abandoned SagaRuns + SagaSteps (status=1, stale lease) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAllAbandonedSagaRuns finds saga runs that have been abandoned - started but not making progress. It targets sagas with status=1 (Start) whose SagaKey does NOT appear in SagaLeaseTime with a recent LastUpdaed (within the last hour). This identifies sagas where the owning worker instance crashed, disconnected, or stalled without completing the saga or releasing the lease.

This is a key recovery procedure. The recovery service periodically calls it to find abandoned sagas that need to be resumed by a healthy worker (via TakeSagaRun).

---

## 2. Business Logic

### 2.1 Abandonment Detection

**What**: Combines status filter with lease staleness check to identify truly abandoned sagas.

**Columns/Parameters Involved**: SagaRuns.SagaStatusTypeId, SagaLeaseTime.LastUpdaed

**Rules**:
- Filters SagaRuns WHERE SagaStatusTypeId = 1 (Start only, not Rollback)
- Excludes sagas with a SagaLeaseTime row where `LastUpdaed > DATEADD(hh, -1, GETUTCDATE())` (active within last hour)
- Uses NOT IN subquery on SagaKey for the lease check
- LEFT JOINs SagaSteps for step data, ordered by StepIndex
- No row limit - returns all abandoned sagas
- Note: only targets Start status (1), not Rollback (2). Rollback sagas with stale leases may need separate recovery.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

**Return Columns:** Same as Saga.GetSagaRun (Id, SagaName, SagaKey, Created, Status, CorrelationId, AdditionalData, StepIndex, Request, Response, StepCreated, StepStatus).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT (FROM) | Saga header data filtered to status=1 |
| - | Saga.SagaSteps | SELECT (LEFT JOIN) | Step data joined by SagaRunId |
| - | Saga.SagaLeaseTime | SELECT (NOT IN subquery) | Excludes sagas with fresh leases (LastUpdaed within 1 hour) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetAllAbandonedSagaRuns (procedure)
├── Saga.SagaRuns (table)
├── Saga.SagaSteps (table)
└── Saga.SagaLeaseTime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - filtered by status=1 and stale lease |
| Saga.SagaSteps | Table | LEFT JOIN by SagaRunId |
| Saga.SagaLeaseTime | Table | NOT IN subquery - excludes fresh leases |

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

### 8.1 Find all abandoned sagas
```sql
EXEC Saga.GetAllAbandonedSagaRuns
```

### 8.2 Direct equivalent query
```sql
SELECT sr.Id, sr.SagaName, sr.SagaKey, sr.Created, sr.SagaStatusTypeId AS Status
FROM Saga.SagaRuns sr WITH (NOLOCK)
WHERE sr.SagaStatusTypeId = 1
AND sr.SagaKey NOT IN (
    SELECT SagaKey FROM Saga.SagaLeaseTime WITH (NOLOCK)
    WHERE LastUpdaed > DATEADD(HOUR, -1, GETUTCDATE())
)
```

### 8.3 Count abandoned sagas
```sql
SELECT COUNT(*) FROM Saga.SagaRuns WITH (NOLOCK)
WHERE SagaStatusTypeId = 1
AND SagaKey NOT IN (
    SELECT SagaKey FROM Saga.SagaLeaseTime WITH (NOLOCK)
    WHERE LastUpdaed > DATEADD(HOUR, -1, GETUTCDATE())
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetAllAbandonedSagaRuns | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetAllAbandonedSagaRuns.sql*
