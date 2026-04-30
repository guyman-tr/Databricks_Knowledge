# Trade.OrdersAdd

> Inserts a new legacy position open order into Trade.Orders (the older trading system's active orders table), resolves the conversion rate if not provided, validates parent order and leverage, triggers an async change-log record, and on failure logs the attempted order to History.OrdersFail.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID OUTPUT (auto-assigned via Internal.GetOrderID if null/0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrdersAdd is the legacy order creation procedure for eToro's older position-open pathway. It writes to Trade.Orders (the older open-order table), as opposed to the newer Trade.OrderForOpenCreate which writes to Trade.OrderForOpen. The change history shows it has been in use since at least 2015, with the original Orders-queue message dispatch commented out.

The procedure: validates leverage is non-zero, validates a parent order exists and shares the same instrument (for copy-trade opens), validates amount is positive, auto-generates an OrderID via Internal.GetOrderID if not supplied, resolves price and conversion rates from Trade.CurrencyPrice if not provided, and inserts the full order record into Trade.Orders. After the INSERT, it queues an async change-log entry via Trade.InsertAsyncRecord (type 11) instead of the former synchronous Trade.OrdersChangeLogAdd call (changed in November 2018 for performance).

On any failure, the full order details including the error message and client version are written to History.OrdersFail, and error 60000 is raised.

Data flows: no SP callers found in the Trade schema - called externally by trading engine services. The newer path (Trade.OrderForOpenCreate + Trade.OrderForOpen) handles most opens; this older path still handles specific order types.

---

## 2. Business Logic

### 2.1 Input Validation

**What**: Guards against invalid leverage, parent order mismatch, and zero amount before any writes.

**Columns/Parameters Involved**: `@Leverage`, `@ParentOrderID`, `@InstrumentID`, `@Amount`, `RealOpenOrders (synonym)`

**Rules**:
- @Leverage=0: RAISERROR('@Leverage can not be zero', 16, 1).
- @ParentOrderID NOT NULL AND != 0: SELECT InstrumentID FROM RealOpenOrders WHERE OrderID=@ParentOrderID.
  - Not found: RAISERROR(60034) - 'Could not find an open order with the given OrderID'.
  - InstrumentID mismatch: RAISERROR(60035) - 'Parent's and child's InstrumentID doesn't match'.
  - RealOpenOrders is a synonym for Trade.Orders in the Real environment.
- @Amount <= 0: RAISERROR(60078) - 'The @Amount is not positive'.
- ForexResultID hardcoded to -1 (comment: FK violations occurred with real values; -1 is the safe default used for all positions).

### 2.2 OrderID Assignment

**What**: Auto-generates an OrderID if not provided by the caller.

**Columns/Parameters Involved**: `@OrderID OUTPUT`, `Internal.GetOrderID`

**Rules**:
- If @OrderID IS NULL OR @OrderID=0: EXEC Internal.GetOrderID @OrderID OUTPUT.
- Caller can pre-assign @OrderID; if so, the assignment is skipped.

### 2.3 Price Rate Resolution

**What**: Resolves the last operation price and conversion rates if not supplied.

**Columns/Parameters Involved**: `@LastOpPriceRateID`, `@LastOpPriceRate`, `@LastOpConversionRateID`, `@LastOpConversionRate`, `Trade.CurrencyPrice`, `Trade.Instrument`

**Rules**:
- If @LastOpPriceRateID or @LastOpPriceRate is NULL: SELECT PriceRateID, (Bid+Ask)/2 FROM Trade.CurrencyPrice NOLOCK WHERE ProviderID=@ProviderID AND InstrumentID=@InstrumentID.
- If @LastOpConversionRate or @LastOpConversionRateID is NULL:
  - SELECT SellCurrencyID, BuyCurrencyID, IsMajor FROM Trade.Instrument WHERE InstrumentID=@InstrumentID.
  - IsMajor=1: ConversionRate=1 (USD-denominated, no conversion needed).
  - SellCurrencyID!=1 AND BuyCurrencyID=1: ConversionRate=1/Bid via cross-instrument lookup (find instrument where BuyCurrencyID=1 AND SellCurrencyID=@SellCurrencyID).
  - Else: ConversionRate=Bid via inverse lookup (find instrument where SellCurrencyID=1 AND BuyCurrencyID=@SellCurrencyID).
- ConversionRate=1 (or NULL) stored as 0 in the table (CASE WHEN = 1 THEN 0).

### 2.4 Order Insert and Async Change Log

**What**: Inserts the order and queues the change-log update asynchronously.

**Columns/Parameters Involved**: `Trade.Orders`, `Trade.InsertAsyncRecord`

**Rules**:
- INSERT INTO Trade.Orders with all parameters, OccurredTime=GETDATE().
- EXEC Trade.InsertAsyncRecord @CID, 11 (type 11=OrdersChangeLogAdd), XML params (OrderID, OperationTypeID=1, ClientRequestGuid, IsSettled, SettlementTypeID, IsNoStopLoss, IsNoTakeProfit, RequestingService), 0, 0, 0.
- Change-log async since 2018-11-13 (FB-51445 context).
- Previous synchronous call (Trade.OrdersChangeLogAdd) is commented out.

### 2.5 Failure Logging

**What**: On any exception, records the attempted order and failure reason to History.OrdersFail.

**Columns/Parameters Involved**: `History.OrdersFail`, `Customer.Login.ClientVersion`

**Rules**:
- CATCH block reads ClientVersion from Customer.Login NOLOCK WHERE CID=@CID.
- INSERT INTO History.OrdersFail with all order parameters, FailReason (built from ERROR_MESSAGE()+line+number), FailOccurred=GETDATE(), ClientVersion.
- @OrderID defaults to -1 if NULL (ISNULL(@OrderID,-1)).
- RAISERROR(60000) is raised after logging.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | YES | - | CODE-BACKED | OUTPUT: auto-assigned via Internal.GetOrderID if null or 0. Returned to caller after insert. Written to Trade.Orders.OrderID. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Written to Trade.Orders.CID. Used to look up ClientVersion in CATCH. |
| 3 | @CurrencyID | INT | NO | - | CODE-BACKED | Currency of the order. Written to Trade.Orders.CurrencyID. |
| 4 | @ProviderID | INT | NO | - | CODE-BACKED | Liquidity provider. Used for price rate resolution. Written to Trade.Orders.ProviderID. |
| 5 | @OrderTypeID | INT | NO | - | CODE-BACKED | Type of order. Written to Trade.Orders.OrderTypeID. |
| 6 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to open a position on. Validated against parent order. Written to Trade.Orders.InstrumentID. |
| 7 | @Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. Must be non-zero (RAISERROR on 0). Written to Trade.Orders.Leverage. |
| 8 | @Amount | INT | NO | - | CODE-BACKED | Dollar amount (cents). Must be > 0 (RAISERROR on <= 0). Written to Trade.Orders.Amount. |
| 9 | @Units | INT | NO | - | CODE-BACKED | Position size in instrument units (integer). Written to Trade.Orders.Units. |
| 10 | @UnitMargin | INT | NO | - | CODE-BACKED | Margin per unit required. Written to Trade.Orders.UnitMargin. |
| 11 | @LotCountDecimal | Decimal(16,6) | NO | - | CODE-BACKED | Lot count in decimal precision. Written to Trade.Orders.LotCountDecimal. |
| 12 | @RateFrom | dtPrice | NO | - | CODE-BACKED | Price range lower bound. Written to Trade.Orders.RateFrom. |
| 13 | @RateTo | dtPrice | NO | - | CODE-BACKED | Price range upper bound. Written to Trade.Orders.RateTo. |
| 14 | @IsBuy | BIT | NO | - | CODE-BACKED | 1=Buy (long), 0=Sell (short). Written to Trade.Orders.IsBuy. |
| 15 | @ForexResultID | INT | YES | -1 | CODE-BACKED | Always overridden to -1 inside the procedure regardless of what is passed. Historical FK violation workaround. |
| 16 | @GameID | INT | YES | 0 | CODE-BACKED | Game ID for demo/game accounts. Written to Trade.Orders.GameID. |
| 17 | @SpreadID | INT | YES | 0 | CODE-BACKED | Spread configuration ID. Written to Trade.Orders.SpreadID. |
| 18 | @LoginID | INT | YES | 0 | CODE-BACKED | Login session ID. Written to Trade.Orders.LoginID. |
| 19 | @IsOverWeekend | BIT | YES | 1 | CODE-BACKED | 1=Position held over weekend. Written to Trade.Orders.IsOverWeekend. |
| 20 | @StopLosAmount | INT | YES | 0 | CODE-BACKED | Stop Loss amount in cents. Written to Trade.Orders.StopLosAmount. |
| 21 | @TakeProfitAmount | INT | YES | 0 | CODE-BACKED | Take Profit amount in cents. Written to Trade.Orders.TakeProfitAmount. |
| 22 | @MarketSpreadPips | INT | YES | 0 | CODE-BACKED | Market spread in pips. |
| 23 | @MarketSpreadCents | INT | YES | 0 | CODE-BACKED | Market spread in cents. |
| 24 | @StopLosRate | dtPrice | NO | - | CODE-BACKED | Stop Loss rate. Written to Trade.Orders.StopLosRate. |
| 25 | @TakeProfitRate | dtPrice | NO | - | CODE-BACKED | Take Profit rate. Written to Trade.Orders.TakeProfitRate. |
| 26 | @TradeRange | INT | NO | - | CODE-BACKED | Price slippage tolerance range. Written to Trade.Orders.TradeRange. |
| 27 | @ParentOrderID | INT | YES | 1 | CODE-BACKED | Parent order ID for copy-trade opens. Validated: must exist in RealOpenOrders with same InstrumentID. Written to Trade.Orders.ParentOrderID. |
| 28 | @IsTslEnabled | TINYINT | YES | 0 | CODE-BACKED | 1=Trailing Stop Loss. Written as IIF(ISNULL=0,0,1). Added FB-34563. |
| 29 | @AmountInUnitsDecimal | Decimal(16,6) | YES | NULL | CODE-BACKED | Decimal precision units (vs integer @Units). Added FB-47233. Written to Trade.Orders.AmountInUnitsDecimal. |
| 30 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client GUID for deduplication/tracing. Passed to async change-log. Added FB-51445. |
| 31 | @IsSettled | BIT | YES | NULL | CODE-BACKED | Whether this is a settled (T+2) order. Written to Trade.Orders.IsSettled. Added FB-53719 (Free Stocks). |
| 32 | @SettlementTypeID | TINYINT | YES | NULL | CODE-BACKED | Settlement type (e.g., T+0, T+2). Written to Trade.Orders.SettlementTypeID. |
| 33 | @IsDiscounted | BIT | YES | NULL | CODE-BACKED | 1=Spread-discounted position. Written to Trade.Orders.IsDiscounted. |
| 34 | @IsNoStopLoss | bit | YES | NULL | CODE-BACKED | 1=Customer opted out of SL. Written to Trade.Orders.IsNoStopLoss. |
| 35 | @IsNoTakeProfit | bit | YES | NULL | CODE-BACKED | 1=Customer opted out of TP. Written to Trade.Orders.IsNoTakeProfit. |
| 36 | @RequestingService | varchar(10) | YES | NULL | CODE-BACKED | Identifier of the requesting service. Passed to async change-log for routing attribution. |
| 37 | @LastOpPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Price rate ID at open. Auto-resolved from Trade.CurrencyPrice if NULL. |
| 38 | @LastOpPriceRate | dtPrice | YES | NULL | CODE-BACKED | Mid-price at open ((Bid+Ask)/2). Auto-resolved from Trade.CurrencyPrice if NULL. |
| 39 | @LastOpConversionRateID | BIGINT | YES | NULL | CODE-BACKED | Currency conversion rate ID. Auto-resolved from cross-instrument lookup if NULL. |
| 40 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Currency conversion rate to USD. 3-way resolution: major=1, cross via BuyCurrencyID=1, or cross via SellCurrencyID=1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ParentOrderID | RealOpenOrders (synonym -> Trade.Orders) | Read | Validates parent order exists and shares InstrumentID |
| @OrderID | Internal.GetOrderID | EXEC | Auto-assigns OrderID when not provided |
| @ProviderID, @InstrumentID | Trade.CurrencyPrice | Read NOLOCK | Price rate resolution when @LastOpPriceRateID not provided |
| @InstrumentID | Trade.Instrument | Read NOLOCK | SellCurrencyID/BuyCurrencyID/IsMajor for conversion rate calculation |
| @OrderID + all params | Trade.Orders | Write | Main INSERT destination |
| @CID, type=11 | Trade.InsertAsyncRecord | EXEC | Async change-log dispatch |
| @CID | Customer.Login | Read NOLOCK | ClientVersion lookup on failure |
| @OrderID + all params | History.OrdersFail | Write (on error) | Failed order audit log |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SP callers found in Trade schema) | - | - | Called externally by legacy trading engine service; no SP callers in Trade schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersAdd (procedure)
├── Internal.GetOrderID (procedure)
├── RealOpenOrders (synonym -> Trade.Orders)
├── Trade.CurrencyPrice (table)
├── Trade.Instrument (table)
├── Trade.Orders (table)
├── Trade.InsertAsyncRecord (procedure)
├── Customer.Login (table)
└── History.OrdersFail (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetOrderID | Procedure | Assigns OrderID when not pre-supplied |
| RealOpenOrders | Synonym | Parent order validation (synonym for Trade.Orders in Real environment) |
| Trade.CurrencyPrice | Table | NOLOCK; price rate resolution for LastOpPriceRate/ID |
| Trade.Instrument | Table | NOLOCK; currency metadata for conversion rate resolution |
| Trade.Orders | Table | Main INSERT destination |
| Trade.InsertAsyncRecord | Procedure | Async change-log dispatch (type 11) |
| Customer.Login | Table | NOLOCK; ClientVersion lookup for failure logging |
| History.OrdersFail | Table | Failure audit log written in CATCH block |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No SP dependents found) | - | Called by legacy external trading engine service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. SET XACT_ABORT ON ensures any nested error rolls back the whole transaction. Explicit BEGIN TRANSACTION / COMMIT TRANSACTION. CATCH block: ROLLBACK if @@TRANCOUNT=1, COMMIT if >1 (nested transaction support). On error: History.OrdersFail is written OUTSIDE the rolled-back transaction (separate implicit transaction in CATCH), then RAISERROR(60000).

---

## 8. Sample Queries

### 8.1 Check recently inserted orders for a customer

```sql
SELECT OrderID, CID, InstrumentID, Amount, IsBuy, Leverage,
       StopLosRate, TakeProfitRate, OccurredTime, IsSettled
FROM Trade.Orders WITH (NOLOCK)
WHERE CID = <CID>
ORDER BY OccurredTime DESC;
```

### 8.2 Check failed order attempts for a customer

```sql
SELECT OrderID, CID, InstrumentID, FailReason, FailOccurred, ClientVersion
FROM History.OrdersFail WITH (NOLOCK)
WHERE CID = <CID>
ORDER BY FailOccurred DESC;
```

### 8.3 Verify conversion rate resolution for an instrument

```sql
SELECT TI.InstrumentID, TI.IsMajor, TI.SellCurrencyID, TI.BuyCurrencyID,
       TCP.Bid, TCP.Ask, (TCP.Bid + TCP.Ask)/2 AS MidRate
FROM Trade.Instrument TI WITH (NOLOCK)
JOIN Trade.CurrencyPrice TCP WITH (NOLOCK) ON TI.InstrumentID = TCP.InstrumentID
WHERE TI.InstrumentID = <InstrumentID>
  AND TCP.ProviderID = <ProviderID>;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 40 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers (external only) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.OrdersAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrdersAdd.sql*
