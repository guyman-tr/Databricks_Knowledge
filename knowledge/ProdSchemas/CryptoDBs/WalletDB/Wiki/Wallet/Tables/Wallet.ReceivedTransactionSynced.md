# Wallet.ReceivedTransactionSynced

> Tracks the last synchronization timestamp for each wallet's received transactions, enabling incremental sync by recording when each wallet was last checked for incoming blockchain transactions.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | WalletId (uniqueidentifier, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

This table tracks when each wallet was last synchronized for incoming (received) blockchain transactions. The WalletSync background process periodically checks wallets for new incoming transactions from the blockchain provider. This table stores the timestamp of the last successful sync per wallet, enabling incremental synchronization - only transactions newer than `LastSynced` need to be checked.

Without this table, the sync process would need to re-check all transactions from the beginning for every wallet on every run, which would be prohibitively expensive with 813K+ wallets.

Rows are created/updated by `Wallet.UpsertReceivedTransactionSynced` and read by `Wallet.GetWalletSyncRequests` to determine which wallets need syncing.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple last-synced timestamp per wallet.

---

## 3. Data Overview

| WalletId | LastSynced | Meaning |
|---|---|---|
| B1FD00C7-... | 2026-04-14 16:44 | Recently synced wallet - fully up to date with blockchain state |
| EBE89B13-... | 2026-04-14 16:43 | Also recently synced within seconds |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet this sync record belongs to. PK and FK to Wallet.WalletPool.WalletId. One row per wallet. |
| 2 | LastSynced | datetime | NO | - | CODE-BACKED | Timestamp of the last successful received transaction sync for this wallet. The sync process only checks for transactions newer than this timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.WalletPool | FK | Links to the pool wallet |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.UpsertReceivedTransactionSynced | - | Writer | Creates/updates sync timestamps |
| Wallet.GetWalletSyncRequests | - | Reader | Reads sync state for scheduling |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.ReceivedTransactionSynced (table)
└── Wallet.WalletPool (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | FK target for WalletId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.UpsertReceivedTransactionSynced | Stored Procedure | Upserts sync timestamps |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ReceivedTransactionSynced | CLUSTERED PK | WalletId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_...WalletId__Wallet_WalletPool_WalletId | FK | WalletId -> Wallet.WalletPool.WalletId |

---

## 8. Sample Queries

### 8.1 Find wallets not synced recently
```sql
SELECT TOP 20 WalletId, LastSynced,
    DATEDIFF(MINUTE, LastSynced, GETUTCDATE()) AS MinutesSinceSync
FROM Wallet.ReceivedTransactionSynced WITH (NOLOCK)
ORDER BY LastSynced ASC
```

### 8.2 Check sync status for a specific wallet
```sql
SELECT LastSynced FROM Wallet.ReceivedTransactionSynced WITH (NOLOCK)
WHERE WalletId = 'B1FD00C7-E8C7-46D0-8082-DE44AE48EED2'
```

### 8.3 Count wallets by sync recency
```sql
SELECT CASE
    WHEN LastSynced > DATEADD(HOUR, -1, GETUTCDATE()) THEN 'Last hour'
    WHEN LastSynced > DATEADD(DAY, -1, GETUTCDATE()) THEN 'Last day'
    ELSE 'Older'
END AS SyncRecency, COUNT(*) AS WalletCount
FROM Wallet.ReceivedTransactionSynced WITH (NOLOCK)
GROUP BY CASE
    WHEN LastSynced > DATEADD(HOUR, -1, GETUTCDATE()) THEN 'Last hour'
    WHEN LastSynced > DATEADD(DAY, -1, GETUTCDATE()) THEN 'Last day'
    ELSE 'Older'
END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ReceivedTransactionSynced | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ReceivedTransactionSynced.sql*
