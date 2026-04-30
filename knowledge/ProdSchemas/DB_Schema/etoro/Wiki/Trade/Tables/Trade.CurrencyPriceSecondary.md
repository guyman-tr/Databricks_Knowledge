# Trade.CurrencyPriceSecondary

> Per-provider, per-instrument, per-feed secondary currency price feed holding bid/ask, skew, and unit margins for alternate price sources used in feed comparison and margin calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ProviderID, InstrumentID, FeedID (composite PK) |
| **Partition** | No |
| **Indexes** | 3 |

---

## 1. Business Meaning

Trade.CurrencyPriceSecondary stores **alternate** (secondary) price feeds for instrument-provider pairs, distinguished by FeedID. Unlike Trade.CurrencyPrice (the primary feed), this table holds one row per (ProviderID, InstrumentID, FeedID) — enabling multiple feeds per instrument for comparison and validation. The primary use case is Trade.CollectCurrencyPriceDifferencesBetweenFeeds, which compares FeedID=2 secondary bid/ask against the primary CurrencyPrice and inserts rows into dbo.Syn_CurrencyPriceFeedDifferences when prices diverge beyond a tolerance.

Data flows in from the Price schema: Price.SetCurrencyPriceBulkSecondary and Price.SetCurrencyPriceBulkSecondaryWithUnitMargin perform UPDATE (when prices changed) or INSERT (for new instrument-feed combinations). Each row carries bid, ask, skew values, market price rate IDs, and unit margins. The explicit FK to Trade.ProviderToInstrument ensures only tradeable instrument-provider pairs receive secondary prices.

---

## 2. Business Logic

### 2.1 Feed Differentiation and Tolerance Checking

**What**: Multiple feeds per (ProviderID, InstrumentID) allow validation that secondary feeds stay within a percentage of the primary feed.

**Columns/Parameters Involved**: FeedID, Bid, Ask, Occurred, ProviderID, InstrumentID.

**Rules**:
- FeedID=2 is used by CollectCurrencyPriceDifferencesBetweenFeeds as the secondary feed to compare against primary CurrencyPrice.
- When secondary Bid or Ask falls outside LowerBid..UpperBid or LowerAsk..UpperAsk (derived from primary × tolerance), a difference row is inserted into Syn_CurrencyPriceFeedDifferences.
- One row per (ProviderID, InstrumentID, FeedID) — PK enforces uniqueness.

### 2.2 Price Update Semantics (Upsert)

**What**: Price.SetCurrencyPriceBulkSecondary performs UPDATE when PriceRateID differs, INSERT when no row exists for the instrument-feed pair.

**Columns/Parameters Involved**: PriceRateID, Bid, Ask, Occurred, OccurredOnServer, MarketPriceRateID, LastPrice, SkewValueBid, SkewValueAsk, UnitMarginBid, UnitMarginAsk.

**Rules**:
- UPDATE: joins on InstrumentID, FeedID where CP.PriceRateID <> RTU.PriceRateID.
- INSERT: when NOT EXISTS (CPS for same InstrumentID, FeedID).
- @ProviderID is passed as a parameter and applied to all updated/inserted rows.

### 2.3 Skew and Unit Margin

**What**: SkewValueBid/Ask and UnitMargin/UnitMarginBid/UnitMarginAsk support asymmetric pricing and per-side margin calculations.

**Columns/Parameters Involved**: SkewValueBid, SkewValueAsk, UnitMargin, UnitMarginBid, UnitMarginAsk.

**Rules**:
- SkewValueBid and SkewValueAsk default to 0; used for spreaded pricing adjustments.
- UnitMarginBid and UnitMarginAsk can differ; SetCurrencyPriceBulkSecondaryWithUnitMargin populates both; base SetCurrencyPriceBulkSecondary sets UnitMarginAsk = NULL.

---

## 3. Data Overview

Live data sample was empty at documentation time (connected DB may not have secondary feed configured). Representative structure from DDL and procedure logic:

| ProviderID | InstrumentID | FeedID | Bid | Ask | Occurred | PriceRateID | Meaning |
|------------|--------------|--------|-----|-----|----------|-------------|---------|
| 1 | 1 | 2 | 1.08500 | 1.08520 | 2026-03-14 10:00:00 | 123456789 | EUR/USD secondary feed. Used for feed-difference checks against primary. |
| 1 | 5 | 2 | 149.500 | 149.520 | 2026-03-14 10:00:01 | 123456790 | JPY secondary feed. Alternate source for validation. |
| 1 | 10 | 2 | 163.200 | 163.220 | 2026-03-14 10:00:02 | 123456791 | EUR/JPY secondary feed. Multi-feed setup for major crosses. |

**Selection criteria**: Picked from typical forex instrument IDs (1, 5, 10) with FeedID=2 per CollectCurrencyPriceDifferencesBetweenFeeds usage.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | 0 | CODE-BACKED | FK to Trade.ProviderToInstrument. Part of PK. Execution provider for this price row. |
| 2 | InstrumentID | int | NO | 0 | CODE-BACKED | FK to Trade.ProviderToInstrument. Part of PK. Tradeable instrument. |
| 3 | Bid | dbo.dtPrice | NO | - | CODE-BACKED | Bid price for the secondary feed. Used in feed-difference checks. |
| 4 | Ask | dbo.dtPrice | NO | - | CODE-BACKED | Ask price for the secondary feed. |
| 5 | Occurred | datetime | NO | getdate() | CODE-BACKED | When the price occurred (market time). Default DF_CurrencyPriceSecondary_LASTUPDATE. |
| 6 | OccurredOnServer | datetime | NO | - | CODE-BACKED | When the price was received on the price server. |
| 7 | PriceRateID | bigint | NO | - | CODE-BACKED | Unique identifier for this price tick. Used to detect changes (PriceRateID <> RTU.PriceRateID). |
| 8 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | Timestamp when price server received the rate. |
| 9 | MarketPriceRateID | bigint | YES | 0 | CODE-BACKED | Reference to market price rate. Default 0. |
| 10 | LastPrice | dbo.dtPrice | NO | 0 | CODE-BACKED | Last traded price. Default 0. |
| 11 | BidMarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate for bid side. |
| 12 | AskMarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate for ask side. |
| 13 | MarkupPips | decimal(12,4) | YES | - | CODE-BACKED | Markup in pips applied to prices. |
| 14 | UnitMargin | decimal(12,5) | YES | - | CODE-BACKED | Margin per unit (single value). |
| 15 | FeedID | smallint | NO | - | CODE-BACKED | Identifies the secondary feed. FeedID=2 used in CollectCurrencyPriceDifferencesBetweenFeeds. Part of PK. |
| 16 | SkewValueBid | decimal(19,8) | NO | 0 | CODE-BACKED | Skew adjustment for bid. Default 0. |
| 17 | SkewValueAsk | decimal(19,8) | NO | 0 | CODE-BACKED | Skew adjustment for ask. Default 0. |
| 18 | UnitMarginBid | decimal(12,5) | YES | - | CODE-BACKED | Per-unit margin for bid side. Set by SetCurrencyPriceBulkSecondaryWithUnitMargin. |
| 19 | UnitMarginAsk | decimal(12,5) | YES | - | CODE-BACKED | Per-unit margin for ask side. Set by SetCurrencyPriceBulkSecondaryWithUnitMargin. |

---

## 5. Relationships

### 5.1 References To
| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID, InstrumentID | Trade.ProviderToInstrument | FK (explicit) | FK_CurrencyPriceSecondary_ProviderToInstrument. Only valid provider-instrument pairs. |

### 5.2 Referenced By
| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CollectCurrencyPriceDifferencesBetweenFeeds | CPS | JOIN | Compares secondary FeedID=2 to primary CurrencyPrice; inserts into Syn_CurrencyPriceFeedDifferences when out of tolerance. |
| Price.SetCurrencyPriceBulkSecondary | CP, CPS | UPDATE, INSERT | Bulk update/insert of secondary prices. |
| Price.SetCurrencyPriceBulkSecondaryWithUnitMargin | CP, CPS | UPDATE, INSERT | Same as above, with UnitMarginBid/Ask. |

---

## 6. Dependencies

### 6.0 Dependency Chain
```
Trade.CurrencyPriceSecondary (table)
└── Trade.ProviderToInstrument (table) [FK]
```

### 6.1 Objects This Depends On
| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FK (ProviderID, InstrumentID). |
| dbo.dtPrice | UDT | Bid, Ask, LastPrice. |

### 6.2 Objects That Depend On This
| Object | Type | How Used |
|--------|------|----------|
| Trade.CollectCurrencyPriceDifferencesBetweenFeeds | Procedure | JOIN for feed comparison. |
| Price.SetCurrencyPriceBulkSecondary | Procedure | UPDATE, INSERT. |
| Price.SetCurrencyPriceBulkSecondaryWithUnitMargin | Procedure | UPDATE, INSERT. |
| dbo.Syn_CurrencyPriceFeedDifferences | Table | Insert target for feed differences. |

---

## 7. Technical Details

### 7.1 Indexes
| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CurrencyPriceSecondary | CLUSTERED PK | ProviderID, InstrumentID, FeedID | - | - | Active |
| IX_CurrencyPriceSecondary_INSTRUMENT | NC | InstrumentID | - | - | Active |
| IX_CurrencyPriceSecondary_PROVIDER | NC | ProviderID | - | - | Active |

### 7.2 Constraints
| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_CurrencyPriceSecondary_ProviderToInstrument | FK | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument |
| DF_CurrencyPriceSecondary_PROVIDERID | DEFAULT | ProviderID = 0 |
| DF_CurrencyPriceSecondary_INSTRUMENTID | DEFAULT | InstrumentID = 0 |
| DF_CurrencyPriceSecondary_LASTUPDATE | DEFAULT | Occurred = getdate() |
| DF_CurrencyPriceSecondary_MarketPriceRateID | DEFAULT | MarketPriceRateID = 0 |
| DF_CurrencyPriceSecondary_LastPrice | DEFAULT | LastPrice = 0 |
| (Unnamed) | DEFAULT | SkewValueBid = 0 |
| (Unnamed) | DEFAULT | SkewValueAsk = 0 |

---

## 8. Sample Queries

### 8.1 List secondary prices for a provider and feed
```sql
SELECT CPS.ProviderID, CPS.InstrumentID, CPS.FeedID, CPS.Bid, CPS.Ask, CPS.Occurred,
       CPS.PriceRateID, CPS.MarketPriceRateID, CPS.SkewValueBid, CPS.SkewValueAsk
  FROM Trade.CurrencyPriceSecondary CPS WITH (NOLOCK)
 WHERE CPS.ProviderID = 1 AND CPS.FeedID = 2
 ORDER BY CPS.InstrumentID;
```

### 8.2 Compare primary vs secondary prices for FeedID 2
```sql
SELECT CP.InstrumentID, CP.ProviderID,
       CP.Bid AS PrimaryBid, CPS.Bid AS SecondaryBid,
       CP.Ask AS PrimaryAsk, CPS.Ask AS SecondaryAsk,
       CP.Occurred AS PrimaryOccurred, CPS.Occurred AS SecondaryOccurred
  FROM Trade.CurrencyPrice CP WITH (NOLOCK)
 INNER JOIN Trade.CurrencyPriceSecondary CPS WITH (NOLOCK)
    ON CPS.ProviderID = CP.ProviderID AND CPS.InstrumentID = CP.InstrumentID AND CPS.FeedID = 2;
```

### 8.3 Get latest secondary price per instrument for FeedID 2
```sql
SELECT CPS.InstrumentID, CPS.Bid, CPS.Ask, CPS.Occurred, CPS.PriceRateID
  FROM Trade.CurrencyPriceSecondary CPS WITH (NOLOCK)
 INNER JOIN (SELECT InstrumentID, MAX(Occurred) AS MaxOccurred
               FROM Trade.CurrencyPriceSecondary WITH (NOLOCK)
              WHERE FeedID = 2
              GROUP BY InstrumentID) M ON CPS.InstrumentID = M.InstrumentID AND CPS.Occurred = M.MaxOccurred
 WHERE CPS.FeedID = 2;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| - | - | No Atlassian sources linked in documentation. |

---

*Generated: 2026-03-14 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 4/10)*
