# Hedge.LogHedgeExecutionResponse

> TCA response-side writer: inserts one row into Hedge.ExecutionResponseBreakdownLog per LP fill/rejection received, capturing eToro's live bid/ask alongside both the provider's quoted prices (at request time) and the actual execution prices (at fill time) - the "after" half of the TCA slippage framework.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.ExecutionResponseBreakdownLog; reads live price from Trade.CurrencyPrice |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.LogHedgeExecutionResponse` is the second half of eToro's hedge TCA (Transaction Cost Analysis) logging framework. When the hedge system receives a fill confirmation or rejection from a liquidity provider, this procedure fires to snapshot the pricing environment at response time, recording both the provider's quoted prices (passed from the original request) AND the actual execution prices from the fill confirmation.

Where `Hedge.LogHedgeExecutionRequest` creates the "before" record (prices when order was sent), this procedure creates the "after" record (prices when order was filled). Together, joined on HedgeID, they form the complete TCA pair that powers `Hedge.Report_TCA` slippage analysis.

**Key additions vs the Request procedure**: `@ExecutionPriceBid` / `@ExecutionPriceAsk` (the actual fill prices, which may differ from the quoted prices due to slippage), `@WasOpened` (fill success flag), `@TradeID` / `@OrderID` (LP-assigned identifiers for reconciliation), `@OccurredAtProvider` (LP's own timestamp), and `@ParentHedgeID` (parent hedge order reference for order chains).

Like the request procedure, eToro's live bid/ask is read from `Trade.CurrencyPrice` at INSERT time, capturing any price movement between when the order was sent and when the fill was received.

The procedure was updated on 2012-09-02 by Yitzchak Wahnon (FB 17303) to change MarketPriceRateID from INT to BIGINT (same change as the Request variant).

---

## 2. Business Logic

### 2.1 Quoted Price vs Execution Price (Slippage Capture)

**What**: Two pairs of provider prices are captured: the quoted prices at request time AND the actual execution prices, enabling direct slippage measurement.

**Columns/Parameters Involved**: `@ProviderPriceBid`, `@ProviderPriceAsk`, `@ExecutionPriceBid`, `@ExecutionPriceAsk`

**Rules**:
- `@ProviderPriceBid` / `@ProviderPriceAsk`: the LP's quoted prices at the time the order was SENT (re-provided by the caller at response time for pairing).
- `@ExecutionPriceBid` / `@ExecutionPriceAsk`: the actual fill prices from the LP's execution report. These may differ from the quoted prices.
- **Slippage** = ExecutionPrice - ProviderQuotedPrice (at request time). Adverse slippage: provider filled at a worse price than quoted.
- In Report_TCA: `ExecToRequestDelayPipsDiff` = `-(Req.ProviderPriceAsk - Res.ExecutionPriceAsk) * 10^Precision` for buys.
- eToroPriceBid / eToroPriceAsk at response time: read from `Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID`. This second snapshot measures how much eToro's price moved during the order's time-in-market.

### 2.2 WasOpened Flag and Successful Fill Identification

**What**: Distinguishes between successful executions and rejections/close orders.

**Columns/Parameters Involved**: `@WasOpened`

**Rules**:
- `@WasOpened = 1`: The LP successfully opened (or continued) the position - a fill event.
- `@WasOpened = 0`: The LP rejected the order, or this is a close/sell response where the position was closed (not "opened" in the traditional sense).
- `Hedge.ExecutionResponseBreakdownLog` has a filtered NC index on HedgeID WHERE WasOpened=1, optimizing lookups of successful fills.
- Report_TCA uses `Res.WasOpened = 1` to filter for successful execution pairs when computing slippage metrics.

### 2.3 TCA Slippage Calculation

**What**: This record, paired with the corresponding ExecutionRequestBreakdownLog row, enables Report_TCA slippage computations.

**Columns/Parameters Involved**: `HedgeID`, `IsBuy`, `AmountInUnits`, provider price columns, execution price columns

**Rules**:
- Join: `ExecutionRequestBreakdownLog.HedgeID = ExecutionResponseBreakdownLog.HedgeID`.
- FULL JOIN used in Report_TCA to handle unpaired rows.
- BUY slippage: `-(Req.ProviderPriceAsk - Res.ExecutionPriceAsk) * 10^Precision` (negative = adverse, provider raised ASK).
- SELL slippage: `(Req.ProviderPriceBid - Res.ExecutionPriceBid) * 10^Precision` (positive = adverse, provider lowered BID).
- **Cost calculation**: SlippagePips converted to monetary cost: `SlippagePips / 10^Precision * AmountInUnits * USDRate`.

**Diagram**:
```
LP sends execution confirmation (fill/reject)
  |
  | EXEC Hedge.LogHedgeExecutionResponse(
  |   @HedgeID, ..., @WasOpened, @TradeID, @OrderID,
  |   @ProviderPriceBid, @ProviderPriceAsk,   -- quoted at request time
  |   @ExecutionPriceBid, @ExecutionPriceAsk,  -- actual fill prices
  |   @OccurredAtProvider, @ParentHedgeID)
  |
  | INSERT INTO Hedge.ExecutionResponseBreakdownLog
  |   SELECT @HedgeID, ..., Bid AS eToroPriceBid, Ask AS eToroPriceAsk,
  |          @ProviderPriceBid, @ProviderPriceAsk,
  |          @ExecutionPriceBid, @ExecutionPriceAsk, ...
  |   FROM Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID
  v
Hedge.ExecutionResponseBreakdownLog (1 row: response-side TCA snapshot)
  |
  +-> Report_TCA: JOIN on HedgeID with ExecutionRequestBreakdownLog
  +-> Slippage = ExecutionPrice - ProviderQuotedPrice (at request)
  +-> eToro markup = eToro price - Provider mid at both request and response time
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INT | NO | - | CODE-BACKED | Internal hedge order ID. TCA join key: links this response to the corresponding ExecutionRequestBreakdownLog row. Maps to ExecutionResponseBreakdownLog.HedgeID. |
| 2 | @HedgeServerID | INT | NO | - | CODE-BACKED | Hedge server instance that received this fill. Maps to ExecutionResponseBreakdownLog.HedgeServerID. |
| 3 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument being hedged. Used to read eToro's live price from Trade.CurrencyPrice at INSERT time. Maps to ExecutionResponseBreakdownLog.InstrumentID. |
| 4 | @LiquidityAccountID | INT | NO | - | CODE-BACKED | LP account that filled the order. Maps to ExecutionResponseBreakdownLog.LiquidityAccountID. |
| 5 | @AmountInUnits | DECIMAL(16,6) | NO | - | CODE-BACKED | Order size in units. Used in cost calculations: SlippagePips * AmountInUnits = total slippage cost. Maps to ExecutionResponseBreakdownLog.AmountInUnits. |
| 6 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy, 0=Sell. Determines which price column (Bid or Ask) applies in slippage calculation. Maps to ExecutionResponseBreakdownLog.IsBuy. |
| 7 | @WasOpened | BIT | NO | - | CODE-BACKED | 1=LP successfully opened/filled the position; 0=rejected or closed. Filtered NC index on HedgeID WHERE WasOpened=1. Maps to ExecutionResponseBreakdownLog.WasOpened. |
| 8 | @TradeID | VARCHAR(50) | NO | - | CODE-BACKED | LP-assigned trade identifier from the execution confirmation (FIX TradeID or equivalent). Used for reconciliation with LP trade statements. Maps to ExecutionResponseBreakdownLog.TradeID. |
| 9 | @OrderID | VARCHAR(50) | NO | - | CODE-BACKED | LP-assigned order identifier from the execution confirmation. Maps to ExecutionResponseBreakdownLog.OrderID. |
| 10 | @OccurredAtProvider | DATETIME | NO | - | CODE-BACKED | LP's own timestamp for when the execution occurred. May differ from @OccurredAtServer due to network latency. Maps to ExecutionResponseBreakdownLog.OccurredAtProvider. |
| 11 | @OccurredAtServer | DATETIME | NO | - | CODE-BACKED | Hedge server timestamp when the execution response was received. Maps to ExecutionResponseBreakdownLog.OccurredAtServer. |
| 12 | @IsManual | BIT | NO | - | CODE-BACKED | Whether this is a manual dealing desk execution response. Excluded from automated TCA metrics in Report_TCA. Maps to ExecutionResponseBreakdownLog.IsManual. |
| 13 | @ProviderPriceBid | dtPrice | NO | - | CODE-BACKED | LP's quoted BID price at the time the order was originally sent (re-provided by caller at response time). Used as the "before" price in slippage calculation. Maps to ExecutionResponseBreakdownLog.ProviderPriceBid. |
| 14 | @ProviderPriceAsk | dtPrice | NO | - | CODE-BACKED | LP's quoted ASK price at the time the order was originally sent. Maps to ExecutionResponseBreakdownLog.ProviderPriceAsk. |
| 15 | @ExecutionPriceBid | dtPrice | YES | NULL | CODE-BACKED | The actual BID price at which the LP executed the order. May differ from ProviderPriceBid (slippage). NULL if execution failed. Maps to ExecutionResponseBreakdownLog.ExecutionPriceBid. |
| 16 | @ExecutionPriceAsk | dtPrice | YES | NULL | CODE-BACKED | The actual ASK price at which the LP executed the order. May differ from ProviderPriceAsk. NULL if execution failed. Maps to ExecutionResponseBreakdownLog.ExecutionPriceAsk. |
| 17 | @MarketPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Market price rate snapshot ID at response time. Changed from INT to BIGINT in 2012 (FB 17303). Maps to ExecutionResponseBreakdownLog.MarketPriceRateID. |
| 18 | @ParentHedgeID | INT | YES | NULL | CODE-BACKED | Parent hedge order ID for order chains (child orders in a multi-step execution). NULL for top-level hedge orders. Added in a separate refactoring (comment: "Add ParentHedgeID to SP"). Maps to ExecutionResponseBreakdownLog.ParentHedgeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.CurrencyPrice | Reader (NOLOCK) | Reads live Bid/Ask for @InstrumentID at INSERT time - eToro price snapshot at response time |
| - | Hedge.ExecutionResponseBreakdownLog | Writer (INSERT) | Inserts one TCA response record |

### 5.2 Referenced By (other objects point to this)

Not found in SQL repo. PROD\BIadmins holds VIEW DEFINITION. Called from the hedge server application on every LP execution response.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.LogHedgeExecutionResponse (procedure)
|-- Trade.CurrencyPrice (table) [READ - live eToro Bid/Ask for InstrumentID at response time]
+-- Hedge.ExecutionResponseBreakdownLog (table) [INSERT - TCA response snapshot]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | Read: current eToro Bid/Ask for the instrument at LP response time |
| Hedge.ExecutionResponseBreakdownLog | Table | INSERT target for response-side TCA record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from hedge server application on each LP execution response. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INSERT...SELECT FROM Trade.CurrencyPrice | Live price lookup | eToroPriceBid/Ask at response time is read at DB insert time, not passed. If CurrencyPrice has 0 rows for @InstrumentID, no row is inserted (silent failure). |
| No TRY/CATCH | Error propagation | Exceptions propagate directly to caller (same as Request variant). |

---

## 8. Sample Queries

### 8.1 Log a successful fill response
```sql
EXEC [Hedge].[LogHedgeExecutionResponse]
    @HedgeID             = 998916,
    @HedgeServerID       = 1,
    @InstrumentID        = 1,
    @LiquidityAccountID  = 10,
    @AmountInUnits       = 100000.0,
    @IsBuy               = 1,
    @WasOpened           = 1,
    @TradeID             = 'ZBFX-TRADE-99123',
    @OrderID             = 'ZBFX-ORD-88456',
    @OccurredAtProvider  = GETUTCDATE(),
    @OccurredAtServer    = GETUTCDATE(),
    @IsManual            = 0,
    @ProviderPriceBid    = 1.08520,  -- quoted at request time
    @ProviderPriceAsk    = 1.08540,
    @ExecutionPriceBid   = 1.08518,  -- actual fill (2 pips slippage on bid)
    @ExecutionPriceAsk   = 1.08542,
    @MarketPriceRateID   = 9876543210
```

### 8.2 Compute slippage for recent responses
```sql
SELECT r.HedgeID,
       r.InstrumentID,
       r.IsBuy,
       req.ProviderPriceAsk AS QuotedAsk,
       r.ExecutionPriceAsk AS FilledAsk,
       CASE WHEN r.IsBuy = 1
            THEN -(req.ProviderPriceAsk - r.ExecutionPriceAsk) * 10000
            ELSE (req.ProviderPriceBid - r.ExecutionPriceBid) * 10000
       END AS SlippagePips
FROM [Hedge].[ExecutionResponseBreakdownLog] r WITH (NOLOCK)
JOIN [Hedge].[ExecutionRequestBreakdownLog] req WITH (NOLOCK)
    ON req.HedgeID = r.HedgeID
WHERE r.WasOpened = 1
  AND r.Occurred >= DATEADD(day, -1, GETUTCDATE())
ORDER BY r.Occurred DESC
```

### 8.3 Preview eToro price that would be captured for an instrument
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
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.LogHedgeExecutionResponse | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.LogHedgeExecutionResponse.sql*
