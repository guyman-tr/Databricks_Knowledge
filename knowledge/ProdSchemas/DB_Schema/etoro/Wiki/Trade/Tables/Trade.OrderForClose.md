# Trade.OrderForClose

> Transient memory-optimized hot processing table for position-close orders during execution; orders are created here, processed, then archived to History.OrderForClose when reaching terminal status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OrderID |
| **Partition** | No |
| **Indexes** | 6 |

---

## 1. Business Meaning

**WHAT:** Trade.OrderForClose is a memory-optimized In-Memory OLTP table that holds orders awaiting or in the process of closing positions. Each row represents one order to close (full or partial) an existing position for a customer. The table is the live execution layer for close operations, analogous to OrderForOpen but for closes.

**WHY:** Position close orders require the same sub-millisecond throughput as opens. Memory-optimized tables with native compiled procedures (OrderForCloseCreate, OrderForCloseUpdate) support high-volume close execution. Orders are transient - once terminal status is reached, they are archived to History.OrderForClose and deleted. Default OrderType = 19 (OrderForCloseByUnits).

**HOW:** Trade.OrderForCloseCreate inserts or updates orders (when TriggeringOrderID > 0 and TriggeringOrderType IN (19,20) for WAITING_FOR_MARKET execution). Trade.OrderForCloseUpdate propagates status and filled amounts. Trade.DeleteOrderForCloseJob archives terminal orders to History.OrderForClose via MERGE, then deletes them. Trade.OrderForCloseJob orchestrates cleanup. Trade.ManualPositionClose, Trade.PositionCloseWithTimeout, and close execution flows consume OrderForClose.

---

## 2. Business Logic

### 2.1 Two Paths for Order Creation
When OrderForCloseCreate is called with TriggeringOrderID > 0 and TriggeringOrderType IN (19, 20) (OrderForCloseByUnits variants), the procedure UPDATEs an existing WAITING_FOR_MARKET order and logs to OrderForExecutionChangeLog and ExecutionPlanChangeLog. Otherwise, it INSERTs a new order and writes to CloseExecutionPlan.

### 2.2 Status Lifecycle
Orders progress through Dictionary.OrderForExecutionStatus. Terminal statuses (FILLED, REJECTED, CANCELED, etc.) trigger archival by DeleteOrderForCloseJob. StatusID=11 is WAITING_FOR_MARKET; StatusID=2 is PLACED.

### 2.3 Mirror and Copy-Trade Close
MirrorCloseActionType indicates how a copy-trade mirror close was triggered. IsGuaranteedSL indicates guaranteed stop-loss. RequiresHierarchicalOperation supports tree-based (parent-child) close operations.

### 2.4 Units vs Lots
UnitsToDeduct specifies how many units to close; LotsToDeduct supports lot-based closes. FilledAmountInUnits tracks execution progress. AggregatedAmountInUnits supports multi-level close plans.

### 2.5 Replace Order Flow
When OrderIdToReplace > 0, OrderForCloseCreate calls OrderForCloseUpdate on the old order to set StatusID=7 (CANCELED) and OrderCloseActionType=10 (Cancellation due to replacement with full order).

---

## 3. Data Overview

| Row | Meaning |
|-----|---------|
| 1 | Order in WAITING_FOR_MARKET (StatusID=11) awaiting price |
| 2 | Order in PLACED status (StatusID=2) awaiting fill |
| 3 | Order with MirrorCloseActionType set - copy-trade close |
| 4 | Order with IsGuaranteedSL=1 - guaranteed stop-loss close |
| 5 | Order with RequiresHierarchicalOperation=1 - tree-based close |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | Primary key; unique order identifier |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID |
| 3 | StatusID | int | NO | - | VERIFIED | OrderForExecutionStatus: 1=RECEIVED, 2=PLACED, 3=FILLED, 4=REJECTED, etc., 11=WAITING_FOR_MARKET |
| 4 | PositionID | bigint | NO | 0 | CODE-BACKED | Position to close; links to Trade.Position |
| 5 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | Units to close (partial close) |
| 6 | FilledAmountInUnits | decimal(16,8) | NO | 0 | CODE-BACKED | Executed units closed |
| 7 | RequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client request correlation GUID |
| 8 | RequestOccurred | datetime | NO | - | CODE-BACKED | When client submitted request |
| 9 | LastUpdate | datetime | NO | - | CODE-BACKED | Last status update time |
| 10 | OpenOccurred | datetime | NO | getutcdate() | CODE-BACKED | When order entered this table |
| 11 | ErrorCode | int | NO | 0 | CODE-BACKED | Error code if rejected/failed |
| 12 | ErrorMessage | varchar(1000) | YES | - | CODE-BACKED | Human-readable error message |
| 13 | ExecutionID | bigint | YES | - | CODE-BACKED | Execution engine correlation ID |
| 14 | ClientViewRateID | bigint | NO | - | CODE-BACKED | Rate shown to client |
| 15 | InstrumentID | int | NO | 0 | CODE-BACKED | Instrument of position (denormalized) |
| 16 | OrderType | int | NO | 19 | VERIFIED | Default 19=OrderForCloseByUnits; Dictionary.OrderType |
| 17 | AggregatedAmountInUnits | decimal(16,6) | NO | 0 | CODE-BACKED | Total units across close plan levels |
| 18 | DelayedOrderID | bigint | NO | 0 | CODE-BACKED | Links to Trade.DelayedOrderForClose |
| 19 | TriggeringOrderID | bigint | NO | 0 | CODE-BACKED | OrderID that triggered this (WAITING_FOR_MARKET update) |
| 20 | TriggeringOrderType | int | NO | 0 | CODE-BACKED | Type of triggering order (19/20) |
| 21 | CustomerFlow | int | YES | - | CODE-BACKED | Customer flow classification |
| 22 | MirrorCloseActionType | int | YES | - | CODE-BACKED | Copy-trade mirror close action type |
| 23 | ClientViewRate | decimal(16,6) | YES | - | CODE-BACKED | Rate displayed to client (denormalized) |
| 24 | OrderCloseActionType | int | YES | - | CODE-BACKED | Close action type when canceled/closed |
| 25 | SettlementTypeID | tinyint | YES | - | VERIFIED | Dictionary.SettlementTypes: 0=CFD, 1=REAL, etc. |
| 26 | OperationType | tinyint | YES | - | CODE-BACKED | Operation classification |
| 27 | LotsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | Lots to close (lot-based close) |
| 28 | PriceRateID | bigint | YES | 0 | CODE-BACKED | Price rate reference |
| 29 | CloseRate | decimal(16,8) | YES | - | CODE-BACKED | Actual close price rate |
| 30 | TriggeringOrderRate | decimal(16,8) | YES | - | CODE-BACKED | Rate from triggering order |
| 31 | TriggeringOrderRateID | bigint | YES | - | CODE-BACKED | Price rate ID from triggering order |
| 32 | IsGuaranteedSL | bit | YES | - | CODE-BACKED | Guaranteed stop-loss indicator |
| 33 | RequiresHierarchicalOperation | bit | YES | - | CODE-BACKED | Tree-based close required |

---

## 5. Relationships

### 5.1 References To
- CID -> Trading.Customer (logical)
- PositionID -> Trade.Position (logical)
- InstrumentID -> Dictionary.Instrument (logical)
- DelayedOrderID -> Trade.DelayedOrderForClose (logical)

### 5.2 Referenced By
- Trade.CloseExecutionPlan (OrderID)
- Trade.OrderForExecutionChangeLog (OrderID)
- Trade.ExecutionPlanChangeLog (OrderID)
- Trade.GetAllOpenOrders (view - StatusID=1 only, with OrderTypeID=14 for ExitOrder)
- Trade.GetOrderForCloseContextData, GetOpenPositionsData, ManualPositionClose, GetPortfolioAggregates, etc.

---

## 6. Dependencies

### 6.0 Dependency Chain
OrderForClose -> CloseExecutionPlan; OrderForCloseCreate/Update consume OrderForExecutionStatus, OrderType, SettlementTypes dictionaries.

### 6.1 Objects This Depends On
- Dictionary.OrderForExecutionStatus
- Dictionary.OrderType
- Dictionary.SettlementTypes
- Trade.CloseExecutionPlan
- Trade.DelayedOrderForClose (optional)

### 6.2 Objects That Depend On This
- Trade.GetAllOpenOrders (view)
- Trade.OrderForCloseCreate (native compiled)
- Trade.OrderForCloseUpdate (native compiled)
- Trade.DeleteOrderForCloseJob
- Trade.ManualPositionClose, PositionCloseWithTimeout
- Trade.GetOrderForCloseInfo, GetOrderForContextData, GetPortfolioAggregates, GetMirrorDataWithCIDForAPI, etc.

---

## 7. Technical Details

### 7.1 Indexes
| Index | Type | Key Columns |
|-------|------|-------------|
| PK__Trade_OrderForClose | PRIMARY KEY NONCLUSTERED HASH | OrderID |
| IXInstrumentID | NONCLUSTERED HASH | InstrumentID |
| IX_CID | NONCLUSTERED HASH | CID |
| IX_CustomerFlow | NONCLUSTERED | CustomerFlow |
| ix_PositionID | NONCLUSTERED | PositionID |
| ix_StatusID | NONCLUSTERED | StatusID |

### 7.2 Constraints
- PK on OrderID
- DEFAULT (0) on PositionID, FilledAmountInUnits, ErrorCode, InstrumentID, AggregatedAmountInUnits, DelayedOrderID, TriggeringOrderID, TriggeringOrderType
- DEFAULT (19) on OrderType
- DEFAULT (getutcdate()) on OpenOccurred
- DEFAULT (0) on PriceRateID (constraint D_PriceRateID)

---

## 8. Sample Queries

```sql
-- Pending close orders (StatusID=1 = RECEIVED)
SELECT OrderID, CID, PositionID, UnitsToDeduct, OrderType, StatusID, OpenOccurred
FROM Trade.OrderForClose WITH (NOLOCK)
WHERE StatusID = 1;

-- Orders by position
SELECT OrderID, CID, PositionID, StatusID, UnitsToDeduct, OpenOccurred
FROM Trade.OrderForClose WITH (NOLOCK)
WHERE PositionID = @PositionID;

-- Status distribution
SELECT StatusID, COUNT(*) AS cnt
FROM Trade.OrderForClose WITH (NOLOCK)
GROUP BY StatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.5/10*
