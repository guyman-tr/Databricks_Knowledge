# Trade.PositionOpen

> Core trading engine procedure that opens a new position: validates balance, allocates PositionID, inserts into Trade.PositionTbl, creates tree info, deducts balance, handles orders for execution, and queues post-processing - with full support for mirror/CopyTrader, real/demo, DLT flows, and partial open scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (OUTPUT - allocated position identifier) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionOpen is one of the most critical procedures in the trading engine - it creates a new open position. This procedure handles the complete lifecycle of position creation: balance validation, ID allocation, position record insertion, tree info management (for stop-loss/take-profit sharing), balance deduction, fee/tax processing, order execution tracking, and post-open event queuing.

The procedure supports multiple trading scenarios:
- **Manual positions**: Direct user trades
- **Mirror/CopyTrader positions**: Positions copied from parent traders, with tree info inheritance from the root position
- **Entry/Exit orders**: Positions opened by pending order execution (OrderType 17/18)
- **Real vs Demo**: Different validation paths for production vs demo environments
- **DLT flow**: Special hedge server handling when RootHedgeServerID=86
- **Pre/Post flow**: Special handling for pre/post-market trading

The procedure has evolved significantly since 2012, accumulating over 60 documented change entries.

---

## 2. Business Logic

### 2.1 Balance Validation

**What**: Ensures the customer (or mirror) has sufficient funds to open the position.

**Columns/Parameters Involved**: `@CID`, `@Amount`, `@MirrorID`, `@ParentPositionID`, `@ValidateUserBalance`

**Rules**:
- For manual positions: reads credit from Customer.Customer
- For mirror positions (@ParentPositionID != 0 AND @MirrorID != 0): reads credit from Trade.Mirror
- Mirror must be active (IsActive=1) unless @IsPrePostFlow=1
- Insufficient funds: RAISERROR 60003 if Credit - Amount/100 < -1.00 AND @ValidateUserBalance=1
- Inactive mirror: RAISERROR 60092

### 2.2 Amount and Position Ratio Validation

**What**: Validates position amounts and computes position ratio.

**Columns/Parameters Involved**: `@Amount`, `@AmountInUnitsDecimal`, `@PositionRatio`, `@RealizedEquity`

**Rules**:
- Amount must be positive when @ValidateAmount=1: RAISERROR 60076
- AmountInUnitsDecimal must be positive: RAISERROR 60077
- If @PositionRatio not provided: calculated as Amount / (RealizedEquity * 100), clamped to [0, 1]

### 2.3 Position ID Allocation and Tree Management

**What**: Allocates a unique PositionID and manages TreeID for stop-loss/take-profit sharing.

**Columns/Parameters Involved**: `@PositionID`, `@TreeID`, `@IsReal`, `@MirrorID`

**Rules**:
- PositionID allocated via Internal.GetPositionID_Bigint
- If TreeID=0: TreeID is set to PositionID (root of a new tree)
- For demo + non-mirror: TreeID negated (multiplied by @IsReal = -1)
- For real + mirror: validates root position exists (StatusID=1 in Trade.PositionTbl)
- PositionTreeInfo INSERT only when tree doesn't exist yet (idempotent, handles race conditions with error 2627 suppression in demo)

### 2.4 Position Record Insertion

**What**: Inserts the full position record into Trade.PositionTbl.

**Columns/Parameters Involved**: 80+ columns spanning all position attributes

**Rules**:
- Amount stored as dollars (divided by 100)
- Commission stored as dollars (divided by 100)
- FullCommission divided by 100
- InitialUnits set to @AmountInUnitsDecimal
- InitialLotCount set to @LotCountDecimal
- IsComputeForHedge defaults based on PlayerLevelID (4 = no hedge compute)
- ForexResultID defaults to -1 (not computed yet)

### 2.5 Balance Deduction and Fee Processing

**What**: Deducts the position amount from customer balance and processes fees/taxes.

**Columns/Parameters Involved**: `@CID`, `@Amount`, `@MirrorID`, `@OpenTotalFees`, `@OpenTotalTaxes`

**Rules**:
- Customer.SetBalanceOpenPosition: deducts position amount, returns CreditID
- Customer.SetBalanceClameFee: processes OpenTotalFees if non-zero, returns CreditID
- Customer.SetBalanceClameFee: processes OpenTotalTaxes if non-zero, returns CreditID

### 2.6 Order for Execution Handling

**What**: Updates order status and records execution data for pending order fills.

**Columns/Parameters Involved**: `@OrderID`, `@OrderType`, `@IsPrePostFlow`

**Rules**:
- Only when OrderID != 0 AND OrderType IN (17, 18) AND @IsPrePostFlow=1
- Validates CID matches OrdersOwner from Trade.OrderForOpen
- Calls Trade.OrderForOpenUpdate to update order status
- Inserts into Trade.OrderExecutionData if execution doesn't exist
- Inserts into Trade.ExecutedOpenOrders

### 2.7 DLT Flow Special Handling

**What**: Adjusts RootHedgeServerID for mirrored DLT positions.

**Columns/Parameters Involved**: `@MirrorID`, `@RootHedgeServerID`, `@HedgeServerID`

**Rules**:
- When MirrorID != 0 AND RootHedgeServerID = 86: override to HedgeServerID
- Fixes an issue where mirrored positions of DLT root positions cannot be closed

### 2.8 Post-Position Open Processing

**What**: Queues async post-processing tasks for the new position.

**Columns/Parameters Involved**: All key position attributes

**Rules**:
- INSERT into Trade.PostPositionOpenMot with position details
- Triggers downstream processing (notifications, mirror propagation, etc.)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | OUTPUT: Allocated unique position identifier from Internal.GetPositionID_Bigint. |
| 2 | @HedgeServerID | INT | NO | - | CODE-BACKED | Hedge server this position is assigned to for risk management. |
| 3 | @InitForexRate | dtPrice | NO | - | CODE-BACKED | The execution price/rate at which the position was opened. |
| 4 | @InitDateTime | DATETIME | NO | - | CODE-BACKED | When the position was opened (trade timestamp). |
| 5 | @LimitRate | dtPrice | NO | - | CODE-BACKED | OUTPUT: Take-profit rate. May be overridden from tree info for child positions. |
| 6 | @StopRate | dtPrice | NO | - | CODE-BACKED | OUTPUT: Stop-loss rate. May be overridden from tree info for child positions. |
| 7 | @Commission | MONEY | NO | - | CODE-BACKED | Commission in cents. Stored as dollars (divided by 100) in PositionTbl. |
| 8 | @SpreadedCommission | INT | NO | - | CODE-BACKED | Spread-adjusted commission component. |
| 9 | @TradeRange | INT | YES | 0 | CODE-BACKED | Market range tolerance for the trade. |
| 10 | @InitForexPriceRateID | BIGINT | NO | - | CODE-BACKED | Price rate ID at open time, used for audit and rate tracking. |
| 11 | @MarketPriceRateID | BIGINT | NO | - | CODE-BACKED | Market price rate ID at the time of opening. |
| 12 | @MarketPriceRate | dtPrice | NO | - | CODE-BACKED | Market price at open time. |
| 13 | @SpreadedPipBid | dtPrice | YES | 0 | CODE-BACKED | Spread in pips on bid side. |
| 14 | @SpreadedPipAsk | dtPrice | YES | 0 | CODE-BACKED | Spread in pips on ask side. |
| 15 | @OrderID | INT | YES | 0 | CODE-BACKED | Entry order ID that triggered this position open (0 = manual/immediate). |
| 16 | @ParentPositionID | BIGINT | YES | 0 | CODE-BACKED | Parent position for CopyTrader/mirror positions. 0 = root position. |
| 17 | @LastOpPriceRate | dtPrice | YES | NULL | CODE-BACKED | Last operation price rate. Defaults to @InitForexRate if NULL. |
| 18 | @LastOpPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Last operation price rate ID. Defaults to @InitForexPriceRateID if NULL. |
| 19 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Last operation conversion rate (for currency conversion). |
| 20 | @LastOpConversionRateID | BIGINT | YES | NULL | CODE-BACKED | Last operation conversion rate ID. |
| 21 | @MirrorID | INT | YES | 0 | CODE-BACKED | Mirror/CopyTrader ID. 0 = not a mirrored position. |
| 22 | @CID | INT | NO | - | CODE-BACKED | Customer ID opening the position. |
| 23 | @CurrencyID | INT | YES | 1 | CODE-BACKED | Currency of the position. Default 1. |
| 24 | @InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument being traded. |
| 25 | @Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier for the position. |
| 26 | @Amount | MONEY | NO | - | CODE-BACKED | Position amount in cents. Stored as dollars (divided by 100). |
| 27 | @AmountInUnitsDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in instrument units (fractional). |
| 28 | @UnitMargin | DECIMAL(16,8) | NO | - | CODE-BACKED | Margin per unit for the position. |
| 29 | @LotCountDecimal | DECIMAL(16,6) | YES | 0 | CODE-BACKED | Position size in lots (fractional). |
| 30 | @IsBuy | BIT | NO | - | CODE-BACKED | 1=Long/Buy position, 0=Short/Sell position. |
| 31 | @PositionRatio | DECIMAL(7,6) | YES | 0 | CODE-BACKED | Ratio of position amount to account equity. Computed if 0 or NULL. |
| 32 | @DirectAggLotCount | DECIMAL(16,6) | NO | - | CODE-BACKED | OUTPUT: Aggregated lot count for hedge computation. 0 for PlayerLevelID=4. |
| 33 | @InitialPositionAmount | INT | YES | 0 | CODE-BACKED | Original position amount in cents. Defaults to @Amount if 0. |
| 34 | @IsOpenOpen | BIT | YES | 0 | CODE-BACKED | Whether this is an "open-open" position. |
| 35 | @OpenMarketPriceRateID | BIGINT | YES | 0 | CODE-BACKED | Market price rate ID at open. Falls back to Trade.CurrencyPrice if 0. |
| 36 | @InitExecutionID | BIGINT | YES | 0 | CODE-BACKED | Execution ID from the trading engine. |
| 37 | @RootHedgeServerID | INT | YES | 0 | CODE-BACKED | Root hedge server ID. Overridden to @HedgeServerID for DLT mirror positions (=86). |
| 38 | @TreeID | BIGINT | YES | 0 | CODE-BACKED | OUTPUT: Tree identifier for SL/TP sharing. Set to @PositionID if 0. Negated for demo non-mirror. |
| 39 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Trading session ID. |
| 40 | @OrderType | INT | YES | 0 | CODE-BACKED | Order type from Dictionary.OrderType (13=Entry, 14=Exit, 17/18=ForExecution). |
| 41 | @RequestOccurred | DATETIME | NO | - | CODE-BACKED | When the request arrived at Trading API (client-side timestamp). |
| 42 | @IsTslEnabled | TINYINT | YES | 0 | CODE-BACKED | 0=no trailing stop loss, 1+=TSL enabled. |
| 43 | @SLManualVerTimestamp | DATETIME | YES | NULL | CODE-BACKED | OUTPUT: Timestamp for stop-loss manual version tracking. Set to GETUTCDATE(). |
| 44 | @Occurred | DATETIME | YES | NULL | CODE-BACKED | OUTPUT: Server-side timestamp when position was opened. Set to GETUTCDATE(). |
| 45 | @InitSLNextThresHold | dtPrice | YES | NULL | CODE-BACKED | Initial trailing stop loss threshold (next level to trigger). |
| 46 | @FullCommission | MONEY | YES | NULL | CODE-BACKED | Full commission amount in cents. Stored as dollars (divided by 100). |
| 47 | @IsSettled | BIT | YES | 0 | CODE-BACKED | Whether this position is settled (T+2 settlement). |
| 48 | @SettlementTypeID | TINYINT | YES | NULL | CODE-BACKED | Settlement type. Defaults to CAST(@IsSettled AS TINYINT) if NULL. |
| 49 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation ID for the client request. |
| 50 | @ValidateUserBalance | TINYINT | YES | 1 | CODE-BACKED | 1=validate sufficient balance, 0=skip balance check (reopen trades). |
| 51 | @UnitsBaseValueCents | INT | YES | NULL | CODE-BACKED | Base value of units in cents. Defaults to @InitialPositionAmount if NULL. |
| 52 | @ClientViewRateID | BIGINT | YES | NULL | CODE-BACKED | Rate ID shown to client at open time. |
| 53 | @ClientViewRate | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Rate shown to client at open time. |
| 54 | @ClientRateForCalcID | BIGINT | YES | NULL | CODE-BACKED | Rate ID used for PnL calculations shown to client. |
| 55 | @ClientRateForCalc | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Rate used for PnL calculations shown to client. |
| 56 | @IsDiscounted | BIT | YES | 0 | CODE-BACKED | Whether the position has a discounted spread/commission. |
| 57 | @IsPrePostFlow | BIT | YES | 0 | CODE-BACKED | Whether this is a pre/post-market trading flow. |
| 58 | @OrderForOpenStatusID | INT | YES | 0 | CODE-BACKED | Status to set on the OrderForOpen after position is opened. |
| 59 | @OpenActionType | INT | YES | -1 | CODE-BACKED | Type of open action (e.g., 1=hierarchical for mirror). Default -1. |
| 60 | @MarketRangeValidationType | TINYINT | YES | 1 | CODE-BACKED | Type of market range validation to apply. |
| 61 | @MarketRangePercentage | DECIMAL(5,2) | YES | NULL | CODE-BACKED | Percentage for market range validation. |
| 62 | @OpenCorrelationID | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation ID for the open execution. |
| 63 | @PostAdjustmentRatio | DECIMAL(16,15) | YES | 1 | CODE-BACKED | Post-adjustment ratio for unit calculations. Default 1 (no adjustment). |
| 64 | @RequestedUnits | DECIMAL(16,6) | YES | 0.0 | CODE-BACKED | Originally requested units (may differ from actual). |
| 65 | @OrderExecutionTime | DATETIME | YES | NULL | CODE-BACKED | Time the order was executed. |
| 66 | @ValidateAmount | INT | YES | 1 | CODE-BACKED | 1=validate Amount > 0, 0=skip (allows zero-amount positions). |
| 67 | @ExecutionRateDiscounted | dtPrice | YES | NULL | CODE-BACKED | Discounted execution rate recorded in OrderExecutionData. |
| 68 | @ExecutionRateSpreaded | dtPrice | YES | NULL | CODE-BACKED | Spreaded execution rate recorded in OrderExecutionData. |
| 69 | @ExecutionRateID | BIGINT | YES | NULL | CODE-BACKED | Execution rate ID recorded in OrderExecutionData. |
| 70 | @PnLVersion | INT | YES | 0 | CODE-BACKED | PnL calculation version for this position. |
| 71 | @OpenTotalTaxes | MONEY | YES | 0 | CODE-BACKED | Total taxes charged at open. Processed via Customer.SetBalanceClameFee if non-zero. |
| 72 | @OpenTotalFees | MONEY | YES | 0 | CODE-BACKED | Total fees charged at open. Processed via Customer.SetBalanceClameFee if non-zero. |
| 73 | @OpenMarketSpread | MONEY | YES | NULL | CODE-BACKED | Market spread at open time. |
| 74 | @OpenMarkup | MONEY | YES | NULL | CODE-BACKED | Markup applied at open time. |
| 75 | @CloseMarkupOnOpen | MONEY | YES | NULL | CODE-BACKED | Expected close markup captured at open time. |
| 76 | @OpenEtoroPrice | dtPrice | YES | NULL | CODE-BACKED | eToro internal price at open time. |
| 77 | @IsNoStopLoss | BIT | YES | NULL | CODE-BACKED | OUTPUT: Whether the position has no stop-loss. Read from tree info for child positions. |
| 78 | @IsNoTakeProfit | BIT | YES | NULL | CODE-BACKED | OUTPUT: Whether the position has no take-profit. Read from tree info for child positions. |
| 79 | @CreditIDOpenPosition | BIGINT | YES | NULL | CODE-BACKED | OUTPUT: Credit ID from the balance deduction for the position amount. |
| 80 | @CreditIDOpenTotalFees | BIGINT | YES | NULL | CODE-BACKED | OUTPUT: Credit ID from the fee deduction. |
| 81 | @CreditIDOpenTotalTaxes | BIGINT | YES | NULL | CODE-BACKED | OUTPUT: Credit ID from the tax deduction. |
| 82 | @IsComputeForHedge | BIT | YES | NULL | CODE-BACKED | Override for hedge computation flag. NULL defaults based on PlayerLevelID. |
| 83 | @SnapshotTimestamp | DATETIME | YES | NULL | CODE-BACKED | Snapshot timestamp for the position. |
| 84 | @PriceType | INT | YES | NULL | CODE-BACKED | Type of pricing used for this position. |
| 85 | @CompensationReasonID | INT | YES | NULL | CODE-BACKED | Reason for compensation, passed to Customer.SetBalanceOpenPosition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | READ | Balance, SpreadGroupID, LotCountGroupID, PlayerLevelID, RealizedEquity |
| @MirrorID | Trade.Mirror | READ | Mirror amount and IsActive check for CopyTrader positions |
| @PositionID | Trade.PositionTbl | INSERT | Main position record - 80+ columns |
| @TreeID | Trade.PositionTreeInfo | INSERT/READ | SL/TP/TSL tree info (insert for root, read for child) |
| @InstrumentID | Trade.CurrencyPrice | READ | Fallback for OpenMarketPriceRateID |
| @CID | Customer.SetBalanceOpenPosition | EXEC | Deducts position amount from customer balance |
| @CID | Customer.SetBalanceClameFee | EXEC | Processes open fees and taxes |
| @PositionID | Internal.GetPositionID_Bigint | EXEC | Allocates unique BIGINT PositionID |
| @OrderID | Trade.OrderForOpen | READ | Validates order owner CID |
| @OrderID | Trade.OrderForOpenUpdate | EXEC | Updates order status after position open |
| @OrderID | Trade.OrderExecutionData | INSERT | Records execution rate data |
| @OrderID | Trade.ExecutedOpenOrders | INSERT | Records executed open order details |
| - | Trade.PostPositionOpenMot | INSERT | Queues post-open processing tasks |
| FeatureID=22 | Maintenance.Feature | READ | Determines real vs demo environment |
| @TreeID | dbo.RealPositionTreeInfo | READ | Demo: inherits tree info from real server for mirror positions |
| @TreeID | Trade.PositionTbl | READ | Validates root position exists for mirror positions in real env |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading engine | External | EXEC | Called by the trading engine to open positions |
| CopyTrader service | External | EXEC | Called to open mirror/copy positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionOpen (procedure)
+-- Customer.Customer (table)
+-- Trade.Mirror (table)
+-- Trade.PositionTbl (table)
+-- Trade.PositionTreeInfo (table)
+-- Trade.CurrencyPrice (table)
+-- Trade.OrderForOpen (table)
+-- Trade.OrderExecutionData (table)
+-- Trade.ExecutedOpenOrders (table)
+-- Trade.PostPositionOpenMot (table)
+-- Maintenance.Feature (table)
+-- dbo.RealPositionTreeInfo (table/view)
+-- Internal.GetPositionID_Bigint (procedure)
+-- Customer.SetBalanceOpenPosition (procedure)
+-- Customer.SetBalanceClameFee (procedure)
+-- Trade.OrderForOpenUpdate (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | READ - balance, player info |
| Trade.Mirror | Table | READ - mirror amount/status |
| Trade.PositionTbl | Table | INSERT - main position record + READ for root position validation |
| Trade.PositionTreeInfo | Table | INSERT/READ - tree info for SL/TP sharing |
| Trade.CurrencyPrice | Table | READ - fallback market price rate |
| Trade.OrderForOpen | Table | READ - validates order owner |
| Trade.OrderExecutionData | Table | INSERT + READ - execution rate data |
| Trade.ExecutedOpenOrders | Table | INSERT - executed open order records |
| Trade.PostPositionOpenMot | Table | INSERT - post-open processing queue |
| Maintenance.Feature | Table | READ - FeatureID=22 (real vs demo) |
| dbo.RealPositionTreeInfo | Table/View | READ - tree info from real server (demo only) |
| Internal.GetPositionID_Bigint | Procedure | EXEC - PositionID allocation |
| Customer.SetBalanceOpenPosition | Procedure | EXEC - balance deduction |
| Customer.SetBalanceClameFee | Procedure | EXEC - fee/tax processing |
| Trade.OrderForOpenUpdate | Procedure | EXEC - order status update |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading engine | External | EXEC - position open flow |
| CopyTrader service | External | EXEC - mirror position open |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET XACT_ABORT ON | Transaction safety | Ensures automatic rollback on errors |
| Explicit transaction | Atomicity | BEGIN TRANSACTION / COMMIT with ROLLBACK on error |
| Error 60003 | Business | Insufficient funds to open position |
| Error 60076 | Validation | Amount is not positive |
| Error 60077 | Validation | AmountInUnitsDecimal is not positive |
| Error 60092 | Business | Mirror not active |
| Error 60116 | Business | Root position not found for mirror child |
| Error 2627 suppression | Race condition | Demo: ignores duplicate key on PositionTreeInfo INSERT |
| PartitionCol = @TreeID%50 | Partitioning | PositionTreeInfo and PositionTbl partitioned by TreeID/PositionID modulo 50 |

---

## 8. Sample Queries

### 8.1 View recent positions for a customer

```sql
SELECT TOP 10 PositionID, InstrumentID, IsBuy, Amount, AmountInUnitsDecimal, StatusID, Occurred
FROM   Trade.PositionTbl WITH (NOLOCK)
WHERE  CID = 12345
ORDER BY Occurred DESC;
```

### 8.2 Check position tree info

```sql
SELECT TreeID, StopRate, LimitRate, IsTslEnabled, NextThresHold, IsDiscounted
FROM   Trade.PositionTreeInfo WITH (NOLOCK)
WHERE  TreeID = 123456789;
```

### 8.3 View post-open processing queue

```sql
SELECT TOP 20 PositionID, CID, InstrumentID, StatusID
FROM   Trade.PostPositionOpenMot WITH (NOLOCK)
ORDER BY 1 DESC;
```

---

## 9. Atlassian Knowledge Sources

- **TRADEX-1704** (Jira): Referenced in change log for OpenActionType parameter addition (2021-08-16).

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 85 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 4 analyzed (SetBalanceOpenPosition, SetBalanceClameFee, GetPositionID_Bigint, OrderForOpenUpdate) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionOpen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionOpen.sql*
