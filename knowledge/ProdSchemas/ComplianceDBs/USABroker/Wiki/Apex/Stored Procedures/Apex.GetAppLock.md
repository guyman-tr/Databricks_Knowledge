# Apex.GetAppLock

> Acquires an exclusive SQL Server application lock on a named resource with a specified timeout, used for cross-session distributed locking within the database.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns RetCode (lock result) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GetAppLock wraps SQL Server's sp_getapplock to acquire an exclusive application lock on a named resource. Unlike the Apex.Lock table (used for cross-process distributed locking with expiration), this procedure uses SQL Server's built-in application lock mechanism for intra-session/intra-connection locking. The lock is automatically released when the session ends or the transaction commits.

This is used for coordinating critical sections within database operations - ensuring that only one session at a time can process a specific resource (e.g., a specific customer's state machine transition).

---

## 2. Business Logic

### 2.1 Lock Acquisition with Timeout

**What**: Attempts to acquire an exclusive lock, waiting up to @LockTimeoutMs milliseconds before giving up.

**Columns/Parameters Involved**: `@Resource`, `@LockTimeoutMs`

**Rules**:
- Return code >= 0: lock acquired (0=granted without wait, 1=granted after wait)
- Return code -1: lock timed out (another session holds it)
- Return code -2: lock request was canceled
- Return code -3: deadlock victim
- Lock mode is always 'Exclusive' - no shared locks

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Resource | nvarchar(150) | NO | - | CODE-BACKED | Named resource to lock. Application defines the naming convention. |
| 2 | @LockTimeoutMs | int | NO | - | CODE-BACKED | Maximum milliseconds to wait for the lock. 0 = return immediately if not available. -1 = wait indefinitely. |

**Returns**: Single-column result set with RetCode: >= 0 success, < 0 failure.

---

## 5. Relationships

### 5.1 References To (this object points to)

This procedure uses sp_getapplock (built-in). No table references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no table dependencies.

### 6.1 Objects This Depends On

No table dependencies. Uses built-in sp_getapplock.

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

### 8.1 Acquire a lock with 5-second timeout

```sql
EXEC Apex.GetAppLock @Resource = N'ApexStateProcessor', @LockTimeoutMs = 5000;
-- RetCode >= 0 means lock acquired
```

### 8.2 Try lock without waiting

```sql
EXEC Apex.GetAppLock @Resource = N'ApexStateProcessor', @LockTimeoutMs = 0;
-- RetCode -1 if already held
```

### 8.3 Acquire and release pattern

```sql
BEGIN TRAN;
EXEC Apex.GetAppLock @Resource = N'MyResource', @LockTimeoutMs = 10000;
-- Do work here
COMMIT TRAN; -- Lock automatically released
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GetAppLock | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.GetAppLock.sql*
