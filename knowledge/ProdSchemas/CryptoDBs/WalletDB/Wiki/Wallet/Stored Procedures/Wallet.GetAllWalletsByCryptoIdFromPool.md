# Wallet.GetAllWalletsByCryptoIdFromPool

> Retrieves a paginated batch of wallet pool entries for a specific cryptocurrency, used for iterating through the pool during checksum validation, funding verification, or inventory audits.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated WalletPool rows filtered by BlockchainCryptoId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides paginated access to the wallet pool for a specific cryptocurrency. The wallet pool contains pre-generated blockchain wallets awaiting assignment to customers. Operations and maintenance processes iterate through the pool by crypto to verify checksums, check funding status, or audit pool inventory.

Without this procedure, batch operations on crypto-specific pool wallets would need to load the entire pool, which is impractical at scale.

The keyset pagination pattern (Id > @IdGreaterThan) provides efficient, consistent paging through the pool.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple paginated SELECT with crypto filter.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IdGreaterThan | bigint | NO | - | CODE-BACKED | Keyset pagination cursor. Pass 0 for the first page, then the last returned Id for subsequent pages. |
| 2 | @MaxRecords | int | NO | - | CODE-BACKED | Maximum number of records to return per page. |
| 3 | @CryptoId | int | NO | - | CODE-BACKED | BlockchainCryptoId to filter pool wallets by. Only wallets for this blockchain are returned. |

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
Wallet.GetAllWalletsByCryptoIdFromPool (procedure)
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
- TOP(@MaxRecords) with ORDER BY Id for keyset pagination

---

## 8. Sample Queries

### 8.1 Get first page of BTC pool wallets
```sql
EXEC Wallet.GetAllWalletsByCryptoIdFromPool @IdGreaterThan = 0, @MaxRecords = 100, @CryptoId = 1
```

### 8.2 Count pool wallets by blockchain crypto
```sql
SELECT BlockchainCryptoId, COUNT(*) AS PoolCount
FROM Wallet.WalletPool WITH (NOLOCK)
GROUP BY BlockchainCryptoId
```

### 8.3 Get next page after a specific ID
```sql
EXEC Wallet.GetAllWalletsByCryptoIdFromPool @IdGreaterThan = 5000, @MaxRecords = 100, @CryptoId = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAllWalletsByCryptoIdFromPool | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAllWalletsByCryptoIdFromPool.sql*
