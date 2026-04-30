# Wallet.GetBlockchainCryptoProviders

> Stored procedure that returns the mapping of blockchain networks to their wallet providers, resolving provider names from the Dictionary.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns BlockchainCryptoProviders with resolved names |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetBlockchainCryptoProviders returns the configured relationships between blockchain networks and their wallet infrastructure providers. Each blockchain crypto can be serviced by one or more wallet providers (e.g., Fireblocks, BitGo), and this procedure resolves the provider names from `Dictionary.CryptoCoinProviders` for human-readable output.

This data is used by the wallet routing system to determine which provider handles operations for each blockchain network.

---

## 2. Business Logic

No complex business logic. JOINs BlockchainCryptoProviders to Dictionary.CryptoCoinProviders for name resolution.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BlockchainCryptoId | int | NO | - | CODE-BACKED | The blockchain network ID (FK to BlockchainCryptos). Identifies which chain this provider mapping applies to. |
| 2 | WalletProviderId | int | NO | - | CODE-BACKED | The wallet provider ID (FK to Dictionary.WalletProvider). Identifies which provider services this blockchain. |
| 3 | BlockchainProviderName | varchar | NO | - | CODE-BACKED | Human-readable name of the crypto coin provider (from Dictionary.CryptoCoinProviders.Name). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.BlockchainCryptoProviders | FROM | Blockchain-to-provider mappings |
| CryptoCoinProviderid | Dictionary.CryptoCoinProviders | JOIN | Provider name resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Provider routing configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetBlockchainCryptoProviders (procedure)
+-- Wallet.BlockchainCryptoProviders (table)
+-- Dictionary.CryptoCoinProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.BlockchainCryptoProviders | Table | FROM with NOLOCK |
| Dictionary.CryptoCoinProviders | Table | JOIN for provider name resolution |

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

### 8.1 Get all blockchain provider mappings
```sql
EXEC Wallet.GetBlockchainCryptoProviders
```

### 8.2 Find providers for a specific blockchain
```sql
SELECT bcp.BlockchainCryptoId, bcp.WalletProviderId, ccp.Name AS ProviderName
FROM Wallet.BlockchainCryptoProviders bcp WITH (NOLOCK)
JOIN Dictionary.CryptoCoinProviders ccp WITH (NOLOCK) ON ccp.Id = bcp.CryptoCoinProviderid
WHERE bcp.BlockchainCryptoId = 1  -- Bitcoin blockchain
```

### 8.3 List all blockchains with their provider names
```sql
SELECT bc.Name AS Blockchain, ccp.Name AS Provider
FROM Wallet.BlockchainCryptoProviders bcp WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON bc.Id = bcp.BlockchainCryptoId
JOIN Dictionary.CryptoCoinProviders ccp WITH (NOLOCK) ON ccp.Id = bcp.CryptoCoinProviderid
ORDER BY bc.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetBlockchainCryptoProviders | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetBlockchainCryptoProviders.sql*
