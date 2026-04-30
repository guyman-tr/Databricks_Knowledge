# Trade.OrdersExitTbl

> Partitioned disk-based table storing exit orders (pending take-profit, stop-loss, trailing stop) that close existing positions when market conditions are met; status 1 = active, archived to History.OrdersExitTbl when closed/canceled.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OrderID, PartitionCol |
| **Partition** | Yes - PS_ORDERS on PartitionCol (computed: CID % 50) |
| **Indexes** | 4 |

---

## 1. Business Meaning

**WHAT:** Trade.OrdersExitTbl stores exit orders - pending orders that close existing positions when a price target is met (take-profit, stop-loss, trailing stop). Each row represents one pending exit order tied to a specific position. Unlike OrderForClose (transient execution orders), exit orders persist until triggered, canceled, or the position is closed. The table is partitioned on PartitionCol (CID % 50) for scalability.

**WHY:** Exit orders are user-placed orders that may sit for days or weeks. They require durable, partitioned storage to handle high volume. The unique clustered index on (CID, PositionID, PartitionCol) enforces one active exit order per position per customer. OrderID comes from Trade.OrderExitSequence. When an exit order is closed/canceled, it is archived to History.OrdersExitTbl via AsyncOrdersChangeLog and deleted from this table.

**HOW:** Trade.OrderExitOpen inserts new exit orders (via view Trade.OrdersExit). Trade.OrderExitClose updates StatusID=2, CloseOccurred, CloseActionType and queues async archive. Trade.AsyncOrdersChangeLog performs the DELETE with OUTPUT into History.OrdersExitTbl. The view Trade.OrdersExit filters StatusID=1 and excludes positions that have a DelayedOrderForClose (positions in delayed close flow). When opening a full close exit order, OrderExitOpen closes all entry orders on the parent position (ParentPositionID) via OrderEntryClose.

---

## 2. Business Logic

### 2.1 One Exit Order Per Position
The unique clustered index (CID, PositionID, PartitionCol) ensures at most one active exit order per position per customer. OrderExitOpen checks EXISTS on Trade.OrdersExit before insert.

### 2.2 Status and Lifecycle
StatusID=1 (active). When closed, StatusID=2, CloseOccurred, CloseActionType set. AsyncOrdersChangeLog archives to History.OrdersExitTbl and deletes. OpenActionType (Dictionary.OrdersExitOpenActionType): 0=Manual, 1=OpenByUnregisterMirror, etc.

### 2.3 Mirror and Copy Trading
MirrorID and MirrorCloseActionType support CopyTrader mirror close scenarios. When a mirror leader closes, mirror followers' exit orders may use MirrorCloseActionType.

### 2.4 Redeem and Partial Close
RedeemID and RedeemReasonID link to fund redemption scenarios. UnitsToDeduct supports partial close; CloseByUnitsID links to the partial close order when closing by units.

### 2.5 Partition Elimination
PartitionCol = CID % 50. Queries filtering by CID can use partition elimination when Join/Where uses PartitionCol or CID%50.

---

## 3. Data Overview

| Row | Meaning |
|-----|---------|
| 1 | Active exit order (StatusID=1) - take-profit or stop-loss on position |
| 2 | Exit order with MirrorID>0 - copy-trade mirror close |
| 3 | Exit order with RedeemID - fund redemption close |
| 4 | Partial close exit - UnitsToDeduct set, CloseByUnitsID links |
| 5 | Exit order excluded from view - position has DelayedOrderForClose |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | NEXT VALUE FOR Trade.OrderExitSequence | CODE-BACKED | Primary key component; unique order identifier |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID; links to Trading.Customer |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | Position to close; links to Trade.Position |
| 4 | OpenOccurred | datetime | NO | getutcdate() | CODE-BACKED | When exit order was created |
| 5 | MirrorID | int | YES | - | VERIFIED | 0=manual; >0=CopyTrader mirror ID |
| 6 | MirrorCloseActionType | int | YES | - | CODE-BACKED | Close action type for mirror scenarios |
| 7 | OpenActionType | int | NO | 0 | VERIFIED | Dictionary.OrdersExitOpenActionType: 0=Manual, 1=OpenByUnregisterMirror, etc. |
| 8 | RedeemID | int | YES | - | CODE-BACKED | Redeem operation ID for fund redemption |
| 9 | RedeemReasonID | int | YES | - | CODE-BACKED | Reason for redemption |
| 10 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | Units to close (partial close); NULL = full close |
| 11 | CloseByUnitsID | bigint | YES | - | CODE-BACKED | Links to partial close order when closing by units |
| 12 | PartitionCol | int | NO | (computed) | CODE-BACKED | Persisted computed: CID % 50; partition key for PS_ORDERS |
| 13 | StatusID | int | NO | 1 | VERIFIED | 1=active, 2=closed; Dictionary.OrderForExecutionStatus |
| 14 | CloseOccurred | datetime | YES | - | CODE-BACKED | When exit order was closed/canceled |
| 15 | CloseActionType | int | YES | - | CODE-BACKED | How order was closed (e.g. executed, canceled) |

---

## 5. Relationships

### 5.1 References To
- CID -> Trading.Customer (logical)
- PositionID -> Trade.Position (logical)
- RedeemID -> Redeem tables (logical)
- CloseByUnitsID -> partial close order (logical)

### 5.2 Referenced By
- Trade.OrdersExit (view - StatusID=1, excludes DelayedOrderForClose positions)
- Trade.OrderExitOpen (insert)
- Trade.OrderExitClose (update)
- Trade.AsyncOrdersChangeLog (delete/archive)
- Trade.OrderExitEdit (update via view)
- Trade.GetOpenPositionData, GetClientPortfolioForAPI, GetAccountPartialExitOrders, GenerateCloseMultiplePositionsList, etc.

---

## 6. Dependencies

### 6.0 Dependency Chain
OrdersExitTbl -> Trade.OrderExitSequence; OrdersExitTbl is base for Trade.OrdersExit view. OrderExitOpen/Close and AsyncOrdersChangeLog drive lifecycle. Partition scheme PS_ORDERS uses PartitionCol.

### 6.1 Objects This Depends On
- Trade.OrderExitSequence
- Dictionary.OrderForExecutionStatus
- Dictionary.OrdersExitOpenActionType
- Trade.DelayedOrderForClose (view exclusion)

### 6.2 Objects That Depend On This
- Trade.OrdersExit (view)
- Trade.OrderExitOpen
- Trade.OrderExitClose
- Trade.OrderExitEdit
- Trade.AsyncOrdersChangeLog
- Trade.GetOpenPositionData, GetClientPortfolioForAPI, GetAccountPartialExitOrders, GetLivePositionWithPartialCloseData, etc.

---

## 7. Technical Details

### 7.1 Indexes
| Index | Type | Key Columns |
|-------|------|-------------|
| PK_OrdersExitNew | PRIMARY KEY NONCLUSTERED | OrderID, PartitionCol |
| IDX_OrdersExitNew_CID_PID | UNIQUE CLUSTERED | CID, PositionID, PartitionCol |
| IDX_OrdersExitNew_Covering_user_portfolio | NONCLUSTERED | CID, OrderID, PositionID (covering) |
| IDX_OrdersExitNew_PositionID1 | NONCLUSTERED | PositionID |

### 7.2 Constraints
- PK on (OrderID, PartitionCol)
- Unique clustered on (CID, PositionID, PartitionCol) - one exit per position per customer
- DEFAULT (NEXT VALUE FOR Trade.OrderExitSequence) on OrderID
- DEFAULT (getutcdate()) on OpenOccurred
- DEFAULT (0) on OpenActionType
- DEFAULT (1) on StatusID
- Partition scheme PS_ORDERS on PartitionCol

---

## 8. Sample Queries

```sql
-- Active exit orders for a customer (use partition elimination)
SELECT OrderID, CID, PositionID, UnitsToDeduct, OpenActionType, OpenOccurred
FROM Trade.OrdersExitTbl WITH (NOLOCK)
WHERE CID = @CID AND StatusID = 1 AND PartitionCol = @CID % 50;

-- Exit orders by position
SELECT OrderID, CID, PositionID, StatusID, CloseOccurred, CloseActionType
FROM Trade.OrdersExitTbl WITH (NOLOCK)
WHERE PositionID = @PositionID;

-- Status distribution
SELECT StatusID, COUNT(*) AS cnt
FROM Trade.OrdersExitTbl WITH (NOLOCK)
GROUP BY StatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.3/10*
