# Trade.OrderForOpenCreate

> Natively compiled, hot-path SP that either inserts a new open order into Trade.OrderForOpen or updates an existing WAITING_FOR_MARKET order (OrderType 17/18), then always writes the open execution plan and optionally marks a linked delayed order as FILLED.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID + @TriggeringOrderType (determines insert vs update path) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrderForOpenCreate is the core write operation for position open orders in eToro's trading engine - the open-order counterpart to Trade.OrderForCloseCreate. When a customer or system requests a position open (manual, copy-trade mirror, delayed order activation), the trading engine calls this procedure to persist the order request.

Like its close counterpart, it is natively compiled (WITH NATIVE_COMPILATION, SCHEMABINDING) in SNAPSHOT isolation for maximum throughput on the hot path. It handles two flows:

**Regular creation**: a brand-new open order is INSERTed into Trade.OrderForOpen with all order attributes - instrument, amount, leverage, SL/TP rates, TSL flag, settlement type, mirror linkage, triggering context, and client-requested values.

**WAITING_FOR_MARKET update** (TriggeringOrderType=17 or 18): an existing order was placed in a market-open queue and is now being activated. The current state is backed up to Trade.OrderForExecutionChangeLog, the order is UPDATEd with the new execution state, and the existing execution plan is backed up to Trade.ExecutionPlanChangeLog and deleted before the new plan is inserted.

After either flow, the execution plan rows from @OpenExecutionPlan TVP are inserted into Trade.OpenExecutionPlan. If a @DelayedOrderID was associated, it is marked FILLED (StatusID=2) via Trade.DelayedOrderForOpenStatusUpdate.

The procedure is called directly by Trade.OrderForOpenCreateWrapper (discovered as caller in SSDT).

---

## 2. Business Logic

### 2.1 WAITING_FOR_MARKET Update Path

**What**: Handles re-activation of an open order that was waiting for market open (OrderType 17 or 18).

**Columns/Parameters Involved**: `@TriggeringOrderID`, `@TriggeringOrderType`, `Trade.OrderForOpen`, `Trade.OrderForExecutionChangeLog`, `Trade.OpenExecutionPlan`, `Trade.ExecutionPlanChangeLog`

**Rules**:
- Condition: @TriggeringOrderID > 0 AND @TriggeringOrderType IN (17, 18).
- Step 1: INSERT INTO Trade.OrderForExecutionChangeLog from Trade.OrderForOpen WHERE OrderID=@OrderID (backs up pre-update state: Amount, AmountInUnits, UnitMargin, IsDiscounted, rate fields, FrozenAmount).
- Step 2: UPDATE Trade.OrderForOpen: StatusID, Amount, AmountInUnits, UnitMargin, IsDiscounted, RequestGuid, RequestOccurred, LastUpdate=GETUTCDATE(), PriceRateID, ClientViewRateID, TriggeringOrderID, TriggeringOrderType, ErrorCode, ErrorMessage, AggregatedAmount, AggregatedAmountInUnits, OrderCloseActionType, OpenRate, ConversionRate, ConversionPriceRateID, FrozenAmount, LotCount, TriggeringOrderRate, TriggeringOrderRateID.
  - If @@ROWCOUNT=0: THROW 50000 'Update Trade.OrderForOpen failed. Order not found. Order may already be in terminal state.'
- Step 3: INSERT INTO Trade.ExecutionPlanChangeLog from Trade.OpenExecutionPlan WHERE OrderID=@OrderID.
- Step 4: DELETE FROM Trade.OpenExecutionPlan WHERE OrderID=@OrderID.

**Diagram**:
```
TriggeringOrderType:
  17 or 18 (WAITING_FOR_MARKET open) -> Update path (backup + UPDATE OrderForOpen + backup + DELETE OpenExecutionPlan)
  other                               -> Create path (INSERT OrderForOpen)
```

### 2.2 Regular Creation Path

**What**: Inserts a new open order for standard position opens.

**Columns/Parameters Involved**: All @* parameters -> `Trade.OrderForOpen` columns

**Rules**:
- INSERT INTO Trade.OrderForOpen with all 47+ parameters mapped directly.
- LastUpdate=GETUTCDATE() is set automatically.
- MirrorID links the open order to a copy-trade mirror if applicable.
- IsNoStopLoss/IsNoTakeProfit: explicit flags to record that the customer opted out of SL/TP.
- FrozenAmount: amount held in reserve while the order is pending.
- AdditionalMargin: extra margin required beyond UnitMargin (e.g., overnight financing).

### 2.3 Execution Plan Write (Always)

**What**: Inserts the open execution plan from the TVP for both code paths.

**Columns/Parameters Involved**: `@OpenExecutionPlan Trade.OpenExecutionPlanTbl`, `Trade.OpenExecutionPlan`

**Rules**:
- INSERT INTO Trade.OpenExecutionPlan(OrderID, Level, Units, CID, MirrorID, SettlementTypeID, IsHedged, OpenActionType, OpenCorrelationID, ParentOpenCorrelationID, Amount) SELECT @OrderID, ... FROM @OpenExecutionPlan.
- Always executed regardless of create vs update path.
- OpenCorrelationID/ParentOpenCorrelationID: supports hierarchical copy-trade tree execution sequencing.

### 2.4 Optional: Delayed Order Mark FILLED

**What**: Marks the source delayed order as consumed when this open order activates it.

**Columns/Parameters Involved**: `@DelayedOrderID`, `Trade.DelayedOrderForOpenStatusUpdate`

**Rules**:
- If @DelayedOrderID <> 0: EXEC Trade.DelayedOrderForOpenStatusUpdate @OrderID=@DelayedOrderID, @StatusID=2 (FILLED).
- Ensures the delayed order lifecycle is closed when its triggering open order is created.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | Open order identifier. On create: new OrderID to insert. On WAITING_FOR_MARKET update: existing OrderID to update. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID owning the open order. |
| 3 | @StatusID | int | NO | - | CODE-BACKED | Initial/updated order status. |
| 4 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument to open a position on. |
| 5 | @Amount | money | NO | - | CODE-BACKED | Dollar amount of the position. |
| 6 | @AmountInUnits | decimal(16,6) | NO | - | CODE-BACKED | Position size in instrument units. |
| 7 | @UnitMargin | decimal(16,6) | NO | - | CODE-BACKED | Margin per unit required for this position. |
| 8 | @IsBuy | tinyint | NO | - | CODE-BACKED | 1=Buy (long), 0=Sell (short). |
| 9 | @Leverage | int | NO | - | CODE-BACKED | Leverage multiplier applied to the position. |
| 10 | @StopRate | decimal(16,8) | NO | - | CODE-BACKED | Stop Loss rate. |
| 11 | @LimitRate | decimal(16,8) | NO | - | CODE-BACKED | Take Profit rate. |
| 12 | @IsTslEnabled | tinyint | NO | - | CODE-BACKED | 1=Trailing Stop Loss enabled for this position. |
| 13 | @IsDiscounted | tinyint | NO | - | CODE-BACKED | 1=Spread-discounted position (spread-adjusted prices used). |
| 14 | @RequestGuid | uniqueidentifier | NO | - | CODE-BACKED | Client-provided GUID for idempotency. |
| 15 | @RequestOccurred | datetime | NO | - | CODE-BACKED | When the open request was made by the client. |
| 16 | @PriceRateID | bigint | NO | - | CODE-BACKED | Reference to the execution price rate. |
| 17 | @ClientViewRateID | bigint | NO | - | CODE-BACKED | Reference to the price rate the client saw. |
| 18 | @OrderType | int | NO | - | CODE-BACKED | Type of open order (e.g., market, limit, copy-trade, delayed). |
| 19 | @AggregatedAmount | money | NO | - | CODE-BACKED | Total aggregated amount across a copy-trade tree open. |
| 20 | @AggregatedAmountInUnits | decimal(16,6) | NO | - | CODE-BACKED | Total aggregated units across the tree open. |
| 21 | @OpenExecutionPlan | Trade.OpenExecutionPlanTbl (READONLY TVP) | NO | - | CODE-BACKED | Plan rows: (Level, Units, Amount, CID, MirrorID, SettlementType, IsHedged, OpenActionType, OpenCorrelationID, ParentOpenCorrelationID) defining the tree-level execution hierarchy. |
| 22 | @ErrorCode | INT | YES | 0 | CODE-BACKED | Error code if order created in error state. |
| 23 | @ErrorMessage | VARCHAR(1000) | YES | NULL | CODE-BACKED | Error message detail. |
| 24 | @MirrorID | INT | YES | 0 | CODE-BACKED | CopyTrader mirror ID if this open is for a copied position. 0 if not copy-trade. |
| 25 | @DelayedOrderID | BIGINT | YES | 0 | CODE-BACKED | If non-zero: the originating delayed order is marked FILLED after this open order is created. |
| 26 | @OpenActionType | INT | YES | 0 | CODE-BACKED | Action type of the open (e.g., manual, copy, SL-reverse). |
| 27 | @TriggeringOrderID | BIGINT | YES | 0 | CODE-BACKED | ID of the order that triggered this open. >0 with TriggeringOrderType 17/18 activates WAITING_FOR_MARKET update path. |
| 28 | @TriggeringOrderType | INT | YES | 0 | CODE-BACKED | 17 or 18 = WAITING_FOR_MARKET open order types; triggers update path. |
| 29 | @IsFatalError | TINYINT | YES | 1 | CODE-BACKED | Whether the error (if any) is fatal. |
| 30 | @TriggeringOrderCloseActionType | INT | YES | 0 | CODE-BACKED | Close action type from the triggering context. |
| 31 | @CustomerFlow | INT | YES | NULL | CODE-BACKED | Customer flow identifier for routing/audit. |
| 32 | @StopLossPercentage | decimal(16,8) | YES | NULL | CODE-BACKED | SL as a percentage of position value (alternative to absolute StopRate). |
| 33 | @TakeProfitPercentage | decimal(16,8) | YES | NULL | CODE-BACKED | TP as a percentage of position value. |
| 34 | @ParentPositionID | BIGINT | YES | 0 | CODE-BACKED | Parent position ID for copy-trade tree linkage. |
| 35 | @ClientViewRate | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Actual rate the client saw at request time. |
| 36 | @OrderCloseActionType | INT | YES | NULL | CODE-BACKED | Close action type context (carried from triggering chain). |
| 37 | @SettlementTypeID | tinyint | YES | NULL | CODE-BACKED | Settlement type for the open order. |
| 38 | @OperationType | tinyint | YES | NULL | CODE-BACKED | Operation type classification. |
| 39 | @IsComputedForBalance | BIT | YES | NULL | CODE-BACKED | Whether the amount was computed from a balance-based formula. |
| 40 | @OpenRate | DECIMAL(16,8) | YES | NULL | CODE-BACKED | The actual rate at which the order was opened/will open. |
| 41 | @ConversionRate | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Currency conversion rate applied at open time. |
| 42 | @ConversionPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Rate ID for the conversion rate used. |
| 43 | @FrozenAmount | MONEY | YES | NULL | CODE-BACKED | Amount held in reserve while order is pending execution. |
| 44 | @ClientRequestedAmount | MONEY | YES | NULL | CODE-BACKED | Original client-requested amount before engine adjustments. |
| 45 | @ClientRequestedUnits | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Original client-requested units before adjustments. |
| 46 | @RequestedSettlementTypeID | tinyint | YES | NULL | CODE-BACKED | Client's requested settlement type. |
| 47 | @RequestedOpenActionType | INT | YES | NULL | CODE-BACKED | Client's requested open action type. |
| 48 | @IsNoStopLoss | BIT | YES | NULL | CODE-BACKED | 1=Customer explicitly opted out of Stop Loss for this position. |
| 49 | @IsNoTakeProfit | BIT | YES | NULL | CODE-BACKED | 1=Customer explicitly opted out of Take Profit. |
| 50 | @LotCount | decimal(16,6) | YES | NULL | CODE-BACKED | Lot count for lot-based instruments. |
| 51 | @TriggeringOrderRate | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Rate at which the triggering order fired. |
| 52 | @TriggeringOrderRateID | BIGINT | YES | NULL | CODE-BACKED | Rate ID reference for the triggering order. |
| 53 | @AdditionalMargin | MONEY | YES | 0 | CODE-BACKED | Extra margin required beyond UnitMargin (e.g., overnight financing, special instruments). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrderForOpen | Write | INSERTed (create) or UPDATEd (WAITING_FOR_MARKET) |
| @OrderID (pre-update) | Trade.OrderForExecutionChangeLog | Write | Backup of OrderForOpen state before update |
| @OrderID | Trade.OpenExecutionPlan | Write | INSERTed from TVP; old plan DELETEd on update path |
| @OrderID (pre-update) | Trade.ExecutionPlanChangeLog | Write | Backup of OpenExecutionPlan before deletion on update path |
| @OpenExecutionPlan | Trade.OpenExecutionPlanTbl | UDT Reference | TVP type for execution plan rows |
| @DelayedOrderID | Trade.DelayedOrderForOpenStatusUpdate | EXEC (conditional) | Marks source delayed order as FILLED when @DelayedOrderID<>0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenCreateWrapper | - | EXEC | Wrapper procedure that calls this; provides simplified interface for some callers |
| Trading engine (external) | - | Direct Caller | Called directly by the core position open service on the hot path |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderForOpenCreate (procedure - natively compiled)
├── Trade.OpenExecutionPlanTbl (TVP type)
├── Trade.OrderForOpen (table)
├── Trade.OrderForExecutionChangeLog (table)
├── Trade.OpenExecutionPlan (table)
├── Trade.ExecutionPlanChangeLog (table)
└── Trade.DelayedOrderForOpenStatusUpdate (procedure - conditional)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenExecutionPlanTbl | User Defined Type | TVP parameter type |
| Trade.OrderForOpen | Table | INSERTed or UPDATEd; SELECTed for backup on update path |
| Trade.OrderForExecutionChangeLog | Table | INSERTed with pre-update state snapshot |
| Trade.OpenExecutionPlan | Table | INSERTed from TVP; DELETEd and re-inserted on update path |
| Trade.ExecutionPlanChangeLog | Table | INSERTed with pre-delete plan snapshot |
| Trade.DelayedOrderForOpenStatusUpdate | Procedure | EXECuted conditionally to FILL the delayed order |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenCreateWrapper | Procedure | Wrapper caller with simplified parameter interface |
| Trading engine (external) | External Application | Direct hot-path caller for position open requests |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Natively compiled with SCHEMABINDING. ATOMIC block with SNAPSHOT isolation - lock-free reads on hot path. No explicit BEGIN/COMMIT TRAN needed within ATOMIC block.

### 7.2 Constraints

N/A for stored procedure. THROW on order-not-found during update path. Note: unlike Trade.OrderForCloseCreate, there is no @OrderIdToReplace parameter - open orders are not replaced in the same way as close orders.

---

## 8. Sample Queries

### 8.1 Check open order status

```sql
SELECT OFO.OrderID, OFO.CID, OFO.StatusID, OFO.OrderType, OFO.InstrumentID,
       OFO.Amount, OFO.IsBuy, OFO.Leverage, OFO.StopRate, OFO.LimitRate,
       OFO.RequestOccurred, OFO.LastUpdate, OFO.ErrorCode
FROM Trade.OrderForOpen AS OFO WITH (NOLOCK)
WHERE OFO.OrderID = <OrderID>;
```

### 8.2 View execution plan for an open order

```sql
SELECT OEP.OrderID, OEP.Level, OEP.Units, OEP.Amount, OEP.CID, OEP.MirrorID,
       OEP.OpenActionType, OEP.OpenCorrelationID, OEP.ParentOpenCorrelationID
FROM Trade.OpenExecutionPlan AS OEP WITH (NOLOCK)
WHERE OEP.OrderID = <OrderID>
ORDER BY OEP.Level;
```

### 8.3 Find open orders for a customer

```sql
SELECT OrderID, StatusID, InstrumentID, Amount, AmountInUnits, IsBuy, Leverage,
       OrderType, MirrorID, RequestOccurred, LastUpdate
FROM Trade.OrderForOpen WITH (NOLOCK)
WHERE CID = <CID>
ORDER BY RequestOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

Confluence search returned a page titled "Trade.OrderForOpenCreate" (ID 13794279512) in TRAD space but the page was not accessible (404). No extractable content.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 53 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence (not accessible) + 0 Jira | Procedures: 1 SP caller (OrderForOpenCreateWrapper) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.OrderForOpenCreate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderForOpenCreate.sql*
