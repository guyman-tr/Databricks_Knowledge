# Wallet.ExtendProcessRecordsLockExpiration

> Extends the lock expiration time for a batch of processing records owned by a specific process instance, returning the IDs of successfully extended records.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns list of RecordIds with extended locks |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of the distributed processing framework. When a process instance (e.g., a transaction processor, sync worker, or reconciliation job) holds locks on records via ProcessingRecords, those locks have an expiration time to prevent deadlocks from crashed instances. If a process is still actively working on records, it calls this procedure to extend the lock duration, similar to a lease renewal.

Without this procedure, long-running processes would lose their locks when the initial lock period expires, causing other instances to pick up the same records and leading to duplicate processing, race conditions, and data corruption.

The procedure validates the process name, calculates the new expiration time, and updates only records matching both the ProcessId and InstanceId (ensuring one instance cannot extend another instance's locks).

---

## 2. Business Logic

### 2.1 Process Name Validation

**What**: Resolves process name to ID and fails if the process is not registered.

**Columns/Parameters Involved**: `@ProcessName`, Wallet.Processes

**Rules**:
- Looks up ProcessId from Wallet.Processes by Name
- If process not found, raises error severity 16: 'Process name "{name}" not found'
- This prevents accidental lock extension for non-existent processes

### 2.2 Instance-Scoped Lock Extension

**What**: Only extends locks owned by the calling instance.

**Columns/Parameters Involved**: `@InstanceId`, `@RecordIds`, ProcessingRecords

**Rules**:
- JOINs @RecordIds (BigintListType TVP) to ProcessingRecords
- Requires match on ProcessId AND RecordId AND InstanceId
- Updates ExpirationTime to GETDATE() + @LockTimeInSeconds
- Returns only the RecordIds that were successfully extended (via OUTPUT clause)
- Records not owned by this instance are silently excluded

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessName | varchar(100) | NO | - | CODE-BACKED | Name of the registered process (e.g., "TransactionSync", "BalanceReconciliation"). Resolved to ProcessId via Wallet.Processes. |
| 2 | @RecordIds | Wallet.BigintListType (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the IDs of records whose locks should be extended. |
| 3 | @InstanceId | varchar(127) | NO | - | CODE-BACKED | Unique identifier of the calling process instance (e.g., machine name + PID). Ensures only the lock owner can extend. |
| 4 | @LockTimeInSeconds | int | NO | - | CODE-BACKED | Duration in seconds to extend the lock from the current time. New expiration = GETDATE() + this value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProcessName | Wallet.Processes | Lookup | Resolves process name to ID |
| UPDATE target | Wallet.ProcessingRecords | Modifier | Extends lock expiration time |
| @RecordIds | Wallet.BigintListType | UDT | Table-valued parameter |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application processing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ExtendProcessRecordsLockExpiration (procedure)
  ├── Wallet.Processes (table)
  ├── Wallet.ProcessingRecords (table)
  └── Wallet.BigintListType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Processes | Table | Resolves process name to ID |
| Wallet.ProcessingRecords | Table | UPDATE target |
| Wallet.BigintListType | User Defined Type | Table-valued parameter |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- RAISERROR severity 16 if process name not found
- Uses OUTPUT clause for returning affected RecordIds
- @Result table variable for collecting outputs
- DATEADD(SECOND, @LockTimeInSeconds, GETDATE()) for expiration calculation

---

## 8. Sample Queries

### 8.1 View locked records for a process
```sql
SELECT pr.RecordId, pr.InstanceId, pr.ExpirationTime, p.Name AS ProcessName
FROM Wallet.ProcessingRecords pr WITH (NOLOCK)
JOIN Wallet.Processes p WITH (NOLOCK) ON p.Id = pr.ProcessId
WHERE pr.ExpirationTime > GETDATE()
ORDER BY pr.ExpirationTime
```

### 8.2 Find expired locks (available for pickup)
```sql
SELECT pr.RecordId, pr.InstanceId, pr.ExpirationTime, p.Name AS ProcessName
FROM Wallet.ProcessingRecords pr WITH (NOLOCK)
JOIN Wallet.Processes p WITH (NOLOCK) ON p.Id = pr.ProcessId
WHERE pr.ExpirationTime <= GETDATE()
```

### 8.3 Lock counts by process
```sql
SELECT p.Name, COUNT(*) AS ActiveLocks
FROM Wallet.ProcessingRecords pr WITH (NOLOCK)
JOIN Wallet.Processes p WITH (NOLOCK) ON p.Id = pr.ProcessId
WHERE pr.ExpirationTime > GETDATE()
GROUP BY p.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ExtendProcessRecordsLockExpiration | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.ExtendProcessRecordsLockExpiration.sql*
