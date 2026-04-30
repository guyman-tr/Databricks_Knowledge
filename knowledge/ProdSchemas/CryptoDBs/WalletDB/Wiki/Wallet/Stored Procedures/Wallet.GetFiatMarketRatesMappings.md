# Wallet.GetFiatMarketRatesMappings

> Stored procedure that returns the mapping between fiat currency IDs and their market rates provider symbols, enabling exchange rate lookups.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Wallet.FiatMarketRatesMappings rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetFiatMarketRatesMappings returns the configuration that maps internal fiat currency IDs to the symbol strings used by the market rates provider. This is the fiat counterpart to `GetCryptoMarketRatesMappings` and uses the same output schema with `IsCrypto = 0` to distinguish fiat entries.

---

## 2. Business Logic

No complex business logic. Direct SELECT with `IsCrypto = CAST(0 AS BIT)` constant flag.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Primary key of the mapping record. |
| 2 | CurrencyId | int | NO | - | CODE-BACKED | The FiatId (aliased as CurrencyId for API compatibility). FK to Wallet.FiatTypes. |
| 3 | MarketRatesCurrencySymbol | varchar | NO | - | CODE-BACKED | The symbol string used by the market rates provider (e.g., 'USD', 'EUR', 'GBP'). |
| 4 | IsCrypto | bit | NO | - | CODE-BACKED | Always 0 (hardcoded). Distinguishes fiat from crypto mappings when combined. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.FiatMarketRatesMappings | FROM | Market rates symbol mappings for fiats |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market rates service | - | EXEC | Loads fiat symbol mappings for rate queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetFiatMarketRatesMappings (procedure)
+-- Wallet.FiatMarketRatesMappings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FiatMarketRatesMappings | Table | FROM |

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

### 8.1 Get all fiat market rate mappings
```sql
EXEC Wallet.GetFiatMarketRatesMappings
```

### 8.2 Inline equivalent
```sql
SELECT Id, FiatId AS CurrencyId, MarketRatesCurrencySymbol, CAST(0 AS BIT) AS IsCrypto
FROM Wallet.FiatMarketRatesMappings WITH (NOLOCK)
```

### 8.3 Map fiat names to market symbols
```sql
SELECT ft.FiatName, fmrm.MarketRatesCurrencySymbol
FROM Wallet.FiatMarketRatesMappings fmrm WITH (NOLOCK)
JOIN Wallet.FiatTypes ft WITH (NOLOCK) ON ft.FiatId = fmrm.FiatId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetFiatMarketRatesMappings | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetFiatMarketRatesMappings.sql*
