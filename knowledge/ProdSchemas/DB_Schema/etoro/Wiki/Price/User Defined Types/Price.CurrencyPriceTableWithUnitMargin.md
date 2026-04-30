# Price.CurrencyPriceTableWithUnitMargin

> Extended primary-feed price TVP that adds side-specific unit margins (UnitMarginBid, UnitMarginAsk) on top of CurrencyPriceTable, enabling asymmetric margin requirements for buy vs sell directions without USD conversion rate data.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (primary upsert key in Trade.CurrencyPrice) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the input contract for `Price.SetCurrencyPriceBulkWithUnitMargin`. It extends `Price.CurrencyPriceTable` by adding `UnitMarginBid` and `UnitMarginAsk` - side-specific margin requirements for standard (non-discounted) prices. It sits between the base `CurrencyPriceTable` (no side-specific margins) and `CurrencyPriceTableWithConversionRate` (adds USD conversion on top of the same side-specific margins) in the TVP family hierarchy.

Use this type when the pricing system has computed asymmetric margin requirements (different buy vs sell margin) but does NOT need to simultaneously deliver USD conversion rates. This is common for USD-denominated instruments or when conversion rate updates are handled by a separate call.

Data flows from the liquidity provider -> price server (app) -> this TVP -> `SetCurrencyPriceBulkWithUnitMargin` -> upsert into `Trade.CurrencyPrice`.

---

## 2. Business Logic

### 2.1 TVP Family Hierarchy

**What**: This type sits in a family of progressively richer CurrencyPrice TVPs.

**Columns/Parameters Involved**: All fields

**Rules**:
- CurrencyPriceTable (base): standard prices + discounted prices + symmetric UnitMargin
- CurrencyPriceTableWithUnitMargin (this): adds UnitMarginBid + UnitMarginAsk (side-specific, non-discounted)
- CurrencyPriceTableWithConversionRate: adds USD conversion rates on top of this type

**Diagram**:
```
CurrencyPriceTable
  |-- + UnitMarginBid, UnitMarginAsk
  v
CurrencyPriceTableWithUnitMargin (this type)
  |-- + USDConversionRateBidSpreaded, USDConversionRateAskSpreaded, USDConversionPriceRateID
  v
CurrencyPriceTableWithConversionRate
```

### 2.2 Side-Specific vs Symmetric Margin

**What**: Supports instruments where regulatory or risk models require different collateral for buy (long) vs sell (short) positions.

**Columns/Parameters Involved**: `UnitMargin`, `UnitMarginBid`, `UnitMarginAsk`

**Rules**:
- UnitMargin (symmetric) is still present for backward compatibility
- UnitMarginBid overrides UnitMargin for long (buy) positions
- UnitMarginAsk overrides UnitMargin for short (sell) positions
- NULL in UnitMarginBid/Ask means use the symmetric UnitMargin

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
| 4 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the price tick occurred at the source. |
| 5 | OccurredOnServer | datetime | YES | - | CODE-BACKED | Timestamp when the price server processed this tick. |
| 6 | PriceRateID | bigint | YES | - | CODE-BACKED | Unique identifier for this price tick. |
| 7 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | Timestamp when the price server received this tick from the feed. |
| 8 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Reference to the underlying raw market price rate. |
| 9 | LastPrice | dbo.dtPrice | YES | - | CODE-BACKED | Most recent traded price. Custom type dtPrice = decimal(16,8). |
| 10 | BidMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the raw market bid. Enables bid-side price auditing. |
| 11 | AskMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the raw market ask. Enables ask-side price auditing. |
| 12 | MarkupPips | decimal(18,0) | YES | - | CODE-BACKED | Dealer markup in pips added to raw spread. |
| 13 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Symmetric margin per unit (legacy/fallback). Applied when side-specific margins are NULL. |
| 14 | SkewValueBid | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Bid-side skew adjustment. Default 0 = no skew active. |
| 15 | SkewValueAsk | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Ask-side skew adjustment. Default 0 = no skew active. |
| 16 | BidDiscounted | dbo.dtPrice | YES | - | CODE-BACKED | Discounted bid price for loyalty clients. NULL when no discount program is active. |
| 17 | AskDiscounted | dbo.dtPrice | YES | - | CODE-BACKED | Discounted ask price for loyalty clients. NULL when no discount program is active. |
| 18 | UnitMarginBidDiscounted | decimal(16,8) | YES | - | CODE-BACKED | Margin per unit for bid side under discounted pricing. NULL when not applicable. |
| 19 | UnitMarginAskDiscounted | decimal(16,8) | YES | - | CODE-BACKED | Margin per unit for ask side under discounted pricing. NULL when not applicable. |
| 20 | UnitMarginBid | decimal(16,8) | YES | - | CODE-BACKED | Standard bid-side (long) unit margin override. When provided, replaces UnitMargin for buy positions. Maps to Trade.CurrencyPrice.UnitMarginBid. |
| 21 | UnitMarginAsk | decimal(16,8) | YES | - | CODE-BACKED | Standard ask-side (short) unit margin override. When provided, replaces UnitMargin for sell positions. Maps to Trade.CurrencyPrice.UnitMarginAsk. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SetCurrencyPriceBulkWithUnitMargin | @RatesToUpdate | TVP Parameter | Upserts Trade.CurrencyPrice with side-specific margin data |

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
| Price.SetCurrencyPriceBulkWithUnitMargin | Stored Procedure | Declares @RatesToUpdate as this type READONLY; upserts Trade.CurrencyPrice with UnitMarginBid/Ask |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| InstrumentID NOT NULL | NOT NULL | Every row must identify a valid instrument |
| SkewValueBid DEFAULT 0 | DEFAULT | Baseline is no skew |
| SkewValueAsk DEFAULT 0 | DEFAULT | Baseline is no skew |

---

## 8. Sample Queries

### 8.1 Use TVP with asymmetric margins for a set of instruments

```sql
DECLARE @Prices Price.CurrencyPriceTableWithUnitMargin;
INSERT INTO @Prices (InstrumentID, Bid, Ask, Occurred, OccurredOnServer, PriceRateID,
                     ReceivedOnPriceServer, MarketPriceRateID, LastPrice,
                     BidMarketPriceRateID, AskMarketPriceRateID, MarkupPips,
                     UnitMargin, SkewValueBid, SkewValueAsk,
                     BidDiscounted, AskDiscounted, UnitMarginBidDiscounted, UnitMarginAskDiscounted,
                     UnitMarginBid, UnitMarginAsk)
VALUES (1, 1.08450, 1.08470, GETUTCDATE(), GETUTCDATE(), 9999001,
        GETUTCDATE(), 9999000, 1.08460, 9998900, 9998901, 2,
        0.01, 0, 0, NULL, NULL, NULL, NULL, 0.012, 0.010);
EXEC Price.SetCurrencyPriceBulkWithUnitMargin @RatesToUpdate = @Prices, @ProviderID = 5;
```

### 8.2 Inspect side-specific margins in CurrencyPrice

```sql
SELECT TOP 20
    InstrumentID, Bid, Ask,
    UnitMargin, UnitMarginBid, UnitMarginAsk,
    BidDiscounted, AskDiscounted,
    UnitMarginBidDiscounted, UnitMarginAskDiscounted,
    Occurred
FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE UnitMarginBid IS NOT NULL
ORDER BY Occurred DESC;
```

### 8.3 Find instruments with asymmetric margin (bid != ask)

```sql
SELECT
    InstrumentID,
    UnitMarginBid,
    UnitMarginAsk,
    ABS(UnitMarginBid - UnitMarginAsk) AS MarginAsymmetry
FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE UnitMarginBid IS NOT NULL
  AND UnitMarginAsk IS NOT NULL
  AND UnitMarginBid <> UnitMarginAsk
ORDER BY MarginAsymmetry DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CurrencyPriceTableWithUnitMargin | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.CurrencyPriceTableWithUnitMargin.sql*
