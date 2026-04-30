# Trade.GetOrdersDataWithCIDForAPI

> Returns all pending orders for a customer from Trade.Orders - the bulk API-facing order listing with null-safe output and amount converted from cents to dollars.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersDataWithCIDForAPI` retrieves all pending orders from `Trade.Orders` for a given customer ID. It is the bulk counterpart to `GetOrdersDataWithCIDAndOrderIdForAPI` - returning ALL of a customer's orders rather than a specific one.

**WHY:** APIs need to display a customer's full pending order list (order book). This SP provides that data with null-safe numeric defaults and amount in dollars.

**HOW:** Single SELECT from Trade.Orders WHERE CID = @cid. Same output schema as GetOrdersDataWithCIDAndOrderIdForAPI.

Change log: 2017-08-08 (FB 47233 - AmountInUnitsDecimal added), 2019-03-13 (FB 53719 - Free Stocks, added IsDiscounted).

---

## 2. Business Logic

### 2.1 All Orders for Customer - No Status Filter

**What:** Returns all Trade.Orders rows for the customer regardless of status. The API layer must handle the full order lifecycle state.

**Columns/Parameters Involved:** `@cid`

**Rules:**
- `WHERE o.CID = @cid` -> all orders for this customer, no StatusID filter
- Includes root orders (ParentOrderID=0) AND child orders (ParentOrderID!=0)

### 2.2 Null-Safe API Output - Same Pattern as CID+OrderId Variant

**What:** Identical ISNULL defaults as GetOrdersDataWithCIDAndOrderIdForAPI. Amount converted from cents to dollars.

See GetOrdersDataWithCIDAndOrderIdForAPI Section 2.2 for full details.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID whose orders to retrieve. All orders for this customer are returned. |

**Output columns (from Trade.Orders WHERE CID=@cid) - identical to GetOrdersDataWithCIDAndOrderIdForAPI:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Unique order ID. |
| 2 | OrderTypeID | INT | YES | - | CODE-BACKED | Order type classification. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID (equals @cid). ISNULL defaulted to 0. |
| 4 | AmountInDollars | DECIMAL | NO | - | CODE-BACKED | Order amount in dollars: ISNULL(Amount, 0) / 100. Trade.Orders stores in cents. |
| 5 | OccurredTime | DATETIME | YES | - | CODE-BACKED | Order placement timestamp. |
| 6 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being ordered. ISNULL defaulted to 0. |
| 7 | IsBuy | INT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. ISNULL defaulted to 0. |
| 8 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. ISNULL defaulted to 0. |
| 9 | TakeProfitRate | DECIMAL | NO | - | CODE-BACKED | Take-profit rate. ISNULL defaulted to 0. |
| 10 | StopLosRate | DECIMAL | NO | - | CODE-BACKED | Stop-loss rate. ISNULL defaulted to 0. |
| 11 | ParentOrderID | INT | NO | - | CODE-BACKED | Parent order ID. ISNULL defaulted to 0 (0 = root/independent order). |
| 12 | RateFrom | DECIMAL | NO | - | CODE-BACKED | Lower price bound. ISNULL defaulted to 0. |
| 13 | AmountInUnitsDecimal | DECIMAL | NO | - | CODE-BACKED | Order size in instrument units. ISNULL defaulted to 0. Added FB 47233 (2017). |
| 14 | IsTslEnabled | BIT | YES | - | CODE-BACKED | 1 if Trailing Stop Loss is enabled. Not null-defaulted. |
| 15 | IsDiscounted | INT | NO | - | CODE-BACKED | 1 if fee discount applies. ISNULL defaulted to 0. Added FB 53719 (Free Stocks, 2019). |
| 16 | IsNoStopLoss | BIT | YES | - | CODE-BACKED | 1 if no stop-loss protection. Not null-defaulted. |
| 17 | IsNoTakeProfit | BIT | YES | - | CODE-BACKED | 1 if no take-profit level. Not null-defaulted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.Orders | Trade.Orders | Lookup | Source of all pending orders for the customer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersDataWithCIDForAPI (procedure)
|- Trade.Orders (table) - source of customer orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | All orders for @cid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by trading API for customer order book display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL(value, 0) | Null safety | API-safe defaults for all numeric columns |
| Amount / 100 | Computation | Converts cents to dollars |

---

## 8. Sample Queries

### 8.1 Get all orders for a customer

```sql
EXEC Trade.GetOrdersDataWithCIDForAPI
    @cid = 87654321
```

### 8.2 Get a specific order for a customer

```sql
-- Use the CID+OrderId variant for single-order lookup:
EXEC Trade.GetOrdersDataWithCIDAndOrderIdForAPI
    @orderId = 12345678,
    @cid = 87654321
```

### 8.3 Count pending orders by customer

```sql
SELECT CID, COUNT(*) AS PendingOrders
FROM Trade.Orders WITH (NOLOCK)
GROUP BY CID
HAVING COUNT(*) > 5
ORDER BY PendingOrders DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.5/10, Logic: 6.0/10, Relationships: 5.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersDataWithCIDForAPI.sql*
