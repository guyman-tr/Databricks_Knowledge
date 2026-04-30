# Saga.GetSagaRunsByStatus

> Retrieves all saga runs matching a given status with their step details, for bulk status-based queries across all saga types.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of saga runs with steps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all saga runs that match a given SagaStatusTypeId, regardless of saga type or lease status. Unlike `GetAllSagaRunsWithLimitsByStatus` (which requires active leases) or `GetSagaRunsForRecovery` (which targets Start/Rollback for a specific saga name), this is the simplest status-based query with no additional filters or limits.

Used for broad operational queries such as "show me all failed sagas" or "show me all currently running sagas". The unbounded result set (no TOP) means this should be used with caution on busy systems.

---

## 2. Business Logic

No complex business logic. Status-filtered SELECT with step JOIN.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status filter: 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2-12 | (output columns) | - | - | - | CODE-BACKED | Same 11-column result set as GetSagaRun: Id, SagaName, SagaKey, Created, Status, CorrelationId, StepIndex, Request, Response, StepCreated, StepStatus. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT FROM | Reads saga runs filtered by status |
| - | Saga.SagaSteps | LEFT JOIN | Step progress |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsByStatus (procedure)
├── Saga.SagaRuns (table) [SELECT FROM]
└── Saga.SagaSteps (table) [LEFT JOIN]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT FROM |
| Saga.SagaSteps | Table | LEFT JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Uses NOLOCK. SET NOCOUNT ON. No result limit - returns all matching rows.

---

## 8. Sample Queries

### 8.1 Get all failed sagas
```sql
EXEC Saga.GetSagaRunsByStatus @SagaStatusTypeId = 4
```

### 8.2 Get all currently running sagas
```sql
EXEC Saga.GetSagaRunsByStatus @SagaStatusTypeId = 1
```

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsByStatus | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetSagaRunsByStatus.sql*
