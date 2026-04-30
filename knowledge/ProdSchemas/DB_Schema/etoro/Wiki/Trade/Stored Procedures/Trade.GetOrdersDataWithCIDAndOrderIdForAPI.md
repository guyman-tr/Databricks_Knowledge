# Trade.GetOrdersDataWithCIDAndOrderIdForAPI

> Returns a single order's data for a specific customer and order ID combination - API-facing order lookup with null-safe output and amount converted from cents to dollars.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @orderId INT + @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersDataWithCIDAndOrderIdForAPI` retrieves a single pending order from `Trade.Orders` by OrderID and CID. It is the API-facing order lookup returning a specific customer's specific order, with null-safe ISNULL defaults and Amount converted from cents to dollars.

**WHY:** APIs need to check the current state of a specific pending order for a specific customer. The CID filter ensures customers can only retrieve their own orders. The null-safe defaults (ISNULL to 0) ensure the API receives clean numeric values.

**HOW:** Single SELECT from Trade.Orders with `WHERE OrderID = @orderId AND CID = @cid`. No filtering by status - returns the order regardless of StatusID if it exists.

Change log: 2017-08-08 (FB 47233 - AmountInUnitsDecimal added), 2019-03-13 (FB 53719 - Free Stocks, added IsDiscounted).

---

## 2. Business Logic

### 2.1 Customer Ownership Validation

**What:** The dual filter on OrderID + CID ensures an order can only be retrieved if it belongs to the requesting customer. This is a security boundary.

**Columns/Parameters Involved:** `@orderId`, `@cid`

**Rules:**
- `WHERE o.OrderID = @orderId AND o.CID = @cid` -> only returns data if the order belongs to this customer
- Returns 0 rows if OrderID belongs to a different customer (not an error)

### 2.2 Null-Safe API Output

**What:** All critical columns use ISNULL with 0 as default to avoid NULL propagation into the API layer.

**Rules:**
- Numeric columns: ISNULL(value, 0) -> prevents NULL arithmetic issues in API
- Amount: `ISNULL(o.Amount, 0) / 100` -> null-safe cents-to-dollars conversion
- OccurredTime and IsTslEnabled, IsNoStopLoss, IsNoTakeProfit: passed as-is (may be NULL)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @orderId | INT | NO | - | CODE-BACKED | The specific order ID to retrieve. Combined with @cid for customer ownership validation. |
| 2 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Acts as a security filter - only orders owned by this customer are returned. |

**Output columns (from Trade.Orders WHERE OrderID=@orderId AND CID=@cid):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Order ID (matches @orderId). |
| 2 | OrderTypeID | INT | YES | - | CODE-BACKED | Order type classification. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID. ISNULL defaulted to 0 (should never be NULL given the WHERE filter). |
| 4 | AmountInDollars | DECIMAL | NO | - | CODE-BACKED | Order amount in dollars. Explicitly aliased as "AmountInDollars" to document the unit conversion: ISNULL(Amount, 0) / 100. Trade.Orders stores Amount in cents. |
| 5 | OccurredTime | DATETIME | YES | - | CODE-BACKED | Order placement timestamp. |
| 6 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being ordered. ISNULL defaulted to 0. |
| 7 | IsBuy | INT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. ISNULL defaulted to 0. |
| 8 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. ISNULL defaulted to 0. |
| 9 | TakeProfitRate | DECIMAL | NO | - | CODE-BACKED | Take-profit rate. ISNULL defaulted to 0. |
| 10 | StopLosRate | DECIMAL | NO | - | CODE-BACKED | Stop-loss rate. ISNULL defaulted to 0. Note: "StopLosRate" (missing 's') follows Trade.Orders column name. |
| 11 | ParentOrderID | INT | NO | - | CODE-BACKED | Parent order ID. ISNULL defaulted to 0 (0 = root/independent order). |
| 12 | RateFrom | DECIMAL | NO | - | CODE-BACKED | Lower price bound. ISNULL defaulted to 0. |
| 13 | AmountInUnitsDecimal | DECIMAL | NO | - | CODE-BACKED | Order size in instrument units. ISNULL defaulted to 0. Added FB 47233 (2017). |
| 14 | IsTslEnabled | BIT | YES | - | CODE-BACKED | 1 if Trailing Stop Loss is enabled. Not null-defaulted (passed as-is). |
| 15 | IsDiscounted | INT | NO | - | CODE-BACKED | 1 if fee discount applies. ISNULL defaulted to 0. Added FB 53719 (Free Stocks, 2019). |
| 16 | IsNoStopLoss | BIT | YES | - | CODE-BACKED | 1 if no stop-loss protection. Not null-defaulted. |
| 17 | IsNoTakeProfit | BIT | YES | - | CODE-BACKED | 1 if no take-profit level. Not null-defaulted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.Orders | Trade.Orders | Lookup | Source of order data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersDataWithCIDAndOrderIdForAPI (procedure)
|- Trade.Orders (table) - source of pending orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | Single-row lookup by OrderID + CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by trading API for order status lookups |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| AND o.CID = @cid | Security filter | Ensures customer can only view their own orders |
| ISNULL(value, 0) | Null safety | API-safe defaults for all numeric columns |
| Amount / 100 | Computation | Converts cents to dollars for API layer |

---

## 8. Sample Queries

### 8.1 Get a specific order for a customer

```sql
EXEC Trade.GetOrdersDataWithCIDAndOrderIdForAPI
    @orderId = 12345678,
    @cid = 87654321
```

### 8.2 Verify order exists for customer

```sql
SELECT OrderID, CID, Amount / 100.0 AS AmountDollars, IsBuy, OccurredTime
FROM Trade.Orders WITH (NOLOCK)
WHERE OrderID = 12345678 AND CID = 87654321
```

### 8.3 Check all pending orders for a customer (use GetOrdersDataWithCIDForAPI for bulk)

```sql
EXEC Trade.GetOrdersDataWithCIDForAPI
    @cid = 87654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9.5/10, Logic: 7.0/10, Relationships: 5.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersDataWithCIDAndOrderIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersDataWithCIDAndOrderIdForAPI.sql*
