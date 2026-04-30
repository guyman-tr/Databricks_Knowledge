# Saga.InsertSagaRunWithLeaseTime

> Atomically creates a new saga run, its initial status record, and a lease time entry in a single transaction - the primary saga creation procedure.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: BIT LeaseStatus (1=created, 0=failed) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the most critical procedure in the saga schema - it creates a new saga run. In a single explicit transaction, it atomically inserts records into three tables: `Saga.SagaRuns` (the run itself), `Saga.SagaRunStatuses` (the initial Start status history), and `Saga.SagaLeaseTime` (the distributed lease for processing coordination).

The procedure includes a duplicate check (WHERE NOT EXISTS with SagaKey) to prevent creating the same saga twice - essential in a distributed system where multiple service instances might try to initiate the same saga. If the SagaKey already exists, it RAISERROR and rolls back. The lease time is calculated as GETUTCDATE() + @LeaseTimeInMs milliseconds (default 300,000ms = 5 minutes).

Called by saga handler services when initiating a new saga. Also called by `Saga.ReinitiateSaga` (via dynamic SQL) when retrying a failed saga.

---

## 2. Business Logic

### 2.1 Atomic Three-Table Insert

**What**: Creates saga run + initial status + lease in one transaction.

**Columns/Parameters Involved**: `@SagaName`, `@SagaKey`, `@InstanceId`, `@SagaStatusTypeId`, `@LeaseTimeInMs`, `@CorrelationId`, `@AdditionalData`

**Rules**:
- BEGIN TRANSACTION wraps all three INSERTs
- INSERT INTO SagaRuns with WHERE NOT EXISTS (SagaKey) - prevents duplicates
- If SagaKey already exists: RAISERROR 'SagaKey already exists' and rolls back
- INSERT INTO SagaRunStatuses with the initial status (typically 1=Start)
- INSERT INTO SagaLeaseTime with LeaseTime = DATEADD(MILLISECOND, @LeaseTimeInMs, GETUTCDATE())
- COMMIT on success; ROLLBACK on error (TRY/CATCH)
- Returns BIT LeaseStatus: 1=success, 0=failure (in CATCH block)

### 2.2 Idempotency via Duplicate Check

**What**: Prevents duplicate saga creation in a distributed system.

**Columns/Parameters Involved**: `@SagaKey`

**Rules**:
- Uses WHERE NOT EXISTS (SELECT 1 FROM SagaRuns WHERE SagaKey = @SagaKey)
- If the INSERT affects 0 rows, SCOPE_IDENTITY() returns NULL
- NULL check on @SagaRunsId triggers RAISERROR with the SagaKey value
- This pattern handles the race condition where two instances try to create the same saga

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaName | varchar(255) | NO | - | VERIFIED | Saga type name (e.g., 'ExternalReceiveTransactionSaga'). Determines which step pipeline will execute. |
| 2 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Technical saga instance GUID. Must be unique - duplicate causes RAISERROR and rollback. |
| 3 | @InstanceId | uniqueidentifier | NO | - | VERIFIED | Service pod/instance GUID that will process this saga. Written to SagaLeaseTime.InstanceId. |
| 4 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Initial status (typically 1=Start). Written to SagaRuns and SagaRunStatuses. |
| 5 | @LeaseTimeInMs | bigint | NO | - | VERIFIED | Lease duration in milliseconds. Default 300,000 (5 minutes). LeaseTime = GETUTCDATE() + this value. |
| 6 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation GUID linking to the originating request. |
| 7 | @AdditionalData | nvarchar(max) | YES | NULL | CODE-BACKED | Optional JSON payload with saga request context. |
| 8 | LeaseStatus (output) | bit | - | - | CODE-BACKED | 1 = saga created successfully, 0 = creation failed (duplicate or error). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | INSERT INTO | Creates the saga run record |
| - | Saga.SagaRunStatuses | INSERT INTO | Creates the initial status history record |
| - | Saga.SagaLeaseTime | INSERT INTO | Creates the lease for distributed processing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Saga.ReinitiateSaga | Dynamic SQL EXEC | EXEC | Calls this SP to recreate a failed saga with new SagaKey |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.InsertSagaRunWithLeaseTime (procedure)
├── Saga.SagaRuns (table) [INSERT INTO]
├── Saga.SagaRunStatuses (table) [INSERT INTO]
└── Saga.SagaLeaseTime (table) [INSERT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | INSERT INTO (with duplicate check) |
| Saga.SagaRunStatuses | Table | INSERT INTO (initial status) |
| Saga.SagaLeaseTime | Table | INSERT INTO (lease creation) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.ReinitiateSaga | Stored Procedure | EXEC via dynamic SQL - calls this SP to recreate failed sagas |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Explicit BEGIN TRANSACTION / COMMIT / ROLLBACK. TRY/CATCH error handling. RAISERROR on duplicate SagaKey.

---

## 8. Sample Queries

### 8.1 Create a new saga run
```sql
EXEC Saga.InsertSagaRunWithLeaseTime
    @SagaName = 'ExternalReceiveTransactionSaga',
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @InstanceId = 'B7847679-A8DA-41F1-B42F-ABD7A5FEB5FA',
    @SagaStatusTypeId = 1,
    @LeaseTimeInMs = 300000,
    @CorrelationId = 'F08F5895-8683-4427-B047-EC441C9AE5E8',
    @AdditionalData = '{"SagaRequest":"{\"CorrelationId\":\"f08f...\"}"}'
```

### 8.2 Verify the three records were created
```sql
SELECT 'SagaRuns' AS Source, Id, SagaName, SagaKey FROM Saga.SagaRuns WITH (NOLOCK) WHERE SagaKey = @SagaKey
UNION ALL
SELECT 'RunStatuses', Id, '', '' FROM Saga.SagaRunStatuses WITH (NOLOCK) WHERE SagaRunId = (SELECT Id FROM Saga.SagaRuns WITH (NOLOCK) WHERE SagaKey = @SagaKey)
UNION ALL
SELECT 'LeaseTime', Id, '', SagaKey FROM Saga.SagaLeaseTime WITH (NOLOCK) WHERE SagaKey = @SagaKey
```

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | Saga creation is done by handler classes (ReceiveTransactionSagaHandler, AutoC2PSagaHandler) which call this procedure to initiate the saga with a specific name and lease time |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.InsertSagaRunWithLeaseTime | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.InsertSagaRunWithLeaseTime.sql*
