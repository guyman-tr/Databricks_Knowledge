# Wallet.AddWalletSyncRequests

> Creates wallet synchronization requests for a batch of wallet IDs, scheduling them for blockchain transaction sync up to a specified datetime, skipping wallets with existing pending sync requests.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New rows in Wallet.WalletSyncs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure schedules blockchain transaction synchronization for one or more wallets. The wallet sync process reconciles on-chain transaction data with the database, ensuring balances and transaction histories are up to date. Sync requests specify a target datetime up to which the wallet should be synchronized.

Without this procedure, the system could not initiate on-demand synchronization of wallet transaction data, leading to stale balances and missing transactions in the database.

The procedure accepts a table-valued parameter (GuidListType) containing wallet IDs, making it efficient for batch operations. It prevents duplicate sync requests by checking for existing incomplete requests with the same wallet ID and target datetime.

---

## 2. Business Logic

### 2.1 Batch Insert with Duplicate Prevention

**What**: Creates sync requests for multiple wallets, skipping those with existing pending requests.

**Columns/Parameters Involved**: `@WalletIds`, `@SyncToDateTime`, WalletSyncs

**Rules**:
- LEFT JOINs to existing WalletSyncs where SyncedToDateTime <= @SyncToDateTime AND IsCompleted IS NULL
- Only inserts where no matching pending request exists (ws.Id IS NULL)
- Sets both SyncToDateTime and SyncedToDateTime to @SyncToDateTime initially
- RequestSource tracks which system initiated the sync

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletIds | Wallet.GuidListType (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the wallet IDs to sync. Uses the GuidListType UDT (single UNIQUEIDENTIFIER column named Item). |
| 2 | @SyncToDateTime | datetime2(7) | NO | - | CODE-BACKED | Target datetime up to which wallet transactions should be synchronized from the blockchain. |
| 3 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Correlation ID linking this batch of sync requests to the originating operation for traceability. |
| 4 | @RequestSource | varchar(100) | NO | - | CODE-BACKED | Identifier of the system or process that initiated the sync (e.g., "WalletService", "ReconciliationJob", "ManualSync"). Used for monitoring and debugging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletIds | Wallet.GuidListType | UDT | Table-valued parameter type |
| INSERT target | Wallet.WalletSyncs | Writer | Creates sync request records |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application sync services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddWalletSyncRequests (procedure)
  ├── Wallet.WalletSyncs (table)
  └── Wallet.GuidListType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletSyncs | Table | INSERT target + duplicate check |
| Wallet.GuidListType | User Defined Type | Table-valued parameter |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- READONLY modifier on @WalletIds (required for TVPs)
- No explicit error handling

---

## 8. Sample Queries

### 8.1 View pending wallet sync requests
```sql
SELECT TOP 20 Id, WalletId, SyncToDateTime, SyncedToDateTime, IsCompleted, RequestSource, CorrelationId
FROM Wallet.WalletSyncs WITH (NOLOCK)
WHERE IsCompleted IS NULL
ORDER BY Id DESC
```

### 8.2 Find sync requests for a specific wallet
```sql
SELECT Id, SyncToDateTime, SyncedToDateTime, IsCompleted, RequestSource, Created
FROM Wallet.WalletSyncs WITH (NOLOCK)
WHERE WalletId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
ORDER BY Id DESC
```

### 8.3 Sync request summary by source
```sql
SELECT RequestSource, IsCompleted, COUNT(*) AS Cnt
FROM Wallet.WalletSyncs WITH (NOLOCK)
GROUP BY RequestSource, IsCompleted
ORDER BY RequestSource
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddWalletSyncRequests | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddWalletSyncRequests.sql*
