# Saga.GetSagaRunsForRecovery

> Retrieves all saga runs in Start or Rollback status for a specific saga type, providing the complete state needed for HA recovery processing.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of saga runs with steps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary query used by HA (High Availability) recovery workers to find saga runs that need to be resumed. It returns all sagas in Start (1) or Rollback (2) status for a given saga type name - these are the two non-terminal, non-completed states where a saga requires active processing.

Unlike `GetAllAbandonedSagaRuns` which checks lease expiry, this procedure does NOT check lease status. It returns ALL non-terminal sagas for the specified type, leaving lease management to the caller (`TakeSagaRun`). The HA worker pattern is: call GetSagaRunsForRecovery to get candidates, then call TakeSagaRun for each to attempt lease acquisition.

The status constants are hardcoded as local variables (not passed as parameters), making the recovery criteria explicit and immutable.

---

## 2. Business Logic

### 2.1 Recovery Candidate Selection

**What**: Finds all non-terminal sagas for a specific type.

**Columns/Parameters Involved**: `@SagaName`, hardcoded status constants

**Rules**:
- Uses DECLARE variables: @SagaStartStatus = 1, @SagaRollbackStatus = 2
- WHERE SagaStatusTypeId = 1 OR SagaStatusTypeId = 2
- Filtered by @SagaName (each HA worker recovers only its own saga type)
- No limit on results - returns all candidates
- No lease check - the caller handles lease acquisition

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaName | varchar(256) | NO | - | VERIFIED | Saga type name to filter by. Each HA worker passes its own saga type (e.g., 'ExternalReceiveTransactionSaga'). |
| 2-12 | (output columns) | - | - | - | CODE-BACKED | Standard 12-column result set including AdditionalData, ordered by StepIndex. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT FROM | Reads non-terminal saga runs |
| - | Saga.SagaSteps | LEFT JOIN | Step progress detail |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema. Called by HA recovery workers in the application.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsForRecovery (procedure)
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

### 8.1 Find all recovery candidates for ExternalReceiveTransactionSaga
```sql
EXEC Saga.GetSagaRunsForRecovery @SagaName = 'ExternalReceiveTransactionSaga'
```

### 8.2 Find recovery candidates for staking sagas
```sql
EXEC Saga.GetSagaRunsForRecovery @SagaName = 'saga_staking'
```

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | Each saga type has its own HA worker (e.g., AutoC2PSagaHighAvailability) that uses SQL-based HA for pod restarts, calling recovery procedures per saga name |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsForRecovery | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetSagaRunsForRecovery.sql*
