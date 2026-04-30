# History.LogHedgeProviderExecutedOrder

> Stage-5 hedge pipeline writer: records the liquidity provider's trade execution event into History.HedgingBreakdownLog with EntryType=5, capturing execution prices, the FIX TradeID, and an explicit provider-side timestamp.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes EntryType=5 to History.HedgingBreakdownLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogHedgeProviderExecutedOrder` writes stage 5 of the hedging pipeline diagnostic log - the moment the liquidity provider executes the hedge order. In the six-stage hedging lifecycle, stage 5 represents the provider's fill: the actual trade has been matched on the provider's exchange or crossing network, and the execution price and FIX TradeID are now known.

This procedure is the most informationally rich of the three SQL hedge pipeline writers because it captures the provider-side execution prices (`@MarketPriceAsk`, `@MarketPriceBid`), the explicit execution timestamp (`@Occurred` - passed in, not DB-generated), and the `TradeID` which is the provider's own reference for this execution. By comparing these execution prices with the eToro prices captured at stage 4 (`LogHedgeServerOrderToProvider`), engineers can measure hedge slippage.

The `@Occurred` parameter is the key difference from stage 6 (`LogHedgeComfirmation`): stage 5 receives an explicit timestamp representing when the execution event occurred at the provider, not when the DB row was written.

---

## 2. Business Logic

### 2.1 Stage 5 - Provider Execution in the Six-Stage Hedge Pipeline

**What**: Records the execution fill from the liquidity provider, including execution prices and the provider's trade reference.

**Columns/Parameters Involved**: `@OrderID`, `@TradeID`, `@WasOpened`, `@MarketPriceAsk`, `@MarketPriceBid`, `@Occurred`

**Rules**:
- EntryType=5 is hardcoded - not a parameter
- HedgedInstrument is set to @InstrumentID (same value - direct hedge)
- @Occurred is explicit (unlike stage 6 which uses GETUTCDATE()); represents the provider-side execution timestamp
- @MarketPriceAsk / @MarketPriceBid use dtPrice UDT with NULL as default (optional fields, though typically populated for executions)
- @WasOpened: tinyint - 1=position opened with provider (hedge entry), 0=position closed (hedge exit)
- No error handling; no RETURN value

**Diagram**:
```
Hedge Pipeline Stages 4-6:
    |
    Stage 4: LogHedgeServerOrderToProvider
        EntryType=4, eToro prices from Trade.CurrencyPrice, market bid/ask
        |
    Stage 5: LogHedgeProviderExecutedOrder  <- THIS PROCEDURE
        EntryType=5, execution prices from provider fill
        @Occurred = provider-side execution timestamp
        @TradeID = provider's fill reference number
        |
    Stage 6: LogHedgeComfirmation
        EntryType=6, confirmation prices, Occurred = GETUTCDATE()
```

### 2.2 Execution Timestamp Semantics

**What**: The @Occurred parameter carries the provider's reported execution time, distinct from when the DB row is written.

**Columns/Parameters Involved**: `@Occurred`

**Rules**:
- @Occurred is passed by the hedge server application from the FIX execution report timestamp
- This differs from stage 6 where Occurred = GETUTCDATE() (DB INSERT time)
- The gap between stage 4's INSERT time and stage 5's @Occurred = round-trip time for the hedge order to reach the provider and be filled
- Comparing @Occurred across multiple stage-5 entries for the same OrderID would indicate duplicate execution reports

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | int | NO | - | CODE-BACKED | ID of the hedge server that received the execution fill from the provider. Stored as History.HedgingBreakdownLog.HedgeServerID. Correlates with the same field in stage 4 and stage 6 for the same OrderID. |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Customer's trading instrument. Stored as both InstrumentID and HedgedInstrument in this stage (same value - direct hedge). Implicit FK to Trade.Instrument. |
| 3 | @OrderID | varchar(50) | NO | - | CODE-BACKED | FIX protocol order identifier. Primary key for correlating all six pipeline stages for a single hedge operation. Links this execution to the order dispatched in stage 4 and the confirmation in stage 6. |
| 4 | @AmountInUnitsDecimal | decimal(16,6) | NO | - | CODE-BACKED | Size of the executed hedge in instrument units. Matches the amount ordered in stage 4; confirming they match validates full execution (no partial fills). |
| 5 | @LiquidityAccountID | int | NO | - | CODE-BACKED | ID of the liquidity provider account that executed the trade. Matches the LiquidityAccountID from stage 4. |
| 6 | @TradeID | varchar(50) | NO | - | CODE-BACKED | Liquidity provider's own reference number for this execution (FIX ExecID or similar). This is the provider's identifier - distinct from @OrderID which is eToro's reference. Used to cross-reference with provider-side records and reconciliations. |
| 7 | @WasOpened | tinyint | NO | - | CODE-BACKED | Direction of the executed hedge. 1=the provider opened a position with eToro (hedge entry - customer opened a trade); 0=the provider closed a position (hedge exit - customer closed a trade). |
| 8 | @MarketPriceAsk | dtPrice | YES | NULL | CODE-BACKED | Liquidity provider's ask price at execution time. Uses the dtPrice UDT. NULL allowed (default). Compared against stage 4's eToroPriceAsk (eToro's internal ask) to measure slippage. |
| 9 | @MarketPriceBid | dtPrice | YES | NULL | CODE-BACKED | Liquidity provider's bid price at execution time. Uses the dtPrice UDT. NULL allowed (default). Compared against stage 4's eToroPriceBid to measure hedge slippage. |
| 10 | @Occurred | datetime | NO | - | CODE-BACKED | Provider-side timestamp of when the execution occurred. Passed explicitly by the hedge server (from FIX execution report). Unlike stage 6 which uses GETUTCDATE(), this timestamp reflects when the provider's exchange matched the order, not when the DB row was inserted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| all params | History.HedgingBreakdownLog | Write target | Inserts EntryType=5 (execution) row |
| @InstrumentID | Trade.Instrument | Implicit | Identifies the hedged instrument |
| @LiquidityAccountID | Liquidity provider config | Implicit | Identifies the LP account |
| @MarketPriceAsk, @MarketPriceBid | dbo.dtPrice | Type | Custom price UDT |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | (application call) | Application | Called when FIX execution report received from liquidity provider. Not referenced by any SSDT procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogHedgeProviderExecutedOrder (procedure)
└── History.HedgingBreakdownLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.HedgingBreakdownLog | Table | INSERT target - stage 5 execution row |
| dbo.dtPrice | User Defined Type | Parameter type for @MarketPriceAsk and @MarketPriceBid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | Application | Calls this procedure when provider fills the hedge order |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No TRY/CATCH, no RETURN value. EntryType=5 and HedgedInstrument=@InstrumentID are hardcoded. @MarketPriceAsk and @MarketPriceBid default to NULL.

---

## 8. Sample Queries

### 8.1 Find stage 5 executions for a specific time window

```sql
SELECT TOP 20
    EntryID,
    HedgeServerID,
    InstrumentID,
    OrderID,
    TradeID,
    AmountInUnitsDecimal,
    WasOpened,
    MarketPriceBid,
    MarketPriceAsk,
    Occurred
FROM History.HedgingBreakdownLog WITH (NOLOCK)
WHERE EntryType = 5
  AND Occurred >= DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY Occurred DESC
```

### 8.2 Compare eToro prices (stage 4) with execution prices (stage 5) to measure slippage

```sql
SELECT
    s4.OrderID,
    s4.InstrumentID,
    s4.eToroPriceBid AS EtoroBidAtDispatch,
    s4.MarketPriceBid AS MarketBidAtDispatch,
    s5.MarketPriceBid AS ExecutionBid,
    (s5.MarketPriceBid - s4.eToroPriceBid) AS BidSlippage,
    s5.Occurred AS ExecutionTime
FROM History.HedgingBreakdownLog s4 WITH (NOLOCK)
JOIN History.HedgingBreakdownLog s5 WITH (NOLOCK)
    ON s5.OrderID = s4.OrderID
    AND s5.EntryType = 5
WHERE s4.EntryType = 4
ORDER BY s5.Occurred DESC
```

### 8.3 Find hedge executions by instrument with volume summary

```sql
SELECT
    InstrumentID,
    COUNT(*) AS ExecutionCount,
    SUM(AmountInUnitsDecimal) AS TotalUnitsExecuted,
    MIN(Occurred) AS EarliestExecution,
    MAX(Occurred) AS LatestExecution
FROM History.HedgingBreakdownLog WITH (NOLOCK)
WHERE EntryType = 5
GROUP BY InstrumentID
ORDER BY ExecutionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.LogHedgeProviderExecutedOrder | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogHedgeProviderExecutedOrder.sql*
