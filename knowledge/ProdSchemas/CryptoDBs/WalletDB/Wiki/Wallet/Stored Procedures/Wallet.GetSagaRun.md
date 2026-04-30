# Wallet.GetSagaRun

> Retrieves a saga run with all its steps by saga key, providing the complete execution state of a distributed workflow orchestration.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns saga run details with all steps ordered by index |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the complete state of a saga (distributed workflow) by its unique key. The saga pattern is used to orchestrate multi-step operations that span multiple services or resources - such as a crypto send that involves validation, blockchain submission, and status tracking. Each saga run has a series of ordered steps, and this procedure returns the run metadata along with all steps in execution order.

Without this procedure, there would be no way to inspect the current state of a multi-step workflow, making it impossible to debug stuck operations or understand which step failed in a complex transaction chain.

Data comes from `Wallet.SagaRuns` LEFT JOINed to `Wallet.SagaSteps`. The LEFT JOIN ensures saga runs with no steps yet (just created) are still returned. Results are ordered by StepIndex for logical execution order.

---

## 2. Business Logic

### 2.1 Saga State Retrieval

**What**: Returns the full saga execution state including all steps in order.

**Columns/Parameters Involved**: `@SagaKey`, `SagaRuns.SagaKey`, `SagaSteps.StepIndex`

**Rules**:
- Lookup by SagaKey (uniqueidentifier) - each saga instance has a unique key
- LEFT JOIN to SagaSteps ensures newly created sagas (no steps yet) are still visible
- Steps ordered by StepIndex for logical execution sequence
- Both request and response payloads are returned per step for full audit trail

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | CODE-BACKED | Unique saga instance key. Each saga run is identified by this GUID. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Saga run identity. PK of Wallet.SagaRuns. |
| 2 | SagaName | nvarchar | NO | - | CODE-BACKED | Name/type of the saga (e.g., "SendTransaction", "Conversion"). Identifies the workflow template. |
| 3 | SagaKey | uniqueidentifier | NO | - | CODE-BACKED | Unique saga instance key (echoed from input). |
| 4 | Created | datetime2(7) | NO | - | CODE-BACKED | When the saga run was created. |
| 5 | Status | tinyint | NO | - | CODE-BACKED | Current saga status (from SagaStatusTypeId). Defines overall saga lifecycle state. |
| 6 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links the saga to the originating request in Wallet.Requests. |
| 7 | StepIndex | tinyint | YES | - | CODE-BACKED | Execution order index of this step within the saga. NULL if saga has no steps yet. |
| 8 | Request | nvarchar | YES | - | CODE-BACKED | Serialized request payload sent to this step's handler. Contains the step's input data. |
| 9 | Response | nvarchar | YES | - | CODE-BACKED | Serialized response from this step's handler. Contains result or error details. |
| 10 | StepCreated | datetime2(7) | YES | - | CODE-BACKED | When this step was created/executed. |
| 11 | StepStatus | tinyint | YES | - | CODE-BACKED | Status of this individual step (from StepStatusTypeId). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.SagaRuns | FROM | Saga run metadata |
| LEFT JOIN | Wallet.SagaSteps | LEFT JOIN | Individual saga steps |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SQL callers found) | - | - | Called from saga orchestrator in application layer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSagaRun (procedure)
├── Wallet.SagaRuns (table)
└── Wallet.SagaSteps (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table | FROM with NOLOCK - saga run metadata |
| Wallet.SagaSteps | Table | LEFT JOIN with NOLOCK - saga step details |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found in SQL) | - | Called from saga orchestrator |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hints | Read isolation | Both tables read with NOLOCK |
| ORDER BY StepIndex | Result ordering | Steps returned in execution order |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Look up a saga by its key
```sql
EXEC Wallet.GetSagaRun @SagaKey = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Find saga runs and their step counts
```sql
SELECT sr.SagaKey, sr.SagaName, sr.SagaStatusTypeId, sr.Created,
    COUNT(ss.Id) AS StepCount
FROM Wallet.SagaRuns sr WITH (NOLOCK)
    LEFT JOIN Wallet.SagaSteps ss WITH (NOLOCK) ON ss.SagaRunId = sr.Id
GROUP BY sr.SagaKey, sr.SagaName, sr.SagaStatusTypeId, sr.Created
ORDER BY sr.Created DESC;
```

### 8.3 Find failed saga steps
```sql
SELECT sr.SagaKey, sr.SagaName, ss.StepIndex, ss.StepStatusTypeId, ss.Response
FROM Wallet.SagaRuns sr WITH (NOLOCK)
    JOIN Wallet.SagaSteps ss WITH (NOLOCK) ON ss.SagaRunId = sr.Id
WHERE ss.StepStatusTypeId = 2
ORDER BY ss.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSagaRun | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetSagaRun.sql*
