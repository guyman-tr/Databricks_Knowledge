# Trade.OrderForCloseCreate

> Natively compiled, hot-path SP that either inserts a new close order into Trade.OrderForClose or updates an existing WAITING_FOR_MARKET order (OrderType 19/20), then always writes the execution plan, optionally marks a linked delayed order as FILLED, and optionally cancels a replaced order.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID + @TriggeringOrderType (determines insert vs update path) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrderForCloseCreate is the core write operation for position close orders in eToro's trading engine. When a customer or system requests a position close (SL, TP, manual, copy-trade), the trading engine calls this procedure to persist the order request.

The procedure is natively compiled (WITH NATIVE_COMPILATION, SCHEMABINDING) and runs in SNAPSHOT isolation for maximum throughput on the hot path. It handles two flows:

**Regular creation**: a brand-new close order is INSERTed into Trade.OrderForClose with the full set of order attributes - status, instrument, units, client view rate, triggering context, settlement type, and close action type.

**WAITING_FOR_MARKET update** (TriggeringOrderType=19 or 20): an existing order was placed in a market-close queue and is now being activated. The current state is backed up to Trade.OrderForExecutionChangeLog, the order is UPDATEd in place, and the existing execution plan is backed up to Trade.ExecutionPlanChangeLog and deleted before the new plan is inserted.

After either flow, the execution plan rows from @CloseExecutionPlan TVP are inserted into Trade.CloseExecutionPlan. If a @DelayedOrderID was associated, it is marked FILLED (StatusID=2). If @OrderIdToReplace is set, the replaced order is CANCELED (StatusID=7, OrderCloseActionType=10).

---

## 2. Business Logic

### 2.1 WAITING_FOR_MARKET Update Path

**What**: Handles re-activation of an order that was waiting for market open (OrderType 19 or 20).

**Columns/Parameters Involved**: `@TriggeringOrderID`, `@TriggeringOrderType`, `Trade.OrderForClose`, `Trade.OrderForExecutionChangeLog`, `Trade.CloseExecutionPlan`, `Trade.ExecutionPlanChangeLog`

**Rules**:
- Condition: @TriggeringOrderID > 0 AND @TriggeringOrderType IN (19, 20).
- Step 1: SELECT INTO Trade.OrderForExecutionChangeLog from Trade.OrderForClose WHERE OrderID=@OrderID (backs up pre-update state).
- Step 2: UPDATE Trade.OrderForClose: StatusID, RequestGuid, RequestOccurred, LastUpdate=GETUTCDATE(), ClientViewRateID, ClientViewRate, TriggeringOrderID, TriggeringOrderType, ErrorCode, ErrorMessage, AggregatedAmountInUnits, OrderCloseActionType, PriceRateID, CloseRate, TriggeringOrderRate, TriggeringOrderRateID.
  - If @@ROWCOUNT=0: THROW 50000 'Update Trade.OrderForClose failed. Order not found. Order may already be in terminal state.'
- Step 3: SELECT INTO Trade.ExecutionPlanChangeLog from Trade.CloseExecutionPlan WHERE OrderID=@OrderID (backs up existing plan).
- Step 4: DELETE FROM Trade.CloseExecutionPlan WHERE OrderID=@OrderID (removes old plan before inserting new one).

### 2.2 Regular Creation Path

**What**: Inserts a new close order when @TriggeringOrderType is not 19 or 20.

**Columns/Parameters Involved**: All @* parameters -> `Trade.OrderForClose` columns

**Rules**:
- INSERT INTO Trade.OrderForClose with all parameters mapped directly.
- LastUpdate=GETUTCDATE() is set automatically.
- OrderType from @OrderType parameter.
- RequiresHierarchicalOperation: BIT flag for tree-structure close operations.

### 2.3 Execution Plan Write (Always)

**What**: Inserts the close execution plan from the TVP for both code paths.

**Columns/Parameters Involved**: `@CloseExecutionPlan Trade.CloseExecutionPlanTbl`, `Trade.CloseExecutionPlan`

**Rules**:
- INSERT INTO Trade.CloseExecutionPlan(OrderID, PositionID, Level, Units, CID, CloseActionType, IsHedged) SELECT @OrderID, ... FROM @CloseExecutionPlan.
- Always executed regardless of create vs update path.
- Plan rows define which positions to close, at what level in the copy-trade tree, with what lot count.

### 2.4 Optional: Delayed Order and Order Replacement

**What**: Side effects for delayed order lifecycle and order replacement.

**Columns/Parameters Involved**: `@DelayedOrderID`, `@OrderIdToReplace`, `Trade.DelayedOrderForCloseStatusUpdate`, `Trade.OrderForCloseUpdate`

**Rules**:
- If @DelayedOrderID <> 0: EXEC Trade.DelayedOrderForCloseStatusUpdate @OrderID=@DelayedOrderID, @StatusID=2 (FILLED) - marks the source delayed order as consumed.
- If @OrderIdToReplace > 0: EXEC Trade.OrderForCloseUpdate @OrderID=@OrderIdToReplace, @StatusID=7 (CANCELED), @OrderCloseActionType=10 (Cancellation due to replacement with full order).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | Close order identifier. On create: new OrderID to insert. On WAITING_FOR_MARKET update: existing OrderID to update. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID owning the close order. Written to Trade.OrderForClose.CID. |
| 3 | @StatusID | int | NO | - | CODE-BACKED | Initial/updated order status. Written to Trade.OrderForClose.StatusID. |
| 4 | @UnitsToDeduct | decimal(16,6) | NO | - | CODE-BACKED | Number of units to close from the position. Written to Trade.OrderForClose.UnitsToDeduct. |
| 5 | @RequestGuid | uniqueidentifier | NO | - | CODE-BACKED | Client-provided GUID for idempotency. Written to Trade.OrderForClose.RequestGuid. |
| 6 | @RequestOccurred | datetime | NO | - | CODE-BACKED | When the close request was made by the client. Written to Trade.OrderForClose.RequestOccurred. |
| 7 | @ClientViewRateID | bigint | NO | - | CODE-BACKED | Reference to the price rate the client saw when initiating the close. |
| 8 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument being closed. |
| 9 | @OrderType | int | NO | - | CODE-BACKED | Type of close order (e.g., SL, TP, manual, market-close, etc.). |
| 10 | @CloseExecutionPlan | Trade.CloseExecutionPlanTbl (READONLY TVP) | NO | - | CODE-BACKED | Plan rows: (PositionID, Level, Units, CID, CloseActionType, IsHedged) defining exactly which positions to close at what hierarchy level. |
| 11 | @ErrorCode | INT | YES | 0 | CODE-BACKED | Error code if order was created in error state. Written to Trade.OrderForClose.ErrorCode. |
| 12 | @ErrorMessage | VARCHAR(1000) | YES | NULL | CODE-BACKED | Error message if order was created in error state. |
| 13 | @AggregatedAmountInUnits | DECIMAL(16,6) | YES | 0 | CODE-BACKED | Aggregated units across a copy-trade tree close. |
| 14 | @DelayedOrderID | BIGINT | YES | 0 | CODE-BACKED | If non-zero: the originating delayed order is marked FILLED (StatusID=2) after this close order is created. |
| 15 | @TriggeringOrderID | BIGINT | YES | 0 | CODE-BACKED | ID of the order that triggered this close (e.g., SL order, TP order). >0 combined with TriggeringOrderType 19/20 activates WAITING_FOR_MARKET update path. |
| 16 | @TriggeringOrderType | INT | YES | 0 | CODE-BACKED | Type of triggering order. 19 or 20 = WAITING_FOR_MARKET order types that trigger the update path instead of insert. |
| 17 | @IsFatalError | TINYINT | YES | 1 | CODE-BACKED | Whether the error (if any) is fatal. Stored in order record. |
| 18 | @TriggeringOrderCloseActionType | INT | YES | 0 | CODE-BACKED | Close action type from the triggering order context. |
| 19 | @CustomerFlow | INT | YES | NULL | CODE-BACKED | Customer flow identifier for routing/audit. |
| 20 | @MirrorCloseActionType | INT | YES | NULL | CODE-BACKED | If closing a copy-trade mirror position, the type of mirror close action. |
| 21 | @ClientViewRate | DECIMAL(16,6) | YES | NULL | CODE-BACKED | The actual rate the client saw at request time (vs RateID reference). |
| 22 | @OrderCloseActionType | INT | YES | NULL | CODE-BACKED | High-level reason for closing (e.g., SL, TP, manual, expiry). |
| 23 | @OrderIdToReplace | BIGINT | YES | 0 | CODE-BACKED | If >0: an existing close order to cancel (CANCELED, OrderCloseActionType=10) because this order replaces it. |
| 24 | @SettlementTypeID | tinyint | YES | NULL | CODE-BACKED | Settlement type for the close order. |
| 25 | @OperationType | tinyint | YES | NULL | CODE-BACKED | Operation type classification for the close. |
| 26 | @LotsToDeduct | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Lot count to deduct (complementary to @UnitsToDeduct for lot-based instruments). |
| 27 | @PriceRateID | BIGINT | YES | 0 | CODE-BACKED | Reference to the execution price rate used. |
| 28 | @CloseRate | DECIMAL(16,8) | YES | NULL | CODE-BACKED | The actual close rate used for execution. |
| 29 | @TriggeringOrderRate | DECIMAL(16,8) | YES | NULL | CODE-BACKED | The rate at which the triggering SL/TP order fired. |
| 30 | @TriggeringOrderRateID | BIGINT | YES | NULL | CODE-BACKED | Rate ID reference for the triggering order rate. |
| 31 | @RequiresHierarchicalOperation | BIT | YES | NULL | CODE-BACKED | Whether the close requires propagating through a copy-trade position hierarchy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrderForClose | Write | INSERTed (create) or UPDATEd (WAITING_FOR_MARKET) |
| @OrderID (pre-update) | Trade.OrderForExecutionChangeLog | Write | Backup of OrderForClose state before update |
| @OrderID | Trade.CloseExecutionPlan | Write | INSERTed from @CloseExecutionPlan TVP; old plan DELETEd on update path |
| @OrderID (pre-update) | Trade.ExecutionPlanChangeLog | Write | Backup of CloseExecutionPlan before deletion on update path |
| @CloseExecutionPlan | Trade.CloseExecutionPlanTbl | UDT Reference | TVP type for execution plan rows |
| @DelayedOrderID | Trade.DelayedOrderForCloseStatusUpdate | EXEC (conditional) | Marks source delayed order as FILLED when @DelayedOrderID<>0 |
| @OrderIdToReplace | Trade.OrderForCloseUpdate | EXEC (conditional) | Cancels replaced order when @OrderIdToReplace>0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading engine (external) | - | Caller | Called by the core position close service on the hot path; no SP callers found in Trade schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderForCloseCreate (procedure - natively compiled)
├── Trade.CloseExecutionPlanTbl (TVP type)
├── Trade.OrderForClose (table)
├── Trade.OrderForExecutionChangeLog (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.ExecutionPlanChangeLog (table)
├── Trade.DelayedOrderForCloseStatusUpdate (procedure - conditional)
└── Trade.OrderForCloseUpdate (procedure - conditional)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseExecutionPlanTbl | User Defined Type | TVP parameter type |
| Trade.OrderForClose | Table | INSERTed or UPDATEd depending on path; SELECTed for backup |
| Trade.OrderForExecutionChangeLog | Table | INSERTed with pre-update state snapshot |
| Trade.CloseExecutionPlan | Table | INSERTed from TVP; DELETEd and re-inserted on update path |
| Trade.ExecutionPlanChangeLog | Table | INSERTed with pre-delete plan snapshot |
| Trade.DelayedOrderForCloseStatusUpdate | Procedure | EXECuted conditionally to FILL the delayed order |
| Trade.OrderForCloseUpdate | Procedure | EXECuted conditionally to CANCEL the replaced order |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No SP dependents found) | - | Called by the external trading engine service (hot path). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Natively compiled with SCHEMABINDING. Runs in ATOMIC block with SNAPSHOT isolation level - provides lock-free reads in the hot path.

### 7.2 Constraints

N/A for stored procedure. ATOMIC block: automatically atomic - no explicit BEGIN/COMMIT TRAN needed. THROW on order-not-found during update path (message: 'Update Trade.OrderForClose failed. Order not found. Order may already be in terminal state.'). Native compilation eliminates interpreted T-SQL overhead; this is a latency-critical procedure.

---

## 8. Sample Queries

### 8.1 Check close order status

```sql
SELECT OFC.OrderID, OFC.CID, OFC.StatusID, OFC.OrderType, OFC.OrderCloseActionType,
       OFC.RequestOccurred, OFC.LastUpdate, OFC.ErrorCode, OFC.ErrorMessage
FROM Trade.OrderForClose AS OFC WITH (NOLOCK)
WHERE OFC.OrderID = <OrderID>;
```

### 8.2 View execution plan for a close order

```sql
SELECT CEP.OrderID, CEP.PositionID, CEP.Level, CEP.Units, CEP.CID,
       CEP.CloseActionType, CEP.IsHedged
FROM Trade.CloseExecutionPlan AS CEP WITH (NOLOCK)
WHERE CEP.OrderID = <OrderID>
ORDER BY CEP.Level;
```

### 8.3 View execution change log for a close order

```sql
SELECT ECL.ChangeOccurred, ECL.OrderID, ECL.OrderType, ECL.StatusID,
       ECL.RequestGuid, ECL.ClientViewRate
FROM Trade.OrderForExecutionChangeLog AS ECL WITH (NOLOCK)
WHERE ECL.OrderID = <OrderID>
ORDER BY ECL.ChangeOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

Confluence search returned a page titled "Trade.OrderForCloseCreate" (ID 13796114484) in TRAD space but the page was not accessible (404). No extractable content.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence (not accessible) + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.OrderForCloseCreate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderForCloseCreate.sql*
