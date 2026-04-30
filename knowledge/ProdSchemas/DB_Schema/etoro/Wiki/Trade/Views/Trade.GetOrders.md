# Trade.GetOrders

> Wrapper view over Trade.Orders that exposes all order columns with IsBuy and IsOverWeekend cast from BIT to INT for application compatibility.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | OrderID (from Trade.Orders) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetOrders provides a read-only, NOLOCK view of the Trade.Orders table with two type conversions: IsBuy and IsOverWeekend are cast from BIT to INT. This answers: "Give me the current pending/active orders with integer-typed boolean flags." The BIT-to-INT conversion exists because some consuming applications and APIs expect integer types (0/1) rather than SQL BIT values for these flags.

This view exists as an abstraction layer so that callers always get orders with consistent INT typing for boolean fields. The Trade.Orders table stores IsBuy and IsOverWeekend as BIT, but the original application layer (circa 2019, per the FB 53719 change log) needed INT values. Rather than modifying every consumer, this view provides the conversion centrally.

Data flows: The view reads directly from Trade.Orders with NOLOCK. No filtering or aggregation is applied - all rows from the base table pass through. Trade.GetOrderHierarchy is the primary consumer, using this view to build order tree structures.

---

## 2. Business Logic

### 2.1 BIT-to-INT Type Conversion

**What**: IsBuy and IsOverWeekend are CONVERT'd from BIT to INT.

**Columns/Parameters Involved**: `IsBuy`, `IsOverWeekend`

**Rules**:
- `CONVERT(INT, IsBuy)`: BIT 1 -> INT 1 (Buy/Long), BIT 0 -> INT 0 (Sell/Short)
- `CONVERT(INT, IsOverWeekend)`: BIT 1 -> INT 1 (order spans weekend), BIT 0 -> INT 0 (intra-week)
- All other columns pass through without transformation

### 2.2 No Filtering - Full Orders Pass-Through

**What**: Unlike Trade.GetOpenOrders (which filters StatusID=1), this view returns all orders regardless of status.

**Columns/Parameters Involved**: All columns

**Rules**:
- No WHERE clause - all orders (open, closed, cancelled, pending) are included
- The view is a simple SELECT with NOLOCK from Trade.Orders
- Created as part of FB 53719 (Free Stocks feature, March 2019)

---

## 3. Data Overview

No rows returned in the current environment (staging/test may not have active orders).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | Primary key from Trade.Orders. Unique identifier for each order placed on the platform. |
| 2 | CID | bigint | NO | - | CODE-BACKED | Customer ID who placed the order. FK to Customer.Customer.CID. |
| 3 | CurrencyID | int | NO | - | CODE-BACKED | The denomination currency of the order. FK to Dictionary.Currency.CurrencyID. |
| 4 | ProviderID | int | NO | - | CODE-BACKED | The execution provider handling this order. FK to Trade.Provider.ProviderID. |
| 5 | OrderTypeID | tinyint | NO | - | CODE-BACKED | Type of order: defines whether it is a market order, limit order, stop order, etc. FK to Dictionary.OrderType. |
| 6 | InstrumentID | int | NO | - | CODE-BACKED | The tradeable instrument for this order. FK to Trade.Instrument.InstrumentID. |
| 7 | Leverage | int | NO | - | CODE-BACKED | The leverage multiplier applied to this order. Higher leverage = more market exposure relative to invested amount. |
| 8 | Amount | money | NO | - | CODE-BACKED | The monetary amount invested in this order, in the order's currency. |
| 9 | Units | decimal | NO | - | CODE-BACKED | Number of units (shares, lots, contracts) for this order. |
| 10 | UnitMargin | decimal | YES | - | CODE-BACKED | Margin required per unit. Used in margin calculations for leveraged positions. |
| 11 | LotCountDecimal | decimal | YES | - | CODE-BACKED | Lot count expressed as a decimal for fractional lot support. |
| 12 | RateFrom | decimal | NO | - | CODE-BACKED | Lower bound of the acceptable rate range for order execution. For market orders, the minimum acceptable rate. |
| 13 | RateTo | decimal | NO | - | CODE-BACKED | Upper bound of the acceptable rate range for order execution. For market orders, the maximum acceptable rate. |
| 14 | IsBuy | int | NO | - | CODE-BACKED | Direction flag converted from BIT to INT: 1 = Buy/Long position, 0 = Sell/Short position. Original BIT in Trade.Orders. |
| 15 | ForexResultID | int | YES | - | CODE-BACKED | Links to the forex execution result. Used for tracking order execution outcomes. |
| 16 | GameID | int | YES | - | CODE-BACKED | Legacy identifier from the original game/social-trading platform. Used for backward compatibility. |
| 17 | SpreadID | int | YES | - | CODE-BACKED | Identifies the spread configuration applied to this order. FK to Trade.Spread.SpreadID. |
| 18 | LoginID | int | YES | - | CODE-BACKED | The login session ID under which this order was placed. |
| 19 | IsOverWeekend | int | NO | - | CODE-BACKED | Weekend rollover flag converted from BIT to INT: 1 = order spans the weekend (rolls over), 0 = intra-week only. |
| 20 | StopLosAmount | money | YES | - | CODE-BACKED | Stop loss threshold expressed as a monetary amount. When the loss reaches this amount, the position is auto-closed. |
| 21 | TakeProfitAmount | money | YES | - | CODE-BACKED | Take profit threshold as a monetary amount. When profit reaches this amount, the position is auto-closed. |
| 22 | MarketSpreadPips | decimal | YES | - | CODE-BACKED | Market spread at order time measured in pips. Records the spread conditions when the order was placed. |
| 23 | MarketSpreadCents | decimal | YES | - | CODE-BACKED | Market spread at order time measured in cents. Alternative spread measurement for non-forex instruments. |
| 24 | StopLosRate | decimal | YES | - | CODE-BACKED | Stop loss expressed as a specific rate. When the market rate hits this level, the position is closed. |
| 25 | TakeProfitRate | decimal | YES | - | CODE-BACKED | Take profit expressed as a specific rate. When the market rate hits this level, the position is closed with profit. |
| 26 | TradeRange | decimal | YES | - | CODE-BACKED | The acceptable execution price range (market range) for this order. Defines slippage tolerance. |
| 27 | OccurredTime | datetime | NO | - | CODE-BACKED | Timestamp when the order was placed/created. |
| 28 | ParentOrderID | bigint | YES | - | CODE-BACKED | For copy-trade orders, points to the parent order that triggered this copy. NULL for manually placed orders. Self-reference to Trade.Orders.OrderID. |
| 29 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether this order received a fee discount (1=discounted, 0=standard fee). |
| 30 | IsSettled | bit | YES | - | CODE-BACKED | Legacy real-stock flag: 1 = real stock position (customer owns shares), 0 = CFD. Predates SettlementTypeID. |
| 31 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type: 1=Real stocks, 2=CFD, 3=Crypto, 5=MarginTrade. Supersedes the legacy IsSettled flag. FK to Dictionary.SettlementTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | Trade.Orders | FROM | Base table - all order data passes through |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrderHierarchy | OrderID | READER | Builds order tree structures from this view to display parent/child copy-trade orders |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrders (view)
+-- Trade.Orders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | FROM - all order data, read with NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrderHierarchy | Stored Procedure | Reads order data to build order tree hierarchy |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get recent orders for a specific customer

```sql
SELECT  TOP 10 *
FROM    Trade.GetOrders WITH (NOLOCK)
WHERE   CID = 12345678
ORDER BY OccurredTime DESC
```

### 8.2 Find all copy-trade orders (orders with a parent)

```sql
SELECT  OrderID,
        CID,
        ParentOrderID,
        InstrumentID,
        IsBuy,
        Amount
FROM    Trade.GetOrders WITH (NOLOCK)
WHERE   ParentOrderID IS NOT NULL
ORDER BY OccurredTime DESC
```

### 8.3 Show orders with instrument names and settlement types

```sql
SELECT  o.OrderID,
        o.CID,
        gi.Name AS InstrumentName,
        o.IsBuy,
        o.Amount,
        o.Leverage,
        o.SettlementTypeID,
        o.OccurredTime
FROM    Trade.GetOrders o WITH (NOLOCK)
JOIN    Trade.GetInstrument gi WITH (NOLOCK) ON o.InstrumentID = gi.InstrumentID
ORDER BY o.OccurredTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrders | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetOrders.sql*
