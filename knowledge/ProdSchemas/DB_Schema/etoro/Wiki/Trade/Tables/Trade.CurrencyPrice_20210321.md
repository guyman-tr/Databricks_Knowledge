# Trade.CurrencyPrice_20210321

> Archived snapshot of Trade.CurrencyPrice as of 2021-03-21. Historical price cache structure preserved on DICTIONARY filegroup for reference or rollback.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ProviderID, InstrumentID (implicit composite) |
| **Partition** | No |
| **Indexes** | 0 (no PK or indexes in DDL) |

---

## 1. Business Meaning

Trade.CurrencyPrice_20210321 is an archived copy of the Trade.CurrencyPrice table structure, named with the date 2021-03-21 to indicate the point-in-time backup or migration event. The table resides on the [DICTIONARY] filegroup, which typically holds reference and archival data rather than operational tables. It preserves the historical schema of the live price cache: ProviderID, InstrumentID, Bid, Ask, Occurred, PriceRateID, UnitMargin, BidDiscounted, AskDiscounted, and USD conversion columns.

This table exists because schema or data migrations may require preserving a prior state of CurrencyPrice for audit, rollback, or comparison. The date suffix follows a common pattern (e.g., CurrencyPrice_20210321) for versioned snapshots. No procedures in the SSDT repo read or write this table; it is archival/reference only.

Data flows: Original data was likely populated via a one-time INSERT...SELECT from Trade.CurrencyPrice during a migration or backup. No ongoing read/write from application procedures. Inherits business semantics from Trade.CurrencyPrice (see Trade.CurrencyPrice.md): ProviderID and InstrumentID identify the price feed and instrument; Bid/Ask are raw rates; UnitMargin, BidDiscounted, AskDiscounted support execution and P&L logic.

---

## 2. Business Logic

### 2.1 Archived Price Structure

**What**: Snapshot of (ProviderID, InstrumentID) price rows with bid, ask, unit margin, and conversion columns as of 2021-03-21.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `Bid`, `Ask`, `Occurred`, `UnitMargin`, `BidDiscounted`, `AskDiscounted`

**Rules**:
- Same column set as Trade.CurrencyPrice at that point in time (minus later additions like OccurredOnServer defaults).
- Stored on [DICTIONARY] filegroup; no PK or indexes in DDL.
- No active procedures reference this table.

### 2.2 Inherited Semantics from CurrencyPrice

**What**: Bid/Ask, UnitMargin, and conversion columns follow the same meaning as Trade.CurrencyPrice.

**Rules**: See Trade.CurrencyPrice.md sections 2.1 (One Row Per ProviderID/InstrumentID), 2.2 (Bid/Ask and Discounted Prices), 2.3 (Price Rate Linkage).

---

## 3. Data Overview

| ProviderID | InstrumentID | Bid | Ask | Occurred | UnitMargin | BidDiscounted | AskDiscounted | Meaning |
|------------|--------------|-----|-----|----------|------------|---------------|---------------|---------|
| (No live data sampled) | - | - | - | - | - | - | - | Archival table; MCP query returned empty. Use Trade.CurrencyPrice for current structure reference. |

**Selection criteria**: Table may be empty or populated only in specific environments. DDL defines structure; semantics inherit from Trade.CurrencyPrice.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Provider identifier. Implicit FK to Trade.Provider. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier. Implicit FK to Trade.Instrument. |
| 3 | Bid | dbo.dtPrice | NO | - | CODE-BACKED | Bid rate at snapshot time. |
| 4 | Ask | dbo.dtPrice | NO | - | CODE-BACKED | Ask rate at snapshot time. |
| 5 | Occurred | datetime | NO | - | CODE-BACKED | When price was last updated before snapshot. |
| 6 | OccurredOnServer | datetime | NO | - | CODE-BACKED | Server timestamp of price reception. |
| 7 | PriceRateID | bigint | NO | - | CODE-BACKED | Tick/rate identifier. |
| 8 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | When price server received the tick. |
| 9 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market rate ID. |
| 10 | LastPrice | dbo.dtPrice | NO | - | CODE-BACKED | Last traded/reference price. |
| 11 | BidMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for bid source. |
| 12 | AskMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for ask source. |
| 13 | MarkupPips | decimal(18,0) | YES | - | CODE-BACKED | Markup in pips. |
| 14 | UnitMargin | decimal(12,5) | NO | - | CODE-BACKED | Margin per unit for P&L. |
| 15 | SkewValueBid | decimal(19,8) | NO | - | CODE-BACKED | Bid skew. |
| 16 | SkewValueAsk | decimal(19,8) | NO | - | CODE-BACKED | Ask skew. |
| 17 | BidDiscounted | dbo.dtPrice | NO | - | CODE-BACKED | Spread-discounted bid. |
| 18 | AskDiscounted | dbo.dtPrice | NO | - | CODE-BACKED | Spread-discounted ask. |
| 19 | UnitMarginBidDiscounted | decimal(10,5) | YES | - | CODE-BACKED | Discounted unit margin for bid. |
| 20 | UnitMarginAskDiscounted | decimal(10,5) | YES | - | CODE-BACKED | Discounted unit margin for ask. |
| 21 | UnitMarginBid | decimal(12,5) | YES | - | CODE-BACKED | Unit margin for bid. |
| 22 | UnitMarginAsk | decimal(12,5) | YES | - | CODE-BACKED | Unit margin for ask. |
| 23 | USDConversionRateBidSpreaded | dbo.dtPrice | YES | - | CODE-BACKED | USD conversion rate (bid, spreaded). |
| 24 | USDConversionRateAskSpreaded | dbo.dtPrice | YES | - | CODE-BACKED | USD conversion rate (ask, spreaded). |
| 25 | USDConversionPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for USD conversion instrument. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Trade.Provider | Implicit | Provider lookup. |
| InstrumentID | Trade.Instrument | Implicit | Instrument lookup. |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None in SSDT) | - | - | No procedure or view references this table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CurrencyPrice_20210321 (archival table)
└── Trade.Provider (implicit)
└── Trade.Instrument (implicit)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Provider | Table | Implicit ProviderID lookup |
| Trade.Instrument | Table | Implicit InstrumentID lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None) | - | Archival; no active dependents. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (None) | - | - | - | - | No indexes in DDL |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| (None) | - | No PK, FK, or check constraints in DDL |

---

## 8. Sample Queries

### 8.1 Sample rows by Provider and Instrument
```sql
SELECT TOP 5 ProviderID, InstrumentID, Bid, Ask, Occurred, UnitMargin, BidDiscounted, AskDiscounted
  FROM Trade.CurrencyPrice_20210321 WITH (NOLOCK)
 WHERE ProviderID = 1
 ORDER BY InstrumentID
```

### 8.2 Compare structure with live CurrencyPrice
```sql
SELECT 'Archive' AS Source, ProviderID, InstrumentID, Bid, Ask, UnitMargin
  FROM Trade.CurrencyPrice_20210321 WITH (NOLOCK)
 WHERE InstrumentID = 1
UNION ALL
SELECT 'Live', ProviderID, InstrumentID, Bid, Ask, UnitMargin
  FROM Trade.CurrencyPrice WITH (NOLOCK)
 WHERE InstrumentID = 1
```

### 8.3 Count rows by provider
```sql
SELECT ProviderID, COUNT(*) AS RowCount
  FROM Trade.CurrencyPrice_20210321 WITH (NOLOCK)
 GROUP BY ProviderID
 ORDER BY ProviderID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: SSDT DDL, Trade.CurrencyPrice inherited knowledge | Procedures: 0 | Corrections: 0 applied*
*Object: Trade.CurrencyPrice_20210321 | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CurrencyPrice_20210321.sql*
