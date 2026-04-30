# Trade.OrdersEntryTbl

> Disk-based table storing entry orders (pending limit/stop orders) that trigger position opens when market conditions are met; status 1 = active, archived to History.OrdersEntryTbl when closed/canceled.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OrderID |
| **Partition** | No |
| **Indexes** | 6 |

---

## 1. Business Meaning

**WHAT:** Trade.OrdersEntryTbl stores entry orders - pending orders that wait for a price target (limit buy/sell, stop buy/sell) before opening a position. Unlike OrderForOpen (transient execution orders), entry orders persist until triggered or canceled. Each row represents one pending entry order for a customer on an instrument, with optional stop-loss/take-profit percentages and parent position linkage for add-to-position scenarios.

**WHY:** Entry orders are user-placed "set and forget" orders that may sit for hours or days. They require durable disk storage, not memory-optimized transient tables. The table uses Trade.OrdersEntrySequence for OrderID generation and defaults StatusID=1 (active) and OrderTypeID=13 (EntryOrderByAmount). When an entry order is closed or canceled, it is archived to History.OrdersEntryTbl via AsyncOrdersChangeLog (OperationTypeID=2) and deleted from this table.

**HOW:** Trade.OrderEntryOpen inserts new entry orders (via view Trade.OrdersEntry). Trade.OrderEntryClose updates StatusID=2, CloseOccurred, CloseActionType and queues async archive. Trade.AsyncOrdersChangeLog performs the actual DELETE with OUTPUT into History.OrdersEntryTbl. The view Trade.OrdersEntry filters StatusID=1 for active orders only. When a full close exit order is created on a position, OrderExitOpen closes all entry orders with ParentPositionID = that PositionID (ActionTypeID=4) and syncs to SynchOrdersEntry.

---

## 2. Business Logic

### 2.1 Status and Lifecycle
StatusID=1 (active) from Dictionary.OrderForExecutionStatus. When closed, StatusID=2, CloseOccurred and CloseActionType are set. The async job then archives and deletes. CloseActionType=4 means "closed due to exit order on parent position."

### 2.2 Order Types
Default OrderTypeID=13 (EntryOrderByAmount). Dictionary.OrderType defines other entry types. OpenOpenOperationTypeID classifies the open operation. StopLosPercentage and TakeProfitPercentage (note: typo "StopLos" not "StopLoss" in schema) define optional SL/TP levels.

### 2.3 Parent Position and Add-to-Position
ParentPositionID links to an existing position when this entry order is an add-to-position (e.g. scaling in). When a full close exit order is placed on the parent position, all entry orders with that ParentPositionID are closed via OrderEntryClose.

### 2.4 Mirror and Copy Trading
MirrorID=0 for manual; MirrorID>0 for CopyTrader. InitialMirrorAmountInCents stores the mirror allocation amount. Index IX_TradeOrdersEntry_MirrorIDCID supports mirror lookups by CID+MirrorID.

### 2.5 Settlement and SL/TP Flags
SettlementTypeID (Dictionary.SettlementTypes). IsNoStopLoss, IsNoTakeProfit indicate user opted out of default SL/TP.

---

## 3. Data Overview

| Row | Meaning |
|-----|---------|
| 1 | Active entry order (StatusID=1) waiting for limit/stop price |
| 2 | Entry order with ParentPositionID - add-to-position on existing trade |
| 3 | Entry order with MirrorID>0 - copy-trade entry |
| 4 | Entry order with CloseOccurred set - pending async archive |
| 5 | Entry order with StopLosPercentage/TakeProfitPercentage for SL/TP |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | NEXT VALUE FOR Trade.OrdersEntrySequence | CODE-BACKED | Primary key; unique order identifier |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID; links to Trading.Customer |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | Instrument (asset) to trade |
| 4 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier |
| 5 | Amount | money | YES | - | CODE-BACKED | Order size in currency |
| 6 | IsBuy | bit | YES | - | VERIFIED | 1=Buy (long), 0=Sell (short) |
| 7 | StopLosPercentage | money | YES | - | CODE-BACKED | Stop-loss percentage (schema typo: StopLos) |
| 8 | TakeProfitPercentage | money | YES | - | CODE-BACKED | Take-profit percentage |
| 9 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | When order was created |
| 10 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position for add-to-position; 0 or NULL if new position |
| 11 | MirrorID | int | YES | - | VERIFIED | 0=manual; >0=CopyTrader mirror ID |
| 12 | InitialMirrorAmountInCents | money | YES | - | CODE-BACKED | Mirror allocation amount in cents |
| 13 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | Trailing stop-loss enabled |
| 14 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Order size in units |
| 15 | OrderTypeID | int | NO | 13 | VERIFIED | Dictionary.OrderType; 13=EntryOrderByAmount default |
| 16 | OpenOpenOperationTypeID | int | YES | - | CODE-BACKED | Open operation classification |
| 17 | IsDiscounted | bit | YES | - | CODE-BACKED | Discount applied flag |
| 18 | StatusID | int | NO | 1 | VERIFIED | 1=active, 2=closed; Dictionary.OrderForExecutionStatus |
| 19 | CloseOccurred | datetime | YES | - | CODE-BACKED | When order was closed/canceled |
| 20 | CloseActionType | int | YES | - | CODE-BACKED | How order was closed (e.g. 4=parent position exit) |
| 21 | SettlementTypeID | tinyint | YES | - | VERIFIED | Dictionary.SettlementTypes: 0=CFD, 1=REAL, etc. |
| 22 | IsNoStopLoss | bit | YES | - | CODE-BACKED | User opted out of stop-loss |
| 23 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | User opted out of take-profit |

---

## 5. Relationships

### 5.1 References To
- CID -> Trading.Customer (logical)
- InstrumentID -> Dictionary.Instrument (logical)
- ParentPositionID -> Trade.Position (logical)

### 5.2 Referenced By
- Trade.OrdersEntry (view - StatusID=1)
- Trade.OrderEntryOpen (insert)
- Trade.OrderEntryClose (update)
- Trade.AsyncOrdersChangeLog (delete/archive)
- Trade.SynchOrdersEntry (when CloseActionType=4, entry closed due to parent exit)
- Trade.GetOrdersEntryDataWithCIDForAPI, GetOrdersEntryForMirror, GetClientPortfolioForAPI, etc.

---

## 6. Dependencies

### 6.0 Dependency Chain
OrdersEntryTbl -> Trade.OrdersEntrySequence; OrdersEntryTbl is base for Trade.OrdersEntry view. OrderEntryOpen/Close and AsyncOrdersChangeLog drive lifecycle.

### 6.1 Objects This Depends On
- Trade.OrdersEntrySequence
- Dictionary.OrderForExecutionStatus
- Dictionary.OrderType
- Dictionary.SettlementTypes

### 6.2 Objects That Depend On This
- Trade.OrdersEntry (view)
- Trade.OrderEntryOpen
- Trade.OrderEntryClose
- Trade.AsyncOrdersChangeLog
- Trade.GetOrdersEntryDataWithCIDForAPI, GetClientPortfolioForAPI, GetAccountAssets, GetOrderEntry, etc.

---

## 7. Technical Details

### 7.1 Indexes
| Index | Type | Key Columns |
|-------|------|-------------|
| PK_TOrdersEntry | PRIMARY KEY CLUSTERED | OrderID |
| IDX_TradeOrdersEntry_ParentPositionID | NONCLUSTERED | ParentPositionID |
| IX_TOrdersEntry_CID | NONCLUSTERED | CID |
| IX_TradeOrdersEntry_MirrorIDCID | NONCLUSTERED | CID, MirrorID |
| IX_covering_UserPortfolio | NONCLUSTERED | CID, OrderID (covering) |
| Ix_InstrumentID | NONCLUSTERED | InstrumentID |

### 7.2 Constraints
- PK on OrderID
- DEFAULT (NEXT VALUE FOR Trade.OrdersEntrySequence) on OrderID
- DEFAULT (getutcdate()) on Occurred
- DEFAULT (0) on IsTslEnabled
- DEFAULT (13) on OrderTypeID
- DEFAULT (1) on StatusID

---

## 8. Sample Queries

```sql
-- Active entry orders for a customer
SELECT OrderID, CID, InstrumentID, Amount, IsBuy, StopLosPercentage, TakeProfitPercentage, Occurred
FROM Trade.OrdersEntryTbl WITH (NOLOCK)
WHERE CID = @CID AND StatusID = 1;

-- Entry orders by instrument
SELECT OrderID, CID, InstrumentID, OrderTypeID, StatusID, Occurred, CloseOccurred
FROM Trade.OrdersEntryTbl WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID;

-- Status and OrderType distribution
SELECT StatusID, OrderTypeID, COUNT(*) AS cnt
FROM Trade.OrdersEntryTbl WITH (NOLOCK)
GROUP BY StatusID, OrderTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10*
