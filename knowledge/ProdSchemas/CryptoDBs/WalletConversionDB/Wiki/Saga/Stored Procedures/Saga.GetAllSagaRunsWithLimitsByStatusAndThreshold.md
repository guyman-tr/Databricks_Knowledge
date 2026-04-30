# Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold

> Retrieves actively-leased saga runs filtered by status that have been running longer than a time threshold, identifying long-running sagas that may need attention.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: TOP @Limit actively-leased SagaRuns + SagaSteps by status and age threshold |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAllSagaRunsWithLimitsByStatusAndThreshold adds a time threshold to the active-lease query pattern. It returns sagas that are both actively being processed (lease within 5 minutes) AND have been running longer than @Threshold seconds. This identifies sagas that are taking longer than expected - potential candidates for monitoring alerts or escalation.

Used by the monitoring and alerting system to find sagas that have exceeded expected processing times.

---

## 2. Business Logic

### 2.1 Active Lease + Status + Age Threshold + Limit

**What**: Four-way filter: status, active lease, minimum age, and row limit.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `@Threshold`, `@Limit`

**Rules**:
- SELECT TOP (@Limit) WHERE SagaStatusTypeId = @SagaStatusTypeId
- AND DATEDIFF(ss, sr.Created, GETUTCDATE()) > @Threshold (saga older than N seconds)
- AND SagaKey IN SagaLeaseTime WHERE LastUpdaed > DATEADD(MINUTE, -5, GETUTCDATE()) (active lease)
- Identifies sagas that are actively being worked on but taking too long

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status to filter by. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2 | @Threshold | int | NO | - | VERIFIED | Minimum age in seconds. Only sagas older than this threshold are returned. Example: 300 = sagas running for more than 5 minutes. |
| 3 | @Limit | tinyint | NO | - | VERIFIED | Maximum number of saga runs to return. Max 255. |

**Return Columns:** Same as Saga.GetSagaRun.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT (FROM) | Filtered by status and age threshold |
| - | Saga.SagaSteps | SELECT (LEFT JOIN) | Step data joined by SagaRunId |
| - | Saga.SagaLeaseTime | SELECT (IN subquery) | Active lease check |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold (procedure)
├── Saga.SagaRuns (table)
├── Saga.SagaSteps (table)
└── Saga.SagaLeaseTime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - filtered by status, age, and active lease |
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

### 8.1 Find active sagas running for more than 5 minutes
```sql
EXEC Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold @SagaStatusTypeId = 1, @Threshold = 300, @Limit = 10
```

### 8.2 Find active rollback sagas older than 10 minutes
```sql
EXEC Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold @SagaStatusTypeId = 2, @Threshold = 600, @Limit = 10
```

### 8.3 Count long-running active sagas
```sql
SELECT COUNT(*) FROM Saga.SagaRuns sr WITH (NOLOCK)
WHERE sr.SagaStatusTypeId = 1
AND DATEDIFF(SECOND, sr.Created, GETUTCDATE()) > 300
AND sr.SagaKey IN (
    SELECT SagaKey FROM Saga.SagaLeaseTime WITH (NOLOCK)
    WHERE LastUpdaed > DATEADD(MINUTE, -5, GETUTCDATE())
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold.sql*
