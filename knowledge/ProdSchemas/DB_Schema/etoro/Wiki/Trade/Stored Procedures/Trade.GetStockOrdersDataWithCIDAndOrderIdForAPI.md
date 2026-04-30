# Trade.GetStockOrdersDataWithCIDAndOrderIdForAPI

> Returns a single stock order by both CID and OrderID, including Amount and Leverage. Internal API endpoint - dual-key lookup variant of GetStockOrdersDataWithCIDForAPI.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @orderId INT, @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a single specific stock order by both its order ID and customer ID. It is the single-record variant of `Trade.GetStockOrdersDataWithCIDForAPI`. The dual-key lookup (`OrderID AND CID`) serves as a security control: it ensures a customer can only retrieve their own orders, not orders belonging to other customers, even if the OrderID is known.

Like its sibling, this is an internal (non-public) endpoint that includes Amount and Leverage in the output. The public counterpart (`Trade.GetPublicStockOrdersDataWithOrderIdForAPI`) excludes these financial fields.

For full context on Stocks.Orders, field meanings, and the public vs. internal distinction, see `Trade.GetStockOrdersDataWithCIDForAPI.md`.

---

## 2. Business Logic

### 2.1 Dual-Key Single Order Lookup

**What**: Returns at most one order, validated against both the order ID and the customer ID.

**Columns/Parameters Involved**: `@orderId`, `@cid`, `OrderID`, `CID`

**Rules**:
- `WHERE so.OrderID = @orderId AND so.CID = @cid`: both conditions required
- Security: customer cannot retrieve another customer's order by guessing OrderID alone
- Expected result: 0 or 1 row (OrderID is unique in Stocks.Orders)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @orderId | INT | NO | - | CODE-BACKED | Order ID to retrieve. Combined with @cid for security. |
| 2 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Validates that the order belongs to this customer. |

**Output Columns** - identical to Trade.GetStockOrdersDataWithCIDForAPI:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Amount | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Order investment amount. ISNULL-protected to 0. |
| 4 | Leverage | INT | NO | 0 | CODE-BACKED | Leverage multiplier. ISNULL-protected to 0. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer ID. Matches @cid. |
| 6 | InstrumentID | INT | NO | - | CODE-BACKED | Stock being ordered. FK to Trade.Instrument. |
| 7 | IsBuy | BIT | NO | - | CODE-BACKED | 1=Buy/Long, 0=Sell/Short. |
| 8 | IsEntry | BIT | NO | - | CODE-BACKED | 1=opening order, 0=closing order. |
| 9 | MirrorID | INT | NO | 0 | CODE-BACKED | Copy mirror ID if copy-trade order. 0 if not copy. ISNULL-protected. |
| 10 | OpenRequest | DATETIME | NO | - | CODE-BACKED | Order submission timestamp. |
| 11 | OrderID | INT | NO | - | CODE-BACKED | Unique order ID. Matches @orderId. |
| 12 | PositionID | BIGINT | NO | 0 | CODE-BACKED | Linked position for exit orders. 0 if none. ISNULL-protected. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | Stocks.Orders | Reader (cross-schema) | Single-row lookup WHERE OrderID = @orderId AND CID = @cid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal API service | @orderId, @cid | Application call | Authenticated single-order lookup with ownership validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetStockOrdersDataWithCIDAndOrderIdForAPI (procedure)
+-- Stocks.Orders (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Stocks.Orders | Table (Stocks schema) | SELECT 10 fields WHERE OrderID = @orderId AND CID = @cid; NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal API / trading service | External application | Single stock order lookup for authenticated internal calls |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED on Stocks.Orders |
| WHERE OrderID AND CID | Security filter | Dual-key validation; prevents cross-customer data access |

---

## 8. Sample Queries

### 8.1 Get a specific stock order

```sql
EXEC Trade.GetStockOrdersDataWithCIDAndOrderIdForAPI @orderId = 999888, @cid = 12345;
```

### 8.2 Equivalent inline query

```sql
SELECT ISNULL(so.Amount, 0) as Amount, ISNULL(so.Leverage, 0) as Leverage,
       so.CID, so.InstrumentID, so.IsBuy, so.IsEntry,
       ISNULL(so.MirrorID, 0) as MirrorID, so.OpenRequest, so.OrderID,
       ISNULL(so.PositionID, 0) as PositionID
FROM Stocks.Orders so WITH (NOLOCK)
WHERE so.OrderID = 999888 AND so.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetStockOrdersDataWithCIDAndOrderIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetStockOrdersDataWithCIDAndOrderIdForAPI.sql*
