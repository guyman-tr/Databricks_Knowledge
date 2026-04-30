# Wallet.GetWalletSyncRequests

> Returns all incomplete wallet sync requests from the WalletSyncs table, used by the redeem persistor service to process pending blockchain synchronization operations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns WalletSyncs rows where IsCompleted = 0 or NULL |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns all pending wallet sync requests - records in WalletSyncs that have not yet been completed. The redeem persistor service polls this to discover sync requests that need processing. Each sync request specifies a wallet ID, target sync date range, and the source that initiated the request.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple filter on WalletSyncs WHERE IsCompleted = 0 OR IsCompleted IS NULL.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id (output) | bigint | NO | - | CODE-BACKED | Sync request ID. |
| 2 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet to sync. |
| 3 | SyncToDateTime (output) | datetime2(7) | YES | - | CODE-BACKED | Target end time for the sync window. |
| 4 | SyncedToDateTime (output) | datetime2(7) | YES | - | CODE-BACKED | How far the sync has progressed so far. |
| 5 | CorrelationId (output) | uniqueidentifier | YES | - | CODE-BACKED | Business correlation ID for tracing. |
| 6 | RequestSource (output) | varchar | YES | - | CODE-BACKED | What initiated this sync request (e.g., service name). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletSyncs | Filter | Incomplete sync requests |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemPersistorUser | - | EXECUTE | Pending sync processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletSyncRequests (procedure)
+-- Wallet.WalletSyncs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletSyncs | Table | Filtered by IsCompleted |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemPersistorUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get pending sync requests
```sql
EXEC Wallet.GetWalletSyncRequests;
```

### 8.2 Direct equivalent
```sql
SELECT Id, WalletId, SyncToDateTime, SyncedToDateTime, CorrelationId, RequestSource
FROM Wallet.WalletSyncs WITH (NOLOCK) WHERE IsCompleted = 0 OR IsCompleted IS NULL;
```

### 8.3 Count pending syncs
```sql
SELECT COUNT(*) FROM Wallet.WalletSyncs WITH (NOLOCK) WHERE IsCompleted = 0 OR IsCompleted IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletSyncRequests | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletSyncRequests.sql*
