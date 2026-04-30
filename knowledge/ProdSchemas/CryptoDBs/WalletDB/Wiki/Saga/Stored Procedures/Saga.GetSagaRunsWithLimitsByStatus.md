# Saga.GetSagaRunsWithLimitsByStatus

> Retrieves a limited number of saga runs filtered by status and saga type name, with step-level detail.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of saga runs with steps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves saga runs filtered by both status and saga type name with a configurable row limit. It provides targeted retrieval for monitoring specific saga types in specific states, without the lease or threshold checks found in the "GetAll" variants.

This is the simplest bounded reader for a specific saga type + status combination. The `@Limit` (TINYINT, max 255) prevents unbounded result sets.

---

## 2. Business Logic

No complex business logic. Simple status + name filter with TOP limit and step JOIN.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status filter. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2 | @SagaName | varchar(256) | NO | - | VERIFIED | Saga type name filter. |
| 3 | @Limit | tinyint | NO | - | CODE-BACKED | Maximum rows to return. |
| 4-14 | (output columns) | - | - | - | CODE-BACKED | Standard 12-column result set including AdditionalData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT FROM | Reads saga runs |
| - | Saga.SagaSteps | LEFT JOIN | Step progress |

### 5.2 Referenced By (other objects point to this)

No callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsWithLimitsByStatus (procedure)
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

Uses NOLOCK. SET NOCOUNT ON.

---

## 8. Sample Queries

### 8.1 Get 20 failed ExternalReceiveTransactionSaga runs
```sql
EXEC Saga.GetSagaRunsWithLimitsByStatus
    @SagaStatusTypeId = 4, @SagaName = 'ExternalReceiveTransactionSaga', @Limit = 20
```

### 8.2 N/A
N/A.

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsWithLimitsByStatus | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetSagaRunsWithLimitsByStatus.sql*
