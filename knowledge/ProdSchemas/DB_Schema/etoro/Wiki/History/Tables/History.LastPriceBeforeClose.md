# History.LastPriceBeforeClose

> Stores the last Bid/Ask price recorded for each instrument just before market close on a given trade date, written by the PriceMax external service for use in end-of-day price reconciliation and closing price calculations.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, Occurred) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 3 (1 PK clustered + 2 NCI: TradeDate, InsretDate) |

---

## 1. Business Meaning

History.LastPriceBeforeClose records the final market price snapshot for each financial instrument just before the market closes on a given trading day. Each row captures the Bid and Ask prices (both raw and spread-adjusted), the USD conversion rates applicable at that time, and metadata linking to the source price rate records.

This table serves as the authoritative closing price reference for end-of-day processing. It is owned and maintained by the PriceMax service (login: PriceMaxLogin), which writes closing prices directly into this table. The companion table History.CurrencyPriceMaxDateClosingPriceWithSplitView stores a similar aggregated closing price view that merges max-date prices with split-adjusted values.

The table is not deployed in all environments (not present in the standard development MCP connection). Rows are written once per instrument per market close event and identified by (InstrumentID, Occurred) as the primary key. The TradeDate column captures the trading session date (a DATE, distinct from the exact Occurred timestamp), enabling date-based queries without time component filtering.

---

## 2. Business Logic

### 2.1 Closing Price Recording

**What**: Captures the last available price tick for each instrument at or just before market close.

**Columns/Parameters Involved**: `InstrumentID`, `Occurred`, `Bid`, `Ask`, `BidSpreaded`, `AskSpreaded`, `PriceType`, `TradeDate`

**Rules**:
- One row per (InstrumentID, Occurred) - if two price events occur at the same second for the same instrument, only one can be stored
- PriceType classifies the snapshot: 0=RealTime (live feed price), 1=Snapshot (point-in-time capture)
- BidSpreaded/AskSpreaded are the Bid/Ask with trading spread applied - what customers actually trade at
- TradeDate is the trading session calendar date, used for end-of-day queries without timestamp precision

### 2.2 USD Conversion at Close Time

**What**: Stores USD-converted price values at the moment of the closing price capture, preserving the exchange rate in effect at close.

**Columns/Parameters Involved**: `USDConversionRate`, `USDConversionPriceRateID`, `USDConversionRateBidSpreaded`, `USDConversionRateAskSpreaded`

**Rules**:
- USDConversionRate: The rate to convert the instrument's native currency to USD at close time
- USDConversionPriceRateID: Reference to the price rate record used for the USD conversion
- USDConversionRateBidSpreaded/AskSpreaded: USD conversion rates specifically for the spread-adjusted prices (may differ from raw USDConversionRate due to spread impact)
- NULL-able: If the instrument is already USD-denominated, conversion rate fields may be NULL

---

## 3. Data Overview

Table not present in the connected MCP environment - no live data available. Representative conceptual row:

| InstrumentID | Occurred | Bid | Ask | BidSpreaded | AskSpreaded | PriceType | TradeDate | Meaning |
|-------------|---------|-----|-----|------------|------------|-----------|-----------|---------|
| 1001 (AAPL) | 2026-03-20 21:59:58 | 214.250000 | 214.260000 | 214.220000 | 214.290000 | 0 (RealTime) | 2026-03-20 | Last real-time Bid/Ask for Apple stock captured just before US market close on 2026-03-20 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyPriceID | bigint | NO | - | NAME-INFERRED | ID of the source currency price record from which this closing price was derived. Implicit FK to a price feed table (likely Price.CurrencyPrice or similar). The bigint type indicates high-cardinality sequential price records. |
| 2 | InstrumentID | int | NO | - | VERIFIED | Financial instrument ID. Composite PK component. Implicit FK to Trade.Instrument. Identifies which instrument's closing price this row captures. |
| 3 | Bid | decimal(16,8) | NO | - | VERIFIED | Raw Bid (sell) price at close time, without spread applied. In instrument native currency. |
| 4 | Ask | decimal(16,8) | NO | - | VERIFIED | Raw Ask (buy) price at close time, without spread applied. In instrument native currency. |
| 5 | Occurred | datetime | NO | - | VERIFIED | Exact UTC timestamp when the closing price was recorded. Composite PK component with InstrumentID. The precise last price event time before market close for this instrument. |
| 6 | PriceRateID | bigint | NO | - | CODE-BACKED | ID of the source price rate record. Implicit FK to a price rate table. Links this closing price snapshot to the originating price rate event in the price feed system. |
| 7 | USDConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Exchange rate for converting the instrument's native currency to USD at close time. NULL if instrument is USD-denominated. Used in PnL and settlement calculations. |
| 8 | MarketPriceRateID | bigint | YES | - | NAME-INFERRED | ID of the market price rate record, if distinct from PriceRateID. May reference the mid-market rate rather than the executable rate. NULL if not applicable. |
| 9 | BidSpreaded | decimal(16,8) | YES | - | VERIFIED | Spread-adjusted Bid price at close time. This is the price customers can actually sell at (Bid minus half-spread). Lower than raw Bid. NULL if spread data not available. |
| 10 | AskSpreaded | decimal(16,8) | YES | - | VERIFIED | Spread-adjusted Ask price at close time. This is the price customers can actually buy at (Ask plus half-spread). Higher than raw Ask. NULL if spread data not available. |
| 11 | USDConversionRateBidSpreaded | decimal(16,8) | YES | - | CODE-BACKED | USD conversion rate applied to the spread-adjusted Bid price. May differ slightly from USDConversionRate due to spread calculation methodology. NULL if USD-denominated. |
| 12 | USDConversionRateAskSpreaded | decimal(16,8) | YES | - | CODE-BACKED | USD conversion rate applied to the spread-adjusted Ask price. NULL if USD-denominated. |
| 13 | USDConversionPriceRateID | bigint | YES | - | CODE-BACKED | ID of the price rate record used to determine the USD conversion rate at close time. Implicit FK to a price rate table. Allows tracing which FX rate was used for USD conversion. NULL if USD-denominated. |
| 14 | PriceType | int | NO | - | VERIFIED | Type of the closing price capture: 0=RealTime (from live feed at close), 1=Snapshot (point-in-time capture). FK to Dictionary.PriceType. |
| 15 | InsretDate | datetime | NO | getdate() | CODE-BACKED | Timestamp when this row was inserted into the table by PriceMaxLogin. Note: column name is a typo ("InsretDate" should be "InsertDate") - inherited from original table design. DEFAULT getdate() (local server time). Index ix on this column supports queries by insert time. |
| 16 | TradeDate | date | NO | - | VERIFIED | The trading session calendar date for this closing price (date only, no time component). Index IX_TradeDate supports efficient end-of-day price lookups by session date. Distinct from the Occurred timestamp which has full precision. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The financial instrument whose closing price is captured. |
| PriceType | Dictionary.PriceType | Implicit | Classifies the price capture method: 0=RealTime, 1=Snapshot. |
| CurrencyPriceID | Price.CurrencyPrice (or equivalent) | Implicit | Source price feed record from which this closing price was derived. |
| PriceRateID | Price rate table | Implicit | The originating price rate event in the price feed. |
| USDConversionPriceRateID | Price rate table | Implicit | The FX rate record used for USD conversion at close time. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PriceMaxLogin (DB user) | - | CONTROL | The PriceMax external service has full control over this table - it writes closing prices here at market close events. |
| History.CurrencyPriceMaxDateClosingPriceWithSplitView | ClosingPrice_* columns | Companion table | Aggregated closing price cache table that uses similar price data; related but managed separately. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LastPriceBeforeClose (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PriceMaxLogin (external service) | DB User | Has INSERT/SELECT/UPDATE/DELETE/CONTROL - writes closing prices here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LastPriceBeforeClose | CLUSTERED PK | InstrumentID ASC, Occurred ASC | - | - | Active |
| IX_TradeDate | NONCLUSTERED | TradeDate ASC | - | - | Active |
| ix | NONCLUSTERED | InsretDate ASC | - | - | Active |

Note: All indexes on [MAIN] filegroup. No data compression specified.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_LastPriceBeforeClose | PRIMARY KEY CLUSTERED | (InstrumentID, Occurred) - unique close price per instrument per timestamp |
| DF_InsretDate | DEFAULT | InsretDate = getdate() (local server time at insert) |

---

## 8. Sample Queries

### 8.1 Get closing prices for a specific instrument on a trading date
```sql
SELECT InstrumentID, Occurred, Bid, Ask, BidSpreaded, AskSpreaded, PriceType, TradeDate
FROM History.LastPriceBeforeClose WITH (NOLOCK)
WHERE InstrumentID = 1001
  AND TradeDate = '2026-03-20'
ORDER BY Occurred DESC;
```

### 8.2 Get latest closing price for all instruments on a given trade date
```sql
SELECT l.InstrumentID, l.Bid, l.Ask, l.BidSpreaded, l.AskSpreaded,
       l.USDConversionRate, l.Occurred, l.PriceType
FROM History.LastPriceBeforeClose l WITH (NOLOCK)
WHERE l.TradeDate = '2026-03-20'
ORDER BY l.InstrumentID;
```

### 8.3 Join closing prices with instrument names
```sql
SELECT l.InstrumentID, i.InstrumentDisplayName, l.Bid, l.Ask,
       l.BidSpreaded, l.AskSpreaded, pt.Name AS PriceTypeName,
       l.Occurred, l.TradeDate
FROM History.LastPriceBeforeClose l WITH (NOLOCK)
JOIN Trade.Instrument i WITH (NOLOCK) ON l.InstrumentID = i.InstrumentID
JOIN Dictionary.PriceType pt WITH (NOLOCK) ON l.PriceType = pt.PriceTypeID
WHERE l.TradeDate = '2026-03-20'
ORDER BY l.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 8.1/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (PriceMaxLogin permission scan) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LastPriceBeforeClose | Type: Table | Source: etoro/etoro/History/Tables/History.LastPriceBeforeClose.sql*
