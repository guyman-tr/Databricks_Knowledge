# Price.CurrencyPriceSeconadryTableWithUnitMargin

> Extended secondary-feed price TVP that adds side-specific unit margins (bid and ask independently) on top of the base CurrencyPriceSeconadryTable structure, enabling asymmetric margin calculation per feed.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID + FeedID (logical composite key within the TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the input contract for `Price.SetCurrencyPriceBulkSecondaryWithUnitMargin`. It is a superset of `Price.CurrencyPriceSeconadryTable`, adding two columns (`UnitMarginAsk` and `UnitMarginBid`) that provide side-specific margin requirements. While the base type carries a single symmetric `UnitMargin`, this variant allows the pricing engine to specify different margin rates for buy vs sell directions, supporting asymmetric margin models.

Without this type, the `SetCurrencyPriceBulkSecondaryWithUnitMargin` procedure could not receive side-differentiated margin data in a single bulk call. This supports instruments where the risk model requires different collateral on the buy side vs the sell side (e.g., for highly directional instruments or regulatory requirements).

Data flows from the price server -> this TVP -> `SetCurrencyPriceBulkSecondaryWithUnitMargin` -> upsert into `Trade.CurrencyPriceSecondary`. The procedure populates `UnitMarginBid` from the TVP's `UnitMarginBid` and sets `UnitMarginAsk = NULL` (see SP code), indicating the asymmetric logic is applied at the bid side only in the current implementation.

Note: The name "Seconadry" contains a typo (misspelling of "Secondary") preserved for backwards compatibility.

---

## 2. Business Logic

### 2.1 Side-Specific Unit Margin Extension

**What**: Extends the base secondary feed TVP with independent bid-side and ask-side unit margin values.

**Columns/Parameters Involved**: `UnitMargin`, `UnitMarginBid`, `UnitMarginAsk`

**Rules**:
- `UnitMargin` (symmetric) is still present for backward compatibility and for systems that don't differentiate sides
- `UnitMarginBid` is mapped to `Trade.CurrencyPriceSecondary.UnitMarginBid` directly
- `UnitMarginAsk` is accepted in the TVP but the SP sets `UnitMarginAsk = NULL` in Trade.CurrencyPriceSecondary (bid-side margin logic only in current implementation)
- When `UnitMarginBid` is NULL in the TVP, the SP falls back to `UnitMargin` for the bid side

**Diagram**:
```
TVP.UnitMargin          -> CurrencyPriceSecondary.UnitMargin (symmetric, legacy)
TVP.UnitMarginBid       -> CurrencyPriceSecondary.UnitMarginBid (bid-specific margin)
TVP.UnitMarginAsk       -> CurrencyPriceSecondary.UnitMarginAsk = NULL (not written in current SP)
```

### 2.2 Relationship to Base Type

**What**: This type is the extended version of CurrencyPriceSeconadryTable; all base fields are preserved with the same semantics.

**Columns/Parameters Involved**: All 16 columns from CurrencyPriceSeconadryTable, plus UnitMarginAsk, UnitMarginBid

**Rules**:
- All business logic from CurrencyPriceSeconadryTable applies (see that doc for FeedID requirement, skew defaults, upsert condition on PriceRateID change)
- This type is used when the caller has side-specific margin data available; otherwise CurrencyPriceSeconadryTable is used

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | eToro instrument identifier. Used with FeedID as the upsert key in Trade.CurrencyPriceSecondary. |
| 2 | Bid | dbo.dtPrice | YES | - | CODE-BACKED | Best bid price from the secondary liquidity feed, in instrument quote currency. Custom type dtPrice = decimal(16,8). |
| 3 | Ask | dbo.dtPrice | YES | - | CODE-BACKED | Best ask price from the secondary liquidity feed, in instrument quote currency. Custom type dtPrice = decimal(16,8). |
| 4 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the price tick occurred at the exchange/liquidity source. |
| 5 | OccurredOnServer | datetime | YES | - | CODE-BACKED | Timestamp when the eToro price server processed this tick. Used for latency measurement. |
| 6 | PriceRateID | bigint | YES | - | CODE-BACKED | Unique identifier for this price tick. Upsert condition: update only if PriceRateID differs from stored value. |
| 7 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | Timestamp when the price server received this tick from the external feed. Enables latency tracking. |
| 8 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Reference to the raw market price rate underlying this tick (before markup). |
| 9 | LastPrice | dbo.dtPrice | YES | - | CODE-BACKED | Most recent traded price for this instrument on this feed. Custom type dtPrice = decimal(16,8). |
| 10 | BidMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the raw market bid underlying the final Bid. Enables bid-side price tracing. |
| 11 | AskMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the raw market ask underlying the final Ask. Enables ask-side price tracing. |
| 12 | MarkupPips | decimal(18,0) | YES | - | CODE-BACKED | Dealer markup in pips added to the raw spread. Determines final spread width for clients. |
| 13 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Symmetric margin per unit (legacy/fallback). When UnitMarginBid is NULL, the SP uses this value for UnitMarginBid. |
| 14 | FeedID | smallint | NOT NULL | - | CODE-BACKED | Identifies the liquidity feed. NOT NULL - required for secondary feed routing; joins with InstrumentID as the upsert key. |
| 15 | SkewValueBid | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Bid-side skew adjustment from the skew algorithm. Default 0 = no skew applied. |
| 16 | SkewValueAsk | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Ask-side skew adjustment from the skew algorithm. Default 0 = no skew applied. |
| 17 | UnitMarginAsk | decimal(16,8) | YES | - | CODE-BACKED | Ask-side unit margin. Accepted by the TVP but the current SP implementation sets CurrencyPriceSecondary.UnitMarginAsk = NULL; reserved for future asymmetric ask-margin support. |
| 18 | UnitMarginBid | decimal(16,8) | YES | - | CODE-BACKED | Bid-side unit margin. Mapped directly to Trade.CurrencyPriceSecondary.UnitMarginBid on upsert, overriding the symmetric UnitMargin for the bid side. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SetCurrencyPriceBulkSecondaryWithUnitMargin | @RatesToUpdate | TVP Parameter | Receives the secondary feed price batch with side-specific margins and upserts Trade.CurrencyPriceSecondary |

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
| Price.SetCurrencyPriceBulkSecondaryWithUnitMargin | Stored Procedure | Declares @RatesToUpdate as this type READONLY; batch-upserts Trade.CurrencyPriceSecondary with side-specific UnitMarginBid |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FeedID NOT NULL | NOT NULL | Feed identification mandatory for secondary price routing |
| SkewValueBid DEFAULT 0 | DEFAULT | Baseline is no skew; populated only when a skew model is active |
| SkewValueAsk DEFAULT 0 | DEFAULT | Baseline is no skew; populated only when a skew model is active |

---

## 8. Sample Queries

### 8.1 Declare and populate with asymmetric margin data

```sql
DECLARE @Prices Price.CurrencyPriceSeconadryTableWithUnitMargin;
INSERT INTO @Prices (InstrumentID, Bid, Ask, Occurred, OccurredOnServer, PriceRateID,
                     ReceivedOnPriceServer, MarketPriceRateID, LastPrice,
                     BidMarketPriceRateID, AskMarketPriceRateID, MarkupPips,
                     UnitMargin, FeedID, SkewValueBid, SkewValueAsk,
                     UnitMarginAsk, UnitMarginBid)
VALUES (1, 1.08450, 1.08470, GETUTCDATE(), GETUTCDATE(), 9999001,
        GETUTCDATE(), 9999000, 1.08460, 9998900, 9998901, 2,
        0.01, 1, 0, 0, NULL, 0.012);
EXEC Price.SetCurrencyPriceBulkSecondaryWithUnitMargin @RatesToUpdate = @Prices, @ProviderID = 42;
```

### 8.2 Check secondary prices with side-specific margins

```sql
SELECT TOP 10
    InstrumentID, FeedID, Bid, Ask, UnitMargin, UnitMarginBid, UnitMarginAsk,
    SkewValueBid, SkewValueAsk, Occurred
FROM Trade.CurrencyPriceSecondary WITH (NOLOCK)
WHERE UnitMarginBid IS NOT NULL
ORDER BY Occurred DESC;
```

### 8.3 Compare symmetric vs side-specific margin for the same instrument

```sql
SELECT
    InstrumentID, FeedID,
    UnitMargin       AS SymmetricMargin,
    UnitMarginBid    AS BidSideMargin,
    UnitMarginAsk    AS AskSideMargin,
    Occurred
FROM Trade.CurrencyPriceSecondary WITH (NOLOCK)
ORDER BY InstrumentID, FeedID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CurrencyPriceSeconadryTableWithUnitMargin | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.CurrencyPriceSeconadryTableWithUnitMargin.sql*
