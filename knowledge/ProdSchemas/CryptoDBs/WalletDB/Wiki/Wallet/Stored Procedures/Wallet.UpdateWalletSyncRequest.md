# Wallet.UpdateWalletSyncRequest

> Updates a wallet sync request's progress (SyncedToDateTime) and completion status, used by the redeem persistor service to track blockchain synchronization progress.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE WalletSyncs by Id |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure updates the progress of a wallet sync request. The redeem persistor calls this as it processes sync requests created by AddWalletSyncRequests. The SyncedToDateTime tracks how far the sync has progressed, and IsCompleted marks when it's done. Uses ISNULL pattern for SyncedToDateTime - only updates if a new value is provided.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple UPDATE on WalletSyncs by Id.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | bigint | NO | - | VERIFIED | Sync request to update. |
| 2 | @SyncedToDateTime | datetime2(7) | YES | - | CODE-BACKED | How far the sync has progressed. NULL = don't update. |
| 3 | @IsCompleted | bit | NO | - | VERIFIED | Whether the sync is complete. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Id | Wallet.WalletSyncs | UPDATE | Sync progress/completion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemPersistorUser | - | EXECUTE | Sync progress tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateWalletSyncRequest (procedure)
+-- Wallet.WalletSyncs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletSyncs | Table | UPDATE target |

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

### 8.1 Update sync progress
```sql
EXEC Wallet.UpdateWalletSyncRequest @Id=12345, @SyncedToDateTime='2026-04-15 10:00:00', @IsCompleted=0;
```

### 8.2 Mark sync as complete
```sql
EXEC Wallet.UpdateWalletSyncRequest @Id=12345, @SyncedToDateTime='2026-04-15 12:00:00', @IsCompleted=1;
```

### 8.3 Sync lifecycle
```sql
-- 1. AddWalletSyncRequests -> creates sync request
-- 2. GetWalletSyncRequests -> retrieves pending requests
-- 3. UpdateWalletSyncRequest (this SP) -> tracks progress + marks complete
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateWalletSyncRequest | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.UpdateWalletSyncRequest.sql*
