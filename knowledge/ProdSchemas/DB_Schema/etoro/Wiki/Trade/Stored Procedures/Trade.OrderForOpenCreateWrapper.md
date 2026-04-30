# Trade.OrderForOpenCreateWrapper

> Transactional wrapper around Trade.OrderForOpenCreate that adds two post-create side effects: closing any triggering pending order and updating admin position state, all within a single atomic transaction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID + @StatusID (execution result context) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.OrderForOpenCreate` handles the core logic of creating the DB artifacts for a successfully executed open order. This wrapper adds the transactional envelope and two critical post-creation steps that must succeed or fail together with the core creation:

1. **Pending order close**: When a position is opened as a result of a pending order being triggered (e.g. a limit order hitting its target price), the original pending order must be closed at the same time the new position is created. This wrapper enforces that atomicity.
2. **Admin position state update**: When a position is created via the admin position flow, the admin position record must be marked as "placed" once execution succeeds.

The procedure exists because these three operations (create position, close pending order, update admin state) must be atomic - either all succeed together, or all roll back. Without this wrapper, a partial failure could leave the system in an inconsistent state (e.g., a position created but its originating pending order still active).

Data flow: The calling execution service provides all order execution details via the large parameter set. OrderForOpenCreate is called first (does the heavy lifting), then conditional side-effects run based on @TriggeringOrderID and @AdminPositionID values. The entire chain commits atomically.

---

## 2. Business Logic

### 2.1 Core Open Order Creation

**What**: Passes all parameters through to Trade.OrderForOpenCreate within a transaction.

**Columns/Parameters Involved**: All parameters (pass-through)

**Rules**:
- Trade.OrderForOpenCreate is called with ALL parameters verbatim - this wrapper adds no transformation
- Any failure in OrderForOpenCreate causes the entire transaction to roll back

### 2.2 Triggering Pending Order Closure

**What**: When a position was opened by a triggered pending order, closes that pending order within the same transaction.

**Columns/Parameters Involved**: `@TriggeringOrderID`, `@TriggeringOrderType`, `@TriggeringOrderCloseActionType`, `@StatusID`, `@IsFatalError`, `@CID`

**Rules**:
- Condition: @TriggeringOrderID > 0 AND @TriggeringOrderType IN (0, 15) AND (@StatusID = 2 OR (@StatusID = 4 AND @IsFatalError = 1))
  - @TriggeringOrderType = 0: PENDING_OPEN_BY_AMOUNT
  - @TriggeringOrderType = 15: PENDING_OPEN_BY_UNITS
  - @StatusID = 2: PLACED (successful execution)
  - @StatusID = 4 with @IsFatalError = 1: fatal REJECT (execution failed beyond retry)
- Calls Trade.OrdersClose with @TriggeringOrderID and @TriggeringOrderCloseActionType
- If Trade.OrdersClose returns non-zero: RAISERROR and roll back entire transaction
- This ensures: pending order is ALWAYS closed when it triggers (whether execution succeeds or fatally fails)

**Diagram**:
```
@TriggeringOrderID > 0
AND @TriggeringOrderType IN (0=BY_AMOUNT, 15=BY_UNITS)
AND (@StatusID=2=PLACED OR (@StatusID=4=REJECT AND @IsFatalError=1))
  -> EXEC Trade.OrdersClose @TriggeringOrderID, @TriggeringOrderCloseActionType, @CID
  -> IF return <> 0: RAISERROR -> ROLLBACK
```

### 2.3 Admin Position State Transition

**What**: When a position was created via the admin open flow, marks the admin position as placed.

**Columns/Parameters Involved**: `@AdminPositionID`, `@AdminRequestID`, `@StatusID`, `@CID`

**Rules**:
- Condition: @AdminPositionID > 0 AND @StatusID = 2 (only for successful PLACED executions - not for rejects)
- Calls Trade.SetAdminPositionState with @NewState = 2 (placed)
- If SetAdminPositionState returns @res <> 1: RAISERROR and roll back

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | The order ID being executed/created. Passed through to Trade.OrderForOpenCreate. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID for the position being opened. Used in pending order close and admin state calls. |
| 3 | @StatusID | int | NO | - | CODE-BACKED | Execution result status: 2=PLACED (success), 4=REJECT. Controls conditional side-effects. |
| 4 | @InstrumentID | int | NO | - | CODE-BACKED | The instrument being traded. Passed through to OrderForOpenCreate. |
| 5 | @Amount | money | NO | - | CODE-BACKED | Investment amount. Passed through. |
| 6 | @AmountInUnits | decimal(16,6) | NO | - | CODE-BACKED | Investment in instrument units. Passed through. |
| 7 | @UnitMargin | decimal(16,6) | NO | - | CODE-BACKED | Margin per unit for the position. Passed through. |
| 8 | @IsBuy | tinyint | NO | - | CODE-BACKED | Trade direction: 1=Buy/Long, 0=Sell/Short. Passed through. |
| 9 | @Leverage | int | NO | - | CODE-BACKED | Leverage multiplier. Passed through. |
| 10 | @StopRate | decimal(16,8) | NO | - | CODE-BACKED | Stop-loss rate. Passed through. |
| 11 | @LimitRate | decimal(16,8) | NO | - | CODE-BACKED | Take-profit rate. Passed through. |
| 12 | @IsTslEnabled | tinyint | NO | - | CODE-BACKED | Trailing stop-loss enabled flag. Passed through. |
| 13 | @IsDiscounted | tinyint | NO | - | CODE-BACKED | Discount flag for commission. Passed through. |
| 14 | @RequestGuid | uniqueidentifier | NO | - | CODE-BACKED | Idempotency key for the request. Passed through. |
| 15 | @RequestOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the execution request occurred. Passed through. |
| 16 | @PriceRateID | bigint | NO | - | CODE-BACKED | Price rate ID at execution time. Passed through. |
| 17 | @ClientViewRateID | bigint | NO | - | CODE-BACKED | The price rate as seen by the client (may differ from execution rate). Passed through. |
| 18 | @OrderType | int | NO | - | CODE-BACKED | Order type classification. Passed through. |
| 19 | @AggregatedAmount | money | NO | - | CODE-BACKED | Total aggregated amount for the execution plan. Passed through. |
| 20 | @AggregatedAmountInUnits | decimal(16,6) | NO | - | CODE-BACKED | Total aggregated units. Passed through. |
| 21 | @OpenExecutionPlan | Trade.OpenExecutionPlanTbl READONLY | NO | - | CODE-BACKED | TVP containing the execution plan details (multiple execution rows). Passed through. |
| 22 | @ErrorCode | INT | YES | 0 | CODE-BACKED | Error code from execution (0 = no error). Passed through. |
| 23 | @ErrorMessage | VARCHAR(1000) | YES | NULL | CODE-BACKED | Error message from execution. Passed through. |
| 24 | @MirrorID | INT | YES | 0 | CODE-BACKED | CopyTrader mirror ID, if applicable. Passed through. |
| 25 | @DelayedOrderID | BIGINT | YES | 0 | CODE-BACKED | Delayed order ID that triggered this execution, if applicable. Passed through. |
| 26 | @OpenActionType | INT | YES | 0 | CODE-BACKED | Open action sub-type. Passed through. |
| 27 | @TriggeringOrderID | BIGINT | YES | 0 | CODE-BACKED | The pending order ID that triggered this execution. If > 0 and conditions met, that pending order is closed. |
| 28 | @TriggeringOrderType | INT | YES | 0 | CODE-BACKED | Type of the triggering order: 0=PENDING_OPEN_BY_AMOUNT, 15=PENDING_OPEN_BY_UNITS. Controls whether to close the triggering order. |
| 29 | @IsFatalError | TINYINT | YES | 1 | CODE-BACKED | Whether a rejection is fatal (non-retriable). 1=fatal - combined with StatusID=4 triggers pending order close. |
| 30 | @TriggeringOrderCloseActionType | INT | YES | 0 | CODE-BACKED | The close action type to record when closing the triggering pending order. |
| 31 | @CustomerFlow | INT | YES | NULL | CODE-BACKED | Customer flow classification. Passed through. |
| 32 | @StopLossPercentage | decimal(16,8) | YES | NULL | CODE-BACKED | SL as a percentage. Passed through. |
| 33 | @TakeProfitPercentage | decimal(16,8) | YES | NULL | CODE-BACKED | TP as a percentage. Passed through. |
| 34 | @ParentPositionID | BIGINT | YES | 0 | CODE-BACKED | Parent position for copy trades. Passed through. |
| 35 | @ClientViewRate | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Rate as seen by the client at request time. Passed through. |
| 36 | @OrderCloseActionType | INT | YES | NULL | CODE-BACKED | Close action type for the order. Passed through. |
| 37 | @SettlementTypeID | tinyint | YES | NULL | CODE-BACKED | Settlement type (Real/CFD/Crypto). Passed through. |
| 38 | @OperationType | tinyint | YES | NULL | CODE-BACKED | Operation type sub-classification. Passed through. |
| 39 | @IsComputedForBalance | BIT | YES | NULL | CODE-BACKED | Whether amount was computed for balance purposes. Passed through. |
| 40 | @AdminPositionID | BIGINT | YES | NULL | CODE-BACKED | Admin position ID for admin-created positions. If > 0 and StatusID=2: Trade.SetAdminPositionState called with NewState=2. |
| 41 | @AdminRequestID | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Admin request GUID for admin position flow. Used in Trade.SetAdminPositionState call. |
| 42 | @OpenRate | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Execution open rate. Passed through. |
| 43 | @ConversionRate | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Currency conversion rate at execution. Passed through. |
| 44 | @ConversionPriceRateID | BIGINT | YES | NULL | CODE-BACKED | ID of the conversion price rate row. Passed through. |
| 45 | @FrozenAmount | MONEY | YES | NULL | CODE-BACKED | Amount frozen/reserved before execution. Passed through. |
| 46 | @ClientRequestedAmount | MONEY | YES | NULL | CODE-BACKED | Amount originally requested by the client. Passed through. |
| 47 | @ClientRequestedUnits | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Units originally requested by the client. Passed through. |
| 48 | @RequestedSettlementTypeID | tinyint | YES | NULL | CODE-BACKED | Settlement type as requested (may differ from actual). Passed through. |
| 49 | @RequestedOpenActionType | INT | YES | NULL | CODE-BACKED | Open action type as requested. Passed through. |
| 50 | @IsNoStopLoss | BIT | YES | NULL | CODE-BACKED | Position has no stop-loss (user opted out). Passed through. |
| 51 | @IsNoTakeProfit | BIT | YES | NULL | CODE-BACKED | Position has no take-profit (user opted out). Passed through. |
| 52 | @LotCount | decimal(16,6) | YES | NULL | CODE-BACKED | Lot count for the position. Passed through. |
| 53 | @TriggeringOrderRate | DECIMAL(16,8) | YES | NULL | CODE-BACKED | The rate at which the triggering pending order fired. Passed through. |
| 54 | @TriggeringOrderRateID | BIGINT | YES | NULL | CODE-BACKED | ID of the rate row for the triggering order. Passed through. |
| 55 | @AdditionalMargin | MONEY | YES | 0 | CODE-BACKED | Additional margin required beyond the standard amount. Passed through. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Trade.OrderForOpenCreate | EXEC (CALL) | Core creation logic - all parameters passed through |
| @TriggeringOrderID | Trade.OrdersClose | EXEC (CALL) | Closes the triggering pending order (conditional) |
| @AdminPositionID | Trade.SetAdminPositionState | EXEC (CALL) | Marks admin position as placed (conditional) |

### 5.2 Referenced By (other objects point to this)

The Confluence folder has a dedicated page for Trade.OrderForOpenCreateWrapper (page ID 13795819594).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderForOpenCreateWrapper (procedure)
+-- Trade.OrderForOpenCreate (procedure) [EXEC - core position creation]
+-- Trade.OrdersClose (procedure) [EXEC - pending order closure, conditional]
+-- Trade.SetAdminPositionState (procedure) [EXEC - admin state update, conditional]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenCreate | Stored Procedure | Primary call - performs the actual position and order creation |
| Trade.OpenExecutionPlanTbl | User Defined Type | TVP parameter type for @OpenExecutionPlan |
| Trade.OrdersClose | Stored Procedure | Closes the triggering pending order when conditions met |
| Trade.SetAdminPositionState | Stored Procedure | Updates admin position record to state 2 (placed) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Confluence: Trade.OrderForOpenCreateWrapper | External | Documented in the TRAD DB Confluence space (page 13795819594) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ROLLBACK on any failure | Atomicity | BEGIN TRAN/ROLLBACK ensures position creation, pending order close, and admin state update are all atomic |
| TriggeringOrderType filter | Business scope | Only PENDING_OPEN_BY_AMOUNT (0) and PENDING_OPEN_BY_UNITS (15) trigger the pending order close - other order types do not |
| StatusID=2 for admin state | Business scope | Admin position state is only updated on successful execution (PLACED), not on rejects |

---

## 8. Sample Queries

### 8.1 Check a pending order before and after being closed by wrapper
```sql
-- Before: order should exist
SELECT OrderID, CID, InstrumentID, OccurredTime
FROM Trade.Orders WITH (NOLOCK)
WHERE OrderID = @TriggeringOrderID;

-- After wrapper runs: order should be in History
SELECT OrderID, CID, ActionTypeID, CloseOcurred
FROM History.Orders WITH (NOLOCK)
WHERE OrderID = @TriggeringOrderID
ORDER BY CloseOcurred DESC;
```

### 8.2 Check admin position state after wrapper execution
```sql
SELECT
    AdminPositionID,
    CID,
    State,
    AdminRequestID
FROM Trade.AdminPositionLog WITH (NOLOCK)  -- or relevant admin position table
WHERE AdminPositionID = @AdminPositionID
ORDER BY 1 DESC;
```

### 8.3 Check execution plan for a wrapper call
```sql
SELECT
    oep.OrderID,
    oep.CID,
    oep.OpenCorrelationID,
    oep.MirrorID,
    oep.Units,
    eo.PositionID
FROM Trade.OpenExecutionPlan oep WITH (NOLOCK)
LEFT JOIN Trade.ExecutedOpenOrders eo WITH (NOLOCK)
    ON oep.OrderID = eo.OrderID AND oep.OpenCorrelationID = eo.OpenCorrelationID
WHERE oep.OrderID = 999888777;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.OrderForOpenCreateWrapper](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13795819594) | Confluence | Dedicated documentation page exists in TRAD/DB folder for this procedure |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 55 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed (OrderForOpenCreate, OrdersClose, SetAdminPositionState) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderForOpenCreateWrapper | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderForOpenCreateWrapper.sql*
