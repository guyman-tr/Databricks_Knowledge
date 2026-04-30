# Trade.GetStockOrdersDataWithCIDForAPI

> Returns all pending stock orders (entry and exit) for a customer, including Amount and Leverage. Internal API endpoint (non-public variant of GetPublicStockOrdersDataWithCIDForAPI).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the internal API endpoint for retrieving all pending stock orders for a customer. It reads from `Stocks.Orders` (cross-schema) and returns 10 fields including Amount and Leverage - the full financial detail.

This is the **internal/privileged counterpart** to `Trade.GetPublicStockOrdersDataWithCIDForAPI`. The public variant deliberately excludes Amount and Leverage to prevent exposing financial details to unauthenticated API consumers. This procedure is used by internal services and authenticated backend systems that require the full order data.

Orders in `Stocks.Orders` are pending (not yet executed) stock orders placed by customers. `IsEntry=1` = opening order (customer wants to open a position); `IsEntry=0` = closing order (customer wants to close an existing position).

The companion procedure `Trade.GetStockOrdersDataWithCIDAndOrderIdForAPI` retrieves a single order by both CID and OrderID.

---

## 2. Business Logic

### 2.1 All Pending Stock Orders by Customer

**What**: Returns every pending order in Stocks.Orders for the given customer, both entry and exit.

**Columns/Parameters Involved**: `@cid`, `CID`, `IsEntry`, `Amount`, `Leverage`

**Rules**:
- `WHERE so.CID = @cid` -> all orders for this customer
- No IsEntry filter -> returns both entry (IsEntry=1) and exit (IsEntry=0) orders
- `ISNULL(Amount, 0)` and `ISNULL(Leverage, 0)`: NULL-safe; returns 0 if not set
- `ISNULL(MirrorID, 0)` and `ISNULL(PositionID, 0)`: NULL-safe for optional fields

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Filters Stocks.Orders to this customer's orders only. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | Amount | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Order amount (investment size). ISNULL-protected to 0. Present in this procedure but excluded from public variant. |
| 3 | Leverage | INT | NO | 0 | CODE-BACKED | Leverage multiplier applied to the order. ISNULL-protected to 0. Present here, excluded from public variant. |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer ID who placed the order. Matches @cid parameter. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | The stock being ordered. FK to Trade.Instrument. |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Long/Buy, 0=Short/Sell. |
| 7 | IsEntry | BIT | NO | - | CODE-BACKED | Order type: 1=entry order (opening a position), 0=exit order (closing a position). |
| 8 | MirrorID | INT | NO | 0 | CODE-BACKED | Mirror/copy relationship ID if this order was placed via copy trading. 0 if not a copy order. ISNULL-protected. |
| 9 | OpenRequest | DATETIME | NO | - | CODE-BACKED | Timestamp when the order was submitted. |
| 10 | OrderID | INT | NO | - | CODE-BACKED | Unique order identifier in Stocks.Orders. |
| 11 | PositionID | BIGINT | NO | 0 | CODE-BACKED | Position this order is associated with (for exit orders). 0 if no linked position. ISNULL-protected. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Amount, Leverage, CID, InstrumentID, IsBuy, IsEntry, MirrorID, OpenRequest, OrderID, PositionID | Stocks.Orders | Reader (cross-schema) | Reads all orders for @cid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal API service | @cid | Application call | Full stock order data for internal/authenticated consumers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetStockOrdersDataWithCIDForAPI (procedure)
+-- Stocks.Orders (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Stocks.Orders | Table (Stocks schema) | SELECT 10 fields WHERE CID = @cid; NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal API / trading service | External application | Full stock order lookup for authenticated internal calls |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED on Stocks.Orders |
| ISNULL(Amount, 0), ISNULL(Leverage, 0) | Null protection | Returns 0 for financial fields if NULL |
| ISNULL(MirrorID, 0), ISNULL(PositionID, 0) | Null protection | Returns 0 for optional FK fields if NULL |

---

## 8. Sample Queries

### 8.1 Get all stock orders for a customer

```sql
EXEC Trade.GetStockOrdersDataWithCIDForAPI @cid = 12345;
```

### 8.2 Equivalent inline query

```sql
SELECT ISNULL(so.Amount, 0) as Amount, ISNULL(so.Leverage, 0) as Leverage,
       so.CID, so.InstrumentID, so.IsBuy, so.IsEntry,
       ISNULL(so.MirrorID, 0) as MirrorID, so.OpenRequest, so.OrderID,
       ISNULL(so.PositionID, 0) as PositionID
FROM Stocks.Orders so WITH (NOLOCK)
WHERE so.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetStockOrdersDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetStockOrdersDataWithCIDForAPI.sql*
