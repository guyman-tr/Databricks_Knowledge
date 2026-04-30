# Trade.PositionClose

> The core stored procedure for closing trading positions - handles full and partial closes, updates position status to Closed, snapshots to history, adjusts customer balance, and triggers async post-close notifications.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (BIGINT) - position being closed |
| **Partition** | Partition-aware: WHERE @PositionID%50 = PartitionCol |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionClose is the single authoritative procedure for closing a trading position. Every close event - whether triggered by the customer manually, by a stop-loss/take-profit order, by a mirror/copy-trade liquidation, or by a redeem operation - flows through this procedure. It is the transactional boundary: when this procedure commits successfully, the position is definitively closed and the customer's balance is updated.

The procedure exists because position closing is a multi-table atomic transaction. A close requires: (1) updating Trade.PositionTbl to StatusID=2, (2) inserting a history snapshot to History.PositionClosePartial (partial) or recording via OutputCustomer MOT type (full), (3) crediting/debiting the customer's balance via Customer.SetBalanceClosePosition, (4) optionally charging close fees and taxes, (5) optionally updating associated exit orders. If any step fails, the transaction rolls back and the failure is logged to History.PositionFailWrite for investigation.

The procedure supports both full and partial closes. A partial close (when @PartialCloseRatio < 1) splits the position: the closed portion is written to History.PositionClosePartial and the original position's units/amount are reduced in place. A new PositionID (@PartialClosePositionID) is generated for the closed portion. A full close (default) simply sets StatusID=2 on the Trade.PositionTbl record. After the transaction commits, an async record is inserted via Trade.InsertAsyncRecord (ActionID=1) to trigger post-close notifications, equity recalculations, and BI events.

---

## 2. Business Logic

### 2.1 Full Close vs Partial Close Flow

**What**: Two execution paths based on whether the entire position or only a fraction is being closed.

**Columns/Parameters Involved**: `@PartialCloseRatio`, `@PartialClosedUnits`, `@OpenUnits`, `@PartialClosedPositionAmount`, `@OpenPositionAmount`, `@PartialClosePositionID`

**Rules**:
- @PartialCloseRatio = NULL or >= 1: FULL CLOSE - UPDATE Trade.PositionTbl SET StatusID=2. Position is permanently closed.
- @PartialCloseRatio < 1: PARTIAL CLOSE - Trade.PositionTbl is updated to reduce AmountInUnitsDecimal, Amount, LotCountDecimal to @OpenUnits/@OpenPositionAmount. The closed portion is INSERT-ed into History.PositionClosePartial as a snapshot with a new PositionID.
- All 6 partial close parameters (@PartialClosedUnits, @PartialClosedPositionAmount, @OpenUnits, @OpenPositionAmount, @OpenUnitsBaseValueInCents, @PartialClosedUnitsBaseValueInCents) must be non-NULL for partial close or the procedure raises an error.
- @IsPartial local variable controls which branch executes.
- EndOfWeekFee is split proportionally: closed portion gets `(1-@PartialCloseRatio) * EndOfWeekFee`, remaining position keeps the rest.

**Diagram**:
```
EXEC Trade.PositionClose
     |
     +-- @PartialCloseRatio < 1 (PARTIAL CLOSE)
     |        |
     |        +--> EXEC Internal.GetPositionID_Bigint -> @PartialClosePositionID
     |        +--> UPDATE Trade.PositionTbl (reduce AmountInUnitsDecimal, Amount, LotCount)
     |        +--> INSERT History.PositionClosePartial (closed portion snapshot)
     |        +--> Customer.SetBalanceClosePosition (credit closed portion P&L)
     |
     +-- @PartialCloseRatio = NULL or >= 1 (FULL CLOSE)
              |
              +--> UPDATE Trade.PositionTbl SET StatusID=2 (retry up to 3x)
              +--> Customer.SetBalanceClosePosition (credit full P&L + amount)
              +--> INSERT INTO Trade.InsertAsyncRecord (ActionID=1, async notifications)
```

### 2.2 Unit / Cents Convention

**What**: Several monetary parameters are passed in CENTS by the application but stored in dollars in the database.

**Columns/Parameters Involved**: `@NetProfit`, `@CommissionOnClose`, `@FullCommissionOnClose`

**Rules**:
- @NetProfit: passed in CENTS from the application, stored as `ROUND(@NetProfit/100, 2)` in PositionTbl.NetProfit and History tables.
- @CommissionOnClose: passed in CENTS, stored as `ROUND(@CommissionOnClose/100, 2)`.
- @FullCommissionOnClose: divided by 100 at the start of the procedure (`SET @FullCommissionOnClose = ISNULL(@FullCommissionOnClose,0) / 100`).
- Customer balance is computed as `@NetProfit + Amount * 100` (i.e. amounts added back together in cents before calling SetBalanceClosePosition).
- Source: DDL comments say `-- passed and calculated in cents`; confirmed by app code (ExecutionPositionRepository).

### 2.3 ActionType - Close Reason Classification

**What**: @ActionType classifies WHY the position was closed, driving redeem status logic and async notification content.

**Columns/Parameters Involved**: `@ActionType`, `@RedeemID`, `@RedeemReasonID`

**Rules**:
- @ActionType = 19: Position closed BY a redeem operation. Sets RedeemStatus = 6 if the position was in a redeemed state (RedeemStatus > 0).
- @ActionType != 19 AND position has RedeemStatus > 0: Position was in redeem but closed by SL/TP/manual. Sets RedeemStatus = 20 (redeemed position closed non-redeem).
- Other @ActionType values correspond to close reasons (manual, stop-loss, take-profit, etc.) - see Dictionary.ClosePositionActionType.
- @ActionType is written as `ActionType` in both Trade.PositionTbl (full close) and History.PositionClosePartial.

### 2.4 Exit Order Processing (SL/TP/Limit Close)

**What**: When closing via a stop-loss or take-profit order, additional order tables must be updated.

**Columns/Parameters Involved**: `@ExitOrderID`, `@ExitOrderType`, `@IsPrePostFlow`, `@OrderForCloseStatusID`

**Rules**:
- If @ExitOrderID is non-NULL and @ExitOrderType IN (19, 20) and @IsPrePostFlow = 1: executes full exit order lifecycle.
- Verifies order ownership: SELECT CID FROM Trade.OrderForClose WHERE OrderID = @ExitOrderID must match position CID.
- EXEC Trade.OrderForCloseUpdate to mark the order as executed.
- INSERT Trade.OrderExecutionData with execution details (rate, time, type).
- INSERT Trade.ExecutedCloseOrders linking order to position.
- If @Answer != 0 from OrderForCloseUpdate, raises error.

### 2.5 Retry Mechanism for SQL Server Bug

**What**: Full-close UPDATE has a built-in retry loop for a known SQL Server update bug.

**Columns/Parameters Involved**: `@PositionID`, StatusID = 1 filter

**Rules**:
- UPDATE Trade.PositionTbl WHERE StatusID=1 may silently affect 0 rows due to a known SQL Server bug (index page split under concurrent load).
- Retry logic: loops up to 3 times, waits 2ms between retries.
- Before retrying, checks if the position EXISTS with StatusID=1 - if it no longer exists (was already closed), breaks the loop cleanly.
- If 3 retries exhausted and position still exists with StatusID=1 but UPDATE still returns 0 rows: raises error "Number of Retries Maxed Out".

### 2.6 Error Handling and Failure Logging

**What**: All failures are logged to History.PositionFailWrite before propagating.

**Columns/Parameters Involved**: `@PositionID`, `@ActionType`, FailTypeID

**Rules**:
- Two TRY/CATCH blocks: first wraps parameter validation + partial/full close + balance update; second wraps async record insertion.
- Any exception: INSERT into History.PositionFailWrite with FailTypeID=2 (close request), full rate data, session ID, and error message.
- Error 60004: "No Open Position to close was found" - position was already closed or never existed. Not retried.
- Error 60115: position not found at second insert/select attempt (position existed but race condition). Logged and re-raised.
- AdditionalParam 'DB_Direct' marks records written by this SP directly (vs other sources).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | VERIFIED | Position to close. Used with partition filter: @PositionID%50 = PartitionCol. |
| 2 | @EndForexRate | dtPrice | NO | - | VERIFIED | Close execution rate (the actual execution price). Written to PositionTbl.EndForexRate. Per Confluence: "Close execution rate". |
| 3 | @NetProfit | MONEY | NO | - | VERIFIED | Calculated P&L in CENTS. Stored as dollars (divided by 100 in SP). Computed by FlowCalculationApi in the application before calling this SP. |
| 4 | @EndDateTime | DATETIME | NO | - | VERIFIED | Close execution timestamp. Written to PositionTbl.EndDateTime. Per Confluence: "Close execution time". |
| 5 | @CommissionOnClose | MONEY | NO | - | VERIFIED | Spread or commission charged at close, in CENTS. Stored as dollars (divided by 100). |
| 6 | @EndForexPriceRateID | BIGINT | NO | - | VERIFIED | Price rate record ID for the close rate. Written to PositionTbl.EndForexPriceRateID. Per Confluence: "Close price rate ID". |
| 7 | @ActionType | INT | YES | 0 | VERIFIED | Close reason: 19=Redeem close, others=Manual/SL/TP/etc. Drives RedeemStatus logic. Written to PositionTbl.ActionType. |
| 8 | @LastOpPriceRate | dtPrice | YES | NULL | CODE-BACKED | Last operation price rate at close. Auto-fetched from Trade.FnGetCurrentClosingRate if NULL. |
| 9 | @LastOpPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Rate record ID for LastOpPriceRate. Auto-fetched if NULL. |
| 10 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Last operation conversion rate (currency pair). Auto-fetched if NULL. |
| 11 | @LastOpConversionRateID | BIGINT | YES | NULL | CODE-BACKED | Rate record ID for LastOpConversionRate. |
| 12 | @CloseMarketPriceRateID | BIGINT | YES | 0 | CODE-BACKED | Market price rate ID at close (vs execution rate). Used for EndMarketPriceRateID. 0 = use CurrencyPrice table rate. |
| 13 | @EndExecutionID | BIGINT | YES | 0 | CODE-BACKED | Execution engine ID for this close operation. Written to PositionTbl.EndExecutionID. |
| 14 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Trading session identifier. Written to history failure log if close fails. |
| 15 | @ExitOrderID | INT | YES | NULL | VERIFIED | Exit order (SL/TP/limit) that triggered this close. If provided with @ExitOrderType IN (19,20): triggers order update + execution data insert. |
| 16 | @RequestCloseOccurred | DATETIME | YES | NULL | CODE-BACKED | Timestamp when the close REQUEST was received (vs execution time). Used for audit trail in PositionTbl and history. |
| 17 | @PositionStopLoss | dtPrice | YES | NULL | CODE-BACKED | Stop loss rate at close time. Used as StopRate in partial close history; falls back to PositionTbl.StopRate if NULL. |
| 18 | @FullCommissionOnClose | MONEY | YES | NULL | CODE-BACKED | Full (non-spread) commission on close, in CENTS. Divided by 100 at SP start. Written to PositionTbl.FullCommissionOnClose. |
| 19 | @RedeemReasonID | INT | YES | NULL | CODE-BACKED | Reason code for redeem close. If position has RedeemStatus=20, auto-overridden to 18. Passed in async params for post-close processing. |
| 20 | @RedeemID | INT | YES | NULL | CODE-BACKED | Redeem operation identifier. Written to PositionTbl.RedeemID when closing a redeemed position. |
| 21 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency key from client. Logged to History.PositionFailWrite on failure. |
| 22 | @PartialClosedUnits | DECIMAL(16,6) | YES | NULL | VERIFIED | Units being closed in this partial close. Required when @PartialCloseRatio < 1. |
| 23 | @OpenUnits | DECIMAL(16,6) | YES | NULL | VERIFIED | Units remaining in position after partial close. Required when @PartialCloseRatio < 1. SET to Trade.PositionTbl.AmountInUnitsDecimal. |
| 24 | @PartialClosedPositionAmount | MONEY | YES | NULL | VERIFIED | Dollar amount of the closed portion. Required when @PartialCloseRatio < 1. |
| 25 | @OpenPositionAmount | MONEY | YES | NULL | VERIFIED | Dollar amount remaining in position after partial close. Required when @PartialCloseRatio < 1. |
| 26 | @PartialCloseRatio | DECIMAL(16,15) | YES | NULL | VERIFIED | Fraction of position being closed: <1 = partial, NULL or >=1 = full close. Triggers the partial close branch. |
| 27 | @OpenUnitsBaseValueInCents | INT | YES | NULL | CODE-BACKED | Open portion's base value in cents after partial close. Required when @PartialCloseRatio < 1. |
| 28 | @PartialClosedUnitsBaseValueInCents | INT | YES | NULL | CODE-BACKED | Closed portion's base value in cents. Required when @PartialCloseRatio < 1. |
| 29 | @ClientViewRateID | BIGINT | YES | NULL | CODE-BACKED | Rate ID used for client-visible price (may differ from execution rate). Logged on failure. |
| 30 | @ClientViewRate | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Rate shown to client. Logged on failure for discrepancy investigation. |
| 31 | @ClientRateForCalcID | BIGINT | YES | NULL | CODE-BACKED | Rate ID used in client-side P&L calculation. Logged on failure. |
| 32 | @ClientRateForCalc | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Rate used in client-side P&L calculation. Logged on failure. |
| 33 | @ExecutedWithoutSettings | BIT | YES | 0 | CODE-BACKED | 1 = execution proceeded despite settings failure (emergency mode). Passed to async record for downstream handling. |
| 34 | @IsPrePostFlow | BIT | YES | 0 | CODE-BACKED | 1 = called from the standard pre/post execution flow (trading engine). 0 = direct/admin call. Controls whether exit order update logic runs. |
| 35 | @OrderForCloseStatusID | INT | YES | 0 | CODE-BACKED | Target status to set on the exit order after close. Passed to Trade.OrderForCloseUpdate. |
| 36 | @ExitOrderType | INT | YES | NULL | CODE-BACKED | Type of exit order (19/20 = SL/TP types). Added in TRADEX-1704. Controls whether exit order path executes. |
| 37 | @OrderExecutionTime | DATETIME | YES | NULL | CODE-BACKED | Actual execution timestamp from order engine. Written to Trade.OrderExecutionData. |
| 38 | @ExecutionRateDiscounted | dtPrice | YES | NULL | CODE-BACKED | Execution rate after discount. Written to Trade.OrderExecutionData. |
| 39 | @ExecutionRateSpreaded | dtPrice | YES | NULL | CODE-BACKED | Execution rate including spread. Written to Trade.OrderExecutionData. |
| 40 | @ExecutionRateID | BIGINT | YES | NULL | CODE-BACKED | Rate record ID for the execution rate. Written to Trade.OrderExecutionData. |
| 41 | @CloseMarketPriceRate | dtPrice | YES | 0 | CODE-BACKED | Explicit market price at close. If 0, uses Trade.CurrencyPrice Bid/Ask based on IsBuy. |
| 42 | @CloseTotalTaxes | MONEY | YES | 0 | CODE-BACKED | Total taxes charged at close. If non-zero: EXEC Customer.SetBalanceClameFee for tax credit. Written to PositionTbl.CloseTotalTaxes. |
| 43 | @CloseTotalFees | MONEY | YES | 0 | CODE-BACKED | Total fees charged at close (e.g., overnight fees). If non-zero: EXEC Customer.SetBalanceClameFee for fee credit. Written to PositionTbl.CloseTotalFees. |
| 44 | @CloseMarketSpread | MONEY | YES | NULL | CODE-BACKED | Market spread at close. Written to PositionTbl.CloseMarketSpread. |
| 45 | @CloseEtoroPrice | dtPrice | YES | NULL | CODE-BACKED | eToro internal pricing reference at close. Written to PositionTbl.CloseEtoroPrice. |
| 46 | @CloseMarkup | MONEY | YES | NULL | CODE-BACKED | Markup component of close spread. Written to PositionTbl.CloseMarkup. |
| 47 | @PartialClosedLots | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Number of lots in the closed portion. Used to update LotCountDecimal in partial close. |
| 48 | @IsGuaranteedSL | BIT | YES | NULL | CODE-BACKED | 1 = stop-loss is guaranteed. Passed to Trade.OrderForCloseUpdate for guaranteed SL processing. |
| 49 | @SnapshotTimestamp | DATETIME | YES | NULL | CODE-BACKED | Snapshot timestamp for rate consistency validation. Logged to PositionFailWrite on error. |
| 50 | @PriceType | INT | YES | NULL | CODE-BACKED | Price type indicator. Logged to PositionFailWrite on error. |

**Output Parameters:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 51 | @BonusChange | MONEY | YES | VERIFIED | Bonus balance adjustment resulting from this close. Returned from Customer.SetBalanceClosePosition. Per Confluence: "Bonus adjustment". |
| 52 | @PartialClosePositionID | BIGINT | YES | VERIFIED | New PositionID generated for the closed portion in a partial close. NULL for full close. Per Confluence: "New position ID for partial close remainder". |
| 53 | @HedgeServerID | INT | YES | VERIFIED | HedgeServerID of the closed position (may have been re-routed). Returned from PositionTbl so caller has updated hedge context. Per Confluence: "Position's hedge server". |
| 54 | @OccurredDBTime | DATETIME | YES | VERIFIED | DB server timestamp when the close transaction committed. Used by caller for event timestamping. Per Confluence: "DB operation timestamp". |
| 55 | @SettlementTypeID | INT | YES | VERIFIED | Settlement type of the closed position (read from PositionTbl). Returned for downstream P&L calculation routing. Per Confluence: "Settlement type". |
| 56 | @PositionRatio | DECIMAL(7,6) | YES | VERIFIED | Position's copy-trade ratio in its tree (read from PositionTbl). Returned for proportional allocation. Per Confluence: "Position ratio in tree". |
| 57 | @UnitMargin | DECIMAL(16,8) | YES | VERIFIED | Unit margin of the closed position (read from PositionTbl). Returned for margin recalculation. Per Confluence: "Unit margin". |
| 58 | @InitDateTime | DATETIME | YES | VERIFIED | Original open timestamp of the closed position (read from PositionTbl.InitDateTime). Per Confluence: "Position open time". |
| 59 | @InitRateID | BIGINT | YES | VERIFIED | Original open rate ID (read from PositionTbl.InitForexPriceRateID). Per Confluence: "Open rate ID". |
| 60 | @MirrorID | INT | YES | VERIFIED | MirrorID of the closed position. Used by caller for copy-trade tree close propagation. Per Confluence: "Mirror relationship ID". |
| 61 | @IsMirrorActive | BIT | YES | VERIFIED | Whether the position's mirror is still active after this close. Read from Trade.Mirror. Per Confluence: "Is mirror active". |
| 62 | @CreditIDClosePosition | BIGINT | YES | VERIFIED | Credit record ID generated by Customer.SetBalanceClosePosition for the P&L credit. Per Confluence: "Credit ID for close". |
| 63 | @CreditIDCloseTotalFees | BIGINT | YES | VERIFIED | Credit record ID for the close fees deduction (NULL if @CloseTotalFees=0). Per Confluence: "Credit ID for fees". |
| 64 | @CreditIDCloseTotalTaxes | BIGINT | YES | VERIFIED | Credit record ID for the close taxes deduction (NULL if @CloseTotalTaxes=0). Per Confluence: "Credit ID for taxes". |
| 65 | @OpenLots | DECIMAL(16,6) | YES | VERIFIED | Remaining lot count after partial close (0 for full close). Per Confluence: "Remaining lots (partial)". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.PositionTbl | MODIFIER | Updates StatusID=2 (closed), writes close rates, fees, taxes |
| @PositionID | Trade.Position | Reader | Reads position data (fallback for LastOpPriceRate fetch) |
| (join) | Trade.CurrencyPrice | Reader | LEFT JOIN for EndMarketRate derivation |
| @ExitOrderID | Trade.OrderForClose | Reader/Modifier | Reads order owner CID; delegates update to Trade.OrderForCloseUpdate |
| @EndExecutionID | Trade.OrderExecutionData | WRITER | INSERT execution details when ExitOrderType IN (19,20) |
| @PositionID | Trade.ExecutedCloseOrders | WRITER | INSERT linking position to executed exit order |
| (partial close) | History.PositionClosePartial | WRITER | INSERT history snapshot for partial close |
| @PositionID | History.PositionFailWrite | WRITER | INSERT on any TRY/CATCH failure |
| @CID | Customer.CustomerMoney | Reader | SELECT RealizedEquity for async params |
| @MirrorID | Trade.Mirror | Reader | SELECT RealizedEquity + IsActive |
| (via EXEC) | Trade.InsertAsyncRecord | Callee | Inserts ActionID=1 async record for post-close processing |
| (via EXEC) | Customer.SetBalanceClosePosition | Callee | Adjusts customer balance, returns @BonusChange, @CreditIDClosePosition |
| (via EXEC) | Customer.SetBalanceClameFee | Callee | Deducts close fees and taxes |
| (via EXEC) | Trade.PositionCloseValidation | Callee | Pre-close parameter validation |
| (via EXEC) | Internal.GetPositionID_Bigint | Callee | Generates new PositionID for partial close |
| (via EXEC) | Trade.OrderForCloseUpdate | Callee | Marks exit order as executed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecutionPositionRepository.cs | ClosePositionAsync | Application call site | Primary caller - post-execution position close flow |
| Trade.PositionReopen | (via EXEC) | Callee | Calls PositionClose as part of reopen (close old, open new) |
| Trade.ManualPositionClose | (via EXEC) | Callee | Wraps PositionClose for back-office manual close |
| Trade.ManualPositionClose_Casing | (via EXEC) | Callee | Manual close with casing logic |
| Trade.PositionCloseWithTimeout | (via EXEC) | Callee | Timeout-aware wrapper around PositionClose |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionClose (procedure)
├── Trade.PositionTbl (table) - MODIFIER (StatusID=2, write close fields)
├── Trade.Position (view) - Reader (fallback LastOpPriceRate fetch)
├── Trade.CurrencyPrice (table) - Reader (EndMarketRate LEFT JOIN)
├── Trade.Mirror (table) - Reader (IsActive, RealizedEquity)
├── Trade.PositionTreeInfo (table) - Reader (CloseOnEndOfWeek, LimitRate, StopRate in full close INSERT)
├── Trade.OrderForClose (table) - Reader (order owner CID validation)
├── Trade.OrderExecutionData (table) - WRITER
├── Trade.ExecutedCloseOrders (table) - WRITER
├── History.PositionClosePartial (table) - WRITER (partial close snapshot)
├── History.PositionFailWrite (table) - WRITER (failure log)
├── Customer.CustomerMoney (table) - Reader (account equity for async params)
├── Trade.InsertAsyncRecord (procedure) - Callee
├── Customer.SetBalanceClosePosition (procedure) - Callee
├── Customer.SetBalanceClameFee (procedure) - Callee
├── Trade.PositionCloseValidation (procedure) - Callee
├── Internal.GetPositionID_Bigint (procedure) - Callee (partial close only)
└── Trade.OrderForCloseUpdate (procedure) - Callee (exit order path only)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | MODIFIER - primary target: UPDATE StatusID=2, write close data |
| Trade.Position | View | Reader - fallback LastOpPriceRate fetch if not provided |
| Trade.CurrencyPrice | Table | Reader - EndMarketRate derivation via LEFT JOIN on InstrumentID |
| Trade.Mirror | Table | Reader - IsActive and RealizedEquity for async notification params |
| Trade.PositionTreeInfo | Table | Reader - INNER JOIN on TreeID for CloseOnEndOfWeek, LimitRate, StopRate |
| Trade.OrderForClose | Table | Reader - ownership validation for exit order |
| Trade.OrderExecutionData | Table | WRITER - execution details for exit orders |
| Trade.ExecutedCloseOrders | Table | WRITER - position-to-order linkage |
| History.PositionClosePartial | Table | WRITER - partial close history snapshot |
| History.PositionFailWrite | Table | WRITER - failure log on exception |
| Customer.CustomerMoney | Table | Reader - RealizedEquity for async params |
| Trade.InsertAsyncRecord | Procedure | Callee - async post-close record (ActionID=1) |
| Customer.SetBalanceClosePosition | Procedure | Callee - balance credit, bonus change |
| Customer.SetBalanceClameFee | Procedure | Callee - fee/tax deduction |
| Trade.PositionCloseValidation | Procedure | Callee - parameter validation |
| Internal.GetPositionID_Bigint | Procedure | Callee - new PositionID for partial close |
| Trade.OrderForCloseUpdate | Procedure | Callee - exit order status update |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionReopen | Procedure | Calls PositionClose to close the position before re-opening it |
| Trade.ManualPositionClose | Procedure | Wraps PositionClose for back-office manual close operations |
| Trade.ManualPositionClose_Casing | Procedure | Wrapper with casing/position validation |
| Trade.PositionCloseWithTimeout | Procedure | Timeout-safe wrapper for close operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Partition-aware: all queries on Trade.PositionTbl use `WHERE @PositionID%50 = PartitionCol`.
- Transaction scope: BEGIN TRANSACTION wraps the full-close UPDATE + balance update + async insert. ROLLBACK on CATCH, COMMIT on success.
- Retry mechanism: full-close UPDATE retries up to 3 times with 2ms delay for SQL Server row-version bug.
- Error 60004: position not found in open state (already closed).
- Error 60115: position not found at second retry attempt.

---

## 8. Sample Queries

### 8.1 Basic full close call

```sql
DECLARE @BonusChange MONEY, @HedgeServerID INT, @OccurredDBTime DATETIME,
        @SettlementTypeID INT, @PositionRatio DECIMAL(7,6), @UnitMargin DECIMAL(16,8),
        @InitDateTime DATETIME, @InitRateID BIGINT, @MirrorID INT, @IsMirrorActive BIT,
        @CreditIDClosePosition BIGINT, @CreditIDCloseTotalFees BIGINT, @CreditIDCloseTotalTaxes BIGINT,
        @OpenLots DECIMAL(16,6), @PartialClosePositionID BIGINT;

EXEC Trade.PositionClose
    @PositionID            = 123456789,
    @EndForexRate          = 1.23456,
    @NetProfit             = 150000,  -- 1500.00 dollars in cents
    @EndDateTime           = '2026-03-17 14:30:00',
    @CommissionOnClose     = 500,     -- 5.00 dollars in cents
    @EndForexPriceRateID   = 9876543,
    @ActionType            = 1,       -- manual close
    @BonusChange           = @BonusChange OUTPUT,
    @HedgeServerID         = @HedgeServerID OUTPUT,
    @OccurredDBTime        = @OccurredDBTime OUTPUT,
    @SettlementTypeID      = @SettlementTypeID OUTPUT,
    @CreditIDClosePosition = @CreditIDClosePosition OUTPUT,
    @OpenLots              = @OpenLots OUTPUT;
```

### 8.2 Verify position was closed successfully

```sql
SELECT  PositionID, StatusID, NetProfit, CommissionOnClose, EndForexRate, EndDateTime, ActionType,
        CloseOccurred, RedeemStatus
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   PositionID = 123456789
AND     PositionID%50 = PartitionCol;
-- StatusID = 2 confirms close succeeded
```

### 8.3 Find recent close failures for a position

```sql
SELECT  PositionID, FailTypeID, FailReason, EndDateTime, RequestCloseOccurred,
        ClosePositionActionTypeID, ExitOrderType, SessionID
FROM    History.PositionFailWrite WITH (NOLOCK)
WHERE   PositionID = 123456789
AND     FailTypeID = 2  -- close request failures
ORDER BY EndDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.PositionClose](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13795983395) | Confluence | Confirmed: "core SP for closing positions, full and partial, P&L, credits"; all output parameter descriptions |

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.4/10 (Elements: 9.5/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 15 VERIFIED, 50 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 5 callers | App Code: 1 repo / 1 file | Corrections: 0 applied*
*Object: Trade.PositionClose | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionClose.sql*
