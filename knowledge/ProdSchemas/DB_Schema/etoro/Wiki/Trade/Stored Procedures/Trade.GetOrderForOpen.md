# Trade.GetOrderForOpen

> Returns the complete open order record for a given OrderID from Trade.OrderForOpen - used to retrieve all state fields of an in-flight or completed open order.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID BIGINT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForOpen` is a simple single-row lookup that returns the full `Trade.OrderForOpen` record for the given `@OrderID`. It returns all 49 fields: status, amounts, rates, execution IDs, mirror/copy context, action type, and error information.

**WHY:** Used across the trading platform whenever the full state of an open order needs to be retrieved - for status queries, retry logic, display, and audit. `Trade.OrderForOpen` is the authoritative source of open order state while orders are in flight.

**HOW:** Simple `SELECT ... FROM Trade.OrderForOpen WHERE OrderID = @OrderID` with `NOLOCK`. Returns at most one row.

---

## 2. Business Logic

### 2.1 Full Open Order State

**What:** `Trade.OrderForOpen` captures the full lifecycle of an open order from placement through execution. The returned columns cover:

**Key field groups:**
- **Identity**: OrderID, CID, InstrumentID, MirrorID
- **Status/lifecycle**: StatusID, RequestGuid, RequestOccurred, OpenOccurred, LastUpdate, ExecutionID
- **Order parameters**: Amount, AmountInUnits, IsBuy, Leverage, StopRate, LimitRate, UnitMargin, LotCount
- **Fill tracking**: FilledAmount, FilledAmountInUnits, AggregatedAmount, AggregatedAmountInUnits
- **Execution rates**: PriceRateID, ClientViewRateID
- **Error handling**: ErrorCode, ErrorMessage
- **Order classification**: OrderType, OpenActionType, OperationType
- **Delayed/triggered**: DelayedOrderID, TriggeringOrderID, TriggeringOrderType
- **Copy context**: CustomerFlow
- **Risk settings**: StopLossPercentage, TakeProfitPercentage, IsNoStopLoss, IsNoTakeProfit, IsTslEnabled, IsDiscounted
- **Copy position**: ParentPositionID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | The open order ID to retrieve. References Trade.OrderForOpen.OrderID. |

**Return Columns (from Trade.OrderForOpen):**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | OrderID | bigint | NO | CODE-BACKED | Primary key of the open order. |
| R2 | CID | int | NO | CODE-BACKED | Customer who placed the open order. |
| R3 | StatusID | int | NO | CODE-BACKED | Current status: 2=Placed, 3=Executed/Filled, 4=Cancelled, 5=Failed, 11=WaitingForMarket, etc. |
| R4 | InstrumentID | int | NO | CODE-BACKED | Instrument to open. |
| R5 | Amount | money | NO | CODE-BACKED | Requested order amount in account currency. |
| R6 | AmountInUnits | decimal | YES | CODE-BACKED | Requested size in instrument units. |
| R7 | FilledAmount | money | YES | CODE-BACKED | Amount filled so far (partial fill support). |
| R8 | FilledAmountInUnits | decimal | YES | CODE-BACKED | Units filled so far. |
| R9 | IsBuy | bit | NO | CODE-BACKED | Direction: 1=buy, 0=sell. |
| R10 | Leverage | smallint | NO | CODE-BACKED | Leverage multiplier. |
| R11 | StopRate | money | YES | CODE-BACKED | Stop-loss rate. |
| R12 | LimitRate | money | YES | CODE-BACKED | Take-profit rate. |
| R13 | IsTslEnabled | bit | YES | CODE-BACKED | Whether trailing stop-loss is enabled. |
| R14 | IsDiscounted | bit | YES | CODE-BACKED | Whether commission discount applies. |
| R15 | RequestGuid | uniqueidentifier | YES | CODE-BACKED | Idempotency GUID for this open request. |
| R16 | RequestOccurred | datetime | YES | CODE-BACKED | When the order was placed. |
| R17 | OpenOccurred | datetime | YES | CODE-BACKED | When the order was executed/opened. |
| R18 | LastUpdate | datetime | YES | CODE-BACKED | Last status update timestamp. |
| R19 | ExecutionID | bigint | YES | CODE-BACKED | Execution batch ID. |
| R20 | UnitMargin | money | YES | CODE-BACKED | Margin required per unit. |
| R21 | PriceRateID | bigint | YES | CODE-BACKED | Rate record ID used for execution. |
| R22 | ClientViewRateID | bigint | YES | CODE-BACKED | Rate record ID seen by the customer. |
| R23 | ErrorCode | int | YES | CODE-BACKED | Error code if order failed. |
| R24 | ErrorMessage | nvarchar | YES | CODE-BACKED | Error description. |
| R25 | OrderType | tinyint | YES | CODE-BACKED | Open order type (market, limit, delayed, etc.). |
| R26 | MirrorID | int | YES | CODE-BACKED | Mirror relationship this order belongs to. 0 if self-opened. |
| R27 | OpenActionType | int | YES | CODE-BACKED | Why this position was opened. References Dictionary.OpenPositionActionType (0=Customer, 1=Hierarchical, etc.). |
| R28 | AggregatedAmount | money | YES | CODE-BACKED | Total amount across aggregated open orders. |
| R29 | AggregatedAmountInUnits | decimal | YES | CODE-BACKED | Total units across aggregated open orders. |
| R30 | DelayedOrderID | bigint | YES | CODE-BACKED | Linked delayed order ID if this was triggered from a delayed open. |
| R31 | TriggeringOrderID | bigint | YES | CODE-BACKED | Order that triggered this open (e.g., a copy trigger). |
| R32 | TriggeringOrderType | tinyint | YES | CODE-BACKED | Type of the triggering order. |
| R33 | CustomerFlow | bit | YES | CODE-BACKED | 1=customer-initiated, 0=system-initiated. |
| R34 | StopLossPercentage | decimal | YES | CODE-BACKED | Stop-loss as percentage of position value. |
| R35 | TakeProfitPercentage | decimal | YES | CODE-BACKED | Take-profit as percentage of position value. |
| R36 | ParentPositionID | bigint | YES | CODE-BACKED | Parent position ID for copy-trade child orders. |
| R37 | OperationType | tinyint | YES | CODE-BACKED | System operation type classification. |
| R38 | IsNoStopLoss | bit | YES | CODE-BACKED | Whether position has no stop-loss requirement. |
| R39 | IsNoTakeProfit | bit | YES | CODE-BACKED | Whether position has no take-profit requirement. |
| R40 | LotCount | decimal | YES | CODE-BACKED | Order size in lots. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrderForOpen | Direct query | SELECT all fields WHERE OrderID = @OrderID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Open-order execution and management services | N/A | CALLER | Retrieve full open order state |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForOpen (procedure)
└── Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | SELECT all fields WHERE OrderID = @OrderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Open-order execution services | External | Retrieve order state by ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** Uses `WITH (NOLOCK)` for read performance.

---

## 8. Sample Queries

### 8.1 Get open order by ID
```sql
EXEC Trade.GetOrderForOpen @OrderID = 987654321
```

### 8.2 Manual equivalent
```sql
SELECT OrderID, CID, StatusID, InstrumentID, Amount, AmountInUnits, FilledAmount, FilledAmountInUnits,
       IsBuy, Leverage, StopRate, LimitRate, IsTslEnabled, IsDiscounted, RequestGuid, RequestOccurred,
       OpenOccurred, LastUpdate, ExecutionID, UnitMargin, PriceRateID, ClientViewRateID,
       ErrorCode, ErrorMessage, OrderType, MirrorID, OpenActionType, AggregatedAmount,
       AggregatedAmountInUnits, DelayedOrderID, TriggeringOrderID, TriggeringOrderType,
       CustomerFlow, StopLossPercentage, TakeProfitPercentage, ParentPositionID,
       OperationType, IsNoStopLoss, IsNoTakeProfit, LotCount
FROM   Trade.OrderForOpen WITH (NOLOCK)
WHERE  OrderID = 987654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForOpen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForOpen.sql*
