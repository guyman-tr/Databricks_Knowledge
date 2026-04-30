# Apex.Lock

> Distributed lock table implementing optimistic locking with expiration for background job coordination, preventing multiple instances from processing the same work simultaneously.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | Key (VARCHAR(50), CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.Lock implements a database-backed distributed locking mechanism for coordinating background job execution. Each row represents a named lock that can be acquired by one process at a time. The lock includes an expiration time to prevent deadlocks if the owning process crashes without releasing the lock. This pattern enables multiple application instances to safely coordinate exclusive access to shared resources or background jobs.

This table is essential for preventing duplicate processing in the Apex account management system. Without it, multiple application instances could simultaneously process the same state machine transitions, send duplicate API calls to Apex Clearing, or corrupt account data through concurrent writes. The lock mechanism ensures exactly one instance handles each named job at any given time.

The lock lifecycle is managed through three procedures: JobLockAcquire (MERGE with XLOCK hint - acquires a new lock or takes over an expired one), JobLockRenew (extends the expiration while the job is still running), and JobLockRelease (deletes the lock and returns a status code indicating success, expiration, or ownership conflict). The RowVersion (timestamp) column provides optimistic concurrency control at the database level.

---

## 2. Business Logic

### 2.1 Lock Acquisition with Expiration-Based Takeover

**What**: Locks are acquired via MERGE with XLOCK - a new lock is inserted if none exists, or an expired lock is taken over. Active (non-expired) locks cannot be stolen.

**Columns/Parameters Involved**: `Key`, `LockID`, `ExpiresAt`

**Rules**:
- MERGE with XLOCK ensures serialized access to the lock row
- WHEN NOT MATCHED: inserts a new lock (no previous holder)
- WHEN MATCHED AND ExpiresAt <= CurrentTimeUtc: takes over the expired lock (previous holder crashed or timed out)
- WHEN MATCHED AND ExpiresAt > CurrentTimeUtc: no action (lock is active - acquisition fails, @@ROWCOUNT = 0)
- Returns @@ROWCOUNT: 1 = acquired, 0 = lock held by another process

**Diagram**:
```
JobLockAcquire(@Key, @LockID, @ExpiresAt, @CurrentTimeUtc)
    |
    v
Lock row exists for @Key?
    |-- No  --> INSERT (lock acquired)
    |-- Yes --> ExpiresAt <= @CurrentTimeUtc?
                    |-- Yes --> UPDATE LockID+ExpiresAt (expired lock taken over)
                    |-- No  --> No action (lock held - @@ROWCOUNT=0)
```

### 2.2 Lock Release with Status Reporting

**What**: Lock release deletes the row and returns a status code indicating whether the release was clean, the lock had expired, or another process already took it.

**Columns/Parameters Involved**: `Key`, `LockID`, `ExpiresAt`

**Rules**:
- DELETE WHERE Key=@Key AND LockID=@LockID ensures only the lock owner can release it
- Return code 0: lock successfully released (normal path)
- Return code -1: lock not found (another process already took over the expired lock)
- Return code -2: lock was expired at release time (job ran too long and another process may have taken over)
- These return codes allow the application to detect lost locks and handle them gracefully

### 2.3 Lock Renewal (Heartbeat)

**What**: Long-running jobs periodically renew their lock to prevent expiration while they are still working.

**Columns/Parameters Involved**: `Key`, `LockID`, `ExpiresAt`

**Rules**:
- UPDATE ExpiresAt WHERE Key=@Key AND LockID=@LockID AND ExpiresAt > @CurrentTimeUtc
- The ExpiresAt > @CurrentTimeUtc condition prevents renewing an already-expired lock
- Returns @@ROWCOUNT: 1 = renewed, 0 = lock expired or taken over (job should stop)

---

## 3. Data Overview

Table is currently empty (0 rows). Locks are transient - they exist only while a background job is actively running and are deleted upon completion. An empty table indicates no background jobs are currently holding locks.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Key | varchar(50) | NO | - | CODE-BACKED | The named lock identifier. Each key represents a specific background job or resource that requires exclusive access. Serves as the primary key - only one lock per key can exist at a time. Examples would include job names like state machine processor, sync worker, etc. |
| 2 | RowVersion | timestamp | NO | - | CODE-BACKED | SQL Server automatic row version (binary counter). Incremented automatically on every UPDATE. Provides optimistic concurrency control - can be used by the application to detect if the lock row was modified between reads. Not directly used in the stored procedures but available for application-level concurrency checks. |
| 3 | LockID | uniqueidentifier | NO | - | VERIFIED | A GUID identifying the specific process instance that holds the lock. Generated by the acquiring application (typically a new GUID per lock attempt). Used in JobLockRelease and JobLockRenew to verify ownership - only the process that acquired the lock (matching LockID) can release or renew it. Prevents one process from accidentally releasing another's lock. |
| 4 | ExpiresAt | datetime | NO | - | VERIFIED | The UTC timestamp when this lock expires. Set by the acquiring process based on expected job duration. If the lock holder crashes without releasing, the lock automatically becomes available for takeover after this time. JobLockRenew extends this timestamp for long-running jobs. JobLockAcquire checks this to determine if an existing lock can be taken over. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.JobLockAcquire | @Key, @LockID | Writer | Acquires a lock via MERGE with XLOCK hint |
| Apex.JobLockRelease | @Key, @LockID | Deleter | Releases a lock by deleting the row, returns status code |
| Apex.JobLockRenew | @Key, @LockID | Modifier | Extends lock expiration for long-running jobs |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.JobLockAcquire | Stored Procedure | Writer - acquires locks via MERGE+XLOCK |
| Apex.JobLockRelease | Stored Procedure | Deleter - releases locks with status reporting |
| Apex.JobLockRenew | Stored Procedure | Modifier - extends lock expiration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Lock | CLUSTERED PK | Key ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Lock | PRIMARY KEY | Clustered on Key - each named lock is unique |

---

## 8. Sample Queries

### 8.1 Check all currently held locks and their expiration status

```sql
SELECT [Key], LockID, ExpiresAt,
       CASE WHEN ExpiresAt > GETUTCDATE() THEN 'Active'
            ELSE 'Expired (available for takeover)' END AS LockStatus,
       DATEDIFF(SECOND, GETUTCDATE(), ExpiresAt) AS SecondsRemaining
FROM Apex.Lock WITH (NOLOCK)
ORDER BY ExpiresAt;
```

### 8.2 Find expired locks that haven't been cleaned up

```sql
SELECT [Key], LockID, ExpiresAt,
       DATEDIFF(MINUTE, ExpiresAt, GETUTCDATE()) AS MinutesExpired
FROM Apex.Lock WITH (NOLOCK)
WHERE ExpiresAt <= GETUTCDATE()
ORDER BY ExpiresAt ASC;
```

### 8.3 Check lock history via RowVersion ordering

```sql
SELECT [Key], LockID, ExpiresAt, RowVersion
FROM Apex.Lock WITH (NOLOCK)
ORDER BY RowVersion DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.Lock | Type: Table | Source: USABroker/Apex/Tables/Apex.Lock.sql*
