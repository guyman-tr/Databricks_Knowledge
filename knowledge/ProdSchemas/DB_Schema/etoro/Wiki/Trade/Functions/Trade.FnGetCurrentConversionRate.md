# Trade.FnGetCurrentConversionRate

> Returns the current live currency conversion rate for converting a position's PnL from instrument currency to account currency, selecting the appropriate bid/ask price based on direction, real/CFD classification, and reciprocal flag.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with ConversionRate (decimal), PriceRateID (bigint) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnGetCurrentConversionRate returns the live currency conversion rate needed to convert a position's PnL from the instrument's native currency into the customer's account denomination currency. The rate selection depends on whether the conversion instrument is reciprocal, whether the position is real or CFD, and the trade direction.

This function is essential for multi-currency PnL calculation. A customer with a EUR account trading USD/JPY needs a conversion rate from JPY to EUR. The function chains Trade.FnGetConversionInstrument (to find the bridge instrument) and Trade.FnIsRealPosition (to determine pricing tier), then reads the appropriate price from Trade.CurrencyPrice.

It feeds directly into Trade.FnCalculateCurrentPnL and Trade.FnCalculatePnLByRates as the @EndConversionRate parameter.

---

## 2. Business Logic

### 2.1 Conversion Rate Selection Matrix

**What**: 9-way CASE selects the correct price based on self-conversion, reciprocal flag, real/CFD, and direction.

**Columns/Parameters Involved**: `@InstrumentID`, `@AccountCurrencyID`, `@IsBuy`, `@IsSettled`, `ConversionInstrumentID`, `IsReciprocal`, `IsRealPosition`

**Rules**:
- **Self-conversion (ConversionInstrumentID = @InstrumentID AND IsReciprocal=0)**: Return 1 (no conversion needed, instrument trades directly in account currency)
- **Reciprocal=1, Real, Buy**: 1/BidDiscounted
- **Reciprocal=1, CFD, Buy**: 1/Bid
- **Reciprocal=1, Real, Sell**: 1/AskDiscounted
- **Reciprocal=1, CFD, Sell**: 1/Ask
- **Reciprocal=0, Real, Buy**: BidDiscounted
- **Reciprocal=0, CFD, Buy**: Bid
- **Reciprocal=0, Real, Sell**: AskDiscounted
- **Reciprocal=0, CFD, Sell**: Ask

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The traded instrument. Passed to FnGetConversionInstrument and FnIsRealPosition. |
| 2 | @AccountCurrencyID | INT | NO | - | CODE-BACKED | Customer's account currency ID. Passed to FnGetConversionInstrument to find the bridge instrument. |
| 3 | @EstimatedClosingConversionMarkups | DECIMAL | NO | - | CODE-BACKED | Estimated conversion markups. Accepted but not used in current implementation. |
| 4 | @IsBuy | BIT | NO | - | VERIFIED | Position direction. Determines bid vs ask pricing for conversion. |
| 5 | @IsSettled | BIT | NO | - | VERIFIED | Settlement flag. Passed to FnIsRealPosition for real/CFD classification. |
| 6 | ConversionRate (return) | decimal | YES | - | CODE-BACKED | Live conversion rate from instrument currency to account currency. 1.0 if instrument already trades in account currency. NULL if no conversion path exists. |
| 7 | PriceRateID (return) | BIGINT | YES | - | CODE-BACKED | CurrencyPrice.PriceRateID of the conversion instrument for audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConversionInstrumentID | Trade.CurrencyPrice | FROM/WHERE | Reads live prices for the conversion instrument |
| @InstrumentID, @AccountCurrencyID | Trade.FnGetConversionInstrument | CROSS APPLY | Resolves which instrument to use for conversion |
| @IsSettled, @InstrumentID | Trade.FnIsRealPosition | CROSS APPLY | Determines real vs CFD pricing tier |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FnCalculateCurrentPnL | CROSS APPLY | Function call | Provides conversion rate for live PnL |
| Trade.FnCalculatePnLByRates | CROSS APPLY | Function call | Provides conversion rate for rate-based PnL |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnGetCurrentConversionRate (function)
  ├── Trade.CurrencyPrice (table)
  ├── Trade.FnGetConversionInstrument (function)
  │     └── Trade.Instrument (table)
  └── Trade.FnIsRealPosition (function)
        └── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | FROM: reads live bid/ask/discounted prices |
| Trade.FnGetConversionInstrument | Function | CROSS APPLY: resolves conversion instrument + reciprocal flag |
| Trade.FnIsRealPosition | Function | CROSS APPLY: determines real vs CFD |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnCalculateCurrentPnL | Function | CROSS APPLY for live PnL conversion |
| Trade.FnCalculatePnLByRates | Function | CROSS APPLY for rate-based PnL conversion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning ConversionRate + PriceRateID |
| WITH (NOLOCK) | Read hint | CurrencyPrice read with NOLOCK |

---

## 8. Sample Queries

### 8.1 Get conversion rate for a USD-account customer's EUR/JPY position

```sql
SELECT  ConversionRate, PriceRateID
FROM    Trade.FnGetCurrentConversionRate(5, 1, 0, 1, 0);
-- InstrumentID=5 (EUR/JPY hypothetical), AccountCurrencyID=1 (USD), Buy, CFD
```

### 8.2 Show conversion rates for all open positions

```sql
SELECT  p.PositionID, p.InstrumentID,
        conv.ConversionRate
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnGetCurrentConversionRate(p.InstrumentID, 1, 0, p.IsBuy, p.IsSettled) conv
WHERE   p.CID = 12345678 AND p.StatusID = 1;
```

### 8.3 Verify self-conversion returns 1.0

```sql
SELECT  ConversionRate
FROM    Trade.FnGetCurrentConversionRate(1, 1, 0, 1, 0);
-- EUR/USD with USD account: should return 1.0 if SellCurrencyID=USD
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Multi-currency conversion architecture described in Confluence "Supporting Services - Multi-Currency Changes" page.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnGetCurrentConversionRate | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnGetCurrentConversionRate.sql*
