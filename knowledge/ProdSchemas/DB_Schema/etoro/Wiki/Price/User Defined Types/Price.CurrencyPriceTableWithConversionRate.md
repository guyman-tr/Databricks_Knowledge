# Price.CurrencyPriceTableWithConversionRate

> Extended primary-feed price TVP that adds USD conversion rate data (bid/ask spreaded conversion rates and a conversion rate ID) on top of CurrencyPriceTable, enabling the price engine to simultaneously update instrument prices and their USD normalization rates in a single atomic call.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (primary upsert key in Trade.CurrencyPrice) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the input contract for `Price.SetCurrencyPriceBulkWithConversionRate`. It is a superset of `Price.CurrencyPriceTableWithUnitMargin` (which itself extends `Price.CurrencyPriceTable`), adding three USD conversion rate fields: `USDConversionRateBidSpreaded`, `USDConversionRateAskSpreaded`, and `USDConversionPriceRateID`.

USD conversion rates are needed because eToro's PnL, margin, and reporting are denominated in USD. When the underlying instrument is priced in a non-USD currency (e.g., EUR/GBP at 0.860, needing to convert to USD), the price server must simultaneously deliver the instrument price AND the USD conversion rate in the same tick. This ensures price and conversion rate remain perfectly synchronized - using a conversion rate from a different tick would introduce PnL calculation errors.

Data flows from the liquidity provider -> price server (app) -> this TVP -> `SetCurrencyPriceBulkWithConversionRate` -> UPDATE into `Trade.CurrencyPrice` (this procedure only updates existing rows, it does not insert). The conversion rate fields are written alongside all other price fields in the same atomic UPDATE.

---

## 2. Business Logic

### 2.1 Synchronized Price + USD Conversion

**What**: Delivers instrument price and its USD normalization rate atomically, preventing PnL calculation errors from rate/price timestamp mismatches.

**Columns/Parameters Involved**: `Bid`, `Ask`, `USDConversionRateBidSpreaded`, `USDConversionRateAskSpreaded`, `USDConversionPriceRateID`

**Rules**:
- All three conversion fields can be NULL (for USD-denominated instruments that need no conversion)
- USDConversionRateBidSpreaded = the rate to convert the bid-side value from instrument currency to USD
- USDConversionRateAskSpreaded = the rate to convert the ask-side value from instrument currency to USD
- "Spreaded" indicates the conversion rate already includes spread markup (not raw)
- USDConversionPriceRateID tracks the source rate ID for the conversion, enabling audit trails

**Diagram**:
```
Non-USD instrument (e.g. EUR/GBP):
  Instrument Bid (0.860 GBP) x USDConversionRateBidSpreaded (1.2700 USD/GBP)
    = USD-equivalent bid (1.0922 USD)
  -> Used for PnL, margin, and reporting calculations

USD instrument (e.g. EUR/USD):
  USDConversionRateBidSpreaded = NULL (no conversion needed)
```

### 2.2 Update-Only Behavior

**What**: Unlike the base CurrencyPriceTable which supports full upsert, this type is used by a procedure that only updates (no INSERT).

**Columns/Parameters Involved**: All fields

**Rules**:
- SetCurrencyPriceBulkWithConversionRate only runs UPDATE, not INSERT/UPSERT
- If an instrument does not yet exist in Trade.CurrencyPrice, this call silently skips it
- The base SetCurrencyPriceBulk (using CurrencyPriceTable) must have run first to create the row

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. NOT NULL - required upsert key for Trade.CurrencyPrice. |
| 2 | Bid | dbo.dtPrice | YES | - | CODE-BACKED | Best bid price from the primary feed. Custom type dtPrice = decimal(16,8). |
| 3 | Ask | dbo.dtPrice | YES | - | CODE-BACKED | Best ask price from the primary feed. Custom type dtPrice = decimal(16,8). |
| 4 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the price tick occurred at the source exchange. |
| 5 | OccurredOnServer | datetime | YES | - | CODE-BACKED | Timestamp when the eToro price server processed this tick. |
| 6 | PriceRateID | bigint | YES | - | CODE-BACKED | Unique identifier for this price tick from the provider. |
| 7 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | Timestamp when the price server received this tick. Enables latency tracking. |
| 8 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Reference to the raw market price rate before markup/skew. Enables price auditing. |
| 9 | LastPrice | dbo.dtPrice | YES | - | CODE-BACKED | Most recent traded price for this instrument. Custom type dtPrice = decimal(16,8). |
| 10 | BidMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the raw market bid underlying the final Bid. |
| 11 | AskMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the raw market ask underlying the final Ask. |
| 12 | MarkupPips | decimal(18,0) | YES | - | CODE-BACKED | Dealer markup in pips on top of raw spread. |
| 13 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Symmetric margin per unit (legacy/fallback). |
| 14 | SkewValueBid | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Bid-side skew adjustment. Default 0 = no skew. |
| 15 | SkewValueAsk | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Ask-side skew adjustment. Default 0 = no skew. |
| 16 | BidDiscounted | dbo.dtPrice | YES | - | CODE-BACKED | Discounted bid price for loyalty/reduced-spread eligible clients. NULL when inactive. |
| 17 | AskDiscounted | dbo.dtPrice | YES | - | CODE-BACKED | Discounted ask price for loyalty/reduced-spread eligible clients. NULL when inactive. |
| 18 | UnitMarginBidDiscounted | decimal(16,8) | YES | - | CODE-BACKED | Margin per unit for bid side under discounted pricing. NULL when no discount program active. |
| 19 | UnitMarginAskDiscounted | decimal(16,8) | YES | - | CODE-BACKED | Margin per unit for ask side under discounted pricing. NULL when no discount program active. |
| 20 | UnitMarginBid | decimal(16,8) | YES | - | CODE-BACKED | Standard bid-side unit margin (not discounted). Maps to Trade.CurrencyPrice.UnitMarginBid. |
| 21 | UnitMarginAsk | decimal(16,8) | YES | - | CODE-BACKED | Standard ask-side unit margin (not discounted). Maps to Trade.CurrencyPrice.UnitMarginAsk. |
| 22 | USDConversionRateBidSpreaded | dbo.dtPrice | YES | - | CODE-BACKED | The bid-side conversion rate from instrument currency to USD, including spread markup. Used to normalize bid-side PnL and margin to USD. NULL for USD-denominated instruments. Custom type dtPrice = decimal(16,8). |
| 23 | USDConversionRateAskSpreaded | dbo.dtPrice | YES | - | CODE-BACKED | The ask-side conversion rate from instrument currency to USD, including spread markup. Used to normalize ask-side PnL and margin to USD. NULL for USD-denominated instruments. Custom type dtPrice = decimal(16,8). |
| 24 | USDConversionPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the USD conversion rate source. Enables tracing the conversion rate back to its originating price tick for audit and reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SetCurrencyPriceBulkWithConversionRate | @RatesToUpdate | TVP Parameter | Updates Trade.CurrencyPrice with full price and USD conversion rate data atomically |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.SetCurrencyPriceBulkWithConversionRate | Stored Procedure | Declares @RatesToUpdate as this type READONLY; updates Trade.CurrencyPrice including USD conversion rates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| InstrumentID NOT NULL | NOT NULL | Every price row must identify an instrument |
| SkewValueBid DEFAULT 0 | DEFAULT | Baseline is no skew |
| SkewValueAsk DEFAULT 0 | DEFAULT | Baseline is no skew |

---

## 8. Sample Queries

### 8.1 Populate TVP with USD conversion rates for non-USD instruments

```sql
DECLARE @Prices Price.CurrencyPriceTableWithConversionRate;
INSERT INTO @Prices (InstrumentID, Bid, Ask, Occurred, OccurredOnServer, PriceRateID,
                     ReceivedOnPriceServer, MarketPriceRateID, LastPrice,
                     BidMarketPriceRateID, AskMarketPriceRateID, MarkupPips,
                     UnitMargin, SkewValueBid, SkewValueAsk,
                     BidDiscounted, AskDiscounted, UnitMarginBidDiscounted, UnitMarginAskDiscounted,
                     UnitMarginBid, UnitMarginAsk,
                     USDConversionRateBidSpreaded, USDConversionRateAskSpreaded, USDConversionPriceRateID)
VALUES (1001, 0.86010, 0.86030, GETUTCDATE(), GETUTCDATE(), 9999001,
        GETUTCDATE(), 9999000, 0.86020, 9998900, 9998901, 2,
        0.01, 0, 0, NULL, NULL, NULL, NULL,
        0.01, 0.01,
        1.27050, 1.27060, 7771234);
EXEC Price.SetCurrencyPriceBulkWithConversionRate @RatesToUpdate = @Prices, @ProviderID = 5;
```

### 8.2 Check current USD conversion rates stored in CurrencyPrice

```sql
SELECT TOP 20
    InstrumentID, Bid, Ask,
    USDConversionRateBidSpreaded, USDConversionRateAskSpreaded,
    USDConversionPriceRateID, Occurred
FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE USDConversionRateBidSpreaded IS NOT NULL
ORDER BY Occurred DESC;
```

### 8.3 Instruments without USD conversion (USD-denominated)

```sql
SELECT TOP 10
    InstrumentID, Bid, Ask, Occurred
FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE USDConversionRateBidSpreaded IS NULL
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CurrencyPriceTableWithConversionRate | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.CurrencyPriceTableWithConversionRate.sql*
