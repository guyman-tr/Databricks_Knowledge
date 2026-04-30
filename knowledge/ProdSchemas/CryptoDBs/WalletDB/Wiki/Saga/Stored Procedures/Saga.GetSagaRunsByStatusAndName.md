# Saga.GetSagaRunsByStatusAndName

> Retrieves saga runs in Start or Rollback status for a specific saga type, with a configurable limit, for targeted recovery monitoring by saga name.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of saga runs with steps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves saga runs that are in active (non-terminal) states for a specific saga type. It uses a subquery pattern: first selects the TOP @Limit saga runs in status 1 (Start) or 2 (Rollback) ordered by Id ASC (oldest first), then LEFT JOINs to SagaSteps and filters by @SagaName.

This is used by saga-type-specific HA workers to find their sagas needing attention. Unlike `GetSagaRunsForRecovery` which also targets Start/Rollback, this procedure applies a row limit and filters by name after the initial status selection - meaning it gets the oldest @Limit sagas in Start/Rollback across ALL types, then filters to the requested type. This nuance means the actual number of results may be less than @Limit.

---

## 2. Business Logic

### 2.1 Two-Phase Filtering

**What**: Gets oldest non-terminal sagas first, then filters by name.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `@SagaName`, `@Limit`

**Rules**:
- Inner query: TOP (@Limit) from SagaRuns WHERE SagaStatusTypeId IN (1, 2) ORDER BY Id ASC
- Note: @SagaStatusTypeId parameter is declared but NOT used in the WHERE clause - the procedure always filters for statuses 1 and 2
- Outer query: LEFT JOIN SagaSteps, WHERE SagaName = @SagaName
- Result: oldest non-terminal sagas of the specified type, up to @Limit total candidates

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | CODE-BACKED | Declared but NOT used in the procedure body. The WHERE clause hardcodes `SagaStatusTypeId IN (1, 2)`. Likely a vestigial parameter from an earlier version. |
| 2 | @SagaName | varchar(256) | NO | - | VERIFIED | Saga type name to filter by (e.g., 'ExternalReceiveTransactionSaga'). Applied as outer WHERE filter after the TOP selection. |
| 3 | @Limit | int | NO | 100 | CODE-BACKED | Maximum candidate rows from the inner subquery (default 100). Actual results may be fewer after the SagaName filter. |
| 4-14 | (output columns) | - | - | - | CODE-BACKED | Standard 12-column result set including AdditionalData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT FROM | Reads saga runs in non-terminal states |
| - | Saga.SagaSteps | LEFT JOIN | Step progress detail |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsByStatusAndName (procedure)
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

Uses NOLOCK. @SagaStatusTypeId parameter is unused (potential tech debt).

---

## 8. Sample Queries

### 8.1 Get oldest 50 non-terminal ExternalReceiveTransactionSaga runs
```sql
EXEC Saga.GetSagaRunsByStatusAndName
    @SagaStatusTypeId = 1,
    @SagaName = 'ExternalReceiveTransactionSaga',
    @Limit = 50
```

### 8.2 N/A
N/A.

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsByStatusAndName | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetSagaRunsByStatusAndName.sql*
