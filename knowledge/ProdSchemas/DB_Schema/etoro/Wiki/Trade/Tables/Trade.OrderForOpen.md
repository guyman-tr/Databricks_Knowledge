# Trade.OrderForOpen

> Transient memory-optimized hot processing table for position-open orders during execution; orders are inserted here, processed in milliseconds, then archived to History.OrderForOpen when reaching terminal status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OrderID |
| **Partition** | No |
| **Indexes** | 6 |

---

## 1. Business Meaning

**WHAT:** Trade.OrderForOpen is a memory-optimized In-Memory OLTP table that holds orders awaiting or in the process of opening positions. Each row represents one order to open a trade (buy or sell) for a customer on an instrument. The table is the live execution layer where order state changes from RECEIVED to PLACED/FILLED/REJECTED/CANCELED as the trading system processes requests.

**WHY:** Position open orders require sub-millisecond throughput and low latency. Memory-optimized tables with native compiled procedures (OrderForOpenCreate, OrderForOpenUpdate) support the high-volume execution path. Orders are intentionally transient - once they reach a terminal status (FILLED, REJECTED, CANCELED, etc.), they are archived to History.OrderForOpen and deleted from this table. This keeps the table small and fast.

**HOW:** The execution flow inserts orders via Trade.OrderForOpenCreate (either new INSERT or UPDATE of WAITING_FOR_MARKET orders when TriggeringOrderID > 0 and TriggeringOrderType IN (17,18)). Trade.OrderForOpenUpdate propagates status and filled amounts from the execution engine. Trade.PositionOpen consumes order data to create positions. The Trade.DeleteOrderForOpenJob batches terminal orders into History.OrderForOpen via MERGE, then deletes them. Trade.OrderForOpenJob orchestrates cleanup.

---

## 2. Business Logic

### 2.1 Two Paths for Order Creation
When OrderForOpenCreate is called with TriggeringOrderID > 0 and TriggeringOrderType IN (17, 18) (OrderForExecutionByAmount/ByUnits), the procedure UPDATEs an existing WAITING_FOR_MARKET order and logs changes to OrderForExecutionChangeLog and ExecutionPlanChangeLog. Otherwise, it INSERTs a new order and writes to OpenExecutionPlan.

### 2.2 Status Lifecycle
Orders progress through Dictionary.OrderForExecutionStatus: 1=RECEIVED, 2=PLACED, 3=FILLED, 4=REJECTED, 5=PARTIALLY_FILLED, 6=PENDING_CANCEL, 7=CANCELED, 9=CANCELED_PARTIALLY_FILLED, 10=REJECTED_PARTIALLY_FILLED, 11=WAITING_FOR_MARKET. Terminal statuses trigger archival.

### 2.3 Mirror and Copy Trading
MirrorID = 0 indicates manual/direct trades; MirrorID > 0 indicates the order was created from a CopyTrader mirror. OpenActionType (Dictionary.OrdersExitOpenActionType) indicates origin: 0=Manual, 1=OpenByUnregisterMirror, 2=OpenByBackOffice, etc.

### 2.4 Amount vs Units
Orders can specify Amount (money) or AmountInUnits (decimal). FilledAmount/FilledAmountInUnits track execution progress. AggregatedAmount/AggregatedAmountInUnits support multi-level execution plans.

### 2.5 Archive and Cleanup
Trade.DeleteOrderForOpenJob selects terminal orders, MERGEs into History.OrderForOpen (with partition elimination on OccurredAsDate), then DELETEs from Trade.OrderForOpen. Trade.OrderForOpenJob invokes this cleanup.

---

## 3. Data Overview

| Row | Meaning |
|-----|---------|
| 1 | Order in PLACED status (StatusID=2) awaiting fill |
| 2 | Order in WAITING_FOR_MARKET status (StatusID=11) waiting for price |
| 3 | Order in FILLED status (StatusID=3) - about to be archived |
| 4 | Order with MirrorID > 0 - copied from CopyTrader |
| 5 | Order with TriggeringOrderID > 0 - execution of waiting-for-market order |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | Primary key; unique order identifier |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID; links to Trading.Customer |
| 3 | StatusID | int | NO | - | VERIFIED | OrderForExecutionStatus: 1=RECEIVED, 2=PLACED, 3=FILLED, 4=REJECTED, 5=PARTIALLY_FILLED, 6=PENDING_CANCEL, 7=CANCELED, 9=CANCELED_PARTIALLY_FILLED, 10=REJECTED_PARTIALLY_FILLED, 11=WAITING_FOR_MARKET |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Instrument (asset) to trade; links to Dictionary.Instrument |
| 5 | Amount | money | YES | - | CODE-BACKED | Order size in currency |
| 6 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Order size in units (lots/shares) |
| 7 | FilledAmount | decimal(16,8) | NO | 0 | CODE-BACKED | Executed amount in currency |
| 8 | FilledAmountInUnits | decimal(16,8) | NO | 0 | CODE-BACKED | Executed amount in units |
| 9 | IsBuy | tinyint | NO | - | VERIFIED | 1=Buy (long), 0=Sell (short) |
| 10 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier (e.g. 5 for 5x) |
| 11 | StopRate | decimal(16,8) | NO | - | CODE-BACKED | Stop-loss price rate |
| 12 | LimitRate | decimal(16,8) | NO | - | CODE-BACKED | Take-profit/limit price rate |
| 13 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | Trailing stop-loss enabled flag |
| 14 | IsDiscounted | tinyint | YES | - | CODE-BACKED | Whether order has discount |
| 15 | RequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client request correlation GUID |
| 16 | RequestOccurred | datetime | NO | - | CODE-BACKED | When client submitted the request |
| 17 | OpenOccurred | datetime | NO | getutcdate() | CODE-BACKED | When order entered this table |
| 18 | LastUpdate | datetime | NO | - | CODE-BACKED | Last status/amount update time |
| 19 | ExecutionID | bigint | YES | - | CODE-BACKED | Execution engine correlation ID |
| 20 | UnitMargin | decimal(16,6) | YES | - | CODE-BACKED | Margin per unit |
| 21 | PriceRateID | bigint | NO | - | CODE-BACKED | Reference to price rate used |
| 22 | ClientViewRateID | bigint | NO | - | CODE-BACKED | Rate shown to client |
| 23 | ErrorCode | int | NO | 0 | CODE-BACKED | Error code if rejected/failed |
| 24 | ErrorMessage | varchar(1000) | YES | - | CODE-BACKED | Human-readable error message |
| 25 | OrderType | int | NO | - | VERIFIED | Dictionary.OrderType: 1=OpenTrade, 17=OrderForExecutionByAmount, 18=OrderForExecutionByUnits, etc. |
| 26 | MirrorID | int | NO | 0 | VERIFIED | 0=manual; >0=CopyTrader mirror ID |
| 27 | OpenActionType | int | NO | 0 | VERIFIED | Dictionary.OrdersExitOpenActionType: 0=Manual, 1=OpenByUnregisterMirror, 2=OpenByBackOffice, etc. |
| 28 | AggregatedAmount | money | NO | 0 | CODE-BACKED | Total amount across execution plan levels |
| 29 | AggregatedAmountInUnits | decimal(16,6) | NO | 0 | CODE-BACKED | Total units across execution plan levels |
| 30 | DelayedOrderID | bigint | NO | 0 | CODE-BACKED | Links to Trade.DelayedOrderForOpen if from delayed flow |
| 31 | TriggeringOrderID | bigint | NO | 0 | CODE-BACKED | OrderID of order that triggered this (when updating WAITING_FOR_MARKET) |
| 32 | TriggeringOrderType | int | NO | 0 | CODE-BACKED | Type of triggering order (17/18 for execution orders) |
| 33 | CustomerFlow | int | YES | - | CODE-BACKED | Customer flow classification |
| 34 | StopLossPercentage | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss as percentage of price |
| 35 | TakeProfitPercentage | decimal(16,8) | YES | - | CODE-BACKED | Take-profit as percentage of price |
| 36 | ParentPositionID | bigint | YES | 0 | CODE-BACKED | Parent position for add-to-position orders |
| 37 | ClientViewRate | decimal(16,6) | YES | - | CODE-BACKED | Rate displayed to client (denormalized) |
| 38 | OrderCloseActionType | int | YES | - | CODE-BACKED | Close action type when order is canceled/closed |
| 39 | SettlementTypeID | tinyint | YES | - | VERIFIED | Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE |
| 40 | IsNoStopLoss | bit | YES | - | CODE-BACKED | User opted out of stop-loss |
| 41 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | User opted out of take-profit |
| 42 | OperationType | tinyint | YES | - | CODE-BACKED | Operation classification |
| 43 | IsComputedForBalance | bit | YES | - | CODE-BACKED | Whether balance impact is computed |
| 44 | ConversionPriceRateID | bigint | YES | - | CODE-BACKED | Rate used for currency conversion |
| 45 | OpenRate | decimal(16,6) | YES | - | CODE-BACKED | Actual open price rate |
| 46 | ConversionRate | decimal(16,6) | YES | - | CODE-BACKED | Currency conversion rate |
| 47 | ClientRequestedUnits | decimal(16,6) | YES | - | CODE-BACKED | Units requested by client |
| 48 | ClientRequestedAmount | money | YES | - | CODE-BACKED | Amount requested by client |
| 49 | FrozenAmount | money | YES | - | CODE-BACKED | Amount reserved/frozen for order |
| 50 | RequestedSettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type requested by client |
| 51 | RequestedOpenActionType | int | YES | - | CODE-BACKED | Open action type requested |
| 52 | LotCount | decimal(16,6) | YES | - | CODE-BACKED | Number of lots |
| 53 | TriggeringOrderRate | decimal(16,8) | YES | - | CODE-BACKED | Rate from triggering order |
| 54 | TriggeringOrderRateID | bigint | YES | - | CODE-BACKED | Price rate ID from triggering order |
| 55 | AdditionalMargin | money | NO | 0 | CODE-BACKED | Extra margin for the order |

---

## 5. Relationships

### 5.1 References To
- CID -> Trading.Customer (logical)
- InstrumentID -> Dictionary.Instrument (logical)
- DelayedOrderID -> Trade.DelayedOrderForOpen (logical)
- PriceRateID, ClientViewRateID, ConversionPriceRateID -> Price rate tables (logical)

### 5.2 Referenced By
- Trade.OpenExecutionPlan (OrderID)
- Trade.OrderForExecutionChangeLog (OrderID, via change log)
- Trade.ExecutionPlanChangeLog (OrderID, via change log)
- Trade.PositionOpen procedure (consumes order)
- Trade.GetAllOpenOrders (view - StatusID=1 only)
- Trade.GetOrderForContextData, GetPortfolioAggregates, GetMirrorDataWithCIDForAPI, etc.

---

## 6. Dependencies

### 6.0 Dependency Chain
OrderForOpen -> OpenExecutionPlan; OrderForOpenCreate/Update consume OrderForExecutionStatus, SettlementTypes, OrderType, OrdersExitOpenActionType dictionaries.

### 6.1 Objects This Depends On
- Dictionary.OrderForExecutionStatus
- Dictionary.OrderType
- Dictionary.SettlementTypes
- Dictionary.OrdersExitOpenActionType (OpenActionType)
- Trade.OpenExecutionPlan
- Trade.DelayedOrderForOpen (optional)

### 6.2 Objects That Depend On This
- Trade.GetAllOpenOrders (view)
- Trade.OrderForOpenCreate (native compiled)
- Trade.OrderForOpenUpdate (native compiled)
- Trade.DeleteOrderForOpenJob
- Trade.PositionOpen
- Trade.GetOrderForOpenInfo, GetOrderForContextData, GetPortfolioAggregates, GetMirrorDataWithCIDForAPI, GetOrderMatchingItemsByInstrumentID_OrdersForOpen, etc.

---

## 7. Technical Details

### 7.1 Indexes
| Index | Type | Key Columns |
|-------|------|-------------|
| PK__Trade_OrderForOpenTest1 | PRIMARY KEY NONCLUSTERED HASH | OrderID |
| IXInstrumentID | NONCLUSTERED HASH | InstrumentID |
| IX_CID | NONCLUSTERED HASH | CID |
| IX | NONCLUSTERED | CustomerFlow |
| ix_CID | NONCLUSTERED | CID, InstrumentID, StatusID, SettlementTypeID |
| ix_StatusID | NONCLUSTERED | StatusID, OrderID |

### 7.2 Constraints
- PK on OrderID
- DEFAULT (0) on FilledAmount, FilledAmountInUnits, ErrorCode, MirrorID, OpenActionType, AggregatedAmount, AggregatedAmountInUnits, DelayedOrderID, TriggeringOrderID, TriggeringOrderType, ParentPositionID, AdditionalMargin
- DEFAULT (getutcdate()) on OpenOccurred

---

## 8. Sample Queries

```sql
-- Pending open orders (StatusID=1 = RECEIVED)
SELECT OrderID, CID, InstrumentID, Amount, AmountInUnits, IsBuy, OrderType, StatusID, OpenOccurred
FROM Trade.OrderForOpen WITH (NOLOCK)
WHERE StatusID = 1;

-- Orders by customer and instrument
SELECT OrderID, CID, InstrumentID, StatusID, Amount, AmountInUnits, OpenOccurred
FROM Trade.OrderForOpen WITH (NOLOCK)
WHERE CID = @CID AND InstrumentID = @InstrumentID;

-- Status distribution
SELECT StatusID, COUNT(*) AS cnt
FROM Trade.OrderForOpen WITH (NOLOCK)
GROUP BY StatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.5/10*
