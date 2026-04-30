# Saga.GetSagaRun

> Retrieves a single saga run with all its steps by SagaKey, providing the complete state needed to resume or inspect a saga execution.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: SagaRuns + SagaSteps for a specific SagaKey |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetSagaRun is the primary single-saga retrieval procedure. Given a SagaKey, it returns the saga run's header information (status, name, correlation ID, additional data) along with all its steps (index, request, response, step status), ordered by StepIndex. This provides the complete execution state needed by the saga orchestrator to resume processing or determine the next action.

This is the most fundamental query in the saga system - called whenever the application needs to load a saga's full state, whether for continuation, recovery, or inspection.

---

## 2. Business Logic

### 2.1 Denormalized Saga + Steps Result Set

**What**: Returns a single flattened result set joining saga header with all step rows.

**Columns/Parameters Involved**: `SagaRuns.*`, `SagaSteps.*`

**Rules**:
- LEFT JOIN SagaSteps to include sagas that have no steps yet (just created)
- Ordered by StepIndex ASC for pipeline sequence
- Returns SagaStatusTypeId as "Status" and StepStatusTypeId as "StepStatus" (aliased)
- Uses NOLOCK on both tables for non-blocking reads
- For a saga with N steps, returns N rows (one per step), each carrying the saga header columns

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Business-level identifier of the saga run to retrieve. Filters SagaRuns.SagaKey. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | Id | bigint | VERIFIED | SagaRuns.Id - internal surrogate key |
| 2 | SagaName | varchar(255) | VERIFIED | Saga workflow type (always "CryptoToFiatSaga") |
| 3 | SagaKey | uniqueidentifier | VERIFIED | Business-level saga identifier |
| 4 | Created | datetime2(7) | VERIFIED | UTC timestamp of saga creation |
| 5 | Status | tinyint | VERIFIED | Current saga status (aliased from SagaStatusTypeId). 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop |
| 6 | CorrelationId | uniqueidentifier | CODE-BACKED | Distributed tracing correlation ID |
| 7 | AdditionalData | nvarchar(max) | VERIFIED | JSON saga request context |
| 8 | StepIndex | tinyint | CODE-BACKED | Step ordinal position (NULL if no steps) |
| 9 | Request | varchar(max) | CODE-BACKED | Step request JSON payload |
| 10 | Response | varchar(max) | CODE-BACKED | Step response JSON payload |
| 11 | StepCreated | datetime2(7) | CODE-BACKED | Step creation timestamp (aliased from SagaSteps.Created) |
| 12 | StepStatus | tinyint | CODE-BACKED | Current step status (aliased from StepStatusTypeId). 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT (FROM) | Primary data source - saga header |
| - | Saga.SagaSteps | SELECT (LEFT JOIN) | Step data joined on SagaSteps.SagaRunId = SagaRuns.Id |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRun (procedure)
├── Saga.SagaRuns (table)
└── Saga.SagaSteps (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - saga header data |
| Saga.SagaSteps | Table | LEFT JOIN - step data by SagaRunId |

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

### 8.1 Get a saga by key
```sql
EXEC Saga.GetSagaRun @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
```

### 8.2 Get saga with resolved status names
```sql
SELECT sr.SagaName, st.Name AS SagaStatus, ss.StepIndex, sst.Name AS StepStatus, ss.Created
FROM Saga.SagaRuns sr WITH (NOLOCK)
LEFT JOIN Saga.SagaSteps ss WITH (NOLOCK) ON ss.SagaRunId = sr.Id
LEFT JOIN Saga.SagaStatusTypes st WITH (NOLOCK) ON st.Id = sr.SagaStatusTypeId
LEFT JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sst.Id = ss.StepStatusTypeId
WHERE sr.SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
ORDER BY ss.StepIndex
```

### 8.3 Check if a saga exists
```sql
SELECT COUNT(*) FROM Saga.SagaRuns WITH (NOLOCK) WHERE SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRun | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetSagaRun.sql*
