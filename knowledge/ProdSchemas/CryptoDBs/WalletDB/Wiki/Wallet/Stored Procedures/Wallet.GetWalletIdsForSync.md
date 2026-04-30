# Wallet.GetWalletIdsForSync

> Retrieves wallet details for a set of wallet IDs filtered by last sync time, providing the data needed by the wallet sync service to determine which wallets need blockchain synchronization.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns sync-relevant wallet data for specified WalletIds |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the wallet sync service with the data it needs to synchronize wallet state with the blockchain. Given a list of wallet IDs (via the GuidListType TVP), it returns each wallet's details along with its last sync timestamp from ReceivedTransactionSynced. Only wallets whose last sync time is at or before @UpperLastSync are returned, allowing the sync service to prioritize wallets that haven't been synced recently.

The balance and redeem persistor services consume this. The procedure filters to base-chain wallets (CryptoId = BlockchainCryptoId) and uses OUTER APPLY for optional ReceivedTransactionSynced and WalletAddresses lookups (wallets may not yet have sync records or additional addresses).

---

## 2. Business Logic

### 2.1 Sync Eligibility Filtering

**What**: Returns only wallets whose last sync time is at or before the threshold.

**Columns/Parameters Involved**: `@UpperLastSync`, `ReceivedTransactionSynced.LastSynced`

**Rules**:
- Default @UpperLastSync = GETDATE() (all wallets eligible)
- ISNULL(LastSynced, '2018-01-01') handles wallets never synced (treats them as very old)
- Only base-chain wallets returned (CryptoId = BlockchainCryptoId)
- @WalletIds TVP filters to specific wallets (LEFT JOIN + IS NOT NULL pattern)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletIds | Wallet.GuidListType | NO | - | VERIFIED | TVP containing wallet IDs to check for sync eligibility. |
| 2 | @UpperLastSync | datetime2(7) | YES | GETDATE() | VERIFIED | Maximum last-sync threshold. Only wallets synced at or before this time are returned. |
| 3 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID (returned twice for backward compatibility). |
| 4 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Alias of WalletId. |
| 5 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference (returned twice for backward compatibility). |
| 6 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Alias of BlockchainProviderWalletId. |
| 7 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 8 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Wallet address from WalletAddresses. |
| 9 | CryptoId (output) | int | NO | - | CODE-BACKED | Base-chain cryptocurrency. |
| 10 | LastSynced (output) | datetime2(7) | YES | - | CODE-BACKED | Last sync time from ReceivedTransactionSynced. '2018-01-01' if never synced. |
| 11 | BalanceAccountID (output) | bigint | YES | - | CODE-BACKED | Balance account ID cast to BIGINT from WalletAddresses. |
| 12 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Wallet infrastructure provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletIds | Wallet.CustomerWalletsView | LEFT JOIN + filter | Base wallet data |
| WalletId | Wallet.ReceivedTransactionSynced | OUTER APPLY | Last sync timestamp |
| WalletId | Wallet.WalletAddresses | OUTER APPLY | Address and balance account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | Sync eligibility check |
| RedeemPersistorUser | - | EXECUTE | Pre-sync wallet data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletIdsForSync (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.ReceivedTransactionSynced (table)
+-- Wallet.WalletAddresses (table)
+-- Wallet.GuidListType (UDT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Base wallet data |
| Wallet.ReceivedTransactionSynced | Table | Last sync time lookup |
| Wallet.WalletAddresses | Table | Address and balance account |
| Wallet.GuidListType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BalanceUser | Service Account | EXECUTE grant |
| RedeemPersistorUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check sync eligibility for specific wallets
```sql
DECLARE @ids Wallet.GuidListType;
INSERT INTO @ids VALUES ('C0D5EF83-...'), ('A1B2C3D4-...');
EXEC Wallet.GetWalletIdsForSync @WalletIds = @ids;
```

### 8.2 With custom sync threshold
```sql
DECLARE @ids Wallet.GuidListType;
INSERT INTO @ids VALUES ('C0D5EF83-...');
EXEC Wallet.GetWalletIdsForSync @WalletIds = @ids, @UpperLastSync = '2026-04-14 00:00:00';
```

### 8.3 Find wallets that haven't synced in 24 hours
```sql
DECLARE @ids Wallet.GuidListType;
INSERT INTO @ids SELECT Id FROM Wallet.CustomerWalletsView WITH (NOLOCK) WHERE CryptoId = 1;
EXEC Wallet.GetWalletIdsForSync @WalletIds = @ids, @UpperLastSync = DATEADD(HOUR, -24, GETDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletIdsForSync | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletIdsForSync.sql*
