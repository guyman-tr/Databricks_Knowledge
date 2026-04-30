# Wallet.Processes

> Registry of named background service processes that perform scheduled or event-driven operations within the wallet system, used for process activity tracking and distributed locking.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table maintains a registry of all named background processes that run within the crypto wallet platform. Each row represents a distinct service process (e.g., "HandlePendingRedemptions", "ExecuterSendTransaction", "WalletSync") that performs scheduled or event-driven work. The table works in conjunction with `Wallet.ProcesseActivities` to track when each process last ran and with `Wallet.ProcessingRecords` for distributed lock management.

Without this table, the system could not coordinate background processes, detect stuck processes, or implement distributed locking across service instances. It provides the master list of process identifiers that the activity-tracking and lock-management subsystems reference.

Processes are registered when new background services are deployed. The table contains 9 entries spanning from 2018 (initial processes) to 2024 (newer additions like WalletSync). Referenced by stored procedures for setting/getting process activity timestamps and managing process record locks.

---

## 2. Business Logic

### 2.1 Process Activity Tracking

**What**: Each process periodically reports its last activity time for health monitoring.

**Columns/Parameters Involved**: `Id`, `Name`, `Occurred`

**Rules**:
- `Wallet.SetProcessLastActivity` updates the Occurred timestamp for a process
- `Wallet.GetProcessLastActivity` retrieves the last activity time
- If a process hasn't reported activity beyond a threshold, monitoring alerts fire
- Process names are unique (enforced by index) and serve as the lookup key

### 2.2 Distributed Record Locking

**What**: Processes can lock batches of records for exclusive processing to prevent duplicate work.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Wallet.LockRecordsForProcess` associates processing records with a specific process
- `Wallet.ExtendProcessRecordsLockExpiration` extends lock duration for long-running operations
- This prevents two instances of the same service from processing the same records simultaneously

---

## 3. Data Overview

| Id | Name | Occurred | Meaning |
|---|---|---|---|
| 1 | UpdateWalletBalances | 2018-07-09 | The oldest process - periodically recalculates and caches wallet balance snapshots for reporting |
| 2 | HandlePendingRedemptions | 2019-07-14 | Picks up persisted redemption requests and sends them to the blockchain execution service |
| 6 | ExecuterSendTransaction | 2019-07-14 | Core transaction execution process - picks up queued send requests and submits them to the blockchain provider |
| 8 | HandleUserManualOutTransactions | 2024-01-30 | Processes manually-initiated user withdrawal transactions approved by operations |
| 9 | WalletSync | 2024-08-26 | Most recently added process - synchronizes wallet state with blockchain provider for consistency |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Referenced by Wallet.ProcesseActivities and Wallet.ProcessingRecords for linking activities and locks to specific processes. |
| 2 | Name | varchar(100) | NO | - | VERIFIED | Unique name identifying the background process (e.g., "HandlePendingRedemptions", "ExecuterSendTransaction"). Used as lookup key by service code. Names follow PascalCase convention matching the service/job class name. |
| 3 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of when this process was registered in the system. Also updated by Wallet.SetProcessLastActivity to track last heartbeat time. Initial processes share 2019-07-14 registration date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.ProcesseActivities | ProcessId (implicit) | Implicit | Tracks activity history for each process |
| Wallet.ProcessingRecords | ProcessId (implicit) | Implicit | Links locked processing records to the owning process |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SetProcessLastActivity | Stored Procedure | Updates process activity timestamp |
| Wallet.GetProcessLastActivity | Stored Procedure | Reads process last activity for monitoring |
| Wallet.LockRecordsForProcess | Stored Procedure | Locks records for exclusive process access |
| Wallet.ExtendProcessRecordsLockExpiration | Stored Procedure | Extends lock duration |
| Wallet.GetPendingUserManualOutTransactions | Stored Procedure | References process for filtering |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Processes | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_Processes_Name | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Processes_Occurred | DEFAULT | getutcdate() - auto-sets registration timestamp |

---

## 8. Sample Queries

### 8.1 List all registered processes
```sql
SELECT Id, Name, Occurred
FROM Wallet.Processes WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Find a process by name
```sql
SELECT Id, Name, Occurred
FROM Wallet.Processes WITH (NOLOCK)
WHERE Name = 'HandlePendingRedemptions'
```

### 8.3 Check recently active processes
```sql
SELECT p.Name, p.Occurred AS LastActivity,
    DATEDIFF(MINUTE, p.Occurred, GETUTCDATE()) AS MinutesSinceActivity
FROM Wallet.Processes p WITH (NOLOCK)
ORDER BY p.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Processes | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.Processes.sql*
