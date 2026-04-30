# Trade.GetMinorConversionRate

> Returns the bid-side currency conversion rate to convert an instrument's sell-currency price into USD, using the currency conversion view and live price data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DECIMAL(16,8) - conversion rate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMinorConversionRate converts a trading instrument's sell-currency price into USD by looking up the appropriate conversion instrument and returning the bid-side rate. "Minor" refers to the instrument's sell currency (the quote/counter currency in a forex pair). This rate enables converting position values denominated in non-USD currencies into USD for platform-wide calculations.

This function exists because instruments trade in various currency pairs, but many internal calculations (take-profit projections, tree-level P&L aggregation) need values expressed in USD. When an instrument's sell currency is already USD (SellCurrencyID=1), the conversion rate is simply 1.0. Otherwise, the function looks up the conversion instrument via GetCurrencyConversionsView and fetches the live bid price.

The function is consumed by Trade.ChangeTreeInfoPerInstrument, Trade.OldAndNewTakeProfitPerInstrumentID, and Trade.UpdatePositionsTakeProfitByInstrumentID for take-profit and tree-level calculations.

---

## 2. Business Logic

### 2.1 USD Short-Circuit

**What**: If the instrument's sell currency is already USD, no conversion is needed.

**Columns/Parameters Involved**: `@InstrumentID`, `Trade.Instrument.SellCurrencyID`

**Rules**:
- SellCurrencyID = 1 (USD) -> return 1.0 (no conversion needed)
- SellCurrencyID != 1 -> look up conversion instrument and return bid rate (direct or reciprocal)
- IsReciprocal = 1 -> return 1/Bid (invert the rate)
- IsReciprocal = 0 -> return Bid directly

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The trading instrument whose sell currency needs conversion to USD. Looked up in Trade.Instrument for SellCurrencyID. |
| 2 | Return value | DECIMAL(16,8) | YES | - | CODE-BACKED | Bid-side conversion rate to USD. 1.0 when sell currency is already USD. NULL if no conversion path exists (LEFT JOIN returns no match). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Instrument | FROM/WHERE | Lookups SellCurrencyID for the traded instrument |
| SellCurrencyID | Trade.GetCurrencyConversionsView | LEFT JOIN | Maps sell currency to conversion instrument |
| ConversionInstrumentID | Trade.CurrencyPrice | LEFT JOIN | Fetches live bid price for conversion instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ChangeTreeInfoPerInstrument | Function call | Scalar call | Tree-level take-profit conversions |
| Trade.OldAndNewTakeProfitPerInstrumentID | Function call | Scalar call | Take-profit comparison calculations |
| Trade.UpdatePositionsTakeProfitByInstrumentID | Function call | Procedure call | Bulk take-profit updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMinorConversionRate (function)
  ├── Trade.Instrument (table)
  ├── Trade.GetCurrencyConversionsView (view)
  └── Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM for SellCurrencyID lookup |
| Trade.GetCurrencyConversionsView | View | LEFT JOIN for conversion instrument resolution |
| Trade.CurrencyPrice | Table | LEFT JOIN for live bid price |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ChangeTreeInfoPerInstrument | Function | Scalar call for conversion |
| Trade.OldAndNewTakeProfitPerInstrumentID | Function | Scalar call for TP calculations |
| Trade.UpdatePositionsTakeProfitByInstrumentID | Procedure | Scalar call for TP updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS DECIMAL(16,8) | Return type | Scalar function returning conversion rate with 8 decimal precision |
| WITH (NOLOCK) | Read hint | All table reads use NOLOCK |

---

## 8. Sample Queries

### 8.1 Get conversion rate for a specific instrument

```sql
SELECT Trade.GetMinorConversionRate(1001) AS ConversionRateToUSD;
```

### 8.2 Show conversion rates for multiple instruments

```sql
SELECT  i.InstrumentID,
        i.SymbolFull,
        Trade.GetMinorConversionRate(i.InstrumentID) AS ConvRate
FROM    Trade.Instrument i WITH (NOLOCK)
WHERE   i.InstrumentID IN (1, 5, 1001, 100001);
```

### 8.3 Compare bid vs ask conversion rates

```sql
SELECT  i.InstrumentID,
        i.SymbolFull,
        Trade.GetMinorConversionRate(i.InstrumentID) AS BidConvRate,
        ask_rate.ConversionRate AS AskConvRate
FROM    Trade.Instrument i WITH (NOLOCK)
        CROSS APPLY Trade.GetMinorConversionRateAsk(i.InstrumentID) ask_rate
WHERE   i.InstrumentID IN (1, 5, 1001);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMinorConversionRate | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetMinorConversionRate.sql*
