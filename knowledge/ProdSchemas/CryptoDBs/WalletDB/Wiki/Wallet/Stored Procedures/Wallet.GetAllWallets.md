# Wallet.GetAllWallets

> Returns all customer wallets from the CustomerWalletsView with backward-compatible column aliases for integration with legacy consumers.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns full wallet list from CustomerWalletsView |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete list of customer wallets across all cryptocurrencies and customers. It wraps the CustomerWalletsView with backward-compatible column aliases (e.g., BlockchainProviderWalletId aliased as both itself and ProviderWalletId, WalletRecordId aliased as RecordId). This is used by application services that need a full inventory of customer wallets.

Without this procedure, consumers needing the full wallet list would need to query CustomerWalletsView directly, losing the backward-compatible column names.

The procedure is parameterless and returns all rows with no filtering - this is a full table dump intended for caching or initialization scenarios.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple SELECT wrapper over CustomerWalletsView with column aliases.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID (from CustomerWalletsView). |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency ID. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | Main blockchain address. |
| 5 | BlockchainProviderWalletId | nvarchar(512) | YES | - | CODE-BACKED | Provider's wallet identifier (backward compatibility alias). |
| 6 | ProviderWalletId | nvarchar(512) | YES | - | CODE-BACKED | Same as BlockchainProviderWalletId (new alias name). |
| 7 | Status | - | YES | - | CODE-BACKED | Current wallet status. |
| 8 | Occurred | datetime2 | YES | - | CODE-BACKED | When the status was set. |
| 9 | RecordId | bigint | YES | - | CODE-BACKED | WalletRecordId aliased as RecordId. |
| 10 | BlockchainCryptoId | int | NO | - | CODE-BACKED | Base blockchain crypto ID (e.g., BTC for BTC tokens). |
| 11 | WalletProviderId | int | YES | - | CODE-BACKED | Wallet provider/custodian identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CustomerWalletsView | Reader | Source of all wallet data |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAllWallets (procedure)
  └── Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hint on CustomerWalletsView
- No pagination - returns all rows

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetAllWallets
```

### 8.2 Direct query with filtering
```sql
SELECT Id, Gcid, CryptoId, Address, BlockchainProviderWalletId
FROM Wallet.CustomerWalletsView WITH (NOLOCK)
WHERE Gcid = 12345678
```

### 8.3 Count wallets by crypto
```sql
SELECT CryptoId, COUNT(*) AS WalletCount
FROM Wallet.CustomerWalletsView WITH (NOLOCK)
GROUP BY CryptoId
ORDER BY WalletCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAllWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAllWallets.sql*
