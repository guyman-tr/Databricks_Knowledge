# Trade.GetOrdersEntryDataWithCIDForAPI

> Returns all pending entry orders for a customer from Trade.OrdersEntry - the bulk entry-order counterpart to GetOrdersEntryDataWithCIDAndOrderIdForAPI. Amount is NOT divided (Trade.OrdersEntry stores in dollars directly).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersEntryDataWithCIDForAPI` retrieves all pending entry orders from `Trade.OrdersEntry` for a given customer ID. It is the bulk counterpart to `GetOrdersEntryDataWithCIDAndOrderIdForAPI` - returning ALL of a customer's pending entry orders rather than a specific one.

**WHY:** APIs need to display a customer's full pending entry order list. This SP provides that data with null-safe numeric defaults and amount in dollars (stored directly in OrdersEntry, no conversion needed).

**HOW:** Single SELECT from Trade.OrdersEntry WHERE CID=@CID. Identical output schema to `GetOrdersEntryDataWithCIDAndOrderIdForAPI`.

Change log: 2017-08-08 (FB 47233 - AmountInUnitsDecimal added), 2019-03-13 (FB 53719 - Free Stocks, IsDiscounted added).

---

## 2. Business Logic

### 2.1 All Entry Orders for Customer - No Status Filter

**What:** Returns all Trade.OrdersEntry rows for the customer regardless of any implicit status. The API layer must handle the full entry order lifecycle state.

**Columns/Parameters Involved:** `@CID`

**Rules:**
- `WHERE TOE.CID = @CID` -> all pending entry orders for this customer

### 2.2 Amount NOT Converted - Entry Orders Store Dollars Directly

**What:** Unlike the standard orders API SP (`GetOrdersDataWithCIDForAPI`) which divides Amount by 100, this SP returns Amount as-is because Trade.OrdersEntry stores amounts in the base currency (dollars) directly.

**Rules:**
- `ISNULL(TOE.Amount, 0) AS Amount` -> no /100 conversion applied
- Consumers MUST NOT divide Amount by 100

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose entry orders to retrieve. All pending entry orders for this customer are returned. |

**Output columns (from Trade.OrdersEntry WHERE CID=@CID) - identical to GetOrdersEntryDataWithCIDAndOrderIdForAPI:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Entry order ID. |
| 2 | OrderTypeID | INT | YES | - | CODE-BACKED | Entry order type classification. Passed as-is (not ISNULL-defaulted). |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID (equals @CID). ISNULL defaulted to 0. |
| 4 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being ordered. ISNULL defaulted to 0. |
| 5 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. Passed as-is (not ISNULL-defaulted). |
| 6 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. ISNULL defaulted to 0. |
| 7 | Amount | DECIMAL | NO | - | CODE-BACKED | Entry order amount in base currency (dollars). ISNULL defaulted to 0. NOT divided by 100. |
| 8 | StopLosPercentage | DECIMAL | NO | - | CODE-BACKED | Stop-loss threshold as percentage. ISNULL defaulted to 0. |
| 9 | TakeProfitPercentage | DECIMAL | NO | - | CODE-BACKED | Take-profit threshold as percentage. ISNULL defaulted to 0. |
| 10 | Occurred | DATETIME | YES | - | CODE-BACKED | Entry order placement timestamp. Passed as-is (may be NULL). |
| 11 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | For copy-trade orders: the leader's position being copied. ISNULL defaulted to 0. |
| 12 | MirrorID | BIGINT | NO | - | CODE-BACKED | Copy-trade mirror relationship ID. ISNULL defaulted to 0. |
| 13 | InitialMirrorAmountInCents | INT | NO | - | CODE-BACKED | Initial copy amount in cents for mirror orders. ISNULL defaulted to 0. |
| 14 | IsTslEnabled | BIT | YES | - | CODE-BACKED | 1 if Trailing Stop Loss is enabled. Passed as-is (may be NULL). Added FB 47233 (2017). |
| 15 | AmountInUnitsDecimal | DECIMAL | NO | - | CODE-BACKED | Order size in instrument units. ISNULL defaulted to 0. Added FB 47233 (2017). |
| 16 | IsDiscounted | INT | NO | - | CODE-BACKED | 1 if fee discount applies (Free Stocks). ISNULL defaulted to 0. Added FB 53719 (2019). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.OrdersEntry | Trade.OrdersEntry | Lookup | Source of all pending entry orders for the customer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersEntryDataWithCIDForAPI (procedure)
|- Trade.OrdersEntry (view) - pending entry orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | View | All entry orders for @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by trading API for customer entry order book display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL(value, 0) | Null safety | API-safe defaults for all numeric columns |
| Amount NOT divided | Unit convention | Trade.OrdersEntry stores dollars; no /100 needed |

---

## 8. Sample Queries

### 8.1 Get all entry orders for a customer

```sql
EXEC Trade.GetOrdersEntryDataWithCIDForAPI
    @CID = 87654321
```

### 8.2 Get a specific entry order for a customer (use CID+OrderId variant)

```sql
EXEC Trade.GetOrdersEntryDataWithCIDAndOrderIdForAPI
    @OrderID = 12345678,
    @CID = 87654321
```

### 8.3 Count pending entry orders by customer

```sql
SELECT CID, COUNT(*) AS PendingEntryOrders
FROM Trade.OrdersEntry WITH (NOLOCK)
GROUP BY CID
HAVING COUNT(*) > 5
ORDER BY PendingEntryOrders DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.5/10, Logic: 6.5/10, Relationships: 5.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersEntryDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersEntryDataWithCIDForAPI.sql*
