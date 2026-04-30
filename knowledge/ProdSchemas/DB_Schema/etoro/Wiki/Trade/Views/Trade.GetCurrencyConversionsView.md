# Trade.GetCurrencyConversionsView

> Maps each non-USD currency to its conversion instrument (forex pair vs USD) and a reciprocal flag. Used for converting position values and P&L to USD.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | CurrencyID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCurrencyConversionsView defines how every non-USD currency converts to USD for pricing and P&L. Each row maps a Dictionary.Currency (CurrencyID) to the Trade.Instrument that represents the conversion rate: either Currency/USD (e.g., EUR/USD) or USD/Currency (e.g., USD/JPY). The IsReciprocal flag indicates whether the instrument's rate must be inverted to get "currency per USD."

The view exists because the trading engine must convert amounts in any currency to USD for aggregation, margin, and reporting. Procedures like Trade.GetInstrumentsRates, Trade.GetCurrencyConversions, Trade.GetProviderToInstrumentData, Trade.InsertBSLMessagesIntoQueue, and Trade.ManualModifySLForCriptoPositions JOIN to this view to resolve conversion instruments.

Data flows: The view UNIONs two patterns. Branch 1: currencies where BuyCurrencyID=Currency and SellCurrencyID=1 (USD) - direct pair like EUR/USD. Branch 2: currencies where SellCurrencyID=Currency and BuyCurrencyID=1 (USD) - inverse pair like USD/JPY. ConversionCurrencyID is always 1 (USD). CurrencyID 0 and 1 are excluded (0=placeholder, 1=USD needs no conversion).

---

## 2. Business Logic

### 2.1 Conversion Instrument Selection

**What**: Trade.Instrument defines buy/sell currency pairs. The view finds the instrument that converts a currency to USD.

**Columns/Parameters Involved**: `BuyCurrencyID`, `SellCurrencyID`, `ConversionInstrumentID`

**Rules**:
- **Direct pair** (Branch 1): Instrument has BuyCurrencyID=Currency, SellCurrencyID=1. Rate is "Currency per USD" (e.g., EUR/USD). IsReciprocal=0.
- **Inverse pair** (Branch 2): Instrument has SellCurrencyID=Currency, BuyCurrencyID=1. Rate is "USD per Currency" (e.g., USD/JPY). IsReciprocal=1 when SellCurrencyID <> 1.

**Diagram**:
```
EUR (CurrencyID=2) -> Instrument EUR/USD (Buy=EUR, Sell=USD) -> IsReciprocal=0, rate = EUR per 1 USD
JPY (CurrencyID=4) -> Instrument USD/JPY (Buy=USD, Sell=JPY) -> IsReciprocal=1, rate = USD per 1 JPY
```

### 2.2 IsReciprocal Computation

**What**: Indicates whether the conversion rate must be inverted when converting to USD.

**Columns/Parameters Involved**: `IsReciprocal`, `SellCurrencyID`

**Rules**:
- IsReciprocal = CASE WHEN SellCurrencyID = 1 THEN 0 ELSE 1 END.
- When SellCurrencyID=1 (USD is quote), the instrument rate is "currency per USD" - use directly. IsReciprocal=0.
- When SellCurrencyID <> 1 (USD is base), the instrument rate is "USD per currency" - invert for "currency per USD". IsReciprocal=1.

---

## 3. Data Overview

| CurrencyID | ConversionCurrencyID | ConversionInstrumentID | IsReciprocal | Meaning |
|---|---|---|---|---|
| 10029 | 1 | 10029 | 0 | Currency 10029 converts via Instrument 10029. Direct pair (e.g., XXX/USD). IsReciprocal=0. |
| 10030 | 1 | 10030 | 0 | Same pattern - each currency maps to its conversion instrument. |
| 10031 | 1 | 10031 | 0 | ConversionInstrumentID often equals CurrencyID for direct pairs. |
| 10032 | 1 | 10032 | 0 | All rows have ConversionCurrencyID=1 (USD). |
| 10033 | 1 | 10033 | 0 | Sample shows variety of currency-to-instrument mappings. |

**Selection criteria**: From live MCP sample. All IsReciprocal=0 in this sample; inverse pairs (e.g., USD/JPY) would have IsReciprocal=1.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. The currency to convert. Excludes 0 and 1 (USD). (From Dictionary.Currency) |
| 2 | ConversionCurrencyID | int | NO | - | CODE-BACKED | View-computed: always 1 (USD). Target currency for conversion. |
| 3 | ConversionInstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The instrument providing the conversion rate (forex pair vs USD). (From Trade.Instrument) |
| 4 | IsReciprocal | int | NO | - | CODE-BACKED | Computed: CASE WHEN i.SellCurrencyID = 1 THEN 0 ELSE 1 END. 0 = use rate directly; 1 = invert rate for "currency per USD". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Lookup | Source currency to convert. |
| ConversionCurrencyID | Dictionary.Currency | Implicit | Always 1 (USD). |
| ConversionInstrumentID | Trade.Instrument | Lookup | Instrument defining the conversion rate. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCurrencyConversions | Procedure | SELECT | Returns full conversion mapping. |
| Trade.GetInstrumentsRates | Procedure | JOIN | Resolution of conversion instruments. |
| Trade.GetProviderToInstrumentData | Procedure | JOIN | Instrument data with conversion info. |
| Trade.InsertBSLMessagesIntoQueue | Procedure | LEFT JOIN | Conversion for BSL messages. |
| Trade.ManualModifySLForCriptoPositions | Procedure | LEFT JOIN | Crypto position SL modification. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCurrencyConversionsView (view)
├── Dictionary.Currency (table)
└── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | FROM - source of CurrencyID (INNER JOIN) |
| Trade.Instrument | Table | FROM - INNER JOIN on (BuyCurrencyID, SellCurrencyID) with USD (1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCurrencyConversions | Procedure | SELECT |
| Trade.GetInstrumentsRates | Procedure | FROM |
| Trade.GetProviderToInstrumentData | Procedure | INNER JOIN |
| Trade.InsertBSLMessagesIntoQueue | Procedure | LEFT JOIN |
| Trade.ManualModifySLForCriptoPositions | Procedure | LEFT JOIN |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All currency conversion mappings
```sql
SELECT CurrencyID, ConversionCurrencyID, ConversionInstrumentID, IsReciprocal
  FROM Trade.GetCurrencyConversionsView WITH (NOLOCK)
 ORDER BY CurrencyID;
```

### 8.2 Conversion mapping with currency abbreviation
```sql
SELECT c.CurrencyID, dc.Abbreviation AS CurrencyCode, c.ConversionInstrumentID, c.IsReciprocal
  FROM Trade.GetCurrencyConversionsView c WITH (NOLOCK)
  JOIN Dictionary.Currency dc WITH (NOLOCK) ON c.CurrencyID = dc.CurrencyID
 WHERE c.CurrencyID IN (2, 4, 666)
 ORDER BY c.CurrencyID;
```

### 8.3 Reciprocal vs direct conversion instruments
```sql
SELECT IsReciprocal, COUNT(*) AS CurrencyCount
  FROM Trade.GetCurrencyConversionsView WITH (NOLOCK)
 GROUP BY IsReciprocal
 ORDER BY IsReciprocal;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCurrencyConversionsView | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetCurrencyConversionsView.sql*
