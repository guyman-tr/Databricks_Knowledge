# Wallet.GetSagaRunsByStatus

> Retrieves all saga runs in a specified status along with their steps, enabling monitoring of sagas at a particular lifecycle stage (e.g., all in-progress or all failed sagas).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns saga runs filtered by status with all steps |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all saga runs that are currently in a specified status, along with their step details. It is the monitoring counterpart to `Wallet.GetSagaRun` (which looks up by key). While GetSagaRun answers "what is the state of this specific saga?", this procedure answers "which sagas are currently in state X?"

This enables operational monitoring - for example, finding all sagas stuck in an "in-progress" state, or all sagas that have failed and need retry. The saga orchestrator can also use this to resume processing sagas that were interrupted by a service restart.

The structure is identical to GetSagaRun but filtered by SagaStatusTypeId instead of SagaKey.

---

## 2. Business Logic

### 2.1 Status-Based Saga Monitoring

**What**: Finds all sagas at a given lifecycle stage for monitoring and recovery.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `SagaRuns.SagaStatusTypeId`

**Rules**:
- Filters SagaRuns by the specified SagaStatusTypeId
- LEFT JOIN to SagaSteps includes step details for each matching saga
- Results ordered by StepIndex for logical step sequence per saga
- May return large result sets if many sagas are in the specified state

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | CODE-BACKED | Saga status to filter by. Matches SagaRuns.SagaStatusTypeId. Defines the lifecycle stage to query. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Saga run identity. PK of Wallet.SagaRuns. |
| 2 | SagaName | nvarchar | NO | - | CODE-BACKED | Name/type of the saga workflow. |
| 3 | SagaKey | uniqueidentifier | NO | - | CODE-BACKED | Unique saga instance key. |
| 4 | Created | datetime2(7) | NO | - | CODE-BACKED | When the saga run was created. |
| 5 | Status | tinyint | NO | - | CODE-BACKED | Current saga status (always equals @SagaStatusTypeId for all returned rows). |
| 6 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links the saga to the originating request. |
| 7 | StepIndex | tinyint | YES | - | CODE-BACKED | Step execution order index. NULL if saga has no steps. |
| 8 | Request | nvarchar | YES | - | CODE-BACKED | Serialized request payload for this step. |
| 9 | Response | nvarchar | YES | - | CODE-BACKED | Serialized response from this step. |
| 10 | StepCreated | datetime2(7) | YES | - | CODE-BACKED | When this step was executed. |
| 11 | StepStatus | tinyint | YES | - | CODE-BACKED | Status of this individual step. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.SagaRuns | FROM | Saga run metadata filtered by status |
| LEFT JOIN | Wallet.SagaSteps | LEFT JOIN | Step details per saga |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SQL callers found) | - | - | Called from saga orchestrator for monitoring/recovery |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSagaRunsByStatus (procedure)
├── Wallet.SagaRuns (table)
└── Wallet.SagaSteps (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table | FROM with NOLOCK - filtered by SagaStatusTypeId |
| Wallet.SagaSteps | Table | LEFT JOIN with NOLOCK - step details |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found in SQL) | - | Monitoring and recovery endpoint |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hints | Read isolation | Both tables use NOLOCK |
| ORDER BY StepIndex | Result ordering | Steps in execution order |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Find all in-progress sagas
```sql
EXEC Wallet.GetSagaRunsByStatus @SagaStatusTypeId = 1;
```

### 8.2 Count sagas by status
```sql
SELECT SagaStatusTypeId, COUNT(*) AS SagaCount
FROM Wallet.SagaRuns WITH (NOLOCK)
GROUP BY SagaStatusTypeId
ORDER BY SagaStatusTypeId;
```

### 8.3 Find stuck sagas (in-progress for over 1 hour)
```sql
SELECT sr.SagaKey, sr.SagaName, sr.Created,
    DATEDIFF(MINUTE, sr.Created, GETUTCDATE()) AS MinutesRunning
FROM Wallet.SagaRuns sr WITH (NOLOCK)
WHERE sr.SagaStatusTypeId = 1
    AND DATEDIFF(HOUR, sr.Created, GETUTCDATE()) > 1
ORDER BY sr.Created;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSagaRunsByStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetSagaRunsByStatus.sql*
