# Dictionary.StockOrderCloseReason

> Classifies the reason why a stock order was closed or cancelled in the trading system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OrderCloseReasonID (int, PK) |
| **Row Count** | 5 |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

### What It Is
Dictionary.StockOrderCloseReason is a lookup table that categorizes the reasons why stock orders are closed or cancelled. Each entry provides a human-readable label mapped to a numeric ID used throughout the order lifecycle.

### Why It Exists
When stock orders are moved from the live trading engine to the historical archive (`History.StocksOrders`), each order must record **why** it was closed. This table provides the standardized set of close reasons, enabling accurate reporting on order outcomes and distinguishing between normal execution, user-initiated cancellations, and CopyTrading cascade closures.

### How It Works
The `OrderCloseReasonID` column is written to `History.StocksOrders` during order archival. The default value is `1` (Normal), meaning orders that complete their lifecycle without intervention are recorded as normally closed. CopyTrading-specific reasons (3, 4, 5) track cascade effects when parent orders or mirrors are closed. The `Cancel` reason (10) covers explicit user/system cancellations.

---

## 2. Business Logic

### Value Map (Complete — 5 rows)

| OrderCloseReasonID | Name | Business Meaning |
|---------------------|------|------------------|
| 1 | Normal | Standard order completion — order executed or expired naturally |
| 3 | Parent Order Canceled | CopyTrading cascade — parent trader's order was cancelled, triggering child cancellation |
| 4 | Mirror Closed | CopyTrading — the mirror (copy) relationship was terminated |
| 5 | Parent Mirror Closed | CopyTrading cascade — parent mirror relationship closed, triggering child order closure |
| 10 | Cancel | Explicit cancellation — user or system cancelled the order |

### ID Gap Pattern
IDs 2, 6-9 are not assigned, suggesting either deprecated values removed over time or reserved slots.

### CopyTrading Cascade Pattern
Three of five values (3, 4, 5) relate to CopyTrading, indicating this table was extended specifically to track mirror/copy cascade effects on stock orders.

---

## 3. Data Overview

| OrderCloseReasonID | Name | Scenario |
|---------------------|------|----------|
| 1 | Normal | A stock buy order executes at market price and fills completely |
| 3 | Parent Order Canceled | A copied trader cancels their pending order, auto-cancelling all copier orders |
| 4 | Mirror Closed | User stops copying a trader, closing all open copy orders |
| 5 | Parent Mirror Closed | The parent CopyTrading link closes, cascading to child mirror orders |
| 10 | Cancel | User manually cancels a pending entry order |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderCloseReasonID | int | NO | — | HIGH | Primary key identifying the close reason. Referenced by `History.StocksOrders.OrderCloseReasonID` (default `1` = Normal). Values: `1`=Normal, `3`=Parent Order Canceled, `4`=Mirror Closed, `5`=Parent Mirror Closed, `10`=Cancel. |
| 2 | Name | char(50) | NO | — | HIGH | Human-readable label for the close reason. Fixed-width `char(50)` with trailing spaces. |

---

## 5. Relationships

### Referenced By (Implicit — no declared FK)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| History.StocksOrders | OrderCloseReasonID | Implicit FK → OrderCloseReasonID | DDL default `1`, used in all stock archival procedures |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Stocks.OpenPosition | INSERT into History.StocksOrders | Archives order with OrderCloseReasonID during position opening |
| Stocks.ClosePosition | INSERT into History.StocksOrders | Archives order with OrderCloseReasonID during position closing |
| Stocks.CloseExitOrder | INSERT into History.StocksOrders | Archives exit orders with close reason |
| Stocks.CancelEntryOrder | INSERT into History.StocksOrders | Archives cancelled entry orders with close reason |
| Stocks.CancelOrderExecSingle | INSERT into History.StocksOrders | Archives single cancelled execution orders with close reason |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `History.StocksOrders` — stores `OrderCloseReasonID` for every archived stock order

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_DSOCR | CLUSTERED PK | OrderCloseReasonID ASC | Abbreviated PK name (Dictionary Stock Order Close Reason) |

---

## 8. Sample Queries

```sql
-- Get all close reasons
SELECT  OrderCloseReasonID,
        RTRIM(Name) AS Name
FROM    Dictionary.StockOrderCloseReason WITH (NOLOCK)
ORDER BY OrderCloseReasonID;

-- Find the close reason for a specific archived order
SELECT  so.OrderID,
        RTRIM(cr.Name) AS CloseReason
FROM    History.StocksOrders so WITH (NOLOCK)
JOIN    Dictionary.StockOrderCloseReason cr WITH (NOLOCK)
        ON so.OrderCloseReasonID = cr.OrderCloseReasonID
WHERE   so.OrderID = @OrderID;

-- Count archived orders by close reason
SELECT  RTRIM(cr.Name) AS CloseReason,
        COUNT(*) AS OrderCount
FROM    History.StocksOrders so WITH (NOLOCK)
JOIN    Dictionary.StockOrderCloseReason cr WITH (NOLOCK)
        ON so.OrderCloseReasonID = cr.OrderCloseReasonID
GROUP BY cr.Name
ORDER BY OrderCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `StockOrderCloseReason`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.StockOrderCloseReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.StockOrderCloseReason.sql*
