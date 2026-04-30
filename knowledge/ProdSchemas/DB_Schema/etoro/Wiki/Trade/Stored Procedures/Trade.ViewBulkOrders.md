# Trade.ViewBulkOrders

> Returns detailed position and order data for all positions belonging to a bulk order ID, searching both live and historical order tables (active and DB_Logs.History) for open and close orders, and classifying each as Copy or Self-Directed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID INT; reads Trade.OrderForOpen, Trade.OrderForClose, Trade.OpenExecutionPlan, Trade.CloseExecutionPlan, Trade.ExecutedOpenOrders, Trade.ExecutedCloseOrders, and DB_Logs.History equivalents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A "bulk order" in eToro is a single OrderID that triggers multiple positions simultaneously - this happens when a copy trading relationship is created (the copier's positions mirror the leader's open positions) or when a mass operation affects multiple positions at once (e.g., "Close All" for a portfolio).

This procedure is the diagnostic tool for inspecting a bulk order after the fact. Given an @OrderID, it reconstructs the full picture: which positions were opened or closed under this order, what was their execution status, whether they were copy or self-directed trades, and what the position details are (instrument, leverage, amount, PnL).

The dual-source design - querying both live trade tables (Trade.OrderForOpen/Close, etc.) and the historical archive (DB_Logs.History.OrderForOpen/Close, etc.) - ensures that even orders that have already been processed and moved to history are fully visible. The CustomerFlow=1 filter scopes the procedure to customer-initiated orders only (excluding internal/system-generated order flows).

This procedure is used by operations and support teams to investigate bulk order issues: why did certain positions fail to open, what happened to a copy trade batch, or verifying the state of a "Close All" operation.

---

## 2. Business Logic

### 2.1 Copy vs. Self-Directed Classification

**What**: Classifies each order line as either "Copy" or "Self-Directed" (or "Close All" for mass close orders) based on action type IDs.

**Columns/Parameters Involved**: `OpenActionType`, `CloseActionType`, `Dictionary.OpenPositionActionType`, `Dictionary.ClosePositionActionType`, `#OrdersForOpen_CopySd`, `#OrdersForClose_CopySd`

**Rules**:
- **Open orders**: ActionTypeId=0 -> 'Self-Directed'; ActionTypeId IN (1,3,8) -> 'Copy'; others -> OpenPositionActionName
- **Close orders**: ActionTypeId=0 -> 'Self-Directed'; ActionTypeId IN (9,10,13,14,17) -> 'Copy'; others -> ClosePositionActionName
- **OrderType=20** on close orders -> 'Close All' (overrides the CopySd classification)
- These mappings are built once into temp tables #OrdersForOpen_CopySd and #OrdersForClose_CopySd and JOINed via LEFT JOIN in subsequent queries

**Diagram**:
```
Dictionary.OpenPositionActionType:
  ID=0         -> 'Self-Directed'
  ID in (1,3,8) -> 'Copy'
  else         -> OpenPositionActionName

Dictionary.ClosePositionActionType:
  ID=0             -> 'Self-Directed'
  ID in (9,10,13,14,17) -> 'Copy'
  else             -> ClosePositionActionName
  AND OrderType=20 -> 'Close All' (IIF override)
```

### 2.2 Four-Source Order Collection

**What**: Collects order-to-position mappings from 4 sources: live open orders, live close orders, historical open orders, historical close orders.

**Columns/Parameters Involved**: `Trade.OrderForOpen`, `Trade.OrderForClose`, `Trade.OpenExecutionPlan`, `Trade.CloseExecutionPlan`, `Trade.ExecutedOpenOrders`, `Trade.ExecutedCloseOrders`, `DB_Logs.History.*`, `CustomerFlow`

**Rules**:
- All 4 sources filtered by @OrderID and CustomerFlow=1 (customer-initiated orders only)
- Open order chain: OrderForOpen -> OpenExecutionPlan (JOIN on OrderID) -> ExecutedOpenOrders (JOIN on OrderID + OpenCorrelationID)
- Close order chain: OrderForClose -> CloseExecutionPlan (JOIN on OrderID, filter PositionID != 0) -> ExecutedCloseOrders (JOIN on OrderID + PositionID)
- Historical tables in DB_Logs.History.* mirror the same structure as Trade.*
- IsOrderClosed = 0 for live tables, 1 for historical tables
- LEFT JOINs preserve orders that have an execution plan but no executed order (pending/failed executions)

**Diagram**:
```
#order_temp (PositionID, StatusID, IsOrderClosed, OrderDescription, Level):
  [1] Trade.OrderForOpen     -> OpenExecutionPlan -> ExecutedOpenOrders
  [2] Trade.OrderForClose    -> CloseExecutionPlan -> ExecutedCloseOrders
  [3] DB_Logs.History.OrderForOpen  -> History.OpenExecutionPlan  -> History.ExecutedOpenOrders
  [4] DB_Logs.History.OrderForClose -> History.CloseExecutionPlan -> History.ExecutedCloseOrders
All filtered: @OrderID + CustomerFlow=1
```

### 2.3 Position Detail Enrichment

**What**: Enriches each order line with full position details from PositionTbl (live) or History.PositionSlim (closed).

**Columns/Parameters Involved**: `Trade.PositionTbl`, `History.PositionSlim`, `#position_temp`

**Rules**:
- #position_temp collects: PositionID, CID, OrderID, OrderType, InstrumentID, Leverage, Amount, AmountInUnitsDecimal, UnitMargin, LotCountDecimal, InitDateTime, NetProfit, IsBuy
- First INSERT: FROM Trade.PositionTbl WHERE PositionID IN (#order_temp) - live positions
- Second INSERT: FROM History.PositionSlim WHERE PositionID IN (#order_temp) - closed positions
- The UNION of both sources covers all positions regardless of lifecycle state

### 2.4 Final Output Assembly

**What**: Joins order and position temp tables with Dictionary lookups for human-readable output.

**Columns/Parameters Involved**: `Dictionary.OrderType`, `Trade.InstrumentMetaData`, `Dictionary.OrderForExecutionStatus`

**Rules**:
- Dictionary.OrderType -> Name (the order type name)
- Trade.InstrumentMetaData -> Symbol, InstrumentDisplayName
- Dictionary.OrderForExecutionStatus -> Status (human-readable order status for the StatusID)
- IsBuy: IIF(IsBuy=1, 'BUY', 'SELL')
- IsOrderClosed: IIF(IsOrderClosed=1, 'True', 'False')
- Level: from the execution plan (position within the bulk order execution hierarchy)
- All JOINs are LEFT JOIN to avoid excluding rows with unmapped types

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | int | NO | - | CODE-BACKED | The bulk order ID to inspect. Searched across all 4 order sources (live open, live close, historical open, historical close). All positions associated with this OrderID via the execution plan chain are returned. |

**Output columns:**

| # | Column | Description |
|---|--------|-------------|
| 1 | OrderID | The bulk order ID |
| 2 | PositionID | Individual position ID within the order |
| 3 | CID | Customer ID that owns the position |
| 4 | Status | Order execution status (from Dictionary.OrderForExecutionStatus) |
| 5 | Level | Position level within the bulk order execution plan hierarchy |
| 6 | OrderClosed | 'True' if from historical tables; 'False' if from live tables |
| 7 | Name | Order type name (from Dictionary.OrderType) |
| 8 | OrderDescription | 'Copy', 'Self-Directed', 'Close All', or the raw action type name |
| 9 | Side | 'BUY' or 'SELL' |
| 10 | Symbol | Instrument ticker symbol |
| 11 | InstrumentDisplayName | Instrument full display name |
| 12 | Leverage | Leverage applied to the position |
| 13 | Amount | Position invested amount (USD) |
| 14 | AmountInUnitsDecimal | Position size in instrument units (shares/lots) |
| 15 | UnitMargin | Margin per unit |
| 16 | LotCountDecimal | Position size in lots |
| 17 | InitDateTime | Position open timestamp |
| 18 | NetProfit | Net profit/loss of the position (USD) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Open action classification | Dictionary.OpenPositionActionType | Reader | Lookup for Copy vs Self-Directed classification of open orders |
| Close action classification | Dictionary.ClosePositionActionType | Reader | Lookup for Copy vs Self-Directed classification of close orders |
| Live open order source | Trade.OrderForOpen | Reader | Active open orders matching @OrderID |
| Live open execution plan | Trade.OpenExecutionPlan | Reader | Execution plan for live open orders - provides Level and OpenActionType |
| Live executed open orders | Trade.ExecutedOpenOrders | Reader | Completed open order executions (PositionID) |
| Live close order source | Trade.OrderForClose | Reader | Active close orders matching @OrderID |
| Live close execution plan | Trade.CloseExecutionPlan | Reader | Execution plan for live close orders - provides Level and CloseActionType |
| Live executed close orders | Trade.ExecutedCloseOrders | Reader | Completed close order executions |
| Historical open order source | DB_Logs.History.OrderForOpen | Reader (cross-DB) | Archived open orders in DB_Logs database |
| Historical open execution plan | DB_Logs.History.OpenExecutionPlan | Reader (cross-DB) | Archived execution plans for open orders |
| Historical executed open orders | DB_Logs.History.ExecutedOpenOrders | Reader (cross-DB) | Archived completed open order executions |
| Historical close order source | DB_Logs.History.OrderForClose | Reader (cross-DB) | Archived close orders in DB_Logs database |
| Historical close execution plan | DB_Logs.History.CloseExecutionPlan | Reader (cross-DB) | Archived execution plans for close orders |
| Historical executed close orders | DB_Logs.History.ExecutedCloseOrders | Reader (cross-DB) | Archived completed close order executions |
| Live position data | Trade.PositionTbl | Reader | Position details for open positions in the order |
| Closed position data | History.PositionSlim | Reader (cross-schema) | Position details for closed positions in the order |
| Order type name | Dictionary.OrderType | Reader | Human-readable name for pos.OrderType |
| Instrument info | Trade.InstrumentMetaData | Reader | Symbol and display name for each position's instrument |
| Order status name | Dictionary.OrderForExecutionStatus | Reader | Human-readable status for StatusID from execution plan |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations / support tooling | EXECUTE | Caller | Used by operations teams to diagnose bulk order issues (failed copy trades, Close All outcomes, etc.) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ViewBulkOrders (procedure)
├── Dictionary.OpenPositionActionType (lookup - open Copy vs Self-Directed)
├── Dictionary.ClosePositionActionType (lookup - close Copy vs Self-Directed)
├── Trade.OrderForOpen + Trade.OpenExecutionPlan + Trade.ExecutedOpenOrders (live open)
├── Trade.OrderForClose + Trade.CloseExecutionPlan + Trade.ExecutedCloseOrders (live close)
├── DB_Logs.History.OrderForOpen + OpenExecutionPlan + ExecutedOpenOrders (hist open)
├── DB_Logs.History.OrderForClose + CloseExecutionPlan + ExecutedCloseOrders (hist close)
├── Trade.PositionTbl (live position details)
├── History.PositionSlim (closed position details)
├── Dictionary.OrderType (order type name)
├── Trade.InstrumentMetaData (symbol, display name)
└── Dictionary.OrderForExecutionStatus (status name)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OpenPositionActionType | Table | Open action ID -> 'Copy'/'Self-Directed' classification |
| Dictionary.ClosePositionActionType | Table | Close action ID -> 'Copy'/'Self-Directed' classification |
| Trade.OrderForOpen | Table | Live open orders for @OrderID (CustomerFlow=1) |
| Trade.OpenExecutionPlan | Table | Live open execution plan chain - Level, OpenActionType |
| Trade.ExecutedOpenOrders | Table | Live executed open orders - PositionID per execution |
| Trade.OrderForClose | Table | Live close orders for @OrderID (CustomerFlow=1) |
| Trade.CloseExecutionPlan | Table | Live close execution plan chain - Level, CloseActionType |
| Trade.ExecutedCloseOrders | Table | Live executed close orders |
| DB_Logs.History.OrderForOpen | Table (cross-DB) | Archived open orders |
| DB_Logs.History.OpenExecutionPlan | Table (cross-DB) | Archived open execution plans |
| DB_Logs.History.ExecutedOpenOrders | Table (cross-DB) | Archived executed open orders |
| DB_Logs.History.OrderForClose | Table (cross-DB) | Archived close orders |
| DB_Logs.History.CloseExecutionPlan | Table (cross-DB) | Archived close execution plans |
| DB_Logs.History.ExecutedCloseOrders | Table (cross-DB) | Archived executed close orders |
| Trade.PositionTbl | Table | Live position detail: Leverage, Amount, InstrumentID, etc. |
| History.PositionSlim | Table | Closed position detail: same columns |
| Dictionary.OrderType | Table | OrderType ID -> Name |
| Trade.InstrumentMetaData | Table | InstrumentID -> Symbol, InstrumentDisplayName |
| Dictionary.OrderForExecutionStatus | Table | StatusID -> Status string |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations support tooling | External process | Diagnostic tool for bulk order investigation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CustomerFlow = 1 | Business logic | Applied to all 4 order sources. Filters to customer-initiated orders only, excluding internal/system order flows (CustomerFlow != 1). |
| PositionID != 0 filter (close plan) | Business logic | CloseExecutionPlan rows with PositionID=0 are excluded - these represent order-level entries without a specific position association |
| LEFT JOINs throughout | Design | Preserves orders/positions at any stage of execution - including orders that have an execution plan but no executed position yet (pending/failed) |
| Cross-database reads (DB_Logs) | Design | Requires linked server or same-instance access to the DB_Logs database. The historical tables mirror the structure of the live tables. |
| OrderType=20 override | Business logic | Close orders with OrderType=20 are labeled 'Close All' regardless of CloseActionType - this is the "close all positions" operation type |

---

## 8. Sample Queries

### 8.1 Investigate a specific bulk order

```sql
EXEC Trade.ViewBulkOrders @OrderID = 98765432
-- Returns all positions associated with this order, their status, and Copy/SD classification
```

### 8.2 Find recent bulk orders to investigate

```sql
-- Find recent open bulk orders (OrderType IN (2,4) are typically bulk)
SELECT TOP 20
    OrderID,
    OrderType,
    StatusID,
    CustomerFlow,
    CreateDateTime
FROM Trade.OrderForOpen WITH (NOLOCK)
WHERE CustomerFlow = 1
ORDER BY OrderID DESC
```

### 8.3 Check if a bulk order is in history

```sql
-- Check historical orders if the live query returns nothing
SELECT TOP 10
    OrderID,
    StatusID,
    CustomerFlow
FROM DB_Logs.History.OrderForOpen WITH (NOLOCK)
WHERE OrderID = 98765432
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ViewBulkOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ViewBulkOrders.sql*
