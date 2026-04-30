# Wallet.ProcessingRecords

> Distributed lock table for background processing - each row represents a record exclusively claimed by a specific process instance, preventing duplicate or concurrent processing across service replicas.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 NC UNIQUE on (ProcessId, RecordId) |

---

## 1. Business Meaning

This table implements a distributed record-level locking mechanism for the wallet platform's background processing services. When a background process (e.g., `HandlePendingRedemptions`, `ExecuterSendTransaction`) picks up a record to work on, it inserts a row here claiming that record. Other instances of the same process - running on different service replicas or pods - will see the lock and skip the record, ensuring exactly-once processing semantics across a horizontally-scaled deployment.

Without this table, two service instances could simultaneously process the same pending redemption or send transaction, resulting in duplicate blockchain submissions, double-debited balances, or conflicting state updates. The `ExpirationTime` column provides a safety valve: if a service instance dies while holding a lock, the lock eventually expires and another instance can reclaim the record. The `InstanceId` identifies which specific service replica holds the lock, enabling targeted monitoring for stuck processes.

With ~92K rows, the table reflects accumulated lock history across all background processes. Rows are managed by `Wallet.LockRecordsForProcess` (insert), `Wallet.ExtendProcessRecordsLockExpiration` (extend), and corresponding unlock procedures (delete). The unique constraint on `(ProcessId, RecordId)` prevents two processes of the same type from simultaneously claiming the same record.

---

## 2. Business Logic

### 2.1 Record Locking Protocol

**What**: Background services use this table to implement a lease-based distributed lock before processing any record.

**Columns/Parameters Involved**: `ProcessId`, `RecordId`, `InstanceId`, `ExpirationTime`

**Rules**:
- Before processing a record, a service instance attempts to insert a row for (ProcessId, RecordId)
- If the insert succeeds (unique constraint not violated), the instance holds the lock
- If the insert fails (duplicate key), the record is already locked by another instance - skip it
- If an existing row has `ExpirationTime` in the past, the lock has expired and can be re-acquired by deleting the old row and inserting a new one
- `InstanceId` identifies the specific service replica (e.g., pod name, hostname + PID) to enable per-instance lock monitoring

### 2.2 Lock Expiration and Extension

**What**: Locks have a time-to-live to recover from service crashes and prevent indefinite record blocking.

**Columns/Parameters Involved**: `ExpirationTime`, `Occurred`

**Rules**:
- `ExpirationTime` is set at lock acquisition time based on the expected processing duration
- `Wallet.ExtendProcessRecordsLockExpiration` updates ExpirationTime for long-running operations that need more time
- If a service crashes without releasing its lock, another instance can take over after ExpirationTime passes
- Monitoring should alert if any lock has been held significantly beyond its ExpirationTime without extension

---

## 3. Data Overview

| Id | ProcessId | RecordId | InstanceId | ExpirationTime | Occurred | Meaning |
|---|---|---|---|---|---|---|
| 92000 | 6 (ExecuterSendTransaction) | TXN-88455210 | pod-wallet-exec-7d9f | 2026-04-14 12:10:00 | 2026-04-14 12:05:00 | Send transaction record locked for execution by pod-wallet-exec-7d9f |
| 91999 | 2 (HandlePendingRedemptions) | RED-44120033 | pod-wallet-rdm-3c8a | 2026-04-14 12:09:45 | 2026-04-14 12:04:45 | Redemption record locked for processing by the redemptions handler pod |
| 91990 | 8 (HandleUserManualOutTransactions) | MANOUT-12090 | pod-wallet-mo-1b2c | 2026-04-14 11:58:00 | 2026-04-14 11:53:00 | Manual outbound transaction locked for processing |
| 91950 | 6 (ExecuterSendTransaction) | TXN-88455100 | pod-wallet-exec-7d9f | 2026-04-14 11:45:00 | 2026-04-14 11:40:00 | Completed send transaction lock - row persisted after processing |
| 91900 | 9 (WalletSync) | SYNC-WALLET-99042 | pod-wallet-sync-4e5d | 2026-04-14 11:20:00 | 2026-04-14 11:15:00 | Wallet sync record lock for synchronisation process |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | ProcessId | int | NO | - | VERIFIED | Identifies which background process owns this lock. FK to Wallet.Processes.Id. Scopes the lock to a specific process type so different process types can independently lock the same RecordId. |
| 3 | RecordId | varchar(128) | NO | - | VERIFIED | String identifier of the record being locked (e.g., transaction ID, redemption ID, correlation ID). Combined with ProcessId forms the unique lock key. Format varies by process type. |
| 4 | InstanceId | varchar(127) | YES | - | CODE-BACKED | Identifier of the specific service instance (pod, host, thread) holding this lock. Used for monitoring and debugging to determine which replica is processing each record. |
| 5 | ExpirationTime | datetime2(7) | YES | - | VERIFIED | UTC timestamp after which this lock is considered stale and can be re-acquired. Provides crash recovery - expired locks can be taken over by healthy service instances. |
| 6 | Occurred | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp of when the lock was acquired. Combined with ExpirationTime shows the lock duration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProcessId | Wallet.Processes | FK | Identifies the background process that owns this lock |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.LockRecordsForProcess | - | Writer | Inserts lock rows when a process claims records |
| Wallet.ExtendProcessRecordsLockExpiration | - | Writer | Extends ExpirationTime for active locks |

---

## 6. Dependencies

### 6.0 Dependency Chain

Wallet.Processes → Wallet.ProcessingRecords

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Processes | Table | FK target - identifies the owning background process |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LockRecordsForProcess | Stored Procedure | Creates lock rows |
| Wallet.ExtendProcessRecordsLockExpiration | Stored Procedure | Extends lock expiry |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProcessingRecords | CLUSTERED PK | Id ASC | - | - | Active |
| UX_ProcessingRecords_ProcessId_RecordId | NC UNIQUE | ProcessId ASC, RecordId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_ProcessingRecords_ProcessId | FK | ProcessId -> Wallet.Processes.Id |
| UX_ProcessingRecords_ProcessId_RecordId | UNIQUE | (ProcessId, RecordId) - prevents duplicate locks for the same process/record combination |

---

## 8. Sample Queries

### 8.1 All currently active (non-expired) locks by process
```sql
SELECT pr.ProcessId, p.Name AS ProcessName,
       pr.RecordId, pr.InstanceId,
       pr.ExpirationTime, pr.Occurred
FROM Wallet.ProcessingRecords pr WITH (NOLOCK)
JOIN Wallet.Processes p WITH (NOLOCK) ON pr.ProcessId = p.Id
WHERE pr.ExpirationTime > GETUTCDATE()
ORDER BY pr.ProcessId, pr.Occurred
```

### 8.2 Detect potentially stuck locks (expired but not released)
```sql
SELECT pr.ProcessId, p.Name AS ProcessName,
       pr.RecordId, pr.InstanceId,
       pr.ExpirationTime,
       DATEDIFF(MINUTE, pr.ExpirationTime, GETUTCDATE()) AS MinutesExpiredAgo
FROM Wallet.ProcessingRecords pr WITH (NOLOCK)
JOIN Wallet.Processes p WITH (NOLOCK) ON pr.ProcessId = p.Id
WHERE pr.ExpirationTime < GETUTCDATE()
ORDER BY pr.ExpirationTime ASC
```

### 8.3 Count active locks per service instance
```sql
SELECT pr.InstanceId, p.Name AS ProcessName,
       COUNT(*) AS LockedRecords
FROM Wallet.ProcessingRecords pr WITH (NOLOCK)
JOIN Wallet.Processes p WITH (NOLOCK) ON pr.ProcessId = p.Id
WHERE pr.ExpirationTime > GETUTCDATE()
GROUP BY pr.InstanceId, p.Name
ORDER BY LockedRecords DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ProcessingRecords | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ProcessingRecords.sql*
