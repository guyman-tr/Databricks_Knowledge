# Saga.GetAllAbandonedSagaRuns

> Retrieves all saga runs stuck in Start status whose lease has expired (not updated in the last hour), returning run details with step-level progress for recovery analysis.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of abandoned saga runs with steps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary diagnostic tool for identifying sagas that are stuck and need recovery intervention. An "abandoned" saga is one that has SagaStatusTypeId=1 (Start) but whose lease in `Saga.SagaLeaseTime` has not been refreshed in the last hour, indicating the processing instance has crashed or become unresponsive.

The procedure is called by the HA (High Availability) recovery workers that periodically scan for stuck sagas. When found, these sagas can be reclaimed by a healthy instance via `Saga.TakeSagaRun`. The result set includes step-level detail so the recovery system knows exactly where each saga was in its pipeline when it became abandoned.

The 1-hour threshold (`DATEADD(hh, -1, GETUTCDATE())`) provides a generous window to avoid false positives from temporary slowdowns, while still catching genuinely stuck sagas in a timely manner.

---

## 2. Business Logic

### 2.1 Abandoned Saga Detection

**What**: Identifies sagas that are in Start status but have not had their lease renewed within the last hour.

**Columns/Parameters Involved**: `SagaStatusTypeId`, `SagaLeaseTime.LastUpdaed`

**Rules**:
- Saga must be in status 1 (Start) - only actively running sagas can be "abandoned"
- Saga's SagaKey must NOT appear in SagaLeaseTime with LastUpdaed > 1 hour ago
- Uses NOT IN subquery against SagaLeaseTime for the lease freshness check
- Returns all matching sagas with their step details via LEFT JOIN to SagaSteps
- Results ordered by StepIndex to show pipeline progress

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id (output) | bigint | - | - | VERIFIED | SagaRuns.Id - the saga run identifier |
| 2 | SagaName (output) | varchar(255) | - | - | VERIFIED | Saga type name (e.g., ExternalReceiveTransactionSaga) |
| 3 | SagaKey (output) | uniqueidentifier | - | - | VERIFIED | Technical saga instance GUID |
| 4 | Created (output) | datetime2(7) | - | - | CODE-BACKED | When the saga was initiated |
| 5 | Status (output) | tinyint | - | - | VERIFIED | SagaStatusTypeId aliased as "Status". Always 1 (Start) for abandoned sagas. |
| 6 | CorrelationId (output) | uniqueidentifier | - | - | CODE-BACKED | Business correlation GUID linking to the originating request |
| 7 | AdditionalData (output) | nvarchar(max) | - | - | CODE-BACKED | JSON payload with saga request context for debugging |
| 8 | StepIndex (output) | tinyint | - | - | CODE-BACKED | Step position in pipeline (from LEFT JOIN to SagaSteps). NULL if no steps recorded. The highest StepIndex indicates where the saga was when it became abandoned. |
| 9 | Request (output) | varchar(max) | - | - | CODE-BACKED | Step request JSON payload |
| 10 | Response (output) | varchar(max) | - | - | CODE-BACKED | Step response JSON payload (NULL if step did not complete) |
| 11 | StepCreated (output) | datetime2(7) | - | - | CODE-BACKED | SagaSteps.Created aliased as StepCreated |
| 12 | StepStatus (output) | tinyint | - | - | CODE-BACKED | StepStatusTypeId aliased as StepStatus. The last step's status reveals where the saga stalled. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT FROM | Reads saga run records filtered by status |
| - | Saga.SagaSteps | LEFT JOIN | Joins step details via SagaRunId |
| - | Saga.SagaLeaseTime | NOT IN subquery | Checks lease freshness to identify abandoned sagas |

### 5.2 Referenced By (other objects point to this)

No callers found within the Saga schema. Called by HA recovery workers in the application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetAllAbandonedSagaRuns (procedure)
├── Saga.SagaRuns (table) [SELECT FROM]
├── Saga.SagaSteps (table) [LEFT JOIN]
└── Saga.SagaLeaseTime (table) [NOT IN subquery]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT FROM - reads saga runs in Start status |
| Saga.SagaSteps | Table | LEFT JOIN on SagaRunId - retrieves step progress |
| Saga.SagaLeaseTime | Table | NOT IN subquery - filters to leases not updated in last hour |

### 6.2 Objects That Depend On This

No dependents found within the schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Uses NOLOCK hint on all table references. No transaction wrapping.

---

## 8. Sample Queries

### 8.1 Find all abandoned sagas
```sql
EXEC Saga.GetAllAbandonedSagaRuns
```

### 8.2 Equivalent manual query with human-readable status
```sql
SELECT sr.Id, sr.SagaName, sr.SagaKey, sr.Created,
       sst.Name AS SagaStatus, ss.StepIndex, ssst.Name AS StepStatus
FROM Saga.SagaRuns sr WITH (NOLOCK)
LEFT JOIN Saga.SagaSteps ss WITH (NOLOCK) ON ss.SagaRunId = sr.Id
JOIN Saga.SagaStatusTypes sst WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
LEFT JOIN Saga.StepStatusTypes ssst WITH (NOLOCK) ON ss.StepStatusTypeId = ssst.Id
WHERE sr.SagaStatusTypeId = 1
AND sr.SagaKey NOT IN (
    SELECT SagaKey FROM Saga.SagaLeaseTime WITH (NOLOCK)
    WHERE LastUpdaed > DATEADD(HOUR, -1, GETUTCDATE())
)
ORDER BY ss.StepIndex
```

### 8.3 Count abandoned sagas by type
```sql
SELECT SagaName, COUNT(DISTINCT Id) AS AbandonedCount
FROM (
    SELECT sr.Id, sr.SagaName
    FROM Saga.SagaRuns sr WITH (NOLOCK)
    WHERE sr.SagaStatusTypeId = 1
    AND sr.SagaKey NOT IN (
        SELECT SagaKey FROM Saga.SagaLeaseTime WITH (NOLOCK)
        WHERE LastUpdaed > DATEADD(HOUR, -1, GETUTCDATE())
    )
) x
GROUP BY SagaName
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | HA recovery pattern: each saga type has its own HA worker that scans for abandoned sagas and restarts them on healthy pods |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetAllAbandonedSagaRuns | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetAllAbandonedSagaRuns.sql*
