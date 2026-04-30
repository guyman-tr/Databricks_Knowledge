# Saga.SagaRuns

> Central orchestration table tracking every saga run instance in the wallet conversion system, storing the saga identity, current lifecycle status, and request context for distributed transaction coordination.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (PK + 2 NC) |

---

## 1. Business Meaning

SagaRuns is the central table of the saga orchestration system. Each row represents one execution of a saga workflow - a coordinated multi-step distributed transaction. In this database, ALL saga runs are of type "CryptoToFiatSaga", which orchestrates the process of converting cryptocurrency holdings into fiat currency. The table stores the saga's identity (SagaKey), its current lifecycle status, a distributed tracing correlation ID, and the full request context as JSON in AdditionalData.

Without this table, there would be no record of saga executions, no way to track their status, and no foundation for the entire orchestration pattern. Every other table in the Saga schema (steps, step statuses, run statuses, lease times, events) references back to SagaRuns as the root entity.

Saga runs are created atomically by `Saga.InsertSagaRunWithLeaseTime`, which inserts the run, its initial status history record, and a lease row in a single transaction. Status transitions are performed by `Saga.InsertSagaRunStatus`, which updates SagaStatusTypeId and logs to SagaRunStatuses. Numerous query procedures read saga runs filtered by status, name, lease freshness, and age thresholds to support monitoring, recovery, and application workflows.

---

## 2. Business Logic

### 2.1 Saga Run Lifecycle

**What**: Each saga run progresses through a defined lifecycle from creation to terminal state, tracked by SagaStatusTypeId.

**Columns/Parameters Involved**: `SagaStatusTypeId`, `Created`, `SagaKey`

**Rules**:
- Created with SagaStatusTypeId = 1 (Start) by InsertSagaRunWithLeaseTime
- Transitions to 2 (Rollback) if a step fails - InsertSagaRunStatus updates the column
- Transitions to 3 (Completed) when all steps succeed or rollback completes
- Transitions to 4 (Failed) when rollback itself fails
- Can be set to 5 (ForceStop) by operator intervention
- Status distribution (live): 97% Completed, 2.8% Rollback, 0.1% Start, 0.1% Failed, 0% ForceStop
- See [Saga Status Type](../../_glossary.md#saga-status-type) for full status definitions

**Diagram**:
```
[INSERT by InsertSagaRunWithLeaseTime]
         |
    SagaStatusTypeId = 1 (Start)
         |
    +----+----+
    |         |
 success    failure
    |         |
  3 (Done)  2 (Rollback)
              |
         +----+----+
         |         |
      success    failure
         |         |
       3 (Done)  4 (Failed)
```

### 2.2 Deduplication by SagaKey

**What**: The SagaKey GUID serves as a business-level idempotency key preventing duplicate saga creation.

**Columns/Parameters Involved**: `SagaKey`, `Id`

**Rules**:
- InsertSagaRunWithLeaseTime checks `WHERE NOT EXISTS (SELECT 1 FROM SagaRuns WHERE SagaKey = @SagaKey)` before INSERT
- If SagaKey already exists, raises error: 'SagaKey "{key}" already exists'
- This prevents double-submission of the same conversion request
- A unique nonclustered index on SagaKey enforces this at the database level

### 2.3 CryptoToFiatSaga Request Context

**What**: AdditionalData stores the full serialized saga request, providing context for all downstream steps.

**Columns/Parameters Involved**: `SagaName`, `AdditionalData`

**Rules**:
- All 17,042 rows have SagaName = "CryptoToFiatSaga" - this is the only saga type in the system
- AdditionalData contains JSON with the SagaRequest, including SourceWalletId, Gcid (Global Customer ID), and other conversion parameters
- The JSON payload is read by the application to drive step execution - the DB stores it as opaque context

---

## 3. Data Overview

| Id | SagaName | SagaStatusTypeId | Created | Meaning |
|----|----------|------------------|---------|---------|
| 17042 | CryptoToFiatSaga | 3 (Completed) | 2026-04-15 07:56 | Most recent saga - completed successfully. Typical outcome for 97% of runs. |
| 17040 | CryptoToFiatSaga | 2 (Rollback) | 2026-04-15 06:35 | Saga in rollback state - a step failed and compensation is executing. 2.8% of runs reach this state. |
| 17038 | CryptoToFiatSaga | 3 (Completed) | 2026-04-15 06:05 | Another completed saga with AdditionalData containing wallet and customer context for the conversion. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | VERIFIED | Auto-incrementing surrogate primary key. Referenced by SagaRunStatuses.SagaRunId and SagaSteps.SagaRunId as the internal join key. |
| 2 | SagaName | varchar(255) | NO | - | VERIFIED | Name of the saga workflow type. Currently only "CryptoToFiatSaga" exists (100% of 17,042 rows). Indexed alongside SagaStatusTypeId for filtered queries by name and status. Used by recovery and monitoring procedures as a filter parameter. |
| 3 | SagaKey | uniqueidentifier | YES | - | VERIFIED | Business-level unique identifier for the saga run, generated by the application as an idempotency key. Used as the primary lookup key by most procedures (GetSagaRun, TakeSagaRun, InsertSagaStep, etc.). Enforced unique by NC index. Also referenced by SagaLeaseTime and SagaEvents via implicit relationship. Despite DDL allowing NULL, InsertSagaRunWithLeaseTime always provides a value and checks for uniqueness. |
| 4 | Created | datetime2(7) | NO | - | VERIFIED | UTC timestamp when the saga run was initiated. Set to GETUTCDATE() by InsertSagaRunWithLeaseTime. Used by threshold-based queries (GetSagaRunsByStatusAndThreshold, GetAllSagaRunsWithLimitsByStatusAndThreshold) to filter sagas older than N seconds via DATEDIFF. Data range: 2022-08-30 to present. |
| 5 | SagaStatusTypeId | tinyint | NO | - | VERIFIED | Current lifecycle status of the saga run. Values: 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type). Set on INSERT by InsertSagaRunWithLeaseTime (typically 1). Updated by InsertSagaRunStatus which also logs the transition to SagaRunStatuses. Indexed with SagaName for filtered queries. Implicit FK to Saga.SagaStatusTypes. |
| 6 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Distributed tracing correlation identifier linking this saga run to the broader request across microservices. Returned in all query procedure result sets. Enables cross-service debugging by correlating DB state with application logs. |
| 7 | AdditionalData | nvarchar(max) | YES | NULL | VERIFIED | Serialized JSON containing the full saga request context. For CryptoToFiatSaga, contains SagaRequest with fields including SourceWalletId, Gcid (Global Customer ID), and conversion parameters. Read by the application to drive step execution. Stored as opaque context - the DB never parses this column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaStatusTypeId | Saga.SagaStatusTypes | Implicit FK (Lookup) | Current lifecycle status of the saga run. Values defined in SagaStatusTypes. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Saga.SagaRunStatuses | SagaRunId | Implicit FK | Status transition history for this saga run. Joined on SagaRunStatuses.SagaRunId = SagaRuns.Id. |
| Saga.SagaSteps | SagaRunId | Implicit FK | Individual steps belonging to this saga run. Joined on SagaSteps.SagaRunId = SagaRuns.Id. |
| Saga.SagaLeaseTime | SagaKey | Implicit | Distributed lease for this saga run. Linked via SagaKey (not Id). |
| Saga.SagaEvents | SagaKey | Implicit | Event log entries for this saga run. Linked via SagaKey (not Id). |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (no FROM/JOIN in CREATE TABLE).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRunStatuses | Table | SagaRunId references SagaRuns.Id |
| Saga.SagaSteps | Table | SagaRunId references SagaRuns.Id |
| Saga.SagaLeaseTime | Table | SagaKey references SagaRuns.SagaKey |
| Saga.SagaEvents | Table | SagaKey references SagaRuns.SagaKey |
| Saga.InsertSagaRunWithLeaseTime | Stored Procedure | WRITER - creates saga run with lease and initial status |
| Saga.InsertSagaRunStatus | Stored Procedure | MODIFIER - updates SagaStatusTypeId, logs transition |
| Saga.GetSagaRun | Stored Procedure | READER - retrieves saga with steps by SagaKey |
| Saga.GetSagaRunsByStatus | Stored Procedure | READER - queries by status |
| Saga.GetSagaRunsByStatusAndName | Stored Procedure | READER - queries by status IN (1,2) and SagaName |
| Saga.GetSagaRunsForRecovery | Stored Procedure | READER - queries for status 1 or 2 by SagaName |
| Saga.GetAllAbandonedSagaRuns | Stored Procedure | READER - finds status=1 sagas with stale leases |
| Saga.InsertSagaStep | Stored Procedure | READER - looks up SagaRuns.Id by SagaKey |
| Saga.InsertSagaStepStatus | Stored Procedure | READER - looks up SagaRuns.Id by SagaKey |
| Saga.UpdateSagaStepResponse | Stored Procedure | READER - looks up SagaRuns.Id by SagaKey |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaRuns | CLUSTERED | Id ASC | - | - | Active |
| IX_Saga_SagaRuns__SagaKey | UNIQUE NC | SagaKey ASC | - | - | Active |
| IX_Saga_SagaRuns__SagaName_SagaStatusTypeId | NC | SagaName ASC, SagaStatusTypeId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SagaRuns | PRIMARY KEY | Identity-based surrogate key for internal joins. DATA_COMPRESSION = PAGE. |
| IX_Saga_SagaRuns__SagaKey | UNIQUE | Enforces business-level uniqueness on SagaKey, preventing duplicate saga submissions. |

---

## 8. Sample Queries

### 8.1 Get a saga run with its current status label
```sql
SELECT sr.Id, sr.SagaName, sr.SagaKey, sr.Created, st.Name AS Status, sr.CorrelationId
FROM Saga.SagaRuns sr WITH (NOLOCK)
INNER JOIN Saga.SagaStatusTypes st WITH (NOLOCK) ON st.Id = sr.SagaStatusTypeId
WHERE sr.SagaKey = @SagaKey
```

### 8.2 Find sagas stuck in active states for more than 10 minutes
```sql
SELECT sr.Id, sr.SagaName, sr.SagaKey, sr.Created, st.Name AS Status,
       DATEDIFF(SECOND, sr.Created, GETUTCDATE()) AS AgeSeconds
FROM Saga.SagaRuns sr WITH (NOLOCK)
INNER JOIN Saga.SagaStatusTypes st WITH (NOLOCK) ON st.Id = sr.SagaStatusTypeId
WHERE sr.SagaStatusTypeId IN (1, 2)
AND DATEDIFF(SECOND, sr.Created, GETUTCDATE()) > 600
ORDER BY sr.Created ASC
```

### 8.3 Saga status summary
```sql
SELECT st.Name AS Status, COUNT(*) AS RunCount,
       MIN(sr.Created) AS Earliest, MAX(sr.Created) AS Latest
FROM Saga.SagaRuns sr WITH (NOLOCK)
INNER JOIN Saga.SagaStatusTypes st WITH (NOLOCK) ON st.Id = sr.SagaStatusTypeId
GROUP BY st.Id, st.Name
ORDER BY st.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 14 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaRuns | Type: Table | Source: WalletConversionDB/Saga/Tables/Saga.SagaRuns.sql*
