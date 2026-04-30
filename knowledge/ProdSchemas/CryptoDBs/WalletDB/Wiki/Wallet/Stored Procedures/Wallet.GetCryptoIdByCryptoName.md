# Wallet.GetCryptoIdByCryptoName

> Stored procedure that looks up a CryptoId by the cryptocurrency's name/ticker symbol.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CryptoId (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetCryptoIdByCryptoName resolves a cryptocurrency's internal numeric ID from its name/ticker string (e.g., 'BTC' -> 1, 'ETH' -> 2). This is used when external systems or user input provides a crypto by name rather than by numeric ID, and the wallet system needs the ID for further processing.

---

## 2. Business Logic

No complex business logic. Simple SELECT of CryptoId from Wallet.CryptoTypes WHERE Name = @cryptoName. Exact match, case-sensitive per collation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cryptoName | varchar(100) | NO | - | CODE-BACKED | The name/ticker of the cryptocurrency to look up (e.g., 'BTC', 'ETH', 'ADA'). Must match Wallet.CryptoTypes.Name exactly. |
| 2 | CryptoId (result) | int | YES | - | CODE-BACKED | The numeric crypto ID if found, or empty result set if the name doesn't match any configured crypto. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cryptoName | Wallet.CryptoTypes | FROM | Name-to-ID lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Name-to-ID resolution for external inputs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetCryptoIdByCryptoName (procedure)
+-- Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FROM - name lookup |

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

### 8.1 Look up Bitcoin's CryptoId
```sql
EXEC Wallet.GetCryptoIdByCryptoName @cryptoName = 'BTC'
```

### 8.2 Look up Ethereum
```sql
EXEC Wallet.GetCryptoIdByCryptoName @cryptoName = 'ETH'
```

### 8.3 Inline equivalent
```sql
SELECT CryptoId FROM Wallet.CryptoTypes WITH (NOLOCK) WHERE Name = 'BTC'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetCryptoIdByCryptoName | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetCryptoIdByCryptoName.sql*
