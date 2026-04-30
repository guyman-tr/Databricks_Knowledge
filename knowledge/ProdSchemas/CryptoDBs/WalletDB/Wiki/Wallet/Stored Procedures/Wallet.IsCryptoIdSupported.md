# Wallet.IsCryptoIdSupported

> Stored procedure that checks whether a given CryptoId exists in the CryptoTypes table, returning 1 (supported) or 0 (not supported) via RETURN code.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns int via RETURN (1=supported, 0=not) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.IsCryptoIdSupported is a simple validation check that determines whether a given cryptocurrency ID is recognized by the wallet system. It checks for the existence of the CryptoId in `Wallet.CryptoTypes` - the master list of all configured cryptocurrencies.

This procedure is used by application services as a guard before processing crypto-related operations. If a CryptoId is not in CryptoTypes (e.g., a decommissioned or invalid crypto), the operation should be rejected.

Note: this procedure does NOT check `IsActive` status - it returns 1 for any CryptoId that exists in the table, even inactive ones. To check for actively tradeable cryptos, callers should use `Wallet.GetAllCryptoAcctTypes` which filters `WHERE IsActive=1`.

---

## 2. Business Logic

No complex business logic. Simple EXISTS check against Wallet.CryptoTypes by CryptoID, returning RETURN code 1 or 0.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cryptoID | int | NO | - | CODE-BACKED | The cryptocurrency ID to validate against Wallet.CryptoTypes. Common values: 1=BTC, 2=ETH, 3=XRP, etc. |
| 2 | RETURN | int | NO | - | CODE-BACKED | Return code: 1 if CryptoId exists in Wallet.CryptoTypes, 0 if not found. Accessed via `EXEC @result = Wallet.IsCryptoIdSupported @cryptoID`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cryptoID | Wallet.CryptoTypes | EXISTS check | Validates CryptoId against the master crypto configuration table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Input validation before crypto operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.IsCryptoIdSupported (procedure)
+-- Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | EXISTS check on CryptoID column |

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

### 8.1 Check if Bitcoin is supported
```sql
DECLARE @result INT
EXEC @result = Wallet.IsCryptoIdSupported @cryptoID = 1
SELECT @result AS IsSupported  -- Returns 1 (BTC is supported)
```

### 8.2 Check an invalid crypto ID
```sql
DECLARE @result INT
EXEC @result = Wallet.IsCryptoIdSupported @cryptoID = 99999
SELECT @result AS IsSupported  -- Returns 0 (not found)
```

### 8.3 Equivalent inline query
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM Wallet.CryptoTypes WITH (NOLOCK) WHERE CryptoID = 1) THEN 1 ELSE 0 END AS IsSupported
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.IsCryptoIdSupported | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.IsCryptoIdSupported.sql*
