# Price.GetCurrentPricesSnapshot

> Returns a snapshot of all current instrument prices from Trade.CurrencyPrice, exposing bid/ask, USD conversion rates, price rate IDs, timestamps, and discounted prices - the primary price snapshot endpoint for the Price schema.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full price table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetCurrentPricesSnapshot is a full-table snapshot read of `Trade.CurrencyPrice` - the live price store that holds the current bid/ask for every instrument across all feeds. It returns the current state of all prices in a single bulk result set, with selected column aliases that match the API contract expected by the pricing service consumers.

This procedure exists as the named price snapshot endpoint. Consumers (pricing engines, risk systems, admin dashboards) call it to get a complete, consistent point-in-time view of all current instrument prices without needing to know the internal column names of Trade.CurrencyPrice.

The output aliases reveal the API naming convention: `InstrumentID` -> `InstrumentId` (camelCase ID), `PriceRateID` -> `PriceRateId`, `Occurred` -> `Date`. These aliases indicate the procedure is consumed by a service or API layer that uses camelCase JSON/DTO conventions.

---

## 2. Business Logic

### 2.1 Column Selection and Aliasing

**What**: The procedure selects a subset of Trade.CurrencyPrice columns with aliases that match the downstream API contract.

**Columns/Parameters Involved**: All output columns.

**Rules**:
- `InstrumentID AS InstrumentId` - camelCase alias for API consumers
- `USDConversionRateAskSpreaded AS ConversionRateAsk` - the spread-adjusted USD conversion rate on the ask side
- `USDConversionRateBidSpreaded AS ConversionRateBid` - the spread-adjusted USD conversion rate on the bid side
- `Occurred AS [Date]` - the timestamp when this price tick occurred (bracketed because Date is a reserved word)
- `BidDiscounted` and `AskDiscounted` - discounted price levels (used for customer discount programs)
- Columns NOT selected: ProviderID, LastPrice, MarkupPips, MarketPriceRateID, SkewValueBid, SkewValueAsk, UnitMargin, ReceivedOnPriceServer, OccurredOnServer, BidMarketPriceRateID, AskMarketPriceRateID, USDConversionPriceRateID, UnitMarginBid, UnitMarginAsk - these are present in Trade.CurrencyPrice but not exposed by this snapshot

### 2.2 No Pagination, No Filters

**What**: Returns every row in Trade.CurrencyPrice unconditionally.

**Rules**:
- No WHERE clause - all instruments
- No ORDER BY - result set order is nondeterministic (determined by clustered index traversal order)
- Uses `(nolock)` - reads without locks, accepts phantom reads for performance on this high-churn table
- Trade.CurrencyPrice is an in-memory optimized or high-frequency table; NOLOCK is standard for price reads

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No input parameters. Returns all rows from Trade.CurrencyPrice with selected columns. |

**Result set columns** (9 columns):

| # | Output Column | Source Column | Description |
|---|--------------|---------------|-------------|
| 1 | InstrumentId | InstrumentID | eToro instrument identifier (camelCase alias for API) |
| 2 | Ask | Ask | Current ask price (offer price - what clients pay to buy) |
| 3 | Bid | Bid | Current bid price (what clients receive when selling) |
| 4 | ConversionRateAsk | USDConversionRateAskSpreaded | Spread-adjusted USD conversion rate for the ask side. Used to convert non-USD instrument prices to USD for P&L calculations. |
| 5 | ConversionRateBid | USDConversionRateBidSpreaded | Spread-adjusted USD conversion rate for the bid side. |
| 6 | PriceRateId | PriceRateID | Unique identifier for this specific price tick (bigint - sequential, high-volume). Used to detect price staleness and correlate with audit tables. |
| 7 | Date | Occurred | Timestamp when this price tick occurred on the price server. The alias "Date" (bracketed reserved word) matches the API DTO property name. |
| 8 | BidDiscounted | BidDiscounted | Discounted bid price for customer discount programs. May differ from Bid when discounts are active. |
| 9 | AskDiscounted | AskDiscounted | Discounted ask price for customer discount programs. May differ from Ask when discounts are active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | Trade.CurrencyPrice | READER | Full-table read of the live price store |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing service / API) | - | CALLER | Called to get a bulk snapshot of all current instrument prices |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetCurrentPricesSnapshot (procedure)
+-- Trade.CurrencyPrice (table) - full-table read
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | FROM source - entire live price table read with selected columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing service consumers) | External | Calls to retrieve bulk current price snapshot |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

SET NOCOUNT ON. No parameters, no filters, no ORDER BY, no pagination. Uses `(nolock)` on Trade.CurrencyPrice for lock-free reads. The procedure is a thin wrapper over Trade.CurrencyPrice - its primary value is providing stable column aliases that match the API contract, insulating callers from internal column name changes in CurrencyPrice.

---

## 8. Sample Queries

### 8.1 Execute the price snapshot

```sql
EXEC Price.GetCurrentPricesSnapshot;
```

### 8.2 Equivalent manual query

```sql
SELECT
    InstrumentID     AS InstrumentId,
    Ask,
    Bid,
    USDConversionRateAskSpreaded AS ConversionRateAsk,
    USDConversionRateBidSpreaded AS ConversionRateBid,
    PriceRateID      AS PriceRateId,
    Occurred         AS [Date],
    BidDiscounted,
    AskDiscounted
FROM Trade.CurrencyPrice WITH (NOLOCK);
```

### 8.3 Check price freshness for a specific instrument

```sql
SELECT InstrumentID AS InstrumentId, Bid, Ask, Occurred AS [Date]
FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetCurrentPricesSnapshot | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetCurrentPricesSnapshot.sql*
