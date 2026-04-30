# Trade.GetOrdersEntryDataWithCIDAndOrderIdForAPI

> Returns a single entry order for a specific customer and order ID - API-facing entry order lookup with null-safe output. Amount is NOT divided (Trade.OrdersEntry stores in dollars directly).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID INT + @CID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersEntryDataWithCIDAndOrderIdForAPI` retrieves a single pending entry order from `Trade.OrdersEntry` by OrderID and CID. It is the entry-order counterpart to `GetOrdersDataWithCIDAndOrderIdForAPI` (which reads Trade.Orders for standard orders).

**WHY:** APIs need to check the current state of a specific pending entry order for a specific customer. The CID filter is a security boundary ensuring customers can only retrieve their own entry orders.

**HOW:** Single SELECT from Trade.OrdersEntry WHERE OrderID=@OrderID AND CID=@CID. ISNULL defaults applied to all critical numeric columns. Amount is returned as-is (no /100 conversion) because Trade.OrdersEntry stores amounts in the base currency directly, unlike Trade.Orders which stores in cents.

Change log: 2017-08-08 (FB 47233 - AmountInUnitsDecimal added), 2019-03-13 (FB 53719 - Free Stocks, IsDiscounted added).

---

## 2. Business Logic

### 2.1 Customer Ownership Validation

**What:** The dual filter on OrderID + CID ensures an entry order can only be retrieved if it belongs to the requesting customer.

**Columns/Parameters Involved:** `@OrderID`, `@CID`

**Rules:**
- `WHERE TOE.OrderID = @OrderID AND TOE.CID = @CID` -> returns 0 rows if order belongs to another customer (not an error)
- Security boundary: caller cannot retrieve another customer's entry orders

### 2.2 Amount NOT Converted - Entry Orders Store Dollars Directly

**What:** Unlike `GetOrdersDataWithCIDAndOrderIdForAPI` which divides Amount by 100 (cents -> dollars), this SP returns Amount as-is. Trade.OrdersEntry stores amounts in the base currency directly.

**Columns/Parameters Involved:** `Amount`

**Rules:**
- `ISNULL(TOE.Amount, 0) AS Amount` -> no /100 conversion applied
- Trade.Orders stores cents; Trade.OrdersEntry stores dollars (base currency)
- Consumers of this SP must NOT divide Amount by 100

### 2.3 Null-Safe API Output

**What:** All critical numeric columns use ISNULL to 0 as default. IsTslEnabled is passed as-is (may be NULL).

**Rules:**
- ISNULL applied: CID, InstrumentID, Leverage, Amount, StopLosPercentage, TakeProfitPercentage, ParentPositionID, MirrorID, InitialMirrorAmountInCents, AmountInUnitsDecimal, IsDiscounted
- NOT null-defaulted: Occurred, IsTslEnabled (may be NULL in API layer)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The entry order ID to retrieve. Combined with @CID for customer ownership validation. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Acts as security filter - only returns entry orders owned by this customer. |

**Output columns (from Trade.OrdersEntry WHERE OrderID=@OrderID AND CID=@CID):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Entry order ID (matches @OrderID). |
| 2 | OrderTypeID | INT | YES | - | CODE-BACKED | Entry order type classification. Passed as-is (not ISNULL-defaulted). |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID. ISNULL defaulted to 0. |
| 4 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being ordered. ISNULL defaulted to 0. |
| 5 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. Passed as-is (not ISNULL-defaulted). |
| 6 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. ISNULL defaulted to 0. |
| 7 | Amount | DECIMAL | NO | - | CODE-BACKED | Entry order amount in base currency (dollars). ISNULL defaulted to 0. NOTE: NOT divided by 100 - Trade.OrdersEntry stores in dollars, unlike Trade.Orders which stores in cents. |
| 8 | StopLosPercentage | DECIMAL | NO | - | CODE-BACKED | Stop-loss threshold as percentage of amount. ISNULL defaulted to 0. Note: "StopLos" (missing 's') follows Trade.OrdersEntry column name. |
| 9 | TakeProfitPercentage | DECIMAL | NO | - | CODE-BACKED | Take-profit threshold as percentage of amount. ISNULL defaulted to 0. |
| 10 | Occurred | DATETIME | YES | - | CODE-BACKED | Entry order placement timestamp. Passed as-is (may be NULL). |
| 11 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | For copy-trade orders: the leader's position being copied. ISNULL defaulted to 0 (0 = manual order). |
| 12 | MirrorID | BIGINT | NO | - | CODE-BACKED | Copy-trade mirror relationship ID. ISNULL defaulted to 0 (0 = manual order). |
| 13 | InitialMirrorAmountInCents | INT | NO | - | CODE-BACKED | Initial copy amount in cents for mirror orders. ISNULL defaulted to 0. |
| 14 | IsTslEnabled | BIT | YES | - | CODE-BACKED | 1 if Trailing Stop Loss is enabled. Passed as-is (not ISNULL-defaulted). Added FB 47233 (2017). |
| 15 | AmountInUnitsDecimal | DECIMAL | NO | - | CODE-BACKED | Order size in instrument units. ISNULL defaulted to 0. Added FB 47233 (2017). |
| 16 | IsDiscounted | INT | NO | - | CODE-BACKED | 1 if fee discount applies (Free Stocks). ISNULL defaulted to 0. Added FB 53719 (2019). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.OrdersEntry | Trade.OrdersEntry | Lookup | Source of pending entry orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersEntryDataWithCIDAndOrderIdForAPI (procedure)
|- Trade.OrdersEntry (view) - pending entry orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | View | Single-row lookup by OrderID + CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by trading API for entry order status lookups |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| AND TOE.CID = @CID | Security filter | Ensures customer can only view their own entry orders |
| ISNULL(value, 0) | Null safety | API-safe defaults for all numeric columns |
| Amount NOT divided | Unit convention | Trade.OrdersEntry stores in dollars; no /100 needed |

---

## 8. Sample Queries

### 8.1 Get a specific entry order for a customer

```sql
EXEC Trade.GetOrdersEntryDataWithCIDAndOrderIdForAPI
    @OrderID = 12345678,
    @CID = 87654321
```

### 8.2 Verify entry order exists for customer

```sql
SELECT OrderID, CID, Amount, IsBuy, Occurred
FROM Trade.OrdersEntry WITH (NOLOCK)
WHERE OrderID = 12345678 AND CID = 87654321
```

### 8.3 Compare entry order with standard order (different Amount units)

```sql
-- Entry order amount (dollars directly):
SELECT Amount FROM Trade.OrdersEntry WITH (NOLOCK) WHERE OrderID = 12345678
-- Standard order amount (cents, divide by 100):
SELECT Amount / 100.0 AS AmountDollars FROM Trade.Orders WITH (NOLOCK) WHERE OrderID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.5/10, Logic: 7.5/10, Relationships: 5.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersEntryDataWithCIDAndOrderIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersEntryDataWithCIDAndOrderIdForAPI.sql*
