# Wallet.GetWalletsForSync

> Returns base-chain wallets eligible for blockchain synchronization from a specified wallet list, filtered by last sync time, with all addresses aggregated as JSON for the redeem persistor service.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns sync-eligible wallets with JSON addresses by TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns wallets that need blockchain synchronization. Given a list of wallet IDs, it returns base-chain wallets (CryptoId = BlockchainCryptoId) whose last sync time is at or before @UpperLastSync. Each result includes all wallet addresses as a JSON array via STRING_AGG. The redeem persistor service uses this to determine which wallets to sync with the blockchain.

Similar to GetWalletIdsForSync but returns addresses as JSON and uses a simpler result structure. OUTER APPLY to ReceivedTransactionSynced gets the latest sync time; wallets never synced default to '2018-01-01'.

---

## 2. Business Logic

### 2.1 Sync Eligibility by Last Sync Time

**What**: Filters to wallets not synced since the threshold.

**Columns/Parameters Involved**: `@UpperLastSync`, `ReceivedTransactionSynced.LastSynced`

**Rules**:
- Default @UpperLastSync = GETDATE() (all wallets eligible)
- ISNULL(LastSynced, '2018-01-01') for never-synced wallets
- Only base-chain wallets (CryptoId = BlockchainCryptoId)
- Addresses returned as JSON: `["addr1","addr2"]`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletIds | Wallet.GuidListType | NO | - | VERIFIED | TVP of wallet IDs to check. |
| 2 | @UpperLastSync | datetime2(7) | YES | GETDATE() | VERIFIED | Max last-sync threshold. |
| 3 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID. |
| 4 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. |
| 5 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 6 | CryptoId (output) | int | NO | - | CODE-BACKED | Base-chain crypto. |
| 7 | LastSynced (output) | datetime2(7) | YES | - | CODE-BACKED | Last sync time. '2018-01-01' if never synced. |
| 8 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Provider ID. |
| 9 | Addresses (output) | nvarchar(max) | YES | - | CODE-BACKED | JSON array of all wallet addresses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletIds | Wallet.CustomerWalletsView | JOIN | Base wallet data |
| WalletId | Wallet.ReceivedTransactionSynced | OUTER APPLY | Last sync time |
| WalletId | Wallet.WalletAddresses | Subquery | Address JSON aggregation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemPersistorUser | - | EXECUTE | Sync eligibility check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsForSync (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.ReceivedTransactionSynced (table)
+-- Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Base wallet data |
| Wallet.ReceivedTransactionSynced | Table | Last sync time |
| Wallet.WalletAddresses | Table | Address aggregation |

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

### 8.1 Get sync-eligible wallets
```sql
DECLARE @ids Wallet.GuidListType;
INSERT INTO @ids VALUES ('C0D5EF83-...');
EXEC Wallet.GetWalletsForSync @WalletIds = @ids;
```

### 8.2 With custom threshold
```sql
DECLARE @ids Wallet.GuidListType;
INSERT INTO @ids VALUES ('C0D5EF83-...');
EXEC Wallet.GetWalletsForSync @WalletIds = @ids, @UpperLastSync = '2026-04-14';
```

### 8.3 Compare with GetWalletIdsForSync
```sql
-- This SP: returns Addresses as JSON, simpler structure
-- GetWalletIdsForSync: returns BalanceAccountID, Address from WalletAddresses directly
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsForSync | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsForSync.sql*
