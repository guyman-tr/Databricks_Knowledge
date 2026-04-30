# Saga.ReinitiateSaga

> Reinitializes a failed saga by creating a new saga run with fresh SagaKey, InstanceId, and CorrelationId while preserving the original request data, using dynamic SQL to call InsertSagaRunWithLeaseTime.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: CorrelationId of the new saga run |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the saga retry mechanism. When a saga has permanently failed (status 4) and operations teams determine it should be retried, this procedure creates a completely new saga run that replays the same business operation. It reads the original saga's data, generates new GUIDs for SagaKey, InstanceId, and CorrelationId, updates the CorrelationId in the AdditionalData JSON payload, and then calls `Saga.InsertSagaRunWithLeaseTime` via dynamic SQL to create the new run.

The new saga is a fresh instance - it starts from step 1 with status Start, not from where the original failed. The original failed saga remains unchanged for audit purposes. The new CorrelationId ensures the retry is tracked as a distinct business operation.

---

## 2. Business Logic

### 2.1 Saga Retry via New Instance Creation

**What**: Creates a fresh saga run from a failed saga's data.

**Columns/Parameters Involved**: `@Id`, generated SagaKey/InstanceId/CorrelationId

**Rules**:
- Reads SagaName and AdditionalData from the original saga (by @Id)
- Generates new SagaKey (NEWID()), InstanceId (NEWID()), CorrelationId (NEWID())
- Uses JSON_MODIFY + REPLACE to update the CorrelationId within the nested AdditionalData JSON
- Hardcodes SagaStatusTypeId = 1 (Start) and LeaseTimeInMs = 300000 (5 min)
- Builds a dynamic SQL EXEC command for InsertSagaRunWithLeaseTime
- Executes via sp_executesql through a cursor (supports multiple rows, though typically only one)
- Returns the new CorrelationId for tracking the retry

### 2.2 Dynamic SQL Pattern

**What**: Uses cursor + sp_executesql to call InsertSagaRunWithLeaseTime.

**Columns/Parameters Involved**: @Script (dynamic SQL string)

**Rules**:
- Constructs the full EXEC command as a string with escaped single quotes
- Uses cursor to iterate (handles potential multi-row edge case)
- The dynamic SQL approach was chosen because the AdditionalData manipulation requires the full parameter set to be assembled as a string

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | bigint | NO | - | VERIFIED | SagaRuns.Id of the failed saga to reinitiate. The original saga must exist. |
| 2 | CorrelationId (output) | uniqueidentifier | - | - | CODE-BACKED | Returns the newly generated CorrelationId for tracking the retry saga. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Id | Saga.SagaRuns | SELECT FROM | Reads original saga's SagaName and AdditionalData |
| dynamic SQL | Saga.InsertSagaRunWithLeaseTime | EXEC (via sp_executesql) | Creates the new saga run |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema. Called by operations teams for manual saga retry.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.ReinitiateSaga (procedure)
├── Saga.SagaRuns (table) [SELECT FROM]
└── Saga.InsertSagaRunWithLeaseTime (procedure) [EXEC via dynamic SQL]
    ├── Saga.SagaRuns (table) [INSERT INTO]
    ├── Saga.SagaRunStatuses (table) [INSERT INTO]
    └── Saga.SagaLeaseTime (table) [INSERT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT FROM - reads original saga data |
| Saga.InsertSagaRunWithLeaseTime | Stored Procedure | EXEC via dynamic SQL - creates new saga run |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Uses temp table #Result. Cursor-based execution. Dynamic SQL via sp_executesql. JSON_MODIFY for AdditionalData manipulation. Uses NOLOCK for SagaRuns read.

---

## 8. Sample Queries

### 8.1 Reinitiate a failed saga
```sql
EXEC Saga.ReinitiateSaga @Id = 12345
-- Returns: new CorrelationId for tracking
```

### 8.2 Find a failed saga to reinitiate
```sql
SELECT sr.Id, sr.SagaName, sr.Created, sst.Name AS Status, sr.CorrelationId
FROM Saga.SagaRuns sr WITH (NOLOCK)
JOIN Saga.SagaStatusTypes sst WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
WHERE sr.SagaStatusTypeId = 4
ORDER BY sr.Id DESC
```

### 8.3 Verify the retry was created
```sql
SELECT Id, SagaName, SagaKey, CorrelationId, SagaStatusTypeId, Created
FROM Saga.SagaRuns WITH (NOLOCK)
ORDER BY Id DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | HA recovery for pod restarts uses saga name for independent recovery. ReinitiateSaga provides manual retry capability beyond automated HA recovery. |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.ReinitiateSaga | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.ReinitiateSaga.sql*
