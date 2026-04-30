# Trade.GetAllOpenOrders

> Unified view of open orders from both OrderForOpen and OrderForClose, exposing pending open and close orders (StatusID=1 RECEIVED) in a normalized column layout for API and UI consumption.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | OrderID (unique per branch) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetAllOpenOrders is a UNION ALL view that combines pending orders from two memory-optimized tables: Trade.OrderForOpen (position-open orders) and Trade.OrderForClose (position-close orders). Only orders with StatusID=1 (RECEIVED) appear - orders that have not yet been placed or filled. The view normalizes column names (e.g., StopRate -> StopLosRate, LimitRate -> TakeProfitRate, OrderType -> OrderTypeID) and adds NULL placeholders for columns that exist in one branch but not the other, so callers get a uniform result set.

The view exists so Trade.GetOrdersForDataApi and other consumers can query all "open" orders (open + close) in a single call without knowing which table to read. Without it, callers would need to UNION OrderForOpen and OrderForClose manually, handling the column differences. Close orders are identified by OrderTypeID=14 (ExitOrder) and have InstrumentID=NULL; open orders have the full order details.

Data flows: OrderForOpen inserts via OrderForOpenCreate; OrderForClose inserts via OrderForCloseCreate. Both use StatusID=1 initially. When status advances to PLACED, FILLED, etc., rows disappear from this view. The view is read-only; no INSERT/UPDATE.

---

## 2. Business Logic

### 2.1 Two Branches: Open vs Close

**What**: Branch 1 (OrderForOpen) = position-open orders. Branch 2 (OrderForClose) = position-close orders with OrderTypeID=14.

**Columns/Parameters Involved**: `OrderTypeID`, `InstrumentID`, `ExitOrderPositionID`

**Rules**:
- Open orders: OrderType from base table (1=OpenTrade, 17=OrderForExecutionByAmount, 18=OrderForExecutionByUnits). InstrumentID, Amount, Leverage, StopLosRate, TakeProfitRate populated. ExitOrderPositionID=NULL.
- Close orders: OrderTypeID=14 (ExitOrder) hardcoded. InstrumentID=NULL. ExitOrderPositionID=PositionID (position being closed). AmountInUnits=UnitsToDeduct.

**Diagram**:
```
Branch 1: OrderForOpen WHERE StatusID=1
  -> OrderID, CID, OrderTypeID, InstrumentID, Amount, AmountInUnits, StopLosRate, TakeProfitRate, Occurred, etc.

Branch 2: OrderForClose WHERE StatusID=1
  -> OrderID, CID, ExitOrderPositionID=PositionID, OrderTypeID=14, AmountInUnits=UnitsToDeduct, Occurred
```

### 2.2 Null Placeholders for Unified Schema

**What**: Columns that exist in one branch only are NULL in the other.

**Columns/Parameters Involved**: `StopLosPercentage`, `TakeProfitPercentage`, `RateFrom`, `RateTo`, `IsTslEnabled`, `IsDiscounted`

**Rules**:
- Open orders: StopLosPercentage, TakeProfitPercentage, RateFrom, RateTo = NULL (legacy columns not used in view).
- Close orders: InstrumentID, Leverage, Amount, IsBuy, StopLosRate, TakeProfitRate, StopLosPercentage, TakeProfitPercentage, IsTslEnabled, IsDiscounted, RateFrom, RateTo = NULL.

---

## 3. Data Overview

| OrderID | CID | ExitOrderPositionID | OrderTypeID | InstrumentID | Meaning |
|---------|-----|---------------------|-------------|--------------|---------|
| (when open orders exist) | - | NULL | 1,17,18 | 1 | Open order for EUR/USD. StatusID=1 RECEIVED. |
| (when close orders exist) | - | 12345 | 14 | NULL | Close order for PositionID 12345. OrderTypeID=14 ExitOrder. |

**Note**: Live MCP sample returned 0 rows (no open orders at query time). The view is typically non-empty during active trading; rows are transient. When populated, rows represent either pending open orders (InstrumentID set) or pending close orders (ExitOrderPositionID set, OrderTypeID=14).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | Primary key from base table. Unique order identifier. (From OrderForOpen/OrderForClose) |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. Links to Trading.Customer. (From OrderForOpen/OrderForClose) |
| 3 | ExitOrderPositionID | bigint | YES | - | CODE-BACKED | Close branch only: PositionID being closed. NULL for open orders. (From OrderForClose.PositionID) |
| 4 | OrderTypeID | int | NO | - | CODE-BACKED | Dictionary.OrderType. Open: 1,17,18. Close: 14 (ExitOrder). Renamed from OrderType. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Instrument to trade. NULL for close orders. (From OrderForOpen) |
| 6 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier. NULL for close orders. (From OrderForOpen) |
| 7 | Amount | money | YES | - | CODE-BACKED | Order size in currency. NULL for close orders. (From OrderForOpen) |
| 8 | IsBuy | tinyint | YES | - | CODE-BACKED | 1=Buy (long), 0=Sell (short). NULL for close orders. (From OrderForOpen) |
| 9 | StopLosRate | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss price. From StopRate (open). NULL for close. (From OrderForOpen.StopRate) |
| 10 | TakeProfitRate | decimal(16,8) | YES | - | CODE-BACKED | Take-profit price. From LimitRate (open). NULL for close. (From OrderForOpen.LimitRate) |
| 11 | StopLosPercentage | decimal(16,8) | YES | - | CODE-BACKED | View constant: NULL. Placeholder for percentage-based SL. |
| 12 | TakeProfitPercentage | decimal(16,8) | YES | - | CODE-BACKED | View constant: NULL. Placeholder for percentage-based TP. |
| 13 | Occurred | datetime | NO | - | CODE-BACKED | When order entered table. From OpenOccurred. (From OrderForOpen/OrderForClose) |
| 14 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | Trailing stop-loss enabled. From OrderForOpen. NULL for close. |
| 15 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Open: AmountInUnits. Close: UnitsToDeduct. |
| 16 | IsDiscounted | tinyint | YES | - | CODE-BACKED | Order has discount. From OrderForOpen. NULL for close. |
| 17 | RateFrom | decimal | YES | - | CODE-BACKED | View constant: NULL. Placeholder. |
| 18 | RateTo | decimal | YES | - | CODE-BACKED | View constant: NULL. Placeholder. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Trading.Customer | Lookup | Customer who placed the order |
| InstrumentID | Trade.Instrument | Lookup | Instrument for open orders |
| ExitOrderPositionID | Trade.Position | Lookup | Position being closed (close orders) |
| OrderTypeID | Dictionary.OrderType | Lookup | Order type (1,14,17,18) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrdersForDataApi | FROM | Reader | Data API order feed |
| Trade.GetOrderForContextData | FROM | Reader | Context data for orders |
| Trade.GetPortfolioAggregates | FROM | Reader | Portfolio aggregation |
| Trade.GetMirrorDataWithCIDForAPI | FROM | Reader | Mirror/CopyTrader API |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllOpenOrders (view)
├── Trade.OrderForOpen (table)
└── Trade.OrderForClose (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | FROM - open orders WHERE StatusID=1 |
| Trade.OrderForClose | Table | FROM - close orders WHERE StatusID=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrdersForDataApi | Procedure | FROM for Data API |
| Trade.GetOrderForContextData | Procedure | Reader |
| Trade.GetPortfolioAggregates | Procedure | Reader |
| Trade.GetMirrorDataWithCIDForAPI | Procedure | Reader |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All open orders (open + close)
```sql
SELECT OrderID, CID, OrderTypeID, InstrumentID, AmountInUnits, StopLosRate, TakeProfitRate, Occurred
  FROM Trade.GetAllOpenOrders WITH (NOLOCK)
 ORDER BY Occurred DESC
```

### 8.2 Open orders only (position-open, exclude close)
```sql
SELECT OrderID, CID, InstrumentID, Amount, AmountInUnits, IsBuy, Leverage, Occurred
  FROM Trade.GetAllOpenOrders WITH (NOLOCK)
 WHERE OrderTypeID <> 14
 ORDER BY Occurred
```

### 8.3 Close orders with position resolution
```sql
SELECT o.OrderID, o.CID, o.ExitOrderPositionID AS PositionID, o.AmountInUnits, o.Occurred,
       p.InstrumentID, IMD.Symbol
  FROM Trade.GetAllOpenOrders o WITH (NOLOCK)
  JOIN Trade.Position p WITH (NOLOCK) ON o.ExitOrderPositionID = p.PositionID
  JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON p.InstrumentID = IMD.InstrumentID
 WHERE o.OrderTypeID = 14
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.6/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllOpenOrders | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetAllOpenOrders.sql*
