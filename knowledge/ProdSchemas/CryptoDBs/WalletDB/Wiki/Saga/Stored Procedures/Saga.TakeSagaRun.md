# Saga.TakeSagaRun

> Attempts to atomically claim an expired saga lease for a new processing instance, implementing distributed locking for saga recovery.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: BIT LeaseStatus (1=claimed, 0=not available) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements the "take" side of the distributed saga locking mechanism. When an HA recovery worker finds a saga that needs to be resumed (via `GetSagaRunsForRecovery` or `GetAllAbandonedSagaRuns`), it calls this procedure to attempt to claim the saga's lease. The claim only succeeds if the lease has expired (`LeaseTime < GETUTCDATE()`), preventing two instances from processing the same saga simultaneously.

The atomic UPDATE ensures that in a race condition where multiple instances try to take the same saga, only one will succeed - the WHERE clause checks both SagaKey match AND lease expiry in a single statement.

---

## 2. Business Logic

### 2.1 Optimistic Lease Acquisition

**What**: Claims an expired lease for a new processing instance.

**Columns/Parameters Involved**: `@SagaKey`, `@InstanceId`, `@LeaseTimeInMs`

**Rules**:
- UPDATE SagaLeaseTime SET LeaseTime = now + @LeaseTimeInMs, InstanceId = @InstanceId, LastUpdaed = now
- WHERE SagaKey = @SagaKey AND LeaseTime < GETUTCDATE() (only if expired)
- Returns 1 if the lease was claimed (@@ROWCOUNT > 0), 0 if the lease was not expired or SagaKey not found
- Atomic - no transaction needed, single UPDATE statement handles the race condition

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Identifies the saga whose lease to claim. |
| 2 | @InstanceId | uniqueidentifier | NO | - | VERIFIED | Service pod/instance GUID claiming the lease. Written to SagaLeaseTime.InstanceId. |
| 3 | @LeaseTimeInMs | bigint | NO | - | VERIFIED | New lease duration in milliseconds (typically 300,000 = 5 min). |
| 4 | LeaseStatus (output) | bit | - | - | CODE-BACKED | 1 = lease claimed, 0 = lease not available (still active or SagaKey not found). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaLeaseTime | UPDATE (conditional) | Claims the lease if expired |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.TakeSagaRun (procedure)
└── Saga.SagaLeaseTime (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaLeaseTime | Table | UPDATE - claims expired lease |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Single atomic UPDATE with conditional WHERE.

---

## 8. Sample Queries

### 8.1 Attempt to claim a saga lease
```sql
EXEC Saga.TakeSagaRun
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @InstanceId = 'B7847679-A8DA-41F1-B42F-ABD7A5FEB5FA',
    @LeaseTimeInMs = 300000
```

### 8.2 N/A
N/A.

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | SQL-based HA recovery for pod restarts - HA workers claim sagas via lease acquisition |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.TakeSagaRun | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.TakeSagaRun.sql*
