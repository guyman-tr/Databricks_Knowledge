# Saga.GetSagaRunsByStatusAndThreshold

> Retrieves saga runs by status, name, and age threshold (in seconds) with active lease verification, for targeted slow-saga monitoring per saga type.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of saga runs with steps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure combines all available filters for precise saga monitoring: status, saga type name, duration threshold, active lease, and result limit. It is the most targeted reader SP in the saga schema, enabling queries like "find up to 10 ExternalReceiveTransactionSaga runs in Start status that have been running for over 300 seconds and still have an active lease."

Note: uses `GETDATE()` (local time) for the DATEDIFF threshold check, unlike most other SPs which use `GETUTCDATE()`. This is likely a bug that could cause incorrect threshold calculations if the server's local time differs from UTC.

---

## 2. Business Logic

### 2.1 Multi-Filter Active Saga Search

**What**: Combines status + name + age + lease filters.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `@SagaName`, `@Threshold`, `@Limit`

**Rules**:
- Filters by SagaStatusTypeId AND SagaName AND age > @Threshold seconds AND active lease (5 min)
- Uses GETDATE() (not GETUTCDATE()) for threshold DATEDIFF - potential timezone issue
- Returns TOP (@Limit) with step detail

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status filter. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2 | @SagaName | varchar(256) | NO | - | VERIFIED | Saga type name filter. |
| 3 | @Threshold | int | NO | - | CODE-BACKED | Minimum age in seconds (compared via DATEDIFF with GETDATE()). |
| 4 | @Limit | tinyint | NO | - | CODE-BACKED | Maximum rows to return. |
| 5-15 | (output columns) | - | - | - | CODE-BACKED | Standard 12-column result set including AdditionalData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT FROM | Reads saga runs |
| - | Saga.SagaSteps | LEFT JOIN | Step progress |
| - | Saga.SagaLeaseTime | IN subquery | Active lease filter |

### 5.2 Referenced By (other objects point to this)

No callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsByStatusAndThreshold (procedure)
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

Uses NOLOCK. Note: uses GETDATE() instead of GETUTCDATE() for threshold check - inconsistent with other SPs.

---

## 8. Sample Queries

### 8.1 Find slow ExternalReceiveTransactionSagas
```sql
EXEC Saga.GetSagaRunsByStatusAndThreshold
    @SagaStatusTypeId = 1, @SagaName = 'ExternalReceiveTransactionSaga',
    @Threshold = 300, @Limit = 10
```

### 8.2 N/A
N/A.

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsByStatusAndThreshold | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetSagaRunsByStatusAndThreshold.sql*
