# Dictionary.GetCurrency

> Filtered view returning only forex instruments (CurrencyTypeID=1) from Dictionary.Currency with a computed bitmask position column.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | View |
| **Key Identifier** | CurrencyID (from Currency) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetCurrency is the forex-specific member of three legacy "asset class filter" views that partition Dictionary.Currency by CurrencyTypeID. This view returns only forex currency pairs — EUR/USD, GBP/JPY, AUD/CHF, etc. — by filtering on CurrencyTypeID = 1. Forex was eToro's original asset class when the platform launched, making this one of the oldest views in the system.

The view computes `ForexType` from the legacy `Mask` bitmask using `CAST((LOG(Mask)/LOG(2)+1) AS SMALLINT)`. The Mask column stores a power-of-2 bitmask (1, 2, 4, 8, 16...) and ForexType extracts the bit position. Modern forex instruments still have Mask values (unlike commodities and indices where Mask is NULL), as the bitmask system originated with forex pairs.

This is a sister view to Dictionary.GetCommodity (type 2) and Dictionary.GetIndices (type 3/4). It is consumed by trading conversion views and pricing components that need the forex pair subset.

---

## 2. Business Logic

### 2.1 Forex Pair Bitmask Identification

**What**: Converts power-of-2 Mask values into sequential ForexType IDs for the legacy trading engine.

**Columns/Parameters Involved**: `Mask`, `ForexType`

**Rules**:
- Formula: `ForexType = CAST((LOG(Mask)/LOG(2)+1) AS SMALLINT)`
- USD (Mask=1)→ForexType=1, EUR (Mask=2)→2, GBP (Mask=4)→3, JPY (Mask=8)→4, etc.
- The ForexType column is referenced by Trade.GetCurrencyConversionsView, Price.GetCrossToMajorConversions, and Trade.GetInstrumentConversions for currency conversion rate calculations
- Forex instruments with Mask=0 (like EURHUF with CurrencyID=-1) produce ForexType=NULL due to LOG(0) being undefined

**Diagram**:
```
Mask (bitmask)  →  ForexType (bit position)
    1           →      1  (USD)
    2           →      2  (EUR)
    4           →      3  (GBP)
    8           →      4  (JPY)
   16           →      5  (AUD)
   32           →      6  (CAD)
   64           →      7  (CHF)
  128           →      8  (NZD)
   ...               ...
```

---

## 3. Data Overview

| CurrencyID | Name | Abbreviation | Mask | ForexType | Meaning |
|---|---|---|---|---|---|
| 1 | United States of America, US Dollar | USD | 1 | 1 | The base currency for most trading calculations — Mask=1 makes it bit position 1 in the legacy engine |
| 2 | European Economic and Monetary Union, Euro | EUR | 2 | 2 | Second major currency — EUR/USD is the most traded forex pair globally |
| 3 | Great Britain, Pound Sterling | GBP | 4 | 3 | Third major currency — GBP pairs are among the most volatile and liquid |
| 4 | Japan, Yen | JPY | 8 | 4 | Safe-haven currency — JPY pairs are critical during risk-off market events |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | VERIFIED | Unique instrument identifier from Dictionary.Currency. For forex, these are typically small integers (1=USD, 2=EUR, 3=GBP, 4=JPY, etc.). Used across all trading, pricing, and conversion operations. |
| 2 | Name | varchar(100) | YES | - | VERIFIED | Full instrument display name including country/region and currency name (e.g., "United States of America, US Dollar"). Inherited from Dictionary.Currency.Name. |
| 3 | Abbreviation | varchar(10) | YES | - | VERIFIED | ISO 4217 currency code (e.g., "USD", "EUR", "GBP", "JPY"). Used in price feeds, API responses, and trading UIs. Inherited from Dictionary.Currency.Abbreviation. |
| 4 | Mask | bigint | YES | - | CODE-BACKED | Power-of-2 bitmask value for legacy bitwise instrument identification: 1=USD, 2=EUR, 4=GBP, 8=JPY, 16=AUD, 32=CAD, 64=CHF, 128=NZD. Each forex currency has a unique bit position. Inherited from Dictionary.Currency.Mask. |
| 5 | ForexType | smallint | YES | - | CODE-BACKED | Computed: `CAST((LOG(Mask)/LOG(2)+1) AS SMALLINT)`. Extracts the 1-based bit position from Mask. Used by Trade.GetCurrencyConversionsView and Price.GetCrossToMajorConversions for conversion rate matrix lookups. NULL when Mask is 0 or NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Base table (filtered) | Source data filtered on CurrencyTypeID = 1 (Forex) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCurrencyConversionsView | ForexType | JOIN | Currency conversion rate matrix using ForexType bit positions |
| Trade.GetInstrumentConversions | ForexType | JOIN | Instrument-level conversion rate lookups |
| Price.GetCrossToMajorConversions | ForexType | JOIN | Cross-rate to major currency conversions |
| Trade.GetMinorConversionRate | ForexType | Function ref | Minor currency conversion rate calculation |
| Trade.GetMinorConversionRateAsk | ForexType | Function ref | Ask-side minor conversion rates |
| OldStyle.GetForexGame | - | FROM | Legacy game view forex instrument access |
| OldStyle.GetCurrency | - | View | Legacy compatibility wrapper |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetCurrency (view)
└── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | Base table — filtered WHERE CurrencyTypeID = 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCurrencyConversionsView | View | Forex conversion matrix |
| Trade.GetInstrumentConversions | View | Instrument conversion lookups |
| Price.GetCrossToMajorConversions | View | Cross-rate calculations |
| Trade.GetMinorConversionRate | Function | Minor conversion rate logic |
| Trade.GetMinorConversionRateAsk | Function | Ask-side conversion rates |
| Trade.GetMoneyConversionsView | View | Money conversion view |
| OldStyle.GetForexGame | View | Legacy game/forex view |
| OldStyle.GetCurrency | View | Legacy compatibility |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Base table Dictionary.Currency has clustered index on CurrencyID.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all forex currency pairs
```sql
SELECT  CurrencyID, Name, Abbreviation, ForexType
FROM    Dictionary.GetCurrency WITH (NOLOCK)
WHERE   Mask > 0
ORDER BY ForexType
```

### 8.2 Find the ForexType for a specific currency
```sql
SELECT  CurrencyID, Abbreviation, Mask, ForexType
FROM    Dictionary.GetCurrency WITH (NOLOCK)
WHERE   Abbreviation = 'EUR'
```

### 8.3 Join with conversion rates using ForexType
```sql
SELECT  gc.Abbreviation, gc.ForexType, gc.Mask
FROM    Dictionary.GetCurrency gc WITH (NOLOCK)
JOIN    Dictionary.CurrencyType ct WITH (NOLOCK) ON ct.CurrencyTypeID = 1
WHERE   gc.Mask IS NOT NULL AND gc.Mask > 0
ORDER BY gc.ForexType
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetCurrency | Type: View | Source: etoro/etoro/Dictionary/Views/Dictionary.GetCurrency.sql*
