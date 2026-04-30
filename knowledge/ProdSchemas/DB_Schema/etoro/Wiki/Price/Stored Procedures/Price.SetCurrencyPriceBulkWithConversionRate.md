# Price.SetCurrencyPriceBulkWithConversionRate

> Bulk UPDATE of Trade.CurrencyPrice (primary price table) including USD conversion rate fields - the main price tick ingestion procedure for the primary feed when USD conversion rates are available. UPDATE-only (no INSERT), joined on InstrumentID without a PriceRateID change guard.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RatesToUpdate (TVP), @ProviderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.SetCurrencyPriceBulkWithConversionRate is the primary bulk price update procedure for the main price store (Trade.CurrencyPrice). It is called by the pricing engine on each price tick batch when USD conversion rates are available alongside the instrument prices.

The USD conversion rate fields (`USDConversionRateBidSpreaded`, `USDConversionRateAskSpreaded`, `USDConversionPriceRateID`) are used to normalize non-USD instrument prices to USD for PnL, margin, and account value calculations. When these rates are provided in the price tick (i.e., the feed delivers them together with the price), this procedure is used. When they are not available, `SetCurrencyPriceBulkWithUnitMargin` is used instead (which explicitly sets the conversion rate fields to NULL).

Key design characteristics:
- **UPDATE-only**: no INSERT path. Trade.CurrencyPrice rows must pre-exist. Instruments are inserted into CurrencyPrice by a separate initialization step.
- **No PriceRateID change guard**: every call updates all provided instruments regardless of whether PriceRateID changed. This differs from the secondary feed variants which skip no-change updates.
- **Temp table with clustered index on InstrumentID** (no FeedID in the primary store key - CurrencyPrice is per-instrument, not per-instrument+feed).

---

## 2. Business Logic

### 2.1 TVP to Temp Table

**What**: Materializes the input TVP into a temp table with a unique clustered index on InstrumentID.

**Columns/Parameters Involved**: `@RatesToUpdate`, `#CurrencyPriceBulkWithConversionRate`

**Rules**:
- `CREATE TABLE #CurrencyPriceBulkWithConversionRate ... INDEX CIX UNIQUE CLUSTERED (InstrumentID)` - no FeedID in the key (primary price table is per-instrument)
- `INSERT INTO #CurrencyPriceBulkWithConversionRate SELECT * FROM @RatesToUpdate`: copies all TVP rows
- TVP type: `Price.CurrencyPriceTableWithConversionRate` - richest TVP type, includes all price fields plus USD conversion rates

### 2.2 UPDATE Trade.CurrencyPrice

**What**: Full field update of all matching CurrencyPrice rows, including conversion rate fields.

**Columns/Parameters Involved**: All price fields + `USDConversionRateBidSpreaded`, `USDConversionRateAskSpreaded`, `USDConversionPriceRateID`

**Rules**:
- `FROM Trade.CurrencyPrice CP WITH (NOLOCK) JOIN #CurrencyPriceBulkWithConversionRate RTU ON CP.InstrumentID = RTU.InstrumentID`
- Simple inner join (no PriceRateID change guard - updates even if PriceRateID unchanged)
- `USDConversionRateBidSpreaded = RTU.USDConversionRateBidSpreaded`: bid-side USD conversion rate (spreaded = includes spread component)
- `USDConversionRateAskSpreaded = RTU.USDConversionRateAskSpreaded`: ask-side USD conversion rate
- `USDConversionPriceRateID = RTU.USDConversionPriceRateID`: the price rate ID of the conversion rate tick (for tracing which conversion rate was used)
- Includes all discounted fields: BidDiscounted, AskDiscounted, UnitMarginBidDiscounted, UnitMarginAskDiscounted
- Instruments in @RatesToUpdate not found in Trade.CurrencyPrice are silently skipped (no INSERT)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RatesToUpdate | Price.CurrencyPriceTableWithConversionRate READONLY | NOT NULL | - | CODE-BACKED | TVP with full price data including USD conversion rates. Richest TVP in the price update family. Includes: InstrumentID, Bid, Ask, timestamps, PriceRateID, market rate IDs, MarkupPips, UnitMargin, SkewValueBid/Ask, BidDiscounted, AskDiscounted, UnitMarginBid/Ask/BidDiscounted/AskDiscounted, USDConversionRateBidSpreaded, USDConversionRateAskSpreaded, USDConversionPriceRateID. |
| 2 | @ProviderID | INT | NOT NULL | - | CODE-BACKED | The primary feed provider ID. Written to Trade.CurrencyPrice.ProviderID for all updated rows. Identifies which liquidity provider produced these price ticks. |

**Result set**: None.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RatesToUpdate | Price.CurrencyPriceTableWithConversionRate | TVP type | Input price tick batch with USD conversion rates |
| InstrumentID | Trade.CurrencyPrice | WRITER (UPDATE only) | Updates all price fields + USD conversion rates for matching instruments |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (primary pricing engine - with conversion rates) | @RatesToUpdate | CALLER | Called on each primary feed price tick batch when conversion rates are provided |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SetCurrencyPriceBulkWithConversionRate (procedure)
+-- Price.CurrencyPriceTableWithConversionRate (UDT) - TVP type
+-- Trade.CurrencyPrice (table) - UPDATE target (primary price store)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.CurrencyPriceTableWithConversionRate | User Defined Type | TVP parameter type |
| Trade.CurrencyPrice | Table | UPDATE target - all price fields + conversion rates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (primary pricing engine) | External | Calls to update primary price store on each tick batch |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Creates temp table with UNIQUE CLUSTERED INDEX (InstrumentID) at runtime.

### 7.2 Constraints

No SET NOCOUNT ON. No explicit transaction (single UPDATE statement). No INSERT path - all CurrencyPrice rows must pre-exist. No PriceRateID change guard (unlike secondary variants) - all provided instruments are updated on every call, even if the price has not changed. This is appropriate for the primary feed since the pricing engine only calls this procedure when it has a genuinely new price tick. Trade.CurrencyPrice is keyed by InstrumentID (no FeedID in primary) consistent with the temp table clustering. Compare with SetCurrencyPriceBulkWithUnitMargin which is identical except USDConversionRate fields are explicitly set to NULL.

---

## 8. Sample Queries

### 8.1 Update primary prices with conversion rates

```sql
DECLARE @Rates Price.CurrencyPriceTableWithConversionRate;
INSERT INTO @Rates
    (InstrumentID, Bid, Ask, Occurred, PriceRateID, SkewValueBid, SkewValueAsk,
     USDConversionRateBidSpreaded, USDConversionRateAskSpreaded, USDConversionPriceRateID)
VALUES (1, 1.10500000, 1.10520000, GETUTCDATE(), 12345, 0, 0, 1.0, 1.0, 67890);

EXEC Price.SetCurrencyPriceBulkWithConversionRate
    @RatesToUpdate = @Rates,
    @ProviderID = 1;
```

### 8.2 Check current primary prices

```sql
SELECT InstrumentID, Bid, Ask, PriceRateID, ProviderID,
       USDConversionRateBidSpreaded, USDConversionRateAskSpreaded
FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 3)
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SetCurrencyPriceBulkWithConversionRate | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.SetCurrencyPriceBulkWithConversionRate.sql*
