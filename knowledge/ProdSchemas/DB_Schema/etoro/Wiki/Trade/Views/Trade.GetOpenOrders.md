# Trade.GetOpenOrders

> Returns all currently active trading orders with customer username, joining Trade.Orders to Customer.Customer. Base table holds only open orders, so the view effectively exposes the open-order set.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | OrderID (from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetOpenOrders is the primary view for exposing active (open or pending) trading orders. It joins Trade.Orders to Customer.Customer to attach the customer's UserName to each order. The view name is accurate: Trade.Orders is a write-then-delete table - closed orders are moved to History.Orders and removed from this table, so every row in Trade.Orders is by definition an open order.

This view exists so callers can get open orders with display-ready data (UserName) without replicating the JOIN. Applications, matching engines, and portfolio aggregates use it to list pending orders and entry orders awaiting execution. Without it, every caller would need to join Orders to Customer to resolve usernames.

Data flows: The view reads from Trade.Orders (active only) and Customer.Customer with NOLOCK. No WHERE filter on the view - the base table semantics ensure only open orders appear. AmountInUnitsDecimal is computed as LotCountDecimal * Units when the base column is NULL.

---

## 2. Business Logic

### 2.1 Open Order Semantics

**What**: The view returns "open" orders because Trade.Orders holds only active orders.

**Columns/Parameters Involved**: N/A (base table semantics)

**Rules**:
- Trade.OrdersAdd INSERTs new rows when customers place orders
- Trade.OrdersClose DELETEs rows and copies to History.Orders when orders fill or are cancelled
- Therefore every row in Trade.Orders is an open order; no explicit WHERE StatusID needed

### 2.2 AmountInUnitsDecimal Computation

**What**: When Orders.AmountInUnitsDecimal is NULL, the view computes it as LotCountDecimal * Units.

**Columns/Parameters Involved**: `AmountInUnitsDecimal`, `LotCountDecimal`, `Units`

**Rules**:
- Expression: LotCountDecimal * TORD.Units AS AmountInUnitsDecimal
- Supports fractional share trading when AmountInUnitsDecimal was added (FB 47233, Aug 2017)
- Units comes from Trade.ProviderToInstrument via the instrument-provider pair

### 2.3 Proximity Constant

**What**: Proximity is always 0 - a placeholder for order-distance logic.

**Columns/Parameters Involved**: `Proximity`

**Rules**:
- 0 AS Proximity - constant; no dynamic calculation in this view

---

## 3. Data Overview

| CID | UserName | OrderID | InstrumentID | Leverage | LotCountDecimal | Amount | AmountInUnitsDecimal | IsBuy | RateFrom | Meaning |
|-----|----------|---------|---------------|----------|-----------------|--------|----------------------|-------|---------|---------|
| (varies) | (varies) | (varies) | (varies) | (varies) | (varies) | (varies) | (varies) | (varies) | (varies) | Live sample returned empty - Trade.Orders is hot table; test env may have no open orders. |

**Selection criteria**: Trade.Orders holds active orders only. When no customers have pending orders, the view returns 0 rows. Documented structure from DDL and Trade.Orders table documentation.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | FK to Customer.Customer. Customer identifier. From Trade.Orders. |
| 2 | UserName | varchar | YES | - | CODE-BACKED | Customer display name. From Customer.Customer.UserName via JOIN. |
| 3 | OrderID | int | NO | - | CODE-BACKED | Primary key of the order. From Trade.Orders. Referenced by position creation. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The instrument being ordered. From Trade.Orders. |
| 5 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier for the order. From Trade.Orders. |
| 6 | OrderTypeID | int | NO | - | CODE-BACKED | Order type (market, pending, etc.). From Trade.Orders. FK to Dictionary.OrderType. |
| 7 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Precise lot count. From Trade.Orders. Multiplied by Units for AmountInUnitsDecimal. |
| 8 | Amount | decimal(18,2) | YES | - | CODE-BACKED | Order amount in account currency. From Trade.Orders. |
| 9 | AmountInUnitsDecimal | decimal(16,6) | NO | computed | CODE-BACKED | Computed: LotCountDecimal * TORD.Units. Position size in units (fractional shares). |
| 10 | IsBuy | bit | NO | - | CODE-BACKED | 1=buy, 0=sell. From Trade.Orders. |
| 11 | RateFrom | decimal(28,8) | YES | - | CODE-BACKED | Trigger/entry rate for pending orders. From Trade.Orders. |
| 12 | TradeRange | smallint | NO | - | CODE-BACKED | Allowed trade range (pips). From Trade.Orders. |
| 13 | Proximity | int | NO | 0 | CODE-BACKED | Constant 0. Placeholder for order-distance logic. |
| 14 | ParentOrderID | bigint | YES | - | CODE-BACKED | Copy-trade parent order. 0/NULL=independent. From Trade.Orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | FK/JOIN | Customer who placed the order |
| OrderID, InstrumentID, etc. | Trade.Orders | Base | Source of order data |
| InstrumentID | Trade.Instrument | Lookup | Instrument definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Orders (doc) | View reader | READER | GetOpenOrders listed as key reader of Orders |
| Application/matching layer | - | READER | Used for open order display; no direct SQL ref in repo |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenOrders (view)
├── Trade.Orders (table)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | FROM - base order data |
| Customer.Customer | Table | INNER JOIN - CID = TORD.CID for UserName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders (doc) | Table | Documented as key reader |
| Application layer | External | Open order listing; no procedure FROM in repo |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List open orders for a customer
```sql
SELECT CID, UserName, OrderID, InstrumentID, Leverage, LotCountDecimal,
       Amount, AmountInUnitsDecimal, IsBuy, RateFrom, TradeRange, ParentOrderID
  FROM Trade.GetOpenOrders WITH (NOLOCK)
 WHERE CID = 12345678
 ORDER BY OrderID;
```

### 8.2 Open orders by instrument
```sql
SELECT InstrumentID, COUNT(*) AS OrderCount, SUM(Amount) AS TotalAmount
  FROM Trade.GetOpenOrders WITH (NOLOCK)
 GROUP BY InstrumentID
 ORDER BY OrderCount DESC;
```

### 8.3 Copy-trade child orders
```sql
SELECT OrderID, ParentOrderID, CID, UserName, InstrumentID, Amount
  FROM Trade.GetOpenOrders WITH (NOLOCK)
 WHERE ParentOrderID > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenOrders | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetOpenOrders.sql*
