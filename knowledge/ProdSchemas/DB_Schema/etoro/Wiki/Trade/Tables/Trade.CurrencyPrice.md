# Trade.CurrencyPrice

> Real-time price cache for all instruments per provider. Stores latest bid, ask, and derived pricing used by order placement and position valuation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ProviderID, InstrumentID (composite PK) |
| **Partition** | No |
| **Indexes** | 5 active (PK + 4 NC) |

---

## 1. Business Meaning

Trade.CurrencyPrice is the live price cache that holds the current bid, ask, and related rates for every (ProviderID, InstrumentID) pair. Price feeds (from external sources or internal aggregation) UPDATE this table continuously. Order placement (Trade.OrdersAdd), position close (Trade.PositionClose), conversion rate lookups (Trade.FnGetCurrentConversionRate, Trade.FnGetCurrentClosingRate), and many other procedures read from CurrencyPrice to get the latest executable prices.

This table exists because the trading engine needs fast, single-row lookups for "what is the current price for EUR/USD on Provider 1?" without querying raw tick data. Each (ProviderID, InstrumentID) has exactly one row that is overwritten on each price update. The ProviderToInstrument INSERT trigger seeds a row with zero bid/ask when a new instrument-provider pair is created.

Data flows: Trade.SetCurrencyPrice and price feed processes UPDATE rows. Trade.OrdersAdd SELECTs Bid, Ask, (Bid+Ask)/2 for order rate validation. Trade.PositionOpen and Trade.PositionClose JOIN for closing rate and conversion. Trade.ActivateSplit_Inner UPDATEs prices when splits activate. Trade.InsertBSLMInstruction triggers snapshot CurrencyPrice for BSL message context.

---

## 2. Business Logic

### 2.1 One Row Per (ProviderID, InstrumentID)

**What**: Each provider-instrument pair has exactly one row. Prices are overwritten in place.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `Bid`, `Ask`, `Occurred`

**Rules**:
- Composite PK (ProviderID, InstrumentID). FK to Trade.ProviderToInstrument.
- On ProviderToInstrument INSERT, InstrumentProviderInsert trigger INSERTs a row with Bid=0, Ask=0, default Occurred.
- Price updates are UPDATEs, not INSERTs. No history in this table (History.CurrencyPrice exists elsewhere if needed).

**Diagram**:
```
ProviderID=1, InstrumentID=1 (EUR/USD) -> single row, Bid/Ask overwritten on each tick
ProviderID=1, InstrumentID=5 (JPY)    -> single row, LastPrice, UnitMargin, etc.
```

### 2.2 Bid/Ask and Discounted Prices

**What**: Raw market bid/ask plus spread-adjusted (discounted) prices for execution.

**Columns/Parameters Involved**: `Bid`, `Ask`, `BidDiscounted`, `AskDiscounted`, `UnitMargin`, `UnitMarginBidDiscounted`, `UnitMarginAskDiscounted`

**Rules**:
- Bid/Ask are raw or markup-included rates. BidDiscounted/AskDiscounted apply spread/customer discount.
- UnitMargin is the margin per unit for P&L. UnitMarginBidDiscounted/UnitMarginAskDiscounted are discount-adjusted.
- Trade.OrdersAdd uses (Bid+Ask)/2 when LastOpPriceRate is NULL. Trade.GetEstimatedTreeUnitsByCID uses UnitMargin from CurrencyPrice.

### 2.3 Price Rate Linkage

**What**: PriceRateID and related IDs link to external rate tick streams for audit and reconciliation.

**Columns/Parameters Involved**: `PriceRateID`, `MarketPriceRateID`, `BidMarketPriceRateID`, `AskMarketPriceRateID`, `USDConversionPriceRateID`

**Rules**:
- PriceRateID is the tick identifier for the current price.
- MarketPriceRateID, BidMarketPriceRateID, AskMarketPriceRateID support split bid/ask source tracking.
- USDConversionPriceRateID links to the conversion instrument's rate for non-USD instruments.

---

## 3. Data Overview

| ProviderID | InstrumentID | Bid | Ask | LastPrice | UnitMargin | BidDiscounted | AskDiscounted | Meaning |
|------------|--------------|-----|-----|-----------|------------|---------------|---------------|---------|
| 1 | 1 | 1.085 | 1.09 | 1.0869 | 1.085 | 1.087 | 1.087 | EUR/USD on Provider 1. Tight spread (~5 pips). BidDiscounted slightly above Bid (spread discount). |
| 1 | 2 | 1.33785 | 1.33788 | 1.337859 | 1.33785 | 1.33786 | 1.33786 | GBP (Instrument 2). Very tight spread. |
| 1 | 5 | 566314.14 | 566314.143 | 566314.1411 | 566314.14 | 566314.141 | 566314.141 | JPY pair - large numeric values typical for JPY. |
| 1 | 4 | 9.37736 | 9.37739 | 9.377373 | 1 | 9.37738 | 9.37738 | CAD - UnitMargin=1 indicates special handling. USDConversionRateBidSpreaded used for conversion. |
| 1 | 10 | 169.794 | 169.799 | 169.796 | 25874.74 | 169.796 | 169.796 | EUR/JPY cross. UnitMargin reflects pip value. |

**Selection criteria**: Picked from live TOP 10 - major forex (1,2,4,5,6,7,8,9,10) showing variety of Bid/Ask, UnitMargin, and conversion patterns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | 0 | CODE-BACKED | Part of PK. FK to Trade.ProviderToInstrument. TCRP_NULLPROVIDER default. |
| 2 | InstrumentID | int | NO | 0 | CODE-BACKED | Part of PK. FK to Trade.ProviderToInstrument. TCRP_NULLINSTRUMENT default. |
| 3 | Bid | dbo.dtPrice | NO | - | CODE-BACKED | Current bid rate. OrdersAdd, PositionClose, FnGetCurrentClosingRate read this. |
| 4 | Ask | dbo.dtPrice | NO | - | CODE-BACKED | Current ask rate. Used with Bid for mid-price and validation. |
| 5 | Occurred | datetime | NO | getdate() | CODE-BACKED | When this price was last updated. TCRP_LASTUPDATE default. |
| 6 | OccurredOnServer | datetime | NO | - | CODE-BACKED | Server timestamp of price reception. |
| 7 | PriceRateID | bigint | NO | - | CODE-BACKED | Tick/rate identifier. Links to price feed stream. Indexed (IX_PriceRateID). |
| 8 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | When price server received the tick. |
| 9 | MarketPriceRateID | bigint | YES | 0 | CODE-BACKED | Market rate ID. TCRP_NullMarketPriceRateID default. |
| 10 | LastPrice | dbo.dtPrice | NO | 0 | CODE-BACKED | Last traded/reference price. DF_CurrencyPrice_LastPrice default. |
| 11 | BidMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for bid source. |
| 12 | AskMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for ask source. |
| 13 | MarkupPips | decimal(18,0) | YES | - | CODE-BACKED | Markup in pips. |
| 14 | UnitMargin | decimal(16,8) | NO | 0 | CODE-BACKED | Margin per unit for P&L. DF_CurrencyPrice_UnitMargin. GetEstimatedTreeUnitsByCID uses this. |
| 15 | SkewValueBid | decimal(19,8) | NO | 0 | CODE-BACKED | Bid skew. Default 0. |
| 16 | SkewValueAsk | decimal(19,8) | NO | 0 | CODE-BACKED | Ask skew. Default 0. |
| 17 | BidDiscounted | dbo.dtPrice | NO | 0 | CODE-BACKED | Spread-discounted bid. DF_TCRP_BidDiscounted. |
| 18 | AskDiscounted | dbo.dtPrice | NO | 0 | CODE-BACKED | Spread-discounted ask. DF_TCRP_AskDiscounted. |
| 19 | UnitMarginBidDiscounted | decimal(16,8) | YES | - | CODE-BACKED | Discounted unit margin for bid side. |
| 20 | UnitMarginAskDiscounted | decimal(16,8) | YES | - | CODE-BACKED | Discounted unit margin for ask side. |
| 21 | UnitMarginBid | decimal(16,8) | YES | - | CODE-BACKED | Unit margin for bid. |
| 22 | UnitMarginAsk | decimal(16,8) | YES | - | CODE-BACKED | Unit margin for ask. |
| 23 | USDConversionRateBidSpreaded | dbo.dtPrice | YES | - | CODE-BACKED | USD conversion rate (bid, spreaded) for non-USD instruments. |
| 24 | USDConversionRateAskSpreaded | dbo.dtPrice | YES | - | CODE-BACKED | USD conversion rate (ask, spreaded). |
| 25 | USDConversionPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for USD conversion instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID, InstrumentID | Trade.ProviderToInstrument | FK | FK_TPVI_TCRP. Must exist before CurrencyPrice row. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrdersAdd | FROM | Reader | Price lookup for order rate (Bid, Ask, (Bid+Ask)/2). |
| Trade.PositionOpen | FROM | Reader | Fallback price when rate not from order. |
| Trade.PositionClose | LEFT JOIN | Reader | Closing rate, conversion. |
| Trade.ManualPositionClose | FROM | Reader | Manual close price. |
| Trade.ManualPositionStopLoss | FROM | Reader | SL validation. |
| Trade.ManualPositionTakeProfit | FROM | Reader | TP validation. |
| Trade.FnGetCurrentClosingRate | FROM | Reader | Current closing rate. |
| Trade.FnGetCurrentConversionRate | FROM | Reader | Conversion rate for non-USD. |
| Trade.GetCurrentPrice | View | FROM | Base for current price view. |
| Trade.GetCurrentPriceAndConversionRate | View | FROM | Price + conversion. |
| Trade.ProviderToInstrument | Trigger | Writer | InstrumentProviderInsert seeds row on INSERT. |
| Trade.SetCurrencyPrice | UPDATE | Modifier | Price feed updates. |
| Trade.ActivateSplit_Inner | UPDATE | Modifier | Split activation price update. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CurrencyPrice (table)
└── Trade.ProviderToInstrument (table)
      ├── Trade.Provider (table)
      └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FK (ProviderID, InstrumentID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersAdd | Procedure | SELECT Bid, Ask for order rate |
| Trade.PositionOpen | Procedure | SELECT for fallback rate |
| Trade.PositionClose | Procedure | LEFT JOIN for close/conversion |
| Trade.GetCurrentPrice | View | FROM Trade.CurrencyPrice |
| Trade.GetCurrentPriceAndConversionRate | View | FROM (rate, convrate) |
| Trade.SetCurrencyPrice | Procedure | UPDATE |
| Trade.FnGetCurrentClosingRate | Function | FROM |
| Trade.FnGetCurrentConversionRate | Function | FROM |
| Trade.ProviderToInstrument | Table | Trigger seeds row |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TCRP | CLUSTERED | ProviderID, InstrumentID | - | - | Active |
| IX_InstruemtID | NC | InstrumentID | Bid, BidDiscounted, Ask, AskDiscounted | - | Active |
| IX_PriceRateID | NC | PriceRateID | Bid, Ask | - | Active |
| TCRP_INSTRUMENT | NC | InstrumentID | Ask, BidDiscounted, AskDiscounted, PriceRateID, Bid | - | Active |
| TCRP_PROVIDER | NC | ProviderID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TPVI_TCRP | FK | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument |
| TCRP_NULLPROVIDER | DEFAULT | ProviderID = 0 |
| TCRP_NULLINSTRUMENT | DEFAULT | InstrumentID = 0 |
| TCRP_LASTUPDATE | DEFAULT | Occurred = getdate() |
| TCRP_NullMarketPriceRateID | DEFAULT | MarketPriceRateID = 0 |
| DF_CurrencyPrice_LastPrice | DEFAULT | LastPrice = 0 |
| DF_CurrencyPrice_UnitMargin | DEFAULT | UnitMargin = 0 |
| (SkewValueBid/Ask, BidDiscounted, AskDiscounted) | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Get current price for an instrument
```sql
SELECT ProviderID, InstrumentID, Bid, Ask, (Bid + Ask) / 2 AS MidPrice,
       LastPrice, Occurred
  FROM Trade.CurrencyPrice CP WITH (NOLOCK)
 WHERE ProviderID = 1 AND InstrumentID = 1
```

### 8.2 Resolve prices with instrument and provider names
```sql
SELECT CP.ProviderID, P.Name AS ProviderName, CP.InstrumentID, PTI.PresentationCode,
       CP.Bid, CP.Ask, CP.BidDiscounted, CP.AskDiscounted, CP.UnitMargin
  FROM Trade.CurrencyPrice CP WITH (NOLOCK)
  JOIN Trade.Provider P WITH (NOLOCK) ON P.ProviderID = CP.ProviderID
  JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK)
    ON PTI.ProviderID = CP.ProviderID AND PTI.InstrumentID = CP.InstrumentID
 WHERE CP.InstrumentID IN (1, 5, 10)
```

### 8.3 Find stale prices (not updated recently)
```sql
SELECT CP.ProviderID, CP.InstrumentID, CP.Bid, CP.Ask, CP.Occurred,
       DATEDIFF(SECOND, CP.Occurred, GETUTCDATE()) AS SecondsSinceUpdate
  FROM Trade.CurrencyPrice CP WITH (NOLOCK)
 WHERE CP.Occurred < DATEADD(MINUTE, -5, GETUTCDATE())
 ORDER BY CP.Occurred ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.4/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.CurrencyPrice | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CurrencyPrice.sql*
