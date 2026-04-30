# Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold

> Retrieves saga runs by status that have been running longer than a specified threshold (in seconds) and have active leases, for identifying slow-running sagas.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of saga runs with steps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies sagas that are actively processing but have exceeded an expected duration threshold. It combines status filtering with a time-based age check and active lease verification. This is used by monitoring systems to detect sagas that are running slower than expected - potentially stuck in a polling loop or waiting for an external service response.

The threshold is specified in seconds via `DATEDIFF(ss, sr.Created, GETUTCDATE()) > @Threshold`, comparing the saga's age against the expected maximum processing time. For example, if an ExternalReceiveTransactionSaga typically completes in 60 seconds, setting @Threshold=300 would find sagas that have been running for over 5 minutes.

---

## 2. Business Logic

### 2.1 Duration-Based Slow Saga Detection

**What**: Finds actively-processing sagas that have exceeded an expected duration threshold.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `@Threshold`, `@Limit`, `SagaRuns.Created`

**Rules**:
- Filters by SagaStatusTypeId (typically 1=Start for in-progress sagas)
- Checks DATEDIFF in seconds between Created and current UTC time exceeds @Threshold
- Requires active lease (LastUpdaed within 5 minutes) - excludes abandoned sagas
- Returns TOP (@Limit) results with step-level detail

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status filter. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2 | @Threshold | int | NO | - | CODE-BACKED | Minimum age in seconds. Sagas running longer than this are returned. |
| 3 | @Limit | tinyint | NO | - | CODE-BACKED | Maximum rows to return. |
| 4-14 | (output columns) | - | - | - | CODE-BACKED | Same 12-column result set as other GetAll* SPs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT FROM | Reads saga runs |
| - | Saga.SagaSteps | LEFT JOIN | Step progress |
| - | Saga.SagaLeaseTime | IN subquery | Active lease filter |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold (procedure)
├── Saga.SagaRuns (table) [SELECT FROM]
├── Saga.SagaSteps (table) [LEFT JOIN]
└── Saga.SagaLeaseTime (table) [IN subquery]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT FROM |
| Saga.SagaSteps | Table | LEFT JOIN |
| Saga.SagaLeaseTime | Table | IN subquery |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Uses NOLOCK on all table references.

---

## 8. Sample Queries

### 8.1 Find sagas in Start status running longer than 5 minutes
```sql
EXEC Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold
    @SagaStatusTypeId = 1, @Threshold = 300, @Limit = 20
```

### 8.2 Find slow completed sagas (took more than 10 minutes)
```sql
EXEC Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold
    @SagaStatusTypeId = 3, @Threshold = 600, @Limit = 10
```

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold.sql*
