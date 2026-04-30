# Wallet.GetWalletPoolByWalletId

> Retrieves a wallet pool entry by its WalletId, returning the pool record's identity, blockchain crypto, provider details, and public address for the executer service.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns WalletPool row by WalletId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a wallet pool record by its WalletId (the GUID that identifies the pool wallet). Pool wallets are pre-created wallets held in reserve for quick assignment to customers. The executer service uses this to look up pool wallet details during wallet assignment and funding operations.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct single-table read from WalletPool by WalletId.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Pool wallet's GUID to look up. |
| 2 | Id (output) | bigint | NO | - | CODE-BACKED | WalletPool record ID. |
| 3 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Echo of the pool wallet GUID. |
| 4 | BlockchainCryptoId (output) | int | NO | - | CODE-BACKED | Base-chain crypto this pool wallet serves. |
| 5 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Blockchain provider's reference for this wallet. |
| 6 | PublicAddress (output) | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address of this pool wallet. |
| 7 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Wallet infrastructure provider. FK to Wallet.WalletProviders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId | Wallet.WalletPool.WalletId | Lookup | Pool wallet record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Pool wallet lookup during operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletPoolByWalletId (procedure)
+-- Wallet.WalletPool (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | Lookup by WalletId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up a pool wallet
```sql
EXEC Wallet.GetWalletPoolByWalletId @WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678';
```

### 8.2 Direct equivalent
```sql
SELECT Id, WalletId, BlockchainCryptoId, ProviderWalletId, PublicAddress, WalletProviderId
FROM Wallet.WalletPool WITH (NOLOCK) WHERE WalletId = 'C0D5EF83-...';
```

### 8.3 Check pool wallet status
```sql
SELECT wp.WalletId, wps.WalletPoolStatusId
FROM Wallet.WalletPool wp WITH (NOLOCK)
    CROSS APPLY (SELECT TOP 1 WalletPoolStatusId FROM Wallet.WalletPoolStatuses WHERE WalletPoolId = wp.Id ORDER BY Id DESC) wps
WHERE wp.WalletId = 'C0D5EF83-...';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletPoolByWalletId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletPoolByWalletId.sql*
