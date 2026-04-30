# Trade.GetPublicStockOrdersDataWithOrderIdForAPI

> Returns a public-safe subset of a single stock order from Stocks.Orders by OrderID, covering both entry and exit order types.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @orderId INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a single stock order by its OrderID from `Stocks.Orders` (cross-schema). It is the single-record lookup variant of `Trade.GetPublicStockOrdersDataWithCIDForAPI`, which returns all stock orders for a customer. Both procedures expose the same 8 public-safe fields from the 30+ column Stocks.Orders table.

Used when the caller already has a specific OrderID and needs the public details of that one stock order - for example, to check the status of a recently placed stock trade request. The result can be either an entry order (IsEntry=1, position-opening) or an exit order (IsEntry=0, position-closing).

---

## 2. Business Logic

### 2.1 Single Stock Order Lookup by OrderID

**What**: Returns the public fields for one specific stock order from Stocks.Orders.

**Columns/Parameters Involved**: `@orderId`, `Stocks.Orders.OrderID`, `IsEntry`

**Rules**:
- Returns 0 rows if the OrderID does not exist.
- Returns 1 row for a valid OrderID (OrderID is the PK of Stocks.Orders).
- IsEntry distinguishes whether this is an open-position order or close-position order.
- ISNULL coercion on MirrorID and PositionID - zero-safe for public display.

**Diagram**:
```
@orderId
  |
  v
Stocks.Orders (WHERE OrderID = @orderId)
  |
  OUTPUT: CID, InstrumentID, IsBuy, IsEntry,
          MirrorID, OpenRequest, OrderID, PositionID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @orderId | INT | NO | - | CODE-BACKED | The specific stock order to retrieve. PK lookup on Stocks.Orders.OrderID. Returns 0 rows if order does not exist. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID who placed this order. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | The stock instrument ordered. FK to Trade.Instrument. |
| 4 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 5 | IsEntry | BIT | NO | - | CODE-BACKED | Order type: 1=Entry (opening a new position), 0=Exit (closing an existing position). |
| 6 | MirrorID | INT | NO | - | CODE-BACKED | CopyTrader mirror ID. ISNULL(MirrorID, 0) - 0=manual order, >0=copy-trade auto-generated. |
| 7 | OpenRequest | DATETIME | NO | - | CODE-BACKED | Timestamp when the order was submitted/requested. |
| 8 | OrderID | INT | NO | - | CODE-BACKED | Unique stock order identifier. Echoed from the input filter. |
| 9 | PositionID | BIGINT | NO | - | CODE-BACKED | Associated position. ISNULL(PositionID, 0) - 0 for unexecuted entry orders; linked position for exit orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @orderId / all output | Stocks.Orders | Reader (cross-schema) | Source of stock order data, filtered to the requested order |
| PositionID | Trade.Position | Implicit reference | Links exit orders to the open position being closed |
| MirrorID | Trade.Mirror | Implicit FK | Links copy-trade orders to their mirror relationship |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @orderId | Application call | Single stock order detail lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPublicStockOrdersDataWithOrderIdForAPI (procedure)
+-- Stocks.Orders (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Stocks.Orders | Table (Stocks schema) | Filtered by OrderID - returns single stock order record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Single stock order detail retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED for API performance |
| PK lookup | Performance | OrderID is the clustered PK of Stocks.Orders - single-row point lookup |

---

## 8. Sample Queries

### 8.1 Get a specific stock order by ID

```sql
EXEC Trade.GetPublicStockOrdersDataWithOrderIdForAPI @orderId = 456789;
```

### 8.2 Equivalent inline query

```sql
SELECT so.CID, so.InstrumentID, so.IsBuy, so.IsEntry,
       ISNULL(so.MirrorID, 0) AS MirrorID, so.OpenRequest,
       so.OrderID, ISNULL(so.PositionID, 0) AS PositionID
FROM Stocks.Orders so WITH (NOLOCK)
WHERE so.OrderID = 456789;
```

### 8.3 Check whether a stock order opened or closed a position

```sql
SELECT so.OrderID, so.CID,
       CASE WHEN so.IsEntry = 1 THEN 'Opening Order' ELSE 'Closing Order' END AS OrderPurpose,
       ISNULL(so.PositionID, 0) AS PositionID,
       so.OpenRequest
FROM Stocks.Orders so WITH (NOLOCK)
WHERE so.OrderID = 456789;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicStockOrdersDataWithOrderIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicStockOrdersDataWithOrderIdForAPI.sql*
