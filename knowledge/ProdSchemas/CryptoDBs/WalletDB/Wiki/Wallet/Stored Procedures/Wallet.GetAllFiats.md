# Wallet.GetAllFiats

> Stored procedure that returns all fiat currency configurations from the FiatTypes table, ordered by FiatId.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Wallet.FiatTypes |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetAllFiats returns the complete list of fiat currencies configured in the wallet system. This includes each currency's internal ID, standard identifier (FiatId), display name, associated trading instrument, active status, avatar URL, decimal precision, and ISO numeric code. The data is used by application services to populate fiat currency dropdowns, validate fiat operations, and configure display formatting.

The procedure reads from `Wallet.FiatTypes` with NOLOCK and returns all rows ordered by FiatId. It does NOT filter on IsActive - callers receive both active and inactive fiats and must filter client-side if needed.

---

## 2. Business Logic

No complex business logic. Direct SELECT of all columns from Wallet.FiatTypes ordered by FiatId.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Internal auto-increment primary key of the FiatTypes record. |
| 2 | FiatId | tinyint | NO | - | CODE-BACKED | Fiat currency identifier used across the system. Maps to standard currency IDs (e.g., 1=USD, 2=EUR, 3=GBP). |
| 3 | FiatName | varchar | NO | - | CODE-BACKED | Display name of the fiat currency (e.g., 'USD', 'EUR', 'GBP'). |
| 4 | InstrumentId | int | YES | - | CODE-BACKED | Associated trading instrument ID for this fiat pair. Links to Wallet.Instruments for exchange rate lookups. |
| 5 | IsActive | bit | NO | - | CODE-BACKED | Whether this fiat currency is currently active for new operations. |
| 6 | AvatarUrl | varchar | YES | - | CODE-BACKED | URL to the fiat currency's display icon/avatar for UI rendering. |
| 7 | Precision | int | YES | - | CODE-BACKED | Number of decimal places for display and rounding of this fiat currency. |
| 8 | NumericCode | smallint | YES | - | CODE-BACKED | ISO 4217 numeric currency code (e.g., 840=USD, 978=EUR). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.FiatTypes | FROM | Reads all fiat currency configurations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Fiat currency configuration loading at startup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAllFiats (procedure)
+-- Wallet.FiatTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FiatTypes | Table | FROM - reads all fiat currency configurations |

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

### 8.1 Get all fiat currencies
```sql
EXEC Wallet.GetAllFiats
```

### 8.2 Get only active fiats
```sql
SELECT Id, FiatId, FiatName, InstrumentId, Precision, NumericCode
FROM Wallet.FiatTypes WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY FiatId
```

### 8.3 Look up a specific fiat by name
```sql
SELECT * FROM Wallet.FiatTypes WITH (NOLOCK) WHERE FiatName = 'USD'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAllFiats | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAllFiats.sql*
