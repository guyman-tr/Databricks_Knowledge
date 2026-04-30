# Saga.GetAllSagaRunsWithLimitsByStatus

> Retrieves a limited number of saga runs by status that have active leases (updated within the last 5 minutes), with step-level detail for monitoring active saga processing.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of saga runs with steps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves actively-processing saga runs filtered by status, limiting results to sagas with fresh leases (updated in the last 5 minutes). Unlike `GetAllAbandonedSagaRuns` which finds stale sagas, this procedure specifically targets active ones - it only returns sagas whose lease has been renewed recently, confirming a service instance is actively processing them.

Used by the saga monitoring infrastructure to observe currently-active saga processing. The `@Limit` parameter (TINYINT, max 255) prevents result set overload when many sagas are running concurrently.

---

## 2. Business Logic

### 2.1 Active Lease Filter

**What**: Only returns sagas with leases refreshed within the last 5 minutes.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `@Limit`, `SagaLeaseTime.LastUpdaed`

**Rules**:
- Filters SagaRuns by the provided SagaStatusTypeId
- Requires the saga's SagaKey to exist in SagaLeaseTime with LastUpdaed > 5 minutes ago
- Returns TOP (@Limit) rows, ordered by StepIndex
- LEFT JOINs to SagaSteps for step-level progress detail

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status filter: 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2 | @Limit | tinyint | NO | - | CODE-BACKED | Maximum number of saga runs to return (0-255). |
| 3-12 | (output columns) | - | - | - | CODE-BACKED | Same 12-column result set as `Saga.GetAllAbandonedSagaRuns`: Id, SagaName, SagaKey, Created, Status, CorrelationId, AdditionalData, StepIndex, Request, Response, StepCreated, StepStatus. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT FROM | Reads saga runs filtered by status |
| - | Saga.SagaSteps | LEFT JOIN | Joins step details |
| - | Saga.SagaLeaseTime | IN subquery | Filters to active leases (< 5 min old) |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetAllSagaRunsWithLimitsByStatus (procedure)
├── Saga.SagaRuns (table) [SELECT FROM]
├── Saga.SagaSteps (table) [LEFT JOIN]
└── Saga.SagaLeaseTime (table) [IN subquery]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT FROM - reads saga runs by status |
| Saga.SagaSteps | Table | LEFT JOIN - step progress |
| Saga.SagaLeaseTime | Table | IN subquery - active lease filter |

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

### 8.1 Get up to 10 actively-processing sagas in Start status
```sql
EXEC Saga.GetAllSagaRunsWithLimitsByStatus @SagaStatusTypeId = 1, @Limit = 10
```

### 8.2 Get all actively-processing completed sagas (recent)
```sql
EXEC Saga.GetAllSagaRunsWithLimitsByStatus @SagaStatusTypeId = 3, @Limit = 50
```

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetAllSagaRunsWithLimitsByStatus | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetAllSagaRunsWithLimitsByStatus.sql*
