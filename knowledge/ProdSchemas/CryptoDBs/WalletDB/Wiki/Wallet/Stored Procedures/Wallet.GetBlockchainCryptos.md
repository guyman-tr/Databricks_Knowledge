# Wallet.GetBlockchainCryptos

> Stored procedure that returns the list of all blockchain networks (layer-1 chains) configured in the system.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Wallet.BlockchainCryptos |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetBlockchainCryptos returns the master list of blockchain networks (layer-1 chains) recognized by the wallet system. Each `BlockchainCrypto` represents a distinct blockchain (e.g., Bitcoin, Ethereum, Solana) that can host one or more crypto assets (tokens). This is distinct from `CryptoTypes` which lists individual assets - a single blockchain (Ethereum) may have many CryptoTypes (ETH, USDT, SHIB, etc.) all sharing the same BlockchainCryptoId.

The data is used by application services for blockchain network configuration, address validation pattern selection, and provider routing.

---

## 2. Business Logic

No complex business logic. Direct SELECT of Id, Name from Wallet.BlockchainCryptos ordered by Id.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Primary key identifying the blockchain network. Referenced by CryptoTypes.BlockchainCryptoId. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Name of the blockchain network (e.g., 'Bitcoin', 'Ethereum', 'Tron'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.BlockchainCryptos | FROM | Reads all blockchain network configurations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Blockchain network configuration loading |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetBlockchainCryptos (procedure)
+-- Wallet.BlockchainCryptos (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.BlockchainCryptos | Table | FROM - reads all blockchain networks |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all blockchain networks
```sql
EXEC Wallet.GetBlockchainCryptos
```

### 8.2 Find crypto assets on a specific blockchain
```sql
SELECT ct.CryptoId, ct.Name AS AssetName, bc.Name AS BlockchainName
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON bc.Id = ct.BlockchainCryptoId
WHERE bc.Name = 'Ethereum'
```

### 8.3 Count assets per blockchain
```sql
SELECT bc.Name, COUNT(ct.CryptoId) AS AssetCount
FROM Wallet.BlockchainCryptos bc WITH (NOLOCK)
LEFT JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.BlockchainCryptoId = bc.Id AND ct.IsActive = 1
GROUP BY bc.Name ORDER BY AssetCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetBlockchainCryptos | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetBlockchainCryptos.sql*
