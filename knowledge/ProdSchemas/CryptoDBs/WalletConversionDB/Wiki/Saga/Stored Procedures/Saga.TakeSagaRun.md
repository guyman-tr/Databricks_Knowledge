# Saga.TakeSagaRun

> Acquires an expired saga lease for a new worker instance, implementing optimistic concurrency to safely reassign abandoned saga runs for recovery processing.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: LeaseStatus BIT (1=acquired, 0=unavailable) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

TakeSagaRun implements the lease acquisition step of the distributed saga ownership protocol. When a worker instance detects an expired saga lease (via query procedures that check LeaseTime), it calls TakeSagaRun to claim ownership. The procedure atomically updates the lease row only if the lease is still expired, preventing race conditions between competing workers.

Without this procedure, there would be no safe way to recover abandoned sagas. If a worker instance crashes, its sagas' leases expire naturally, and another healthy worker can call TakeSagaRun to take over and continue or roll back the saga.

The procedure returns a BIT result: 1 means the lease was successfully acquired (the caller now owns the saga), 0 means someone else already took it (the caller should move on to the next candidate).

---

## 2. Business Logic

### 2.1 Optimistic Lease Acquisition

**What**: Updates the lease only if it's currently expired, using a WHERE clause as the concurrency guard.

**Columns/Parameters Involved**: `@SagaKey`, `@InstanceId`, `@LeaseTimeInMs`

**Rules**:
- UPDATE SagaLeaseTime SET LeaseTime = GETUTCDATE() + @LeaseTimeInMs, InstanceId = @InstanceId, LastUpdaed = GETUTCDATE()
- WHERE SagaKey = @SagaKey AND LeaseTime < GETUTCDATE() (lease must be expired)
- Returns @@ROWCOUNT-based BIT: 1 if row was updated (lease acquired), 0 if no update (lease not expired or already taken)
- No explicit locking or serialization needed - the UPDATE's WHERE clause provides atomic compare-and-swap semantics

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Business-level identifier of the saga run whose lease to acquire. Must match an existing SagaLeaseTime row. |
| 2 | @InstanceId | uniqueidentifier | NO | - | VERIFIED | Identifier of the worker instance attempting to acquire the lease. Will become the new owner if acquisition succeeds. |
| 3 | @LeaseTimeInMs | bigint | NO | - | VERIFIED | Lease duration in milliseconds from now. Typically ~300,000 (5 minutes) based on live data patterns. |

**Return:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | LeaseStatus | BIT | VERIFIED | 1 = lease acquired (caller now owns the saga), 0 = lease not available (still active or another worker took it first) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaLeaseTime | UPDATE target | Updates lease ownership and expiry for the specified saga |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.TakeSagaRun (procedure)
└── Saga.SagaLeaseTime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaLeaseTime | Table | UPDATE target - acquires expired leases |

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

### 8.1 Attempt to take an abandoned saga
```sql
EXEC Saga.TakeSagaRun
    @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E',
    @InstanceId = 'NEWWORKER-1234-5678-ABCD-INSTANCEID01',
    @LeaseTimeInMs = 300000 -- 5 minutes
```

### 8.2 Find expired leases eligible for takeover
```sql
SELECT sl.SagaKey, sr.SagaName, sl.LeaseTime, sl.InstanceId
FROM Saga.SagaLeaseTime sl WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.SagaKey = sl.SagaKey
WHERE sl.LeaseTime < GETUTCDATE()
AND sr.SagaStatusTypeId IN (1, 2)
```

### 8.3 Check if takeover succeeded
```sql
SELECT SagaKey, InstanceId, LeaseTime, LastUpdaed
FROM Saga.SagaLeaseTime WITH (NOLOCK)
WHERE SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.TakeSagaRun | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.TakeSagaRun.sql*
