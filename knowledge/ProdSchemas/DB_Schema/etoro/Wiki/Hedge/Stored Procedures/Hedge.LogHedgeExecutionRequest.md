# Hedge.LogHedgeExecutionRequest

> TCA request-side writer: inserts one row into Hedge.ExecutionRequestBreakdownLog per hedge order sent, capturing eToro's live bid/ask from Trade.CurrencyPrice alongside the provider's quoted prices at the moment of order submission - enabling slippage and markup analysis when paired with LogHedgeExecutionResponse on HedgeID.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.ExecutionRequestBreakdownLog; reads live price from Trade.CurrencyPrice |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.LogHedgeExecutionRequest` is one half of eToro's hedge TCA (Transaction Cost Analysis) logging framework. Every time the hedge system sends an order to a liquidity provider, this procedure fires to snapshot the pricing environment at request time: eToro's internal bid/ask (from `Trade.CurrencyPrice`) and the provider's quoted bid/ask (passed by the caller).

This creates a "before" record that, when later joined to the corresponding `Hedge.ExecutionResponseBreakdownLog` row (via HedgeID), enables calculation of:
- **Slippage**: the change in provider price between when the order was sent and when it was filled
- **eToro markup**: the gap between eToro's price (customer-facing) and the provider's mid-market rate at request time

The procedure was updated on 2012-09-02 by Yitzchak Wahnon (FB 17303) to change `MarketPriceRateID` from INT to BIGINT, reflecting growth in the price rate ID sequence. The TCA pattern powers `Hedge.Report_TCA`.

**Key design**: The eToro bid/ask snapshot is NOT passed as a parameter - it is read via `SELECT Bid, Ask FROM Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID` inside the procedure. This ensures the price is captured atomically at DB insert time, not at application send time, providing a consistent snapshot for analysis.

---

## 2. Business Logic

### 2.1 Dual-Price Snapshot (eToro vs Provider)

**What**: Two sets of bid/ask prices are captured simultaneously, representing the two sides of eToro's hedge pricing.

**Columns/Parameters Involved**: `@ProviderPriceBid`, `@ProviderPriceAsk`, `eToroPriceBid`, `eToroPriceAsk`

**Rules**:
- `eToroPriceBid` / `eToroPriceAsk`: read from `Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID` at INSERT time. Represents eToro's internal (customer-facing) price at the moment of request.
- `@ProviderPriceBid` / `@ProviderPriceAsk`: passed by the caller (the LP's quoted price transmitted in the order request).
- Gap analysis: `eToroPriceBid - ProviderPriceBid` = eToro's BID markup over the provider mid. `ProviderPriceAsk - eToroPriceAsk` = eToro's ASK markup. eToro earns from the spread between what customers trade at and what the LP offers.
- The procedure uses `INSERT ... SELECT ... FROM Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID` - if CurrencyPrice has 0 rows for the instrument, no row is inserted. If it has multiple rows, multiple rows are inserted (normally exactly 1 row per InstrumentID is expected in CurrencyPrice).

**Diagram**:
```
Hedge Server Application (about to send order to LP)
  |
  | EXEC Hedge.LogHedgeExecutionRequest(
  |   @HedgeID, @InstrumentID, @ProviderPriceBid, @ProviderPriceAsk, ...)
  |
  | INSERT INTO Hedge.ExecutionRequestBreakdownLog
  |   SELECT @HedgeID, ..., Bid AS eToroPriceBid, Ask AS eToroPriceAsk,
  |          @ProviderPriceBid, @ProviderPriceAsk, ...
  |   FROM Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID
  v
Hedge.ExecutionRequestBreakdownLog (1 row: request-side TCA snapshot)
  |
  +-> Later: JOIN to ExecutionResponseBreakdownLog on HedgeID
  +-> Report_TCA: slippage = response prices - request prices
```

### 2.2 TCA Framework: Request + Response Pairing

**What**: This procedure creates the first half of a paired TCA record; the response half is written by LogHedgeExecutionResponse after the LP fill.

**Columns/Parameters Involved**: `HedgeID`

**Rules**:
- `@HedgeID`: the internal hedge order ID. The join key in Report_TCA between request and response logs.
- `Report_TCA` uses FULL JOIN on HedgeID to catch: (a) requests without responses (timed out orders) and (b) responses without requests (edge cases).
- Requests from manual orders (`@IsManualRequest = 1`) are excluded from automated TCA analysis in Report_TCA but are still logged here for audit.
- `@ExposureID`: optional - the exposure batch this order was part of (for exposure-based hedging, not single-order hedging).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INT | NO | - | CODE-BACKED | The internal hedge order identifier. Join key linking this request log to the corresponding ExecutionResponseBreakdownLog row. Maps to ExecutionRequestBreakdownLog.HedgeID. |
| 2 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server instance sending the order. Maps to ExecutionRequestBreakdownLog.HedgeServerID. |
| 3 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument being hedged. Used as the filter key to read eToro's live price from Trade.CurrencyPrice. Maps to ExecutionRequestBreakdownLog.InstrumentID. |
| 4 | @LiquidityAccountID | INT | NO | - | CODE-BACKED | The liquidity provider account this order is being sent to. FK to Trade.LiquidityAccounts. Excluded from Report_TCA if in (22,23) - internal/test accounts. Maps to ExecutionRequestBreakdownLog.LiquidityAccountID. |
| 5 | @OccurredAtServer | DATETIME | NO | - | CODE-BACKED | Hedge server timestamp when the order was submitted. Used in Report_TCA for time-range filtering (alongside DB-generated Occurred column). Maps to ExecutionRequestBreakdownLog.OccurredAtServer. |
| 6 | @AmountInUnits | DECIMAL(16,6) | NO | - | CODE-BACKED | Order size in instrument units. Maps to ExecutionRequestBreakdownLog.AmountInUnits. Used in Report_TCA cost calculations. |
| 7 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy hedge, 0=Sell hedge. Determines which price column (Bid or Ask) to use in slippage calculations in Report_TCA. Maps to ExecutionRequestBreakdownLog.IsBuy. |
| 8 | @IsManualRequest | BIT | NO | - | CODE-BACKED | Whether this is a manually-triggered hedge (dealing desk). @IsManualRequest=1 rows are excluded from automated TCA metrics in Report_TCA but still logged. Maps to ExecutionRequestBreakdownLog.IsManualRequest. |
| 9 | @ProviderPriceBid | dtPrice | NO | - | CODE-BACKED | The LP's quoted BID price at the time the order was sent (dbo.dtPrice high-precision). For BUY hedge orders: the ask side is relevant; for SELL: the bid. Maps to ExecutionRequestBreakdownLog.ProviderPriceBid. |
| 10 | @ProviderPriceAsk | dtPrice | NO | - | CODE-BACKED | The LP's quoted ASK price at the time the order was sent. Maps to ExecutionRequestBreakdownLog.ProviderPriceAsk. |
| 11 | @ExposureID | INT | YES | NULL | CODE-BACKED | Optional exposure batch ID for exposure-based hedging flows (CBH path). NULL for single-order hedge requests. Maps to ExecutionRequestBreakdownLog.ExposureID. |
| 12 | @MarketPriceRateID | BIGINT | YES | NULL | CODE-BACKED | ID of the market price rate record active at request time. Changed from INT to BIGINT in 2012 (FB 17303). Used for cross-referencing the rate snapshot. Maps to ExecutionRequestBreakdownLog.MarketPriceRateID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.CurrencyPrice | Reader (NOLOCK) | Reads live Bid/Ask for @InstrumentID at INSERT time - the eToro price snapshot |
| - | Hedge.ExecutionRequestBreakdownLog | Writer (INSERT) | Inserts one TCA request record |

### 5.2 Referenced By (other objects point to this)

Not found in SQL repo. PROD\BIadmins holds VIEW DEFINITION. Called from the hedge server application on every order submission.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.LogHedgeExecutionRequest (procedure)
|-- Trade.CurrencyPrice (table) [READ - live eToro Bid/Ask for InstrumentID]
+-- Hedge.ExecutionRequestBreakdownLog (table) [INSERT - TCA request snapshot]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | Read: current eToro Bid/Ask for the instrument at request time |
| Hedge.ExecutionRequestBreakdownLog | Table | INSERT target for request-side TCA record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from hedge server application on each order submission. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INSERT...SELECT FROM Trade.CurrencyPrice | Live price lookup | eToroPriceBid/Ask are read at DB insert time, not passed as parameters. If CurrencyPrice has 0 rows for @InstrumentID, no row is inserted (silent failure). |
| No TRY/CATCH | Error propagation | Exceptions propagate directly to the caller (unlike LogExecution which has explicit THROW). |

---

## 8. Sample Queries

### 8.1 Log a buy hedge order request
```sql
EXEC [Hedge].[LogHedgeExecutionRequest]
    @HedgeID             = 998916,
    @HedgeServerID       = 1,
    @InstrumentID        = 1,
    @LiquidityAccountID  = 10,
    @OccurredAtServer    = GETUTCDATE(),
    @AmountInUnits       = 100000.0,
    @IsBuy               = 1,
    @IsManualRequest     = 0,
    @ProviderPriceBid    = 1.08520,
    @ProviderPriceAsk    = 1.08540,
    @MarketPriceRateID   = 9876543210
```

### 8.2 Check recent request log entries
```sql
SELECT TOP 20 HedgeID, HedgeServerID, InstrumentID, LiquidityAccountID,
       OccurredAtServer, AmountInUnits, IsBuy,
       eToroPriceBid, eToroPriceAsk,
       ProviderPriceBid, ProviderPriceAsk,
       eToroPriceBid - ProviderPriceBid AS BidMarkup,
       ProviderPriceAsk - eToroPriceAsk AS AskMarkup
FROM [Hedge].[ExecutionRequestBreakdownLog] WITH (NOLOCK)
ORDER BY Occurred DESC
```

### 8.3 Preview the eToro price that would be captured for an instrument
```sql
SELECT InstrumentID, Bid AS eToroPriceBid, Ask AS eToroPriceAsk
FROM [Trade].[CurrencyPrice] WITH (NOLOCK)
WHERE InstrumentID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.LogHedgeExecutionRequest | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.LogHedgeExecutionRequest.sql*
