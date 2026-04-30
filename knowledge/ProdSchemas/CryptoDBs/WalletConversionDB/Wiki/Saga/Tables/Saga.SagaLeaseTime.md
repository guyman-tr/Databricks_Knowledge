# Saga.SagaLeaseTime

> Distributed lease management table implementing optimistic concurrency control for saga run processing, ensuring each saga is owned by exactly one worker instance at a time.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | SagaKey (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + 1 UNIQUE NC on SagaKey - redundant with PK) |

---

## 1. Business Meaning

SagaLeaseTime implements a distributed lease mechanism that prevents multiple worker instances from processing the same saga run simultaneously. Each row represents a lease for one saga run, recording which instance currently owns it and when the lease expires. This is essential in a multi-instance deployment where multiple conversion worker services compete to process saga runs.

Without this table, concurrent worker instances could pick up the same saga run and execute its steps in parallel, causing duplicate operations, data corruption, or conflicting state transitions in the distributed transaction. The lease pattern ensures exclusive ownership with automatic expiry for fault tolerance.

Lease rows are created by `Saga.InsertSagaRunWithLeaseTime` atomically with the saga run itself (in the same transaction). Active workers periodically renew their leases via `Saga.UpdateSagaLeaseTime`. When a worker crashes or stalls, its leases naturally expire, allowing `Saga.TakeSagaRun` to reassign the saga to a healthy instance. Query procedures use the lease table to distinguish between actively-processed sagas (recent LastUpdaed) and abandoned ones (stale LastUpdaed).

---

## 2. Business Logic

### 2.1 Distributed Lease Acquisition and Renewal

**What**: The lease mechanism provides exclusive saga ownership through optimistic concurrency - only one instance can hold the lease at a time.

**Columns/Parameters Involved**: `SagaKey`, `InstanceId`, `LeaseTime`, `LastUpdaed`

**Rules**:
- **Initial lease**: Created by InsertSagaRunWithLeaseTime with LeaseTime = GETUTCDATE() + @LeaseTimeInMs milliseconds. Inserted atomically with the SagaRuns row in a transaction.
- **Lease renewal**: UpdateSagaLeaseTime extends the lease WHERE SagaKey matches AND InstanceId matches. The InstanceId check ensures only the current owner can renew. Returns LeaseStatus = 1 (success) or 0 (lost ownership).
- **Lease takeover**: TakeSagaRun acquires an expired lease WHERE LeaseTime < GETUTCDATE(). It sets a new InstanceId and LeaseTime. Returns LeaseStatus = 1 (acquired) or 0 (someone else took it first).
- **Lease duration**: Live data shows ~5 minute leases (LeaseTime = LastUpdaed + 5 minutes), renewed continuously by the owning instance.

**Diagram**:
```
Instance A creates saga:
  [InsertSagaRunWithLeaseTime] -> SagaLeaseTime row (InstanceId=A, LeaseTime=now+5m)

Instance A renews:
  [UpdateSagaLeaseTime WHERE InstanceId=A] -> LeaseTime extended by 5m

Instance A crashes (lease expires):
  LeaseTime < GETUTCDATE() -> lease is stale

Instance B takes over:
  [TakeSagaRun WHERE LeaseTime < GETUTCDATE()] -> InstanceId=B, new LeaseTime
```

### 2.2 Abandonment and Liveness Detection

**What**: The lease table enables distinguishing between actively-processed and abandoned sagas through time-based queries.

**Columns/Parameters Involved**: `SagaKey`, `LastUpdaed`

**Rules**:
- **Active (within 5 minutes)**: GetAllSagaRunsWithLimitsByStatus, GetAllSagaRunsWithLimitsByStatusAndThreshold, and GetSagaRunsByStatusAndThreshold filter for `LastUpdaed > DATEADD(MINUTE, -5, GETUTCDATE())` - these return only sagas currently being processed
- **Abandoned (older than 1 hour)**: GetAllAbandonedSagaRuns filters for `LastUpdaed > DATEADD(hh, -1, GETUTCDATE())` with NOT IN - sagas whose lease was NOT updated in the last hour are considered abandoned and eligible for recovery
- The gap between 5-minute active window and 1-hour abandonment window provides a buffer for transient delays

---

## 3. Data Overview

| SagaKey | InstanceId | LastUpdaed | LeaseTime | Meaning |
|---------|-----------|------------|-----------|---------|
| 9E441DD9-... | EC3FDAF2-... | 2026-04-15 08:40:40 | 2026-04-15 08:45:40 | Active saga with 5-minute lease, currently owned by instance EC3FDAF2. Lease expires in ~5 minutes from last renewal. |
| AEE0CBBB-... | C5600209-... | 2026-04-15 08:40:39 | 2026-04-15 08:45:39 | Another active saga on a different worker instance. The 1-second difference in LastUpdaed shows leases are renewed independently per saga. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate key. Not used as the primary lookup key - SagaKey serves that role (PK). |
| 2 | SagaKey | uniqueidentifier | NO | - | VERIFIED | Business-level identifier for the saga run this lease controls. PK (clustered). Links to `Saga.SagaRuns.SagaKey` (implicit - no FK constraint). One lease per saga run. |
| 3 | InstanceId | uniqueidentifier | YES | - | VERIFIED | Identifier of the worker service instance that currently holds the lease. Set on creation by InsertSagaRunWithLeaseTime and on takeover by TakeSagaRun. UpdateSagaLeaseTime uses it in WHERE clause to verify ownership before renewal. NULL if not yet assigned. |
| 4 | LastUpdaed | datetime2(7) | NO | - | VERIFIED | UTC timestamp of the last lease operation (creation, renewal, or takeover). Note: column name contains a typo ("Updaed" instead of "Updated"). Used by query procedures to determine liveness: within 5 minutes = active, beyond 1 hour = abandoned. Set to GETUTCDATE() on every write. |
| 5 | LeaseTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when the lease expires. Calculated as GETUTCDATE() + @LeaseTimeInMs milliseconds (typically 5 minutes based on live data). TakeSagaRun checks `LeaseTime < GETUTCDATE()` to find expired leases available for acquisition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaKey | Saga.SagaRuns | Implicit (no FK constraint) | Links lease to the saga run it controls, via SagaRuns.SagaKey |

### 5.2 Referenced By (other objects point to this)

No other tables reference SagaLeaseTime directly. Multiple procedures query it via subqueries on SagaKey.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.InsertSagaRunWithLeaseTime | Stored Procedure | WRITER - creates lease row atomically with saga run |
| Saga.TakeSagaRun | Stored Procedure | MODIFIER - acquires expired leases for recovery |
| Saga.UpdateSagaLeaseTime | Stored Procedure | MODIFIER - renews lease for current owner instance |
| Saga.GetAllAbandonedSagaRuns | Stored Procedure | READER - subquery excludes sagas with recent LastUpdaed (< 1 hour) |
| Saga.GetAllSagaRunsWithLimitsByStatus | Stored Procedure | READER - subquery includes only sagas with recent LastUpdaed (< 5 min) |
| Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold | Stored Procedure | READER - subquery includes only sagas with recent LastUpdaed (< 5 min) |
| Saga.GetSagaRunsByStatusAndThreshold | Stored Procedure | READER - subquery includes only sagas with recent LastUpdaed (< 5 min) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaLeaseTime | CLUSTERED | SagaKey ASC | - | - | Active |
| IX_Saga_SagaLeaseTime__SagaKey | UNIQUE NC | SagaKey ASC | - | - | Active (redundant with PK) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SagaLeaseTime | PRIMARY KEY | Ensures one lease row per SagaKey. Clustered for fast lookups by saga. DATA_COMPRESSION = PAGE. |

---

## 8. Sample Queries

### 8.1 Find all expired (available) leases
```sql
SELECT SagaKey, InstanceId, LastUpdaed, LeaseTime,
       DATEDIFF(SECOND, LeaseTime, GETUTCDATE()) AS SecondsExpired
FROM Saga.SagaLeaseTime WITH (NOLOCK)
WHERE LeaseTime < GETUTCDATE()
ORDER BY LeaseTime ASC
```

### 8.2 Check lease health for a specific saga
```sql
SELECT sl.SagaKey, sr.SagaName, sl.InstanceId, sl.LastUpdaed, sl.LeaseTime,
       CASE WHEN sl.LeaseTime > GETUTCDATE() THEN 'Active' ELSE 'Expired' END AS LeaseStatus
FROM Saga.SagaLeaseTime sl WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.SagaKey = sl.SagaKey
WHERE sl.SagaKey = @SagaKey
```

### 8.3 Count active vs expired leases by instance
```sql
SELECT InstanceId,
       SUM(CASE WHEN LeaseTime > GETUTCDATE() THEN 1 ELSE 0 END) AS ActiveLeases,
       SUM(CASE WHEN LeaseTime <= GETUTCDATE() THEN 1 ELSE 0 END) AS ExpiredLeases
FROM Saga.SagaLeaseTime WITH (NOLOCK)
GROUP BY InstanceId
ORDER BY ActiveLeases DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaLeaseTime | Type: Table | Source: WalletConversionDB/Saga/Tables/Saga.SagaLeaseTime.sql*
