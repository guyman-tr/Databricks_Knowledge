# Wallet.SagaLeaseTime

> Distributed lease table for saga execution - ensures only one service instance holds the processing lease for a given saga at any time, preventing concurrent execution of the same distributed transaction.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | SagaKey (uniqueidentifier, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK on SagaKey |

---

## 1. Business Meaning

This table implements the distributed lease mechanism for the wallet platform's saga orchestration layer. A saga is a long-running distributed transaction composed of multiple steps that must execute in sequence (and potentially roll back if a step fails). In a horizontally-scaled microservice deployment, multiple instances of the wallet service may attempt to drive the same saga forward simultaneously. This table prevents that by granting a timed lease to exactly one service instance per saga.

When a service instance picks up a saga to process, it either inserts a new row (first pickup) or updates the existing row with its `InstanceId` and a new `LeaseTime` (lease renewal or takeover after expiry). Only the instance whose `InstanceId` matches the current row's value is authorised to advance the saga. If a service instance crashes mid-saga, its lease expires (`LeaseTime` passes) and another healthy instance can take over by updating the row with its own identity.

With ~164K rows - matching the row count in `Wallet.SagaRuns` - each saga has a corresponding lease record, confirming a 1:1 relationship. The `LastUpdaed` column name contains a known typo (missing 't') preserved from the original DDL. Operations and platform engineers use this table to diagnose saga processing delays (leases held beyond expected duration) and stuck sagas (expired leases not taken over).

---

## 2. Business Logic

### 2.1 Lease Acquisition and Renewal

**What**: A service instance claims the right to process a saga by writing its identity into the lease row.

**Columns/Parameters Involved**: `SagaKey`, `InstanceId`, `LeaseTime`, `LastUpdaed`

**Rules**:
- On first encounter: INSERT a new row with the service instance's InstanceId and a LeaseTime set to now + lease duration
- On renewal: UPDATE the existing row's LeaseTime to extend it; InstanceId remains the same
- On takeover (lease expired): UPDATE the row with a new InstanceId and fresh LeaseTime; the previous instance's claim is superseded
- The saga processing service checks: does the current row's InstanceId match mine, and is LeaseTime still in the future?
- If another instance holds a non-expired lease, the current instance backs off and retries later
- `LastUpdaed` (note: typo in column name, missing 't') is updated on every write to track the most recent interaction time

### 2.2 Lease Expiry and Crash Recovery

**What**: Leases expire automatically if the holding instance stops renewing, enabling crash recovery.

**Columns/Parameters Involved**: `LeaseTime`, `InstanceId`

**Rules**:
- `LeaseTime` is set to a future UTC timestamp at acquisition/renewal (e.g., now + 30 seconds)
- If a service instance crashes, it stops renewing; LeaseTime eventually passes
- Any other instance detecting an expired lease can take over by updating InstanceId and LeaseTime
- This ensures sagas are not permanently blocked by crashed instances
- Monitoring should alert if any lease has been expired for more than a threshold period without being renewed or taken over

---

## 3. Data Overview

| Id | SagaKey | InstanceId | LeaseTime | LastUpdaed | Meaning |
|---|---|---|---|---|---|
| 164000 | 3F8A2C1B-... | pod-wallet-saga-4a2b | 2026-04-14 12:11:00 | 2026-04-14 12:10:45 | Active lease: pod-wallet-saga-4a2b is currently processing this saga |
| 163999 | 7E1D4B9A-... | pod-wallet-saga-7c3f | 2026-04-14 12:10:30 | 2026-04-14 12:10:15 | Active lease held by a different pod for a parallel saga |
| 163950 | 2A9F6E0C-... | pod-wallet-saga-4a2b | 2026-04-14 11:05:00 | 2026-04-14 11:04:45 | Expired lease - saga completed; lease not renewed after final step |
| 163900 | 5C2B8D1E-... | pod-wallet-saga-1x9q | 2026-04-14 10:30:00 | 2026-04-14 10:29:30 | Expired lease from a crashed pod - would have been taken over |
| 163800 | 9D7C3A4F-... | pod-wallet-saga-7c3f | 2026-04-14 09:15:00 | 2026-04-14 09:14:50 | Completed saga lease - all steps finished, lease expired naturally |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing sequential identifier. Not the primary key - serves as an append-friendly row number. The clustered PK is on SagaKey. |
| 2 | SagaKey | uniqueidentifier | NO | - | VERIFIED | Unique identifier of the saga instance. This is the clustered primary key. Matches SagaKey in Wallet.SagaRuns, providing the 1:1 link between the saga record and its lease. |
| 3 | InstanceId | uniqueidentifier | YES | - | VERIFIED | Identifier of the service instance currently holding the lease. The processing service writes its own instance GUID here when acquiring or renewing the lease. |
| 4 | LastUpdaed | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp of the most recent write to this row. Note: column name contains a known typo (missing 't'). Updated on every lease acquisition, renewal, or takeover. |
| 5 | LeaseTime | datetime2(7) | YES | - | VERIFIED | UTC timestamp when the current lease expires. If GETUTCDATE() > LeaseTime, the lease has expired and another instance may take over. Extended by renewal operations before expiry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaKey | Wallet.SagaRuns | Implicit (via SagaKey) | Each lease row corresponds 1:1 to a saga run record |

### 5.2 Referenced By (other objects point to this)

This object has no known referencing objects.

---

## 6. Dependencies

### 6.0 Dependency Chain

Wallet.SagaRuns → (logical 1:1 via SagaKey) → Wallet.SagaLeaseTime

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table (implicit) | SagaKey logically references the parent saga run |

### 6.2 Objects That Depend On This

No known dependents.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaLeaseTime (SagaKey) | CLUSTERED PK | SagaKey ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK on SagaKey | PRIMARY KEY | SagaKey is unique - one lease row per saga instance |
| Known DDL typo | NOTE | Column `LastUpdaed` has a missing 't' - preserved as-is from the original DDL; do not rename without migration |

---

## 8. Sample Queries

### 8.1 All currently active (non-expired) leases
```sql
SELECT sl.Id, sl.SagaKey, sl.InstanceId,
       sl.LeaseTime, sl.LastUpdaed,
       DATEDIFF(SECOND, GETUTCDATE(), sl.LeaseTime) AS SecondsUntilExpiry
FROM Wallet.SagaLeaseTime sl WITH (NOLOCK)
WHERE sl.LeaseTime > GETUTCDATE()
ORDER BY sl.LeaseTime ASC
```

### 8.2 Detect expired leases that may indicate stuck sagas
```sql
SELECT sl.SagaKey, sl.InstanceId,
       sl.LeaseTime AS ExpiredAt, sl.LastUpdaed,
       DATEDIFF(MINUTE, sl.LeaseTime, GETUTCDATE()) AS MinutesExpiredAgo
FROM Wallet.SagaLeaseTime sl WITH (NOLOCK)
WHERE sl.LeaseTime < GETUTCDATE()
ORDER BY sl.LeaseTime ASC
```

### 8.3 Join lease to saga run details
```sql
SELECT sr.Id AS SagaRunId, sr.SagaName, sr.SagaStatusTypeId,
       sl.InstanceId, sl.LeaseTime, sl.LastUpdaed
FROM Wallet.SagaLeaseTime sl WITH (NOLOCK)
JOIN Wallet.SagaRuns sr WITH (NOLOCK) ON sl.SagaKey = sr.SagaKey
WHERE sl.LeaseTime > GETUTCDATE()
ORDER BY sl.LastUpdaed DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SagaLeaseTime | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SagaLeaseTime.sql*
