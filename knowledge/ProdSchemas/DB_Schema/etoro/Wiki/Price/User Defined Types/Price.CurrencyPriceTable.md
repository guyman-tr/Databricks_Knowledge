# Price.CurrencyPriceTable

> Primary table-valued parameter (TVP) for bulk price upserts into Trade.CurrencyPrice, carrying bid/ask rates, timestamps, skew values, discounted prices, and side-specific unit margins from the main liquidity feed.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (primary upsert key in Trade.CurrencyPrice) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the input contract for `Price.SetCurrencyPriceBulk`. It represents one price tick per instrument sent by a liquidity provider to the primary eToro pricing engine, to be upserted into `Trade.CurrencyPrice` - the live, real-time price table that drives client-facing quotes, position PnL, and order execution.

The primary feed differs from the secondary feed (CurrencyPriceSeconadryTable) in key ways: InstrumentID is NOT NULL (strict requirement), there is no FeedID (primary feed = one canonical price per instrument), and the type includes discounted price columns (BidDiscounted, AskDiscounted) and side-specific discounted unit margins, supporting loyalty/rebate pricing programs.

Data flows from the liquidity provider -> price server (app) -> this TVP -> `SetCurrencyPriceBulk` -> upsert into `Trade.CurrencyPrice`. This is the hot path for live price distribution: every instrument's current bid/ask is maintained in Trade.CurrencyPrice and read by the quote engine, equity provider, and position management systems.

---

## 2. Business Logic

### 2.1 Primary Feed Architecture

**What**: The primary TVP feeds Trade.CurrencyPrice - eToro's canonical live price store with one row per instrument.

**Columns/Parameters Involved**: `InstrumentID`, `Bid`, `Ask`, `PriceRateID`

**Rules**:
- InstrumentID is NOT NULL (required, unlike the secondary TVP which allows NULL)
- No FeedID: the primary feed is singular per instrument; each instrument has exactly one primary price
- SetCurrencyPriceBulk uses InstrumentID as the sole upsert key

**Diagram**:
```
Liquidity Provider (main feed)
      |
      v
Price Server (app) - builds CurrencyPriceTable TVP
      |
      v
SetCurrencyPriceBulk(@RatesToUpdate, @ProviderID)
      |
      v
Trade.CurrencyPrice (live primary price store, 1 row per instrument)
      |-- Read by: quote engine, PnL calculation, order execution
```

### 2.2 Discounted Pricing Support

**What**: Alongside standard Bid/Ask, this TVP carries "Discounted" price variants for clients eligible for reduced spread or loyalty pricing.

**Columns/Parameters Involved**: `Bid`, `Ask`, `BidDiscounted`, `AskDiscounted`, `UnitMarginBidDiscounted`, `UnitMarginAskDiscounted`

**Rules**:
- BidDiscounted and AskDiscounted are NULL when no discount program is active for an instrument
- UnitMarginBidDiscounted and UnitMarginAskDiscounted carry the margin requirements for discounted positions
- Standard Bid/Ask is used for regular clients; discounted variants are used for eligible accounts

**Diagram**:
```
Standard client  -> uses Bid/Ask + UnitMarginBid/UnitMarginAsk
Discounted client -> uses BidDiscounted/AskDiscounted + UnitMarginBidDiscounted/UnitMarginAskDiscounted
```

### 2.3 Side-Specific Unit Margin

**What**: This TVP carries four unit margin fields - symmetric and side-specific variants.

**Columns/Parameters Involved**: `UnitMargin`, `UnitMarginBid`, `UnitMarginAsk`, `UnitMarginBidDiscounted`, `UnitMarginAskDiscounted`

**Rules**:
- UnitMargin = symmetric legacy value; still present for backward compatibility
- UnitMarginBid and UnitMarginAsk = side-specific margins for the standard price
- UnitMarginBidDiscounted and UnitMarginAskDiscounted = side-specific margins for discounted prices
- NULL values in side-specific columns mean the symmetric UnitMargin applies

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. NOT NULL (required) - the sole upsert key for Trade.CurrencyPrice. Every row must identify a valid instrument. |
| 2 | Bid | dbo.dtPrice | YES | - | CODE-BACKED | Best bid price from the primary liquidity feed, in instrument quote currency. Mapped to Trade.CurrencyPrice.Bid on upsert. Custom type dtPrice = decimal(16,8). |
| 3 | Ask | dbo.dtPrice | YES | - | CODE-BACKED | Best ask price from the primary liquidity feed, in instrument quote currency. Mapped to Trade.CurrencyPrice.Ask on upsert. Custom type dtPrice = decimal(16,8). |
| 4 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the price tick occurred at the exchange/liquidity source. |
| 5 | OccurredOnServer | datetime | YES | - | CODE-BACKED | Timestamp when the eToro price server processed this tick. Used for latency measurement. |
| 6 | PriceRateID | bigint | YES | - | CODE-BACKED | Unique identifier for this price tick from the provider. Used to detect and skip duplicate updates. |
| 7 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | Timestamp when the price server received this tick from the external feed. Enables end-to-end latency tracking. |
| 8 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Reference to the underlying raw market price rate (before markup/skew). Enables price tracing from client quote back to source. |
| 9 | LastPrice | dbo.dtPrice | YES | - | CODE-BACKED | Most recent traded price for this instrument on the primary feed. Custom type dtPrice = decimal(16,8). |
| 10 | BidMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the raw market bid underlying the final Bid. Enables bid-side price auditing. |
| 11 | AskMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the raw market ask underlying the final Ask. Enables ask-side price auditing. |
| 12 | MarkupPips | decimal(18,0) | YES | - | CODE-BACKED | Dealer markup in pips applied on top of the raw market spread. Determines the spread widening clients see. |
| 13 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Symmetric margin per unit (legacy). Required deposit per traded unit at the instrument's current price. Used when side-specific margins are not differentiated. |
| 14 | SkewValueBid | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Bid-side price skew adjustment from the skew algorithm. Default 0 = no skew active. NOT NULL ensures clean bulk inserts. |
| 15 | SkewValueAsk | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Ask-side price skew adjustment from the skew algorithm. Default 0 = no skew active. NOT NULL ensures clean bulk inserts. |
| 16 | BidDiscounted | dbo.dtPrice | YES | - | CODE-BACKED | Discounted bid price for clients on loyalty/reduced-spread programs. NULL when no discount program is active for this instrument. Custom type dtPrice = decimal(16,8). |
| 17 | AskDiscounted | dbo.dtPrice | YES | - | CODE-BACKED | Discounted ask price for clients on loyalty/reduced-spread programs. NULL when no discount program is active. Custom type dtPrice = decimal(16,8). |
| 18 | UnitMarginBidDiscounted | decimal(16,8) | YES | - | CODE-BACKED | Margin per unit for the bid side when using the discounted price. NULL when no discount program is active. |
| 19 | UnitMarginAskDiscounted | decimal(16,8) | YES | - | CODE-BACKED | Margin per unit for the ask side when using the discounted price. NULL when no discount program is active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SetCurrencyPriceBulk | @RatesToUpdate | TVP Parameter | Primary price bulk upsert procedure; writes all fields to Trade.CurrencyPrice |

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
| Price.SetCurrencyPriceBulk | Stored Procedure | Declares @RatesToUpdate as this type READONLY; upserts Trade.CurrencyPrice (primary live price store) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| InstrumentID NOT NULL | NOT NULL | Every price row must identify an instrument; null instrument prices cannot be upserted |
| SkewValueBid DEFAULT 0 | DEFAULT | Baseline is no skew; populated only when a skew model is active for this instrument |
| SkewValueAsk DEFAULT 0 | DEFAULT | Baseline is no skew; populated only when a skew model is active for this instrument |

---

## 8. Sample Queries

### 8.1 Populate and call for a standard price update

```sql
DECLARE @Prices Price.CurrencyPriceTable;
INSERT INTO @Prices (InstrumentID, Bid, Ask, Occurred, OccurredOnServer, PriceRateID,
                     ReceivedOnPriceServer, MarketPriceRateID, LastPrice,
                     BidMarketPriceRateID, AskMarketPriceRateID, MarkupPips,
                     UnitMargin, SkewValueBid, SkewValueAsk,
                     BidDiscounted, AskDiscounted, UnitMarginBidDiscounted, UnitMarginAskDiscounted)
VALUES (1, 1.08450, 1.08470, GETUTCDATE(), GETUTCDATE(), 9999001,
        GETUTCDATE(), 9999000, 1.08460, 9998900, 9998901, 2,
        0.01, 0, 0, NULL, NULL, NULL, NULL);
EXEC Price.SetCurrencyPriceBulk @RatesToUpdate = @Prices, @ProviderID = 5;
```

### 8.2 Check current primary prices with discounted variants

```sql
SELECT TOP 20
    InstrumentID, Bid, Ask, BidDiscounted, AskDiscounted,
    UnitMargin, MarkupPips, SkewValueBid, SkewValueAsk, Occurred
FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE BidDiscounted IS NOT NULL
ORDER BY Occurred DESC;
```

### 8.3 Monitor price latency

```sql
SELECT TOP 10
    InstrumentID,
    Occurred,
    OccurredOnServer,
    ReceivedOnPriceServer,
    DATEDIFF(ms, Occurred, ReceivedOnPriceServer) AS FeedLatencyMs,
    DATEDIFF(ms, ReceivedOnPriceServer, OccurredOnServer) AS ProcessingLatencyMs
FROM Trade.CurrencyPrice WITH (NOLOCK)
ORDER BY OccurredOnServer DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CurrencyPriceTable | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.CurrencyPriceTable.sql*
