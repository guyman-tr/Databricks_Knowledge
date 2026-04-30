# Wallet.GetCryptoMarketRatesMappings

> Stored procedure that returns the mapping between crypto currency IDs and their market rates provider symbols, enabling exchange rate lookups.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Wallet.CryptoMarketRatesMappings rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetCryptoMarketRatesMappings returns the configuration that maps internal crypto currency IDs to the symbol strings used by the market rates provider. Each crypto has a provider-specific symbol (e.g., internal CryptoId 1 maps to the provider symbol 'BTC') used when querying live exchange rates from external market data feeds.

The result includes `IsCrypto = 1` as a constant flag, allowing this to be combined with fiat mappings (from GetFiatMarketRatesMappings where `IsCrypto = 0`) into a unified currency-to-symbol mapping.

---

## 2. Business Logic

No complex business logic. Direct SELECT of Id, CryptoId (aliased as CurrencyId), MarketRatesCurrencySymbol, and a constant `CAST(1 AS BIT) IsCrypto` from Wallet.CryptoMarketRatesMappings.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Primary key of the mapping record. |
| 2 | CurrencyId | int | NO | - | CODE-BACKED | The CryptoId (aliased as CurrencyId for API compatibility with fiat mappings). FK to Wallet.CryptoTypes. |
| 3 | MarketRatesCurrencySymbol | varchar | NO | - | CODE-BACKED | The symbol string used by the market rates provider (e.g., 'BTC', 'ETH', 'ADA'). |
| 4 | IsCrypto | bit | NO | - | CODE-BACKED | Always 1 (hardcoded). Distinguishes crypto mappings from fiat mappings when results are combined. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CryptoMarketRatesMappings | FROM | Market rates symbol mappings for cryptos |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market rates service | - | EXEC | Loads crypto symbol mappings for rate queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetCryptoMarketRatesMappings (procedure)
+-- Wallet.CryptoMarketRatesMappings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoMarketRatesMappings | Table | FROM |

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

### 8.1 Get all crypto market rate mappings
```sql
EXEC Wallet.GetCryptoMarketRatesMappings
```

### 8.2 Combined crypto + fiat mappings
```sql
SELECT Id, CryptoId AS CurrencyId, MarketRatesCurrencySymbol, CAST(1 AS BIT) AS IsCrypto
FROM Wallet.CryptoMarketRatesMappings WITH (NOLOCK)
UNION ALL
SELECT Id, FiatId AS CurrencyId, MarketRatesCurrencySymbol, CAST(0 AS BIT) AS IsCrypto
FROM Wallet.FiatMarketRatesMappings WITH (NOLOCK)
```

### 8.3 Map crypto names to market symbols
```sql
SELECT ct.Name, cmrm.MarketRatesCurrencySymbol
FROM Wallet.CryptoMarketRatesMappings cmrm WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoId = cmrm.CryptoId
WHERE ct.IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetCryptoMarketRatesMappings | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetCryptoMarketRatesMappings.sql*
