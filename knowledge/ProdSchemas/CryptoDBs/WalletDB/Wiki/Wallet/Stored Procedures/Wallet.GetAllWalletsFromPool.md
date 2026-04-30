# Wallet.GetAllWalletsFromPool

> Retrieves a paginated batch of all wallet pool entries across all cryptocurrencies, including the wallet provider ID, for pool-wide iteration during audits, checksum validation, or status monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated WalletPool rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides paginated access to the entire wallet pool across all cryptocurrencies. Similar to GetAllWalletsByCryptoIdFromPool but without a crypto filter, and additionally returns WalletProviderId. Used for cross-crypto pool operations like full inventory audits, checksum batch processing, or provider-level reporting.

Without this procedure, cross-crypto pool operations would need separate queries per cryptocurrency.

Uses the same keyset pagination pattern (Id > @IdGreaterThan) for efficient traversal.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple paginated SELECT.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IdGreaterThan | bigint | NO | - | CODE-BACKED | Keyset pagination cursor. Pass 0 for the first page. |
| 2 | @MaxRecords | int | NO | - | CODE-BACKED | Maximum records per page. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletPool | Reader | Source of pool wallet data |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAllWalletsFromPool (procedure)
  └── Wallet.WalletPool (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hint, SET NOCOUNT ON
- TOP(@MaxRecords) with ORDER BY Id

---

## 8. Sample Queries

### 8.1 Get first page of all pool wallets
```sql
EXEC Wallet.GetAllWalletsFromPool @IdGreaterThan = 0, @MaxRecords = 100
```

### 8.2 Pool inventory by provider
```sql
SELECT WalletProviderId, BlockchainCryptoId, COUNT(*) AS Cnt
FROM Wallet.WalletPool WITH (NOLOCK)
GROUP BY WalletProviderId, BlockchainCryptoId
ORDER BY WalletProviderId, BlockchainCryptoId
```

### 8.3 Next page from specific cursor
```sql
EXEC Wallet.GetAllWalletsFromPool @IdGreaterThan = 10000, @MaxRecords = 100
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAllWalletsFromPool | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAllWalletsFromPool.sql*
