# History.LogHedgeServerOrderToProvider

> Stage-4 hedge pipeline writer: logs the hedge order dispatch event by reading eToro's current bid/ask prices from Trade.CurrencyPrice and inserting an EntryType=4 row into History.HedgingBreakdownLog alongside the provider's market prices at the moment of order submission.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes EntryType=4 to History.HedgingBreakdownLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogHedgeServerOrderToProvider` writes stage 4 of the hedging pipeline diagnostic log - the moment the hedge server dispatches an order to the liquidity provider via FIX. This is the pivot point in the hedging lifecycle: before stage 4, activity is internal (customer order, exposure calculation); from stage 4 onwards, the order is live in the market.

What makes this procedure unique among the three hedge SQL writers is that it does NOT receive the eToro prices as parameters. Instead, it reads them **live** from `Trade.CurrencyPrice` at the exact moment of execution (`SELECT Bid, Ask FROM Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID`). This captures eToro's internal prices at the precise instant the order was sent to the provider - creating the baseline for slippage analysis against stage 5 execution prices.

The stage 4 row therefore contains four price fields: two from eToro's internal book (`eToroPriceBid`, `eToroPriceAsk` - read from Trade.CurrencyPrice) and two from the provider's market (`MarketPriceBid`, `MarketPriceAsk` - passed as parameters). The spread between eToro's prices and the market prices at dispatch reflects the spread/markup eToro captures on the hedge.

---

## 2. Business Logic

### 2.1 Stage 4 - Order Dispatch with Dual Price Capture

**What**: Captures both eToro's internal prices (from DB) and the provider's market prices (from parameters) at the moment a hedge order is sent.

**Columns/Parameters Involved**: `@MarketPriceBid`, `@MarketPriceAsk`, `eToroPriceBid/Ask` (auto-read)

**Rules**:
- EntryType=4 is hardcoded
- eToroPriceBid and eToroPriceAsk are read from Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID - not passed as parameters
- @MarketPriceBid and @MarketPriceAsk are passed by the hedge server (provider's market prices at dispatch time)
- If no row exists in Trade.CurrencyPrice for @InstrumentID, the INSERT will not execute (SELECT returns empty)
- HedgedInstrument = @InstrumentID (direct hedge assumed at this stage)
- No @Occurred parameter; Occurred defaults to GETUTCDATE() at INSERT time

**Diagram**:
```
Stage 4 - Order Dispatch:
    Hedge Server sends order to provider via FIX
    |
    -> EXEC History.LogHedgeServerOrderToProvider(
           @HedgeServerID, @InstrumentID, @AmountInUnitsDecimal,
           @OrderID, @LiquidityAccountID, @MarketPriceBid, @MarketPriceAsk)
    |
    -> SELECT Bid, Ask FROM Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID
    |                    ^ eToro's live internal price at this exact moment
    |
    -> INSERT HedgingBreakdownLog (EntryType=4,
           eToroPriceBid = Bid,        <- eToro's internal bid
           eToroPriceAsk = Ask,        <- eToro's internal ask
           MarketPriceBid = @MarketPriceBid,  <- provider's market bid
           MarketPriceAsk = @MarketPriceAsk,  <- provider's market ask
           ...)

Slippage analysis:
    eToroPriceBid (stage 4) vs MarketPriceBid (stage 5 execution)
    -> reveals actual price difference between when order was placed and when filled
```

### 2.2 Silent Failure When Instrument Price Not Found

**What**: If Trade.CurrencyPrice has no row for @InstrumentID, the INSERT silently does not execute.

**Columns/Parameters Involved**: `@InstrumentID`

**Rules**:
- The INSERT...SELECT pattern means: if the SELECT returns 0 rows, 0 rows are inserted
- No error handling, no RETURN value - the caller receives no signal of failure
- In practice, Trade.CurrencyPrice should always have a row for any actively traded instrument
- A missing row would result in the stage 4 log entry being silently skipped, creating a gap in the HedgingBreakdownLog pipeline for that OrderID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | int | NO | - | CODE-BACKED | ID of the hedge server dispatching the order to the provider. Stored as History.HedgingBreakdownLog.HedgeServerID. Identifies which server in a multi-server deployment submitted this order. |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Trading instrument being hedged. Used as the lookup key in Trade.CurrencyPrice to read eToro's current bid/ask prices. Also stored as both InstrumentID and HedgedInstrument in the log row (direct hedge assumed). |
| 3 | @AmountInUnitsDecimal | decimal(16,6) | NO | - | CODE-BACKED | Size of the hedge order in instrument units, dispatched to the provider. Enables verification against the executed amount in stage 5. |
| 4 | @OrderID | varchar(50) | NO | - | CODE-BACKED | FIX protocol order identifier used to correlate all hedge pipeline stages. This is the key that links the stage 4 dispatch row with stage 5 execution and stage 6 confirmation rows for the same hedge trade. |
| 5 | @LiquidityAccountID | int | NO | - | CODE-BACKED | ID of the liquidity provider account receiving the order. Implicit FK to LP account configuration. |
| 6 | @MarketPriceBid | dtPrice | NO | - | CODE-BACKED | Liquidity provider's current market bid price at the time of order dispatch, as reported by the provider feed. Uses the dtPrice UDT. Stored alongside eToro's internal bid (auto-read from Trade.CurrencyPrice) for contemporaneous comparison. |
| 7 | @MarketPriceAsk | dtPrice | NO | - | CODE-BACKED | Liquidity provider's current market ask price at the time of order dispatch. Uses the dtPrice UDT. Compared against eToro's internal ask (auto-read from Trade.CurrencyPrice) to measure bid/ask spread markup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.CurrencyPrice | Read (SELECT) | Reads current eToro bid/ask prices for the instrument at order dispatch time |
| all params | History.HedgingBreakdownLog | Write target | Inserts EntryType=4 (order dispatch) row with dual price capture |
| @InstrumentID | Trade.Instrument | Implicit | Identifies the instrument being hedged |
| @MarketPriceBid, @MarketPriceAsk | dbo.dtPrice | Type | Custom price UDT |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | (application call) | Application | Called when the hedge server dispatches a FIX order to the liquidity provider. Not referenced by any SSDT procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogHedgeServerOrderToProvider (procedure)
├── History.HedgingBreakdownLog (table)
└── Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.HedgingBreakdownLog | Table | INSERT target - stage 4 order dispatch row |
| Trade.CurrencyPrice | Table | SELECT - reads current eToro Bid/Ask for @InstrumentID at dispatch time |
| dbo.dtPrice | User Defined Type | Parameter type for @MarketPriceBid and @MarketPriceAsk |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | Application | Calls this procedure when dispatching hedge orders to liquidity providers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No TRY/CATCH, no RETURN value. Uses INSERT...SELECT from Trade.CurrencyPrice - silent no-op if no price row found. EntryType=4 and HedgedInstrument=@InstrumentID are hardcoded.

---

## 8. Sample Queries

### 8.1 Find stage 4 order dispatch entries with both eToro and market prices

```sql
SELECT TOP 20
    EntryID,
    HedgeServerID,
    InstrumentID,
    OrderID,
    LiquidityAccountID,
    AmountInUnitsDecimal,
    eToroPriceBid,
    eToroPriceAsk,
    MarketPriceBid,
    MarketPriceAsk,
    Occurred
FROM History.HedgingBreakdownLog WITH (NOLOCK)
WHERE EntryType = 4
ORDER BY EntryID DESC
```

### 8.2 Full hedge pipeline for a recent order (stages 4-6)

```sql
SELECT
    EntryType,
    EntryID,
    HedgeServerID,
    InstrumentID,
    OrderID,
    TradeID,
    eToroPriceBid,
    eToroPriceAsk,
    MarketPriceBid,
    MarketPriceAsk,
    Occurred
FROM History.HedgingBreakdownLog WITH (NOLOCK)
WHERE OrderID = 'your_order_id'
ORDER BY EntryType
```

### 8.3 Spread between eToro internal and market prices at order dispatch

```sql
SELECT TOP 20
    InstrumentID,
    OrderID,
    eToroPriceBid,
    MarketPriceBid,
    (eToroPriceBid - MarketPriceBid) AS BidMarkup,
    eToroPriceAsk,
    MarketPriceAsk,
    (MarketPriceAsk - eToroPriceAsk) AS AskMarkup,
    Occurred
FROM History.HedgingBreakdownLog WITH (NOLOCK)
WHERE EntryType = 4
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.LogHedgeServerOrderToProvider | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogHedgeServerOrderToProvider.sql*
