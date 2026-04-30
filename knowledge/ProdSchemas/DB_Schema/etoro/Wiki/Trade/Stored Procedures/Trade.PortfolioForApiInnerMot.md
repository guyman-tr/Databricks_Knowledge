# Trade.PortfolioForApiInnerMot

> Returns the user's in-flight order and position data for API consumption: orders for open, orders for close, pending close positions, and delayed orders.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Six result sets: orders for open, orders for close, pending close positions, delayed orders for open, delayed orders for close, positions for delayed close |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure assembles the portfolio snapshot used by client-facing APIs for users with active (non-terminal) orders and positions. It returns orders in progress, pending close executions, and scheduled (delayed) orders. This is the inner MOT (Memory-Optimized Table) variant, designed for high-throughput API calls.

Without this procedure, Trade.GetClientPortfolioForAPI would not have the MOT-optimized path to fetch orders for open/close and delayed orders. The procedure supports portfolio display and trade management UIs that need real-time order status.

Data flows when Trade.GetClientPortfolioForAPI invokes this procedure with a CID and optional OpenActionType filter. The procedure runs with native compilation and SNAPSHOT isolation for performance.

---

## 2. Business Logic

### 2.1 Non-Terminal Order Filtering

**What**: Only orders that are not yet in a terminal state are returned.

**Columns/Parameters Involved**: `StatusID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- Orders for open and close are filtered by `JOIN Dictionary.OrderForExecutionStatus dofe ON StatusID = dofe.ID WHERE dofe.IsTerminal = 0`
- Terminal orders (filled, cancelled, rejected) are excluded so the API shows only active orders

### 2.2 Pending Close Positions

**What**: Positions that are on CloseExecutionPlan but not yet in ExecutedCloseOrders.

**Columns/Parameters Involved**: `CloseExecutionPlan.OrderID`, `CloseExecutionPlan.PositionID`, `ExecutedCloseOrders.PositionID`

**Rules**:
- JOIN CloseExecutionPlan to @OrdersForClose on OrderID, Level = 0
- LEFT JOIN ExecutedCloseOrders on OrderID and PositionID; WHERE eo.PositionID IS NULL means not yet executed
- Returns OrderID, PositionID, LotsToDeduct for each pending close

### 2.3 Delayed Order Status

**What**: Delayed orders with StatusID = 1 (PLACED) are returned.

**Columns/Parameters Involved**: `StatusID`

**Rules**:
- DelayedOrderForOpen: StatusID = 1 (OrderForExecutionStatus.PLACED)
- DelayedOrderForClose: StatusID = 1 (DelayedOrderStatus.PLACED)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int | NO | - | CODE-BACKED | Customer ID. Filters all result sets to this customer. |
| 2 | @OpenActionType | int | YES | NULL | CODE-BACKED | Optional filter for orders for open. When NOT NULL, only orders with this OpenActionType are returned. When NULL, all open orders are returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.OrderForOpen | Implicit | Source for orders for open |
| JOIN | Dictionary.OrderForExecutionStatus | Implicit | Terminal status filter |
| FROM | Trade.OrderForClose | Implicit | Source for orders for close |
| FROM | Trade.CloseExecutionPlan | Implicit | Pending close position mapping |
| FROM | Trade.ExecutedCloseOrders | Implicit | Exclude already-executed closes |
| FROM | Trade.DelayedOrderForOpen | Implicit | Scheduled open orders |
| FROM | Trade.DelayedOrderForClose | Implicit | Scheduled close orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetClientPortfolioForAPI | EXEC | Procedure call | Invokes for MOT-optimized portfolio data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PortfolioForApiInnerMot (procedure)
├── Trade.OrderForOpen (table)
├── Trade.OrderForClose (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.ExecutedCloseOrders (table)
├── Trade.DelayedOrderForOpen (table)
├── Trade.DelayedOrderForClose (table)
├── Dictionary.OrderForExecutionStatus (table)
├── Trade.OrdersForCloseType (type)
└── Trade.DelayedOrdersForCloseType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | SELECT non-terminal orders for open |
| Trade.OrderForClose | Table | SELECT non-terminal orders for close |
| Trade.CloseExecutionPlan | Table | JOIN for pending close positions |
| Trade.ExecutedCloseOrders | Table | LEFT JOIN to exclude executed closes |
| Trade.DelayedOrderForOpen | Table | SELECT delayed opens with StatusID = 1 |
| Trade.DelayedOrderForClose | Table | SELECT delayed closes with StatusID = 1 |
| Dictionary.OrderForExecutionStatus | Table | JOIN for IsTerminal = 0 filter |
| Trade.OrdersForCloseType | Type | TVP for orders for close |
| Trade.DelayedOrdersForCloseType | Type | TVP for delayed close orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetClientPortfolioForAPI | Procedure | Calls for inner MOT portfolio data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Procedure uses `native_compilation`, `schemabinding`, `execute as OWNER`, and `ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT)`.

---

## 8. Sample Queries

### 8.1 Call procedure for a customer
```sql
EXEC Trade.PortfolioForApiInnerMot @cid = 12345;
```

### 8.2 Call with OpenActionType filter
```sql
EXEC Trade.PortfolioForApiInnerMot @cid = 12345, @OpenActionType = 1;
```

### 8.3 Inspect non-terminal orders for open (first result set logic)
```sql
SELECT OO.OrderID, OO.CID, OO.StatusID, OO.InstrumentID, OO.Amount
FROM Trade.OrderForOpen AS OO WITH (NOLOCK)
JOIN Dictionary.OrderForExecutionStatus dofe WITH (NOLOCK) ON OO.StatusID = dofe.ID
WHERE OO.CID = 12345 AND dofe.IsTerminal = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PortfolioForApiInnerMot | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PortfolioForApiInnerMot.sql*
