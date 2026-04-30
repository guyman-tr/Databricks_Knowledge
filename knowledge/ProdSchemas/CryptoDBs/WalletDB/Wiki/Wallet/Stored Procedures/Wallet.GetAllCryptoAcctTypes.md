# Wallet.GetAllCryptoAcctTypes

> Stored procedure that returns all active cryptocurrency configurations from CryptoTypes, providing the minimum wallet pool requirements per crypto.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns active CryptoTypes rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetAllCryptoAcctTypes returns the list of active cryptocurrencies with their minimum required wallet account counts. This data is used by the wallet pool management system to ensure that enough pre-generated wallets are available in the pool for each supported cryptocurrency. The `MinReqAccounts` value determines the minimum pool size target for each crypto.

Only active cryptos (`IsActive=1`) are returned, filtering out decommissioned or disabled currencies.

---

## 2. Business Logic

No complex business logic. Simple SELECT of CryptoID, Name, MinReqAccounts from Wallet.CryptoTypes WHERE IsActive=1.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CryptoID | int | NO | - | CODE-BACKED | Cryptocurrency identifier. Common values: 1=BTC, 2=ETH, 3=LTC. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Short name/ticker of the cryptocurrency (e.g., 'BTC', 'ETH', 'ADA'). |
| 3 | MinReqAccounts | int | NO | - | CODE-BACKED | Minimum number of pre-generated wallet accounts that must be available in the wallet pool for this crypto. Used by pool management to trigger wallet generation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CryptoTypes | FROM | Reads active crypto configurations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet pool management | - | EXEC | Determines pool size requirements per crypto |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAllCryptoAcctTypes (procedure)
+-- Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FROM - filtered to IsActive=1 |

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

### 8.1 Get all active crypto account types
```sql
EXEC Wallet.GetAllCryptoAcctTypes
```

### 8.2 Find cryptos needing large pool sizes
```sql
SELECT CryptoID, Name, MinReqAccounts
FROM Wallet.CryptoTypes WITH (NOLOCK)
WHERE IsActive = 1 AND MinReqAccounts > 100
ORDER BY MinReqAccounts DESC
```

### 8.3 Compare pool requirements vs actual pool counts
```sql
SELECT ct.CryptoID, ct.Name, ct.MinReqAccounts,
    (SELECT COUNT(*) FROM Wallet.WalletPool wp WITH (NOLOCK)
     WHERE wp.CryptoId = ct.CryptoID AND wp.WalletPoolStatusId = 1) AS FreeInPool
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
WHERE ct.IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAllCryptoAcctTypes | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAllCryptoAcctTypes.sql*
