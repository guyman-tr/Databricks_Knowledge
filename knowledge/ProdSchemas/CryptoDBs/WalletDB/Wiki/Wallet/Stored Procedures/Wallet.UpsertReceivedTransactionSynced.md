# Wallet.UpsertReceivedTransactionSynced

> Upserts a wallet's last blockchain sync timestamp - updating if exists, inserting if new - used by the balance and redeem persistor services to track when each wallet was last synchronized with the blockchain.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPSERT into ReceivedTransactionSynced by WalletId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure maintains the last sync timestamp for each wallet. After processing blockchain sync data for a wallet, the balance and redeem persistor services call this to record how far the sync has progressed. Uses the classic IF EXISTS/UPDATE ELSE INSERT pattern. The LastSynced timestamp is used by GetWalletIdsForSync and GetWalletsForSync to determine which wallets need synchronization.

---

## 2. Business Logic

### 2.1 Classic Upsert Pattern

**What**: UPDATE if wallet has a sync record, INSERT if not.

**Rules**:
- IF EXISTS (ReceivedTransactionSynced WHERE WalletId): UPDATE SET LastSynced
- ELSE: INSERT new record
- One record per WalletId (maintained over time)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Wallet that was synced. |
| 2 | @LastSynced | datetime | NO | - | VERIFIED | Timestamp of the latest sync. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId | Wallet.ReceivedTransactionSynced | UPSERT | Sync timestamp |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser, RedeemPersistorUser | - | EXECUTE | Sync timestamp recording |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpsertReceivedTransactionSynced (procedure)
+-- Wallet.ReceivedTransactionSynced (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactionSynced | Table | UPSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BalanceUser, RedeemPersistorUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record sync timestamp
```sql
EXEC Wallet.UpsertReceivedTransactionSynced @WalletId='WALLET-GUID', @LastSynced='2026-04-15 12:00:00';
```

### 8.2 Check last sync for a wallet
```sql
SELECT * FROM Wallet.ReceivedTransactionSynced WITH (NOLOCK) WHERE WalletId = 'WALLET-GUID';
```

### 8.3 Find wallets not synced recently
```sql
SELECT WalletId, LastSynced FROM Wallet.ReceivedTransactionSynced WITH (NOLOCK) WHERE LastSynced < DATEADD(HOUR, -24, GETDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpsertReceivedTransactionSynced | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.UpsertReceivedTransactionSynced.sql*
