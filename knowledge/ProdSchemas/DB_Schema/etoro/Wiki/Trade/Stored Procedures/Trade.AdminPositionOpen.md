# Trade.AdminPositionOpen

> Opens positions for administrative purposes (compensations, corporate actions, stock splits, manual adjustments) - wraps Trade.PositionOpen with compensation handling and audit logging via Trade.AdminPositionLog.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (OUTPUT - created position identifier) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.AdminPositionOpen is the administrative position-opening procedure used by back-office operations, corporate action processors, and the Execution Services AdminOrderForOpenFillProcessor. Unlike Trade.PositionOpen (which handles user-initiated trades), this procedure adds a compensation credit to the customer's balance before opening the position, tracks the operation in Trade.AdminPositionLog, and allows configurable validation (amount validation and balance checks can be disabled).

Admin position opens serve several business purposes: compensation for errors (giving a customer a new position to make up for a mistake), corporate actions (stock splits that require new positions), dividend reinvestment (opening positions using dividend payouts), and manual back-office adjustments. Each admin open requires a CompensationReasonID and OpenPositionActionType to ensure full audit traceability.

The procedure runs inside a single transaction: first it optionally credits the customer via Customer.SetBalanceCompensation (when @IsFunded=1 and @InitialPositionAmount!=0), then calls Trade.PositionOpen with all position parameters, and finally updates Trade.AdminPositionLog with the created PositionID and State=3 (Completed). On failure, the transaction rolls back and the log is updated with State=4 (Failed). The Execution Services application calls this via ExecutionAdminPositionRepository.AdminOpenPositionAsync.

---

## 2. Business Logic

### 2.1 Required Admin Parameters Validation

**What**: Enforces that admin-specific parameters are provided before any work begins.

**Columns/Parameters Involved**: `@CompensationReasonID`, `@OpenPositionActionType`

**Rules**:
- Both @CompensationReasonID and @OpenPositionActionType must be non-NULL
- If either is missing: RAISERROR 'Admin Position Open: missing CompensationReasonID or OpenActionType'
- This prevents admin positions from being opened without proper audit classification

### 2.2 Compensation Credit

**What**: Optionally adds a credit to the customer's balance before opening the position.

**Columns/Parameters Involved**: `@InitialPositionAmount`, `@IsFunded`, `@CID`, `@CompensationReasonID`

**Rules**:
- Runs only when @InitialPositionAmount != 0 AND @IsFunded = 1
- Calls Customer.SetBalanceCompensation with @Payment = @InitialPositionAmount, @Description = 'Promotion'
- @ManagerID is hardcoded to 1 (system manager)
- Returns @CreditID used later to link the compensation to the admin position log

**Diagram**:
```
Admin Open Request
    |
    v
[Validate CompensationReasonID + OpenPositionActionType]
    |
    v
[Get ManagerID from BackOffice.Customer]
    |
    v
BEGIN TRANSACTION
    |
    +--> [Credit Compensation?] --YES--> Customer.SetBalanceCompensation
    |         (IsFunded=1 & Amount!=0)         |
    |                                          v
    +--> [Trade.PositionOpen] <----------------+
    |         (all position params)
    |
    +--> [UPDATE Trade.AdminPositionLog]
    |         State=3, PositionID, CompensationCreditID
    |
COMMIT
```

### 2.3 Admin Position Log State Machine

**What**: Tracks the lifecycle of each admin position operation.

**Columns/Parameters Involved**: `@AdminPositionID`, `@PositionID`, `@CreditID`

**Rules**:
- The log row (identified by @AdminPositionID) must exist before this SP is called (pre-populated by the calling service)
- On success: State = 3 (Completed), PositionID set, ExecutionOccurred = @InitDateTime, CompensationCreditID = @CreditID
- On failure: transaction rolls back and error re-thrown via THROW

### 2.4 Configurable Validation

**What**: Admin positions can bypass certain validations that normal positions require.

**Columns/Parameters Involved**: `@ValidateAmount`, `@ValidateUserBalance`, `@IsFunded`

**Rules**:
- @ValidateAmount (default 1): When 0, skips amount validation in Trade.PositionOpen
- @ValidateUserBalance (default 1): When 0, skips balance check in Trade.PositionOpen
- @IsFunded (default 1): When 0, skips compensation credit step

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT OUTPUT | NO | - | VERIFIED | Created position ID. Allocated by Trade.PositionOpen and returned to the caller. Links back to Trade.PositionTbl.PositionID. |
| 2 | @HedgeServerID | INTEGER | NO | - | CODE-BACKED | Hedge server that processes this position's market exposure. FK to Trade.HedgeServer. |
| 3 | @InitForexRate | dtPrice | NO | - | CODE-BACKED | Opening execution rate for the instrument at the time of position creation. |
| 4 | @InitDateTime | DATETIME | NO | - | CODE-BACKED | Timestamp of the position open execution. Also stored as ExecutionOccurred in Trade.AdminPositionLog. |
| 5 | @LimitRate | dtPrice OUTPUT | YES | - | CODE-BACKED | Take-profit rate set by Trade.PositionOpen based on instrument defaults. |
| 6 | @StopRate | dtPrice OUTPUT | YES | - | CODE-BACKED | Stop-loss rate set by Trade.PositionOpen based on instrument defaults. |
| 7 | @Commission | MONEY | NO | - | VERIFIED | Commission charged on position open, stored in cents. Per Confluence: passed through to Trade.PositionOpen. |
| 8 | @SpreadedCommission | INTEGER | NO | - | CODE-BACKED | Commission component from the spread. |
| 9 | @TradeRange | INT | NO | - | CODE-BACKED | Allowed price deviation range for the trade. |
| 10 | @InitForexPriceRateID | BIGINT | NO | - | CODE-BACKED | Price rate snapshot ID at time of position open. |
| 11 | @MarketPriceRateID | BIGINT | NO | - | CODE-BACKED | Market price rate ID at time of execution. |
| 12 | @MarketPriceRate | dtPrice | NO | - | CODE-BACKED | Market price rate value at time of execution. |
| 13 | @SpreadedPipBid | dtPrice | YES | 0 | CODE-BACKED | Bid-side spread in pips applied to the execution. |
| 14 | @SpreadedPipAsk | dtPrice | YES | 0 | CODE-BACKED | Ask-side spread in pips applied to the execution. |
| 15 | @OrderID | INTEGER | YES | 0 | CODE-BACKED | Associated order ID if opened via an order. 0 = no order (direct admin open). |
| 16 | @ParentPositionID | BIGINT | YES | 0 | CODE-BACKED | Parent position ID for copy-trade scenarios. 0 = no parent (standalone). |
| 17 | @LastOpPriceRate | dtPrice | YES | NULL | NAME-INFERRED | Last operational price rate. |
| 18 | @LastOpPriceRateID | BIGINT | YES | NULL | NAME-INFERRED | Last operational price rate ID. |
| 19 | @LastOpConversionRate | dtPrice | YES | NULL | NAME-INFERRED | Last operational conversion rate. |
| 20 | @LastOpConversionRateID | BIGINT | YES | NULL | NAME-INFERRED | Last operational conversion rate ID. |
| 21 | @MirrorID | INT | YES | 0 | CODE-BACKED | Mirror (CopyTrader) relationship ID. 0 = not a copy trade. FK to Trade.Mirror. |
| 22 | @CID | INTEGER | NO | - | VERIFIED | Customer ID of the account receiving the admin position. FK to BackOffice.Customer. Used to look up ManagerID and for compensation. |
| 23 | @CurrencyID | INTEGER | YES | 1 | CODE-BACKED | Account currency for the position. Default 1 = USD. FK to Dictionary.Currency. |
| 24 | @InstrumentID | INTEGER | NO | - | VERIFIED | Financial instrument for the position (stock, ETF, crypto, etc.). FK to Trade.Instrument. |
| 25 | @Leverage | INTEGER | NO | - | CODE-BACKED | Leverage multiplier for the position. Real stocks always use 1. |
| 26 | @Amount | MONEY | NO | - | CODE-BACKED | Position amount in cents (application sends dollars x 100). |
| 27 | @AmountInUnitsDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in instrument units (e.g., number of shares). |
| 28 | @UnitMargin | DECIMAL(16,8) | NO | - | CODE-BACKED | Margin per unit. Used for margin requirement calculations. |
| 29 | @LotCountDecimal | DECIMAL(16,6) | NO | - | CODE-BACKED | Position size in lots. Units / Instrument.Unit. |
| 30 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1 = Buy/Long, 0 = Sell/Short. |
| 31 | @PositionRatio | DECIMAL(7,6) | YES | 0 | CODE-BACKED | Ratio of this position's amount to the account's realized equity. Clamped to [0,1]. |
| 32 | @DirectAggLotCount | DECIMAL(16,6) OUTPUT | YES | - | CODE-BACKED | Aggregated lot count returned by Trade.PositionOpen for the position tree. |
| 33 | @InitialPositionAmount | INT | YES | 0 | VERIFIED | Compensation credit amount (in cents). When non-zero and @IsFunded=1, this amount is credited to the customer's balance via Customer.SetBalanceCompensation before the position opens. |
| 34 | @IsOpenOpen | BIT | YES | 0 | CODE-BACKED | Flag for "open-open" scenario (position opened while already having an open position on same instrument). |
| 35 | @OpenMarketPriceRateID | BIGINT | YES | 0 | CODE-BACKED | Market price rate ID at position open time. |
| 36 | @InitExecutionID | BIGINT | YES | 0 | CODE-BACKED | Execution ID assigned at trade initiation. |
| 37 | @RootHedgeServerID | INT | YES | 0 | CODE-BACKED | Root hedge server for DLT flow (86 = DLT). |
| 38 | @TreeID | BIGINT OUTPUT | YES | 0 | CODE-BACKED | Position tree ID for copy-trade tree management. Created or inherited by Trade.PositionOpen. |
| 39 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Trading session ID for the position. |
| 40 | @OrderType | INT | YES | 0 | CODE-BACKED | Order type: 0=Market, 13=EntryOrder, 14=ExitOrder. From Dictionary.OrderType. |
| 41 | @RequestOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp when the admin request arrived at the TradingAPI. |
| 42 | @IsTslEnabled | TINYINT | YES | 0 | CODE-BACKED | Trailing stop loss enabled: 0=No, 1=Yes. |
| 43 | @FullCommission | MONEY | YES | NULL | CODE-BACKED | Full commission amount before any discounts. |
| 44 | @IsSettled | BIT | YES | 0 | CODE-BACKED | Real stock ownership flag: 1=Real stock (customer owns shares), 0=CFD. Legacy predecessor of SettlementTypeID. |
| 45 | @SettlementTypeID | TINYINT | YES | NULL | CODE-BACKED | Settlement type: 1=Real, 2=CFD, etc. FK to Dictionary.SettlementTypes. Supersedes @IsSettled. |
| 46 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Unique GUID for idempotency and request correlation. |
| 47 | @UnitsBaseValueCents | INT | YES | NULL | CODE-BACKED | Base value of one unit in cents. Used for position worth validation. |
| 48 | @IsDiscounted | BIT | YES | 0 | CODE-BACKED | Whether the position has a discounted fee schedule. |
| 49 | @AccountRealizedEquity | MONEY | YES | 0 | CODE-BACKED | Customer's realized equity at position open time. Used for position ratio calculation. |
| 50 | @AdminPositionID | BIGINT | NO | - | VERIFIED | ID in Trade.AdminPositionLog. Must be pre-populated by the calling service. Updated with PositionID and State=3 on success. |
| 51 | @OpenPositionActionType | INT | NO | - | VERIFIED | Type of admin open action: 1=Admin Manual Open, 2=Compensation, 3=Corporate Action, 4=Stock Split, 5=Dividend Reinvestment. Passed through to Trade.PositionOpen as @OpenActionType. Per Confluence. |
| 52 | @ValidateAmount | BIT | YES | 1 | VERIFIED | When 1, Trade.PositionOpen validates that Amount and AmountInUnitsDecimal are positive. When 0, skips this check (useful for zero-cost admin positions). |
| 53 | @IsFunded | BIT | YES | 1 | VERIFIED | When 1 (and @InitialPositionAmount!=0), Customer.SetBalanceCompensation is called to credit the customer before opening. When 0, no compensation is issued. |
| 54 | @ValidateUserBalance | TINYINT | YES | 1 | VERIFIED | When 1, Trade.PositionOpen checks the customer has sufficient balance. When 0, skips this check (admin can open positions regardless of balance). |
| 55 | @CompensationReasonID | INT | NO | - | VERIFIED | Reason for the compensation credit: 1=Promotion, 2=Error Correction, 3=Corporate Action, 4=Stock Split, 5=Dividend Reinvestment, 6=Manual Adjustment. Per Confluence. Required. |
| 56 | @Occurred | DATETIME OUTPUT | YES | NULL | CODE-BACKED | Actual execution timestamp returned by Trade.PositionOpen. |
| 57 | @IsPrePostFlow | BIT | YES | 0 | CODE-BACKED | Pre/post market trading flow flag. |
| 58 | @OrderExecutionTime | DATETIME | YES | NULL | CODE-BACKED | Order execution timestamp. |
| 59 | @ExecutionRateDiscounted | dtPrice | YES | NULL | CODE-BACKED | Discounted execution rate. |
| 60 | @ExecutionRateSpreaded | dtPrice | YES | NULL | CODE-BACKED | Spread-adjusted execution rate. |
| 61 | @ExecutionRateID | BIGINT | YES | NULL | CODE-BACKED | Execution rate snapshot ID. |
| 62 | @OrderForOpenStatusID | INT | YES | 0 | CODE-BACKED | Status of the order-for-open record. |
| 63 | @OpenCorrelationID | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation ID for tracing the full open flow across services. |
| 64 | @RequestedUnits | DECIMAL(16,6) | YES | 0.0 | CODE-BACKED | Units originally requested by the admin (may differ from @AmountInUnitsDecimal after rounding). |
| 65 | @PnLVersion | INT | YES | 0 | CODE-BACKED | PnL calculation version: 0=Legacy (CFD), 1=New (Real stocks). Derived from SettlementType in application. |
| 66 | @OpenTotalTaxes | MONEY | YES | 0 | CODE-BACKED | Total taxes charged on position open. |
| 67 | @OpenTotalFees | MONEY | YES | 0 | CODE-BACKED | Total fees charged on position open. |
| 68 | @OpenMarketSpread | MONEY | YES | NULL | CODE-BACKED | Market spread at open time. |
| 69 | @OpenMarkup | MONEY | YES | NULL | CODE-BACKED | Markup applied on open. |
| 70 | @CloseMarkupOnOpen | MONEY | YES | NULL | CODE-BACKED | Close-side markup captured at open time. |
| 71 | @OpenEtoroPrice | dtPrice | YES | NULL | CODE-BACKED | eToro's displayed price at open time. |
| 72 | @IsComputeForHedge | BIT | YES | NULL | CODE-BACKED | Whether to compute hedge exposure for this position. |
| 73 | @IsNoStopLoss | BIT OUTPUT | YES | NULL | CODE-BACKED | Output flag: 1 = no stop loss was set for this position. |
| 74 | @IsNoTakeProfit | BIT OUTPUT | YES | NULL | CODE-BACKED | Output flag: 1 = no take profit was set for this position. |
| 75 | @CreditIDOpenPosition | BIGINT OUTPUT | YES | NULL | CODE-BACKED | Credit transaction ID for the position balance deduction. |
| 76 | @CreditIDOpenTotalFees | BIGINT OUTPUT | YES | NULL | CODE-BACKED | Credit transaction ID for total fees charged. |
| 77 | @CreditIDOpenTotalTaxes | BIGINT OUTPUT | YES | NULL | CODE-BACKED | Credit transaction ID for total taxes charged. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | SELECT | Reads ManagerID for the customer |
| EXEC | Trade.PositionOpen | EXEC | Core position creation - all position parameters are passed through |
| EXEC | Customer.SetBalanceCompensation | EXEC | Credits the customer's balance for compensation (conditional) |
| UPDATE | Trade.AdminPositionLog | UPDATE | Records the completed position ID, state, and compensation credit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecutionAdminPositionRepository | AdminOpenPositionAsync | EXEC | Called from Execution Services for admin position opens (Source: trading-execution-services) |
| AdminOrderForOpenFillProcessor | PostExecution | EXEC | Processes admin open orders through the execution pipeline (Source: trading-execution-services) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AdminPositionOpen (procedure)
+-- Trade.PositionOpen (procedure)
+-- Customer.SetBalanceCompensation (procedure)
+-- BackOffice.Customer (table)
+-- Trade.AdminPositionLog (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionOpen | Procedure | EXEC - creates the position (all position parameters passed through) |
| Customer.SetBalanceCompensation | Procedure | EXEC - credits compensation to customer balance (conditional) |
| BackOffice.Customer | Table | SELECT - reads ManagerID for the customer |
| Trade.AdminPositionLog | Table | UPDATE - records completion state, position ID, and compensation credit |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecutionAdminPositionRepository | External (C#) | Calls this SP via AdminOpenPositionAsync |
| AdminOrderForOpenFillProcessor | External (C#) | Orchestrates admin open through execution pipeline |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Required params | Validation | CompensationReasonID and OpenPositionActionType must not be NULL |
| Transaction | Atomicity | Compensation + PositionOpen + Log update all within one transaction |
| THROW | Error handling | On failure, transaction rolls back and error propagates to caller |

---

## 8. Sample Queries

### 8.1 View recent admin position opens from the log

```sql
SELECT  apl.AdminPositionID, apl.PositionID, apl.State, apl.CID,
        apl.InstrumentID, apl.ExecutionOccurred, apl.CompensationCreditID
FROM    Trade.AdminPositionLog apl WITH (NOLOCK)
WHERE   apl.State = 3
ORDER BY apl.ExecutionOccurred DESC;
```

### 8.2 Execute an admin position open for compensation

```sql
DECLARE @PosID BIGINT, @TreeID BIGINT, @LimitRate DECIMAL(18,8), @StopRate DECIMAL(18,8),
        @DirectAgg DECIMAL(16,6), @Occurred DATETIME,
        @IsNoSL BIT, @IsNoTP BIT, @CrPos BIGINT, @CrFee BIGINT, @CrTax BIGINT;

EXEC Trade.AdminPositionOpen
    @PositionID = @PosID OUTPUT,
    @TreeID = @TreeID OUTPUT,
    @LimitRate = @LimitRate OUTPUT,
    @StopRate = @StopRate OUTPUT,
    @DirectAggLotCount = @DirectAgg OUTPUT,
    @Occurred = @Occurred OUTPUT,
    @IsNoStopLoss = @IsNoSL OUTPUT,
    @IsNoTakeProfit = @IsNoTP OUTPUT,
    @CreditIDOpenPosition = @CrPos OUTPUT,
    @CreditIDOpenTotalFees = @CrFee OUTPUT,
    @CreditIDOpenTotalTaxes = @CrTax OUTPUT,
    @AdminPositionID = 12345,
    @OpenPositionActionType = 2,
    @CompensationReasonID = 1,
    @CID = 1000,
    @InstrumentID = 5,
    @Amount = 10000,
    @AmountInUnitsDecimal = 1.500000,
    @UnitMargin = 150.25000000,
    @LotCountDecimal = 1.500000,
    @IsBuy = 1,
    @Leverage = 1,
    @InitForexRate = 150.25,
    @InitDateTime = GETUTCDATE(),
    @HedgeServerID = 1,
    @Commission = 0,
    @SpreadedCommission = 0,
    @TradeRange = 0,
    @InitForexPriceRateID = 0,
    @MarketPriceRateID = 0,
    @MarketPriceRate = 150.25,
    @IsFunded = 1,
    @ValidateUserBalance = 0,
    @InitialPositionAmount = 10000;
```

### 8.3 Check admin position log with compensation credit details

```sql
SELECT  apl.AdminPositionID, apl.CID, apl.InstrumentID,
        apl.State, apl.PositionID, apl.CompensationCreditID,
        p.Amount, p.IsBuy, p.InstrumentID
FROM    Trade.AdminPositionLog apl WITH (NOLOCK)
LEFT JOIN Trade.PositionTbl p WITH (NOLOCK) ON apl.PositionID = p.PositionID
WHERE   apl.AdminPositionID = 12345;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.AdminPositionOpen](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13796114465/Trade.AdminPositionOpen) | Confluence | Full procedure documentation: compensation reason IDs (1-6), open position action types (1-5), admin position log state machine (3=Completed, 4=Failed), logic flow diagram, differences from Trade.PositionOpen |
| [OrderForOpenFill Flow](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/) | Confluence | Confirms this SP is called from the admin order-for-open fill processor in execution services |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 9.2/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 10.0/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 63 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 5 files | Corrections: 0 applied*
*Object: Trade.AdminPositionOpen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AdminPositionOpen.sql*
