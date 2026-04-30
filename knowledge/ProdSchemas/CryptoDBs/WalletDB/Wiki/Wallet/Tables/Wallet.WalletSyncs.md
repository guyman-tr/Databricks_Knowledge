# Wallet.WalletSyncs

> Records wallet synchronization requests and their completion status, tracking when each wallet's blockchain state was synchronized and the time window covered by each sync operation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active NC (filtered) + 1 clustered PK |

---

## 1. Business Meaning

This table records individual wallet synchronization operations. Each row represents a sync request for a specific wallet, defining the time window to sync (SyncToDateTime, SyncedToDateTime) and whether the sync completed. With ~6.15M rows, this is one of the highest-volume operational tables, reflecting the continuous nature of blockchain state synchronization.

The sync process ensures wallet balances and transaction lists are up-to-date with the blockchain. Filtered indexes on IsCompleted=NULL optimize queries for finding incomplete sync operations that need processing.

---

## 2. Business Logic

No complex logic. Operational sync tracking with completion status.

---

## 3. Data Overview

N/A for high-volume operational table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | The wallet being synchronized. Implicit reference to Wallet.WalletPool. |
| 3 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | When this sync request was created. |
| 4 | SyncToDateTime | datetime2(7) | NO | - | CODE-BACKED | The target end time for this sync window - sync transactions up to this point. |
| 5 | SyncedToDateTime | datetime2(7) | NO | - | CODE-BACKED | The actual time up to which transactions have been synced so far. |
| 6 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links to the parent sync request. |
| 7 | RequestSource | varchar(100) | YES | - | CODE-BACKED | Source/reason for the sync request (e.g., "WalletSync", "ManualSync"). |
| 8 | IsCompleted | bit | YES | - | CODE-BACKED | Whether this sync operation has finished: 1=done, NULL=in-progress/pending. Filtered indexes optimize pending sync queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddWalletSyncRequests | - | Writer | Creates sync requests |
| Wallet.GetWalletSyncRequests | - | Reader | Reads pending syncs |
| Wallet.UpdateWalletSyncRequest | - | Modifier | Updates completion status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddWalletSyncRequests | Stored Procedure | Creates sync requests |
| Wallet.GetWalletSyncRequests | Stored Procedure | Reads pending syncs |
| Wallet.UpdateWalletSyncRequest | Stored Procedure | Updates status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletSyncs | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet__Created | NC | Created | - | WHERE IsCompleted IS NULL | Active |
| IX_Wallet__WalletId_SyncedToDateTime | NC | WalletId, SyncedToDateTime | - | WHERE IsCompleted IS NULL | Active |
| IX_WalletSyncs_IsCompleted_Inc | NC | IsCompleted | Id, WalletId, SyncToDateTime, SyncedToDateTime, CorrelationId, RequestSource | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_WalletSyncs__Created | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Find pending sync operations
```sql
SELECT TOP 20 Id, WalletId, SyncToDateTime, SyncedToDateTime, Created
FROM Wallet.WalletSyncs WITH (NOLOCK)
WHERE IsCompleted IS NULL
ORDER BY Created
```

### 8.2 Recent completed syncs
```sql
SELECT TOP 20 Id, WalletId, RequestSource, Created
FROM Wallet.WalletSyncs WITH (NOLOCK)
WHERE IsCompleted = 1
ORDER BY Id DESC
```

### 8.3 Sync backlog size
```sql
SELECT COUNT(*) AS PendingSyncs FROM Wallet.WalletSyncs WITH (NOLOCK) WHERE IsCompleted IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.WalletSyncs | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.WalletSyncs.sql*
