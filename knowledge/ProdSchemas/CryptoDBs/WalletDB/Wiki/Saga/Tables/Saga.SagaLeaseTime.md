# Saga.SagaLeaseTime

> Distributed lease management table that implements optimistic concurrency for saga processing, ensuring only one service instance processes a given saga at any time.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | SagaKey (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 clustered PK (on SagaKey, NOT on Id) |

---

## 1. Business Meaning

This table implements a distributed lease/lock mechanism for saga processing across multiple service instances. In a multi-pod deployment, multiple instances of the saga coordinator service may attempt to process the same saga. The lease time pattern ensures exactly-once processing: an instance must "take" a saga by claiming its lease before processing it, and the lease automatically expires if the instance crashes, allowing another instance to pick up the work.

Without this table, multiple service instances could simultaneously process the same saga, leading to duplicate step executions, inconsistent state, and data corruption. The lease mechanism is critical for the high-availability (HA) recovery pattern described in the Saga Split Architecture - each saga type's HA worker periodically scans for expired leases to restart stuck sagas on a healthy pod.

Lease records are created atomically with the saga run by `Saga.InsertSagaRunWithLeaseTime`. Active saga processors renew their lease via `Saga.UpdateSagaLeaseTime` (heartbeat). When a saga's lease expires (pod crash, timeout), `Saga.TakeSagaRun` allows another instance to claim it atomically. Recovery procedures like `Saga.GetAllAbandonedSagaRuns` check `LeaseTime < GETUTCDATE()` to find expired sagas.

---

## 2. Business Logic

### 2.1 Lease-Based Distributed Locking

**What**: Optimistic concurrency control where a service instance must hold a valid lease to process a saga.

**Columns/Parameters Involved**: `SagaKey`, `InstanceId`, `LeaseTime`, `LastUpdaed`

**Rules**:
- A lease is valid when `LeaseTime > GETUTCDATE()`
- Default lease duration is 5 minutes (300,000ms), set via `@LeaseTimeInMs` parameter
- The processing instance must refresh the lease before expiry by calling `Saga.UpdateSagaLeaseTime`
- If LeaseTime expires, any instance can claim the saga via `Saga.TakeSagaRun` (atomic UPDATE with WHERE LeaseTime < GETUTCDATE())
- InstanceId tracks which pod holds the lease - changes when a different instance takes over
- `Saga.ReinitiateSaga` resets sagas with a 300,000ms (5 min) default lease

**Diagram**:
```
Instance A                         Saga.SagaLeaseTime                    Instance B
    |                                     |                                   |
    +-- InsertSagaRunWithLeaseTime ------>|  LeaseTime = now + 5min           |
    |   (InstanceId = A)                  |                                   |
    +-- UpdateSagaLeaseTime ------------>|  LeaseTime = now + 5min (renew)   |
    |                                     |                                   |
    X (pod crashes)                       |  LeaseTime expires                |
    |                                     |                                   |
    |                                     |<---- TakeSagaRun ----------------+
    |                                     |  InstanceId = B, LeaseTime = now+5|
    |                                     |  (atomic, only if expired)        |
```

### 2.2 One-to-One Relationship with SagaRuns

**What**: Every saga run has exactly one lease record, created atomically during saga initiation.

**Columns/Parameters Involved**: `SagaKey`, `Id`

**Rules**:
- SagaKey is the primary key (CLUSTERED), ensuring 1:1 with SagaRuns
- Id (IDENTITY) exists as an auto-increment surrogate but is not the PK
- Created atomically with the SagaRuns record in `InsertSagaRunWithLeaseTime`
- Row count matches SagaRuns (both ~102K) confirming the 1:1 relationship

---

## 3. Data Overview

| SagaKey | InstanceId | LastUpdaed | LeaseTime | Meaning |
|---------|-----------|------------|-----------|---------|
| EBEAAEE2-... | B7847679-... | 2026-04-15 10:07:18 | 2026-04-15 10:12:18 | Active lease for the most recent saga. Instance B7847679 holds the lease with 5 minutes remaining. LeaseTime = LastUpdaed + 5 min. |
| B7CE915A-... | 5F723669-... | 2026-04-15 09:59:43 | 2026-04-15 10:04:43 | Expired lease from a recently completed saga. Different InstanceId shows this ran on a different pod. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate key. NOT the primary key - SagaKey is the clustered PK. Exists for ordering/identification but is not referenced by other tables. |
| 2 | SagaKey | uniqueidentifier | NO | - | VERIFIED | CLUSTERED primary key. Links 1:1 to `Saga.SagaRuns.SagaKey`. Used by `TakeSagaRun` and `UpdateSagaLeaseTime` to locate the lease record for a specific saga. |
| 3 | InstanceId | uniqueidentifier | YES | - | VERIFIED | GUID identifying the service pod/instance that currently holds (or last held) the lease. Changes when a different instance takes over a saga via `TakeSagaRun`. Used by HA recovery to identify which pod was processing when a saga got stuck. |
| 4 | LastUpdaed | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp of the most recent lease creation or renewal. Note: column name contains a typo ("Updaed" instead of "Updated") - this is the production spelling and must not be changed. Set by `InsertSagaRunWithLeaseTime` and `UpdateSagaLeaseTime` to GETUTCDATE(). |
| 5 | LeaseTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when the lease expires. Calculated as `DATEADD(MILLISECOND, @LeaseTimeInMs, GETUTCDATE())` where the default `@LeaseTimeInMs` is 300,000 (5 minutes). A lease is valid when `LeaseTime > GETUTCDATE()`. Used by `TakeSagaRun` (WHERE LeaseTime < GETUTCDATE()) to claim expired sagas. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaKey | Saga.SagaRuns | Implicit FK (1:1 via SagaKey) | Links this lease record to the corresponding saga run |

### 5.2 Referenced By (other objects point to this)

No inbound references from other tables. Accessed exclusively via stored procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.SagaLeaseTime (table)
└── Saga.SagaRuns (table) [implicit FK - SagaKey]
    └── Saga.SagaStatusTypes (table) [implicit FK - SagaStatusTypeId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | Implicit FK - SagaKey references the parent saga run (1:1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.InsertSagaRunWithLeaseTime | Stored Procedure | WRITER - creates lease record atomically with saga run |
| Saga.UpdateSagaLeaseTime | Stored Procedure | MODIFIER - renews lease by extending LeaseTime (heartbeat) |
| Saga.TakeSagaRun | Stored Procedure | MODIFIER - claims expired lease for another instance |
| Saga.GetAllAbandonedSagaRuns | Stored Procedure | READER - checks LeaseTime to find expired sagas |
| Saga.GetAllSagaRunsWithLimitsByStatus | Stored Procedure | READER - reads lease info alongside saga data |
| Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold | Stored Procedure | READER - reads lease info alongside saga data |
| Saga.GetSagaRunsByStatusAndThreshold | Stored Procedure | READER - reads lease info alongside saga data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaLeaseTime | CLUSTERED PK | SagaKey ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key. Note: the PK is on SagaKey (not Id), which is unusual - this optimizes direct lease lookups by SagaKey.

---

## 8. Sample Queries

### 8.1 Find sagas with expired leases (candidates for recovery)
```sql
SELECT slt.SagaKey, slt.InstanceId, slt.LeaseTime,
       DATEDIFF(MINUTE, slt.LeaseTime, GETUTCDATE()) AS MinutesSinceExpiry,
       sr.SagaName, sst.Name AS SagaStatus
FROM Saga.SagaLeaseTime slt WITH (NOLOCK)
JOIN Saga.SagaRuns sr WITH (NOLOCK) ON slt.SagaKey = sr.SagaKey
JOIN Saga.SagaStatusTypes sst WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
WHERE slt.LeaseTime < GETUTCDATE()
  AND sr.SagaStatusTypeId = 1
ORDER BY slt.LeaseTime ASC
```

### 8.2 Active leases by instance
```sql
SELECT slt.InstanceId, COUNT(*) AS ActiveLeases,
       MIN(slt.LeaseTime) AS EarliestExpiry, MAX(slt.LeaseTime) AS LatestExpiry
FROM Saga.SagaLeaseTime slt WITH (NOLOCK)
WHERE slt.LeaseTime > GETUTCDATE()
GROUP BY slt.InstanceId
ORDER BY ActiveLeases DESC
```

### 8.3 Lease details for a specific saga
```sql
SELECT slt.SagaKey, slt.InstanceId, slt.LastUpdaed, slt.LeaseTime,
       CASE WHEN slt.LeaseTime > GETUTCDATE() THEN 'Active' ELSE 'Expired' END AS LeaseStatus,
       sr.SagaName, sst.Name AS SagaStatus
FROM Saga.SagaLeaseTime slt WITH (NOLOCK)
JOIN Saga.SagaRuns sr WITH (NOLOCK) ON slt.SagaKey = sr.SagaKey
JOIN Saga.SagaStatusTypes sst WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
WHERE slt.SagaKey = @SagaKey
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | HA recovery pattern: each saga type has its own HA worker that scans for expired leases to restart stuck sagas on healthy pods after pod restarts |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaLeaseTime | Type: Table | Source: WalletDB/Saga/Tables/Saga.SagaLeaseTime.sql*
