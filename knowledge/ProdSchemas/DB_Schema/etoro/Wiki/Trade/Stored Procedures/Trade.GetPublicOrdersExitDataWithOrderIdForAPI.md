# Trade.GetPublicOrdersExitDataWithOrderIdForAPI

> Returns the pending exit (close) order matching a specific OrderID from Trade.OrdersExit, with InstrumentID resolved via JOIN to Trade.Position. Single-row exit order lookup for the public API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a single pending exit order by its OrderID from `Trade.OrdersExit`. Exit orders are pending close requests for open positions - they represent an instruction to close a position either at market, at a specific rate, or as part of a mirror close operation. The InstrumentID is not stored directly in Trade.OrdersExit, so it is resolved via an INNER JOIN to Trade.Position using PositionID.

This is the single-order lookup variant of `Trade.GetPublicOrdersExitDataWithCIDForAPI`, which returns all exit orders for a customer. This procedure is used when the caller already knows the specific OrderID and needs full details for that one exit order.

The INNER JOIN to Trade.Position acts as an implicit filter: exit orders whose associated position has already been closed (and thus removed from Trade.Position) are excluded from results. This ensures the API only returns exit orders that are still actionable.

---

## 2. Business Logic

### 2.1 Single Exit Order Lookup by OrderID

**What**: Fetches the exit order record for a specific order identifier, enriched with the instrument context from the associated open position.

**Columns/Parameters Involved**: `@OrderID`, `TOE.OrderID`, `TP.InstrumentID`

**Rules**:
- Exactly one exit order is expected per @OrderID (OrderID is the PK of Trade.OrdersExit).
- InstrumentID is sourced from Trade.Position, not Trade.OrdersExit - the exit order table stores only trade-routing columns.
- INNER JOIN to Trade.Position means this returns 0 rows if the position has already been removed (closed).

**Diagram**:
```
@OrderID
  |
  v
Trade.OrdersExit (WHERE OrderID = @OrderID)
  |__ INNER JOIN Trade.Position ON PositionID
        |__ Provides: InstrumentID
  |
  OUTPUT: OrderID, CID, PositionID, InstrumentID,
          OpenOccurred, MirrorID, MirrorCloseActionType
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The exit order identifier to retrieve. Filters Trade.OrdersExit to a single row. Corresponds to the PK of Trade.OrdersExit. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | OrderID | INT | NO | - | CODE-BACKED | Exit order identifier from Trade.OrdersExit. Echoed back from the input filter. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID who owns this exit order. Identifies which customer's position is being closed. |
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | The open position this exit order targets. Links back to Trade.Position. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument of the position being closed (e.g., EURUSD, Apple stock). Resolved from Trade.Position via JOIN - not stored in Trade.OrdersExit directly. |
| 6 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp when the exit order was created/placed. Indicates when the close instruction was received by the system. |
| 7 | MirrorID | INT | YES | - | CODE-BACKED | Mirror/copy-trade ID if this exit was triggered by a mirror close operation. 0 or NULL = manual or market-driven close; >0 = copy-trade driven close. |
| 8 | MirrorCloseActionType | INT | YES | - | CODE-BACKED | Type of mirror action that triggered this exit (e.g., stop-copy, mirror stop-loss). NULL for non-mirror-driven exits. Inherited from sibling proc context: values map to mirror lifecycle events. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID / OrderID | Trade.OrdersExit | Reader | Primary source of exit order data, filtered to the requested order |
| PositionID | Trade.Position | INNER JOIN / Implicit filter | Resolves InstrumentID; INNER JOIN also excludes exit orders for already-closed positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @OrderID | Application call | Single exit order detail lookup, e.g., for order status display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPublicOrdersExitDataWithOrderIdForAPI (procedure)
+-- Trade.OrdersExit (table)
+-- Trade.Position (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | Table | Source of exit order data; filtered by @OrderID |
| Trade.Position | View | INNER JOIN on PositionID to resolve InstrumentID; implicit filter to open positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Exit order detail retrieval by OrderID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN Trade.Position | Implicit filter | Exit orders for already-closed positions (not present in Trade.Position view) are excluded |
| NOLOCK | Isolation hint | READ UNCOMMITTED on both tables for API performance |

---

## 8. Sample Queries

### 8.1 Retrieve exit order details for a specific order

```sql
EXEC Trade.GetPublicOrdersExitDataWithOrderIdForAPI @OrderID = 987654321;
```

### 8.2 Verify exit order exists for a given order before API display

```sql
-- Check if an exit order is still actionable (position still open)
SELECT oe.OrderID, oe.CID, oe.PositionID, p.InstrumentID,
       oe.OpenOccurred, oe.MirrorID, oe.MirrorCloseActionType
FROM Trade.OrdersExit oe WITH (NOLOCK)
INNER JOIN Trade.Position p WITH (NOLOCK) ON oe.PositionID = p.PositionID
WHERE oe.OrderID = 987654321;
```

### 8.3 Compare exit order context with customer's open positions

```sql
SELECT oe.OrderID, oe.CID, oe.PositionID,
       p.InstrumentID, p.IsBuy, p.OpenRate,
       oe.OpenOccurred AS ExitOrderCreated,
       oe.MirrorID, oe.MirrorCloseActionType
FROM Trade.OrdersExit oe WITH (NOLOCK)
INNER JOIN Trade.Position p WITH (NOLOCK) ON oe.PositionID = p.PositionID
WHERE oe.OrderID = 987654321;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicOrdersExitDataWithOrderIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicOrdersExitDataWithOrderIdForAPI.sql*
