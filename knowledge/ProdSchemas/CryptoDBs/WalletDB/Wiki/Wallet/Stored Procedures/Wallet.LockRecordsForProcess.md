# Wallet.LockRecordsForProcess

> Acquires distributed processing locks on a batch of records for a named background process, handling both new locks and expired lock takeovers, returning the successfully locked record IDs.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE/INSERT into ProcessingRecords with lock acquisition |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements distributed record locking for background processes. When a service instance needs exclusive access to a batch of records (e.g., pending transactions to process), it calls this SP with the record IDs it wants to lock. The procedure attempts to acquire locks in two steps: (1) takeover expired locks from other instances, and (2) create new locks for unlocked records. It returns the IDs of successfully locked records.

Three services use this: the executer (locking pending sends), the redeem persistor (locking pending redemptions), and the redeem scheduler. This prevents multiple service instances from processing the same records simultaneously in a horizontally-scaled environment.

---

## 2. Business Logic

### 2.1 Two-Phase Lock Acquisition

**What**: First takes over expired locks, then creates new ones for remaining capacity.

**Columns/Parameters Involved**: `@ProcessName`, `@RecordIds`, `@InstanceId`, `@LockTimeInSeconds`, `@MaxRecords`

**Rules**:
- Phase 1 (Takeover): UPDATE ProcessingRecords WHERE ProcessId matches AND RecordId in request AND ExpirationTime < now
  - Sets new InstanceId, new ExpirationTime
  - OUTPUT captures locked RecordIds
- Phase 2 (New): INSERT ProcessingRecords for RecordIds NOT already in ProcessingRecords
  - Only inserts up to remaining @MaxRecords (after Phase 1 count subtracted)
  - OUTPUT captures newly locked RecordIds
- Process name resolved to ProcessId from Wallet.Processes (RAISERROR if not found)
- ExpirationTime = DATEADD(SECOND, @LockTimeInSeconds, GETDATE())
- Returns all successfully locked RecordIds ordered alphabetically

### 2.2 Capacity-Limited Locking

**What**: Respects @MaxRecords limit across both phases.

**Rules**:
- If @MaxRecords IS NULL, defaults to COUNT of @RecordIds (try to lock all)
- After Phase 1, @MaxRecords is decremented by number of takeovers
- Phase 2 uses remaining @MaxRecords for TOP clause

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessName | varchar(100) | NO | - | VERIFIED | Name of the background process (e.g., 'HandlePendingRedemptions'). Resolved to ProcessId. |
| 2 | @RecordIds | Wallet.NvarcharListType | NO | - | VERIFIED | TVP of record IDs to lock. |
| 3 | @InstanceId | varchar(127) | NO | - | VERIFIED | Service instance ID acquiring the lock (e.g., pod name). |
| 4 | @LockTimeInSeconds | int | NO | - | VERIFIED | Lock duration in seconds. After this, the lock expires and can be taken over. |
| 5 | @MaxRecords | int | YES | NULL | CODE-BACKED | Maximum records to lock. NULL = lock all requested. |
| 6 | RecordId (output) | varchar(128) | NO | - | CODE-BACKED | IDs of successfully locked records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProcessName | Wallet.Processes.Name | Lookup | Resolves ProcessId |
| - | Wallet.ProcessingRecords | UPDATE + INSERT | Lock acquisition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Locks pending sends |
| RedeemPersistorUser | - | EXECUTE | Locks pending redemptions |
| RedeemSchedulerUser | - | EXECUTE | Locks scheduled redemptions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.LockRecordsForProcess (procedure)
+-- Wallet.Processes (table)
+-- Wallet.ProcessingRecords (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Processes | Table | Process name resolution |
| Wallet.ProcessingRecords | Table | Lock UPDATE + INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser, RedeemPersistorUser, RedeemSchedulerUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table for @RecordIds performance.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Lock records for processing
```sql
DECLARE @ids Wallet.NvarcharListType;
INSERT INTO @ids VALUES ('REC-001'), ('REC-002'), ('REC-003');
EXEC Wallet.LockRecordsForProcess @ProcessName='HandlePendingRedemptions', @RecordIds=@ids, @InstanceId='pod-redeem-1a2b', @LockTimeInSeconds=300;
```

### 8.2 Lock with max limit
```sql
DECLARE @ids Wallet.NvarcharListType;
INSERT INTO @ids VALUES ('REC-001'), ('REC-002'), ('REC-003');
EXEC Wallet.LockRecordsForProcess @ProcessName='ExecuterSendTransaction', @RecordIds=@ids, @InstanceId='pod-exec-3c4d', @LockTimeInSeconds=600, @MaxRecords=2;
```

### 8.3 Check current locks
```sql
SELECT * FROM Wallet.ProcessingRecords WITH (NOLOCK) WHERE ProcessId = (SELECT Id FROM Wallet.Processes WHERE Name = 'HandlePendingRedemptions') ORDER BY ExpirationTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.LockRecordsForProcess | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.LockRecordsForProcess.sql*
