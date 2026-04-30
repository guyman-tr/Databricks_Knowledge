# Price.CurrencyPriceSeconadryTable

> Table-valued parameter (TVP) for bulk secondary-feed price upserts into Trade.CurrencyPriceSecondary, carrying per-instrument bid/ask rates, timestamps, skew adjustments, and unit margin from a specific liquidity feed.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID + FeedID (logical composite key within the TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the input contract for `Price.SetCurrencyPriceBulkSecondary`. It carries a batch of secondary-feed price ticks - one row per instrument per feed - delivered from a liquidity provider to the eToro pricing engine. "Secondary" means this is an alternative price feed (distinct from the primary `Trade.CurrencyPrice` table), used for instruments with multiple pricing sources or as a fallback/cross-validation feed.

Without this type, `SetCurrencyPriceBulkSecondary` could not accept bulk price updates in a single round-trip. The TVP allows the price server to send hundreds of instrument prices atomically as a strongly-typed table parameter, which the procedure upserts into `Trade.CurrencyPriceSecondary`.

Data flows from the price server (via application code) -> this TVP parameter -> `SetCurrencyPriceBulkSecondary` -> upsert into `Trade.CurrencyPriceSecondary`. The procedure uses the TVP data to update existing rows (matched by InstrumentID + FeedID where PriceRateID changed) or insert new rows for instruments not yet in the secondary price store.

Note: The name "Seconadry" contains a typo (misspelling of "Secondary") preserved for backwards compatibility with all callers.

---

## 2. Business Logic

### 2.1 Primary vs Secondary Feed Architecture

**What**: eToro maintains two price tables - primary (Trade.CurrencyPrice) and secondary (Trade.CurrencyPriceSecondary). This TVP serves the secondary feed path.

**Columns/Parameters Involved**: `FeedID`, `InstrumentID`, `Bid`, `Ask`, `PriceRateID`

**Rules**:
- FeedID is NOT NULL (required) - secondary feed requires explicit feed identification since multiple feeds can coexist for the same instrument
- Primary feed TVP (CurrencyPriceTable) omits FeedID; secondary feed requires it
- A row is updated only when PriceRateID has changed for the same InstrumentID + FeedID combination

**Diagram**:
```
Liquidity Provider
      |
      v
Price Server (app)
      |-- batches ticks into CurrencyPriceSeconadryTable TVP
      |
      v
SetCurrencyPriceBulkSecondary(@RatesToUpdate, @ProviderID)
      |-- UPDATE existing rows (InstrumentID + FeedID match, PriceRateID changed)
      |-- INSERT new rows (InstrumentID + FeedID not yet in CurrencyPriceSecondary)
      v
Trade.CurrencyPriceSecondary (live secondary price store)
```

### 2.2 Skew Adjustment Fields

**What**: Bid and Ask prices have corresponding skew values that represent adjustments applied by the price skew algorithm before distribution to clients.

**Columns/Parameters Involved**: `SkewValueBid`, `SkewValueAsk`, `Bid`, `Ask`

**Rules**:
- SkewValueBid and SkewValueAsk default to 0 (no skew) - making them NOT NULL with a default ensures no NULL handling is needed in bulk operations
- Skew values are set by the price algo before this TVP is populated; the SP does not compute them

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | eToro instrument identifier. The SP upserts Trade.CurrencyPriceSecondary using this as the primary join key alongside FeedID. NULL allowed in this TVP but SP logic requires a valid instrument. |
| 2 | Bid | dbo.dtPrice | YES | - | CODE-BACKED | Best bid price (highest price a buyer will pay) from the liquidity feed, in instrument quote currency. Mapped directly to Trade.CurrencyPriceSecondary.Bid on upsert. Custom type dtPrice = decimal(16,8). |
| 3 | Ask | dbo.dtPrice | YES | - | CODE-BACKED | Best ask price (lowest price a seller will accept) from the liquidity feed, in instrument quote currency. Mapped directly to Trade.CurrencyPriceSecondary.Ask on upsert. Custom type dtPrice = decimal(16,8). |
| 4 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the price tick occurred at the exchange/liquidity source. Mapped to Trade.CurrencyPriceSecondary.Occurred on upsert. |
| 5 | OccurredOnServer | datetime | YES | - | CODE-BACKED | Timestamp when the price tick was received/processed on the eToro price server. Used to measure latency between market event and internal processing. Mapped to Trade.CurrencyPriceSecondary.OccurredOnServer. |
| 6 | PriceRateID | bigint | YES | - | CODE-BACKED | Unique identifier for this specific price tick from the liquidity provider. Used in the upsert condition: update only when PriceRateID differs from the current stored value, preventing duplicate updates. |
| 7 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | Timestamp when the price server received this tick from the external feed. Together with Occurred and OccurredOnServer, enables end-to-end latency tracking. |
| 8 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Reference to the market (raw, pre-markup) price rate that underlies this tick. Enables tracing from the final client price back to the raw market price. |
| 9 | LastPrice | dbo.dtPrice | YES | - | CODE-BACKED | Most recent traded price (last deal price) for this instrument on this feed. Distinct from Bid/Ask spread midpoint. Custom type dtPrice = decimal(16,8). |
| 10 | BidMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the market (raw) bid price underlying the final Bid after markup. Enables bid-side price tracing back to source. |
| 11 | AskMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for the market (raw) ask price underlying the final Ask after markup. Enables ask-side price tracing back to source. |
| 12 | MarkupPips | decimal(18,0) | YES | - | CODE-BACKED | Dealer spread markup applied on top of the raw market price, in pips. Determines the spread widening above raw bid/ask. Applied by pricing engine before this TVP is populated. |
| 13 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Required margin deposit per unit of this instrument, used for position margin calculations. Symmetric (same for buy and sell) in this TVP variant; use CurrencyPriceSeconadryTableWithUnitMargin for side-specific margins. |
| 14 | FeedID | smallint | NOT NULL | - | CODE-BACKED | Identifies which liquidity feed this price tick comes from. NOT NULL (required) - distinguishes multiple concurrent feeds for the same instrument in Trade.CurrencyPriceSecondary. Key join column in the upsert condition alongside InstrumentID. |
| 15 | SkewValueBid | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Price skew adjustment applied to the bid side by the skew algorithm. Default 0 = no skew. Added to raw bid to produce the final distributed bid price. NOT NULL with default ensures clean bulk inserts. |
| 16 | SkewValueAsk | decimal(19,8) | NOT NULL | 0 | CODE-BACKED | Price skew adjustment applied to the ask side by the skew algorithm. Default 0 = no skew. Added to raw ask to produce the final distributed ask price. NOT NULL with default ensures clean bulk inserts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SetCurrencyPriceBulkSecondary | @RatesToUpdate | TVP Parameter | Receives the secondary feed price batch and upserts into Trade.CurrencyPriceSecondary |

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
| Price.SetCurrencyPriceBulkSecondary | Stored Procedure | Declares @RatesToUpdate as this type READONLY; batch-upserts Trade.CurrencyPriceSecondary |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FeedID NOT NULL | NOT NULL | Feed identification is mandatory for secondary price routing |
| SkewValueBid DEFAULT 0 | DEFAULT | Zero skew is the baseline; skew is only populated when a skew model is active |
| SkewValueAsk DEFAULT 0 | DEFAULT | Zero skew is the baseline; skew is only populated when a skew model is active |

---

## 8. Sample Queries

### 8.1 Declare and use the TVP in a test batch

```sql
-- Simulate a secondary price update for two instruments
DECLARE @Prices Price.CurrencyPriceSeconadryTable;
INSERT INTO @Prices (InstrumentID, Bid, Ask, Occurred, OccurredOnServer, PriceRateID,
                     ReceivedOnPriceServer, MarketPriceRateID, LastPrice,
                     BidMarketPriceRateID, AskMarketPriceRateID, MarkupPips,
                     UnitMargin, FeedID, SkewValueBid, SkewValueAsk)
VALUES (1, 1.08450, 1.08470, GETUTCDATE(), GETUTCDATE(), 9999001,
        GETUTCDATE(), 9999000, 1.08460, 9998900, 9998901, 2, 0.01, 1, 0.00001, 0.00001),
       (2, 1.25300, 1.25320, GETUTCDATE(), GETUTCDATE(), 9999002,
        GETUTCDATE(), 9999001, 1.25310, 9998902, 9998903, 3, 0.02, 1, 0, 0);
EXEC Price.SetCurrencyPriceBulkSecondary @RatesToUpdate = @Prices, @ProviderID = 42;
```

### 8.2 Check current secondary prices for comparison

```sql
SELECT TOP 10
    InstrumentID, FeedID, Bid, Ask, MarkupPips, UnitMargin,
    SkewValueBid, SkewValueAsk, Occurred
FROM Trade.CurrencyPriceSecondary WITH (NOLOCK)
ORDER BY Occurred DESC;
```

### 8.3 Verify skew application by feed

```sql
SELECT
    cp.InstrumentID,
    cp.FeedID,
    cp.Bid,
    cp.Ask,
    cp.SkewValueBid,
    cp.SkewValueAsk,
    cp.MarkupPips,
    cp.Occurred
FROM Trade.CurrencyPriceSecondary cp WITH (NOLOCK)
WHERE cp.FeedID = 1
ORDER BY cp.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CurrencyPriceSeconadryTable | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.CurrencyPriceSeconadryTable.sql*
