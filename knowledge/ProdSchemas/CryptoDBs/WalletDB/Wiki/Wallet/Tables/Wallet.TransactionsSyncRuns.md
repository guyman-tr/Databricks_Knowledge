# Wallet.TransactionsSyncRuns

> Records each execution of the blockchain transaction synchronization process, tracking the pagination state and count of received transactions per sync run per wallet provider.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table logs each execution cycle of the blockchain transaction sync process. The sync periodically polls each wallet provider (BitGo/CUG) for new incoming transactions. Each row records one sync run: the provider polled, the pagination cursors (Prev/Next), and how many new transactions were received. With 91K rows, it provides a detailed operational history of the sync process.

---

## 2. Business Logic

No complex logic. Operational log of sync executions with pagination state for incremental polling.

---

## 3. Data Overview

N/A for operational log table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | WalletProviderId | int | NO | - | VERIFIED | Which wallet provider was polled: 1=BitGo, 2=CUG. FK to Dictionary.WalletProvider. See [Wallet Provider](../../_glossary.md#wallet-provider). |
| 3 | Prev | nvarchar(256) | YES | - | CODE-BACKED | Previous page cursor from the provider's pagination API. Used for backward navigation. |
| 4 | Next | nvarchar(256) | YES | - | CODE-BACKED | Next page cursor. Stored to resume the next sync run from where the last one left off. |
| 5 | Received | int | NO | - | CODE-BACKED | Count of new transactions received in this sync run. 0 means no new activity since last sync. |
| 6 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of this sync run. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletProviderId | Dictionary.WalletProvider | FK | Provider that was polled |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertTransactionsSyncRun | - | Writer | Records sync runs |
| Wallet.GetLastSyncRun | - | Reader | Gets latest sync state for resumption |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.WalletProvider | Table | FK target for WalletProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertTransactionsSyncRun | Stored Procedure | Records sync runs |
| Wallet.GetLastSyncRun | Stored Procedure | Reads latest sync state |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Wallet_TransactionsSyncRunsEntity | CLUSTERED PK | Id ASC | - | - | Active |
| IX_TransactionsSyncRuns__WalletProviderId_Created | NC UNIQUE | WalletProviderId, Created DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Created | DEFAULT | getutcdate() |
| FK_...WalletProviderId | FK | -> Dictionary.WalletProvider.Id |

---

## 8. Sample Queries

### 8.1 Latest sync run per provider
```sql
SELECT wp.Name AS Provider, tsr.Received, tsr.Created
FROM Wallet.TransactionsSyncRuns tsr WITH (NOLOCK)
JOIN Dictionary.WalletProvider wp WITH (NOLOCK) ON tsr.WalletProviderId = wp.Id
WHERE tsr.Id = (SELECT MAX(t2.Id) FROM Wallet.TransactionsSyncRuns t2 WITH (NOLOCK) WHERE t2.WalletProviderId = tsr.WalletProviderId)
```

### 8.2 Recent sync activity
```sql
SELECT TOP 20 wp.Name AS Provider, tsr.Received, tsr.Created
FROM Wallet.TransactionsSyncRuns tsr WITH (NOLOCK)
JOIN Dictionary.WalletProvider wp WITH (NOLOCK) ON tsr.WalletProviderId = wp.Id
ORDER BY tsr.Created DESC
```

### 8.3 Average transactions per sync
```sql
SELECT wp.Name AS Provider, AVG(tsr.Received) AS AvgReceived, COUNT(*) AS SyncRuns
FROM Wallet.TransactionsSyncRuns tsr WITH (NOLOCK)
JOIN Dictionary.WalletProvider wp WITH (NOLOCK) ON tsr.WalletProviderId = wp.Id
GROUP BY wp.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TransactionsSyncRuns | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.TransactionsSyncRuns.sql*
