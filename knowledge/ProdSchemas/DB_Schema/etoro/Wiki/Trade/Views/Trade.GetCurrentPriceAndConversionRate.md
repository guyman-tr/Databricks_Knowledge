# Trade.GetCurrentPriceAndConversionRate

> Exposes current instrument prices (bid/ask) plus USD conversion rate for non-USD-denominated instruments. UNION of instruments needing conversion and USD-denominated instruments (ConversionRate=0).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID (one row per instrument with price) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCurrentPriceAndConversionRate provides a unified view of live instrument prices together with the rate needed to convert non-USD positions to USD for P&L and reporting. For instruments whose buy or sell currency is USD (CurrencyID=1), no conversion is needed, so ConversionRate=0. For all other instruments (e.g., EUR/CHF, GBP/JPY), the view JOINs to the corresponding USD pair (e.g., EUR/USD, GBP/USD) and computes the conversion rate. When the conversion instrument is quoted with USD as the buy currency (e.g., EUR/USD where BuyCurrencyID=2, SellCurrencyID=1), the rate is inverted (1/Bid) because the view needs "units of USD per unit of the instrument's currency."

This view exists so dividend processing, position valuation, and statement generation can fetch both the instrument's current price and its USD conversion in a single query. Without it, callers would need to replicate the complex JOIN logic and CASE-based rate inversion. dbo.AccountStatement_GetDividends uses this view to resolve instrument prices and conversion rates for dividend calculations.

Data flows: The view reads from Trade.CurrencyPrice (twice for the UNION branches), Trade.Instrument, and a derived table of USD-linked instruments. Price data is fed by Trade.SetCurrencyPrice and price feeds. The first UNION branch returns instruments where neither BuyCurrencyID nor SellCurrencyID is 1 (USD); the second returns instruments where either is USD, with ConversionRate=0 and ConversionRateID=0.

---

## 2. Business Logic

### 2.1 Conversion Rate Calculation (Non-USD Instruments)

**What**: For instruments not quoted in USD, the view finds a "conversion instrument" (one whose BuyCurrencyID=1 or SellCurrencyID=1) that matches the rate instrument's SellCurrencyID. The conversion rate is either the conversion instrument's Bid, or when BuyCurrencyID=1 (USD is the buy side), 1/Bid.

**Columns/Parameters Involved**: `ConversionRate`, `ConversionRateID`, `BuyCurrencyID`, `SellCurrencyID`, `convrate.Bid`

**Rules**:
- Match: rateins.SellCurrencyID = convrateinst.BuyCurrencyID OR rateins.SellCurrencyID = convrateinst.SellCurrencyID. This finds the USD pair for the instrument's sell currency (e.g., EUR/CHF -> EUR/USD or USD/EUR).
- When convrateinst.BuyCurrencyID=1 (e.g., USD/JPY): ConversionRate = 1/convrate.Bid when Bid>0, else 0. Inversion needed because "price of USD in JPY" must become "price of JPY in USD" for conversion.
- When convrateinst.BuyCurrencyID<>1 (e.g., EUR/USD): ConversionRate = convrate.Bid directly (EUR per USD already in right direction).

**Diagram**:
```
EUR/CHF (rateins) -> Match EUR/USD (convrateinst: Buy=2,EUR Sell=1,USD)
  -> BuyCurrencyID=2 <> 1 -> ConversionRate = convrate.Bid
USD/JPY (rateins) -> Match USD/JPY (convrateinst: Buy=1,USD Sell=4,JPY)
  -> BuyCurrencyID=1 -> ConversionRate = 1/convrate.Bid
```

### 2.2 USD-Denominated Instruments (No Conversion)

**What**: Instruments where SellCurrencyID=1 or BuyCurrencyID=1 are already in USD terms. No conversion rate is needed.

**Columns/Parameters Involved**: `ConversionRate`, `ConversionRateID`

**Rules**:
- Second UNION branch: WHERE rateins.SellCurrencyID=1 OR rateins.BuyCurrencyID=1.
- ConversionRate=0, ConversionRateID=0. RateBid, RateAsk, PriceRateID, RateGenerationTime come from CurrencyPrice.

---

## 3. Data Overview

| InstrumentID | RateBid | RateAsk | ConversionRate | RateGenerationTime | Meaning |
|--------------|---------|---------|----------------|--------------------|---------|
| 469 | 11.04 | 11.04004 | 0.091737 | 2025-11-30 | Non-USD instrument with live bid/ask. ConversionRate converts position value to USD. |
| 59 | 1.09291 | 1.09312 | 0.091737 | 2025-11-30 | Cross-pair with conversion. Same ConversionRate as 469 indicates shared conversion instrument (e.g., EUR/USD). |
| 2969 | 0 | 0 | 0.091737 | 2023-02-23 | Zero bid/ask (stale or inactive). ConversionRate still populated from conversion instrument. |
| 2970 | 0 | 0 | 0.091737 | 2023-02-23 | Similar stale instrument. RateGenerationTime shows last price update. |
| 2971 | 0 | 0 | 0.091737 | 2023-02-23 | Edge case: zero prices but conversion rate available. |

**Selection criteria**: Mix of live prices (469, 59) and zero-price instruments (2969-2971) from live MCP sample. ConversionRate consistent for instruments sharing same conversion pair.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Tradeable instrument. From Trade.CurrencyPrice.rate.InstrumentID. FK to Trade.Instrument. |
| 2 | RateBid | dbo.dtPrice | NO | - | CODE-BACKED | Current bid rate for the instrument. From Trade.CurrencyPrice.Bid. Used for valuation and order validation. |
| 3 | RateAsk | dbo.dtPrice | NO | - | CODE-BACKED | Current ask rate. From Trade.CurrencyPrice.Ask. Used with RateBid for mid-price. |
| 4 | PriceRateID | bigint | NO | - | CODE-BACKED | Tick/rate identifier for the instrument price. From Trade.CurrencyPrice.PriceRateID. Links to price feed stream. |
| 5 | ConversionRate | dbo.dtPrice | NO | - | CODE-BACKED | Computed in view: When conversion instrument's BuyCurrencyID=1, 1/convrate.Bid (else 0 if Bid<=0); else convrate.Bid. Rate to convert instrument value to USD. 0 for USD-denominated instruments. |
| 6 | ConversionRateID | bigint | NO | - | CODE-BACKED | PriceRateID of the conversion instrument's rate. 0 for USD-denominated instruments. From convrate.PriceRateID. |
| 7 | RateGenerationTime | datetime | YES | - | CODE-BACKED | When the instrument price was received on the price server. From Trade.CurrencyPrice.ReceivedOnPriceServer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Lookup | Tradeable instrument. |
| PriceRateID | Trade.CurrencyPrice | Implicit | Links to price tick stream. |
| ConversionRateID | Trade.CurrencyPrice | Implicit | Links to conversion instrument's price tick. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AccountStatement_GetDividends | FROM | Reader | Joins on InstrumentID and RateGenerationTime for dividend valuation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCurrentPriceAndConversionRate (view)
├── Trade.CurrencyPrice (table)
├── Trade.Instrument (table)
└── (derived: Trade.Instrument WHERE BuyCurrencyID=1 OR SellCurrencyID=1)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | FROM (rate, convrate) - bid, ask, PriceRateID, ReceivedOnPriceServer |
| Trade.Instrument | Table | FROM (rateins), derived table (convrateinst) - BuyCurrencyID, SellCurrencyID for conversion logic |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountStatement_GetDividends | Procedure | Joins for price and conversion rate on dividends |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get current price and conversion for specific instruments
```sql
SELECT InstrumentID, RateBid, RateAsk, ConversionRate, RateGenerationTime
  FROM Trade.GetCurrentPriceAndConversionRate WITH (NOLOCK)
 WHERE InstrumentID IN (1, 5, 10, 469)
```

### 8.2 Join with instrument names for reporting
```sql
SELECT G.InstrumentID, GI.Name, G.RateBid, G.RateAsk, G.ConversionRate,
       G.RateGenerationTime
  FROM Trade.GetCurrentPriceAndConversionRate G WITH (NOLOCK)
  JOIN Trade.GetInstrument GI WITH (NOLOCK) ON G.InstrumentID = GI.InstrumentID
 WHERE G.ConversionRate > 0
 ORDER BY G.InstrumentID
```

### 8.3 Find instruments with stale prices (RateGenerationTime old)
```sql
SELECT InstrumentID, RateBid, RateAsk, ConversionRate, RateGenerationTime,
       DATEDIFF(MINUTE, RateGenerationTime, GETUTCDATE()) AS MinutesSinceUpdate
  FROM Trade.GetCurrentPriceAndConversionRate WITH (NOLOCK)
 WHERE RateGenerationTime < DATEADD(HOUR, -1, GETUTCDATE())
 ORDER BY RateGenerationTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCurrentPriceAndConversionRate | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetCurrentPriceAndConversionRate.sql*
