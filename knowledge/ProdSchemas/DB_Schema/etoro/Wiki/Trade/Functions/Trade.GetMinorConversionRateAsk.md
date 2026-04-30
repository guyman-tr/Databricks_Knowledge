# Trade.GetMinorConversionRateAsk

> Returns the ask-side currency conversion rate to convert an instrument's sell-currency price into USD, with divide-by-zero protection for reciprocal calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with single column `ConversionRate` (DECIMAL(16,8)) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMinorConversionRateAsk is the ask-side counterpart to Trade.GetMinorConversionRate. It converts a trading instrument's sell-currency price into USD using the ask price rather than the bid price. The ask-side rate is needed when the conversion direction requires the "buying" price of the conversion currency (e.g., when converting fees, spreads, or unfavorable-direction conversions).

This function exists as an inline TVF (unlike the scalar GetMinorConversionRate) and includes explicit divide-by-zero protection: when the ask price is 0 for a reciprocal conversion, it safely returns NULL rather than causing an arithmetic error. This protection was added per bug fix FB:51857.

The function uses the same resolution logic as its bid-side counterpart: if the instrument's sell currency is USD (SellCurrencyID=1), it returns 1.0. Otherwise, it looks up the conversion instrument via GetCurrencyConversionsView and fetches the live ask price from CurrencyPrice.

---

## 2. Business Logic

### 2.1 Ask-Side Conversion with Zero Protection

**What**: Computes conversion rate using ask prices with explicit divide-by-zero safety for reciprocal conversions.

**Columns/Parameters Involved**: `@InstrumentID`, `Trade.Instrument.SellCurrencyID`, `CurrencyPrice.Ask`, `IsReciprocal`

**Rules**:
- SellCurrencyID = 1 (USD) -> return 1.0
- SellCurrencyID != 1 AND IsReciprocal = 1 AND Ask > 0 -> return 1/Ask
- SellCurrencyID != 1 AND IsReciprocal = 1 AND Ask = 0 -> returns NULL (divide-by-zero protection, FB:51857)
- SellCurrencyID != 1 AND IsReciprocal = 0 -> return Ask directly

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The trading instrument whose sell currency needs ask-side conversion to USD. Looked up in Trade.Instrument for SellCurrencyID. |
| 2 | ConversionRate (return) | DECIMAL(16,8) | YES | - | CODE-BACKED | Ask-side conversion rate to USD. 1.0 when sell currency is USD. NULL if no conversion path exists or if reciprocal ask price is 0 (divide-by-zero protection). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Instrument | FROM/WHERE | Lookups SellCurrencyID for the traded instrument |
| SellCurrencyID | Trade.GetCurrencyConversionsView | LEFT JOIN | Maps sell currency to conversion instrument |
| ConversionInstrumentID | Trade.CurrencyPrice | LEFT JOIN | Fetches live ask price for conversion instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (discovered via codebase search) | CROSS APPLY | Various | Used wherever ask-side conversion is needed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMinorConversionRateAsk (function)
  ├── Trade.Instrument (table)
  ├── Trade.GetCurrencyConversionsView (view)
  └── Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM for SellCurrencyID lookup |
| Trade.GetCurrencyConversionsView | View | LEFT JOIN for conversion instrument resolution |
| Trade.CurrencyPrice | Table | LEFT JOIN for live ask price |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Consumers share pattern with GetMinorConversionRate) | Various | Ask-side conversion for fees, spreads, and adverse-direction calculations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning single ConversionRate column |
| WITH (NOLOCK) | Read hint | All table reads use NOLOCK |
| Ask > 0 check | Safety | Prevents divide-by-zero on reciprocal ask (FB:51857) |

---

## 8. Sample Queries

### 8.1 Get ask-side conversion rate for a specific instrument

```sql
SELECT  ConversionRate
FROM    Trade.GetMinorConversionRateAsk(1001);
```

### 8.2 Compare bid vs ask conversion rates

```sql
SELECT  i.InstrumentID,
        i.SymbolFull,
        Trade.GetMinorConversionRate(i.InstrumentID) AS BidRate,
        ask_rate.ConversionRate AS AskRate,
        ask_rate.ConversionRate - Trade.GetMinorConversionRate(i.InstrumentID) AS Spread
FROM    Trade.Instrument i WITH (NOLOCK)
        CROSS APPLY Trade.GetMinorConversionRateAsk(i.InstrumentID) ask_rate
WHERE   i.InstrumentID IN (1, 5, 1001);
```

### 8.3 Find instruments where ask conversion rate is NULL (potential issues)

```sql
SELECT  i.InstrumentID,
        i.SymbolFull,
        i.SellCurrencyID,
        ask_rate.ConversionRate
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
        JOIN Trade.Instrument i WITH (NOLOCK) ON imd.InstrumentID = i.InstrumentID
        CROSS APPLY Trade.GetMinorConversionRateAsk(i.InstrumentID) ask_rate
WHERE   imd.Tradable = 1
        AND ask_rate.ConversionRate IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Divide-by-zero fix referenced as FB:51857.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMinorConversionRateAsk | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.GetMinorConversionRateAsk.sql*
