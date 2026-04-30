# Wallet.GetCryptoProvidersContract

> Stored procedure that returns all crypto provider contract configurations including denomination, unit sizes, ticker symbols, and dust thresholds.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Wallet.CryptoProviderContract rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetCryptoProvidersContract returns the complete provider contract configuration for all crypto assets. Each contract defines how a specific cryptocurrency interacts with its wallet infrastructure provider, including denomination units, tick sizes, environment-specific ticker symbols (production vs test), and the minimum dust threshold below which transactions are economically unviable.

---

## 2. Business Logic

No complex business logic. Direct SELECT of all columns from Wallet.CryptoProviderContract.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Primary key of the contract record. |
| 2 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency ID (FK to Wallet.CryptoTypes). |
| 3 | ProviderId | int | NO | - | CODE-BACKED | Wallet provider ID (FK to Dictionary.WalletProvider). |
| 4 | Denomination | varchar | YES | - | CODE-BACKED | Unit denomination for the crypto (e.g., 'satoshi', 'wei', 'lovelace'). |
| 5 | Units | decimal | YES | - | CODE-BACKED | Base unit conversion factor (e.g., 100000000 for satoshi-to-BTC). |
| 6 | ProdEnvTicker | varchar | YES | - | CODE-BACKED | Ticker symbol used in production environment by the wallet provider. |
| 7 | TestEnvTicker | varchar | YES | - | CODE-BACKED | Ticker symbol used in test/staging environment. |
| 8 | DustThreshold | decimal | YES | - | CODE-BACKED | Minimum transaction amount below which the transaction is considered "dust" and economically unviable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CryptoProviderContract | FROM | Provider contract configurations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Provider contract configuration loading |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetCryptoProvidersContract (procedure)
+-- Wallet.CryptoProviderContract (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoProviderContract | Table | FROM |

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

### 8.1 Get all provider contracts
```sql
EXEC Wallet.GetCryptoProvidersContract
```

### 8.2 Find BTC provider contracts
```sql
SELECT * FROM Wallet.CryptoProviderContract WITH (NOLOCK) WHERE CryptoId = 1
```

### 8.3 Contracts with dust thresholds
```sql
SELECT CryptoId, ProviderId, ProdEnvTicker, DustThreshold
FROM Wallet.CryptoProviderContract WITH (NOLOCK)
WHERE DustThreshold IS NOT NULL
ORDER BY CryptoId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetCryptoProvidersContract | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetCryptoProvidersContract.sql*
