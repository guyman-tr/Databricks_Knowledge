# History.LogHedgeComfirmation

> Stage-6 hedge pipeline writer: records the final confirmation event received from the liquidity provider into History.HedgingBreakdownLog with EntryType=6, completing the audit trail for a hedge operation.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes EntryType=6 to History.HedgingBreakdownLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.LogHedgeComfirmation` writes stage 6 of the hedging pipeline diagnostic log - the final confirmation that arrives from the liquidity provider after a hedge order is executed. In the six-stage hedging lifecycle recorded in `History.HedgingBreakdownLog`, stage 6 represents the provider's acknowledgment that the trade has been confirmed and settled on their side.

This procedure exists as one of three SQL writer procedures (stages 4, 5, 6) that complete the hedge lifecycle record. It is called by the hedge server application after receiving the provider's FIX confirmation message. The `OrderID` and `TradeID` fields enable engineers to correlate this confirmation row with the order submission (stage 4) and execution (stage 5) rows for the same hedge trade.

**Note**: The procedure name contains a typo - "Comfirmation" instead of "Confirmation". This is the actual deployed procedure name in SQL Server and must be referenced exactly as `History.LogHedgeComfirmation` (with the typo) when calling it.

Unlike stage 5 (`LogHedgeProviderExecutedOrder`), this procedure does not accept an `@Occurred` parameter - the timestamp is database-generated (`GETUTCDATE()` default). This means the confirmation timestamp reflects when the DB row was written, not necessarily when the provider confirmation was generated.

---

## 2. Business Logic

### 2.1 Stage 6 - Confirmation in the Six-Stage Hedge Pipeline

**What**: Records the final stage of hedge order processing - the provider's trade confirmation.

**Columns/Parameters Involved**: `@HedgeServerID`, `@OrderID`, `@TradeID`, `@WasOpened`, `@MarketPriceAsk`, `@MarketPriceBid`

**Rules**:
- EntryType=6 is hardcoded in the INSERT - not a parameter
- HedgedInstrument is set to @InstrumentID (same value) - direct hedge with no cross-instrument proxy
- @WasOpened: indicates whether this confirmation is for an opened (1) or closed (0) hedge position
- @MarketPriceAsk / @MarketPriceBid: the provider's market bid/ask at confirmation time (dtPrice UDT)
- Occurred is NOT a parameter - defaults to GETUTCDATE() (DB server timestamp at INSERT time)
- No error handling; no RETURN value

**Diagram**:
```
Hedge Pipeline Stage 6 (Confirmation):
Stage 4 (LogHedgeServerOrderToProvider) -> EntryType=4, eToro prices + market prices
Stage 5 (LogHedgeProviderExecutedOrder) -> EntryType=5, execution prices + explicit Occurred
Stage 6 (LogHedgeComfirmation)          -> EntryType=6, confirmation prices + DB-generated Occurred
    |
    -> HedgingBreakdownLog row: (EntryType=6, HedgeServerID, InstrumentID, AmountInUnitsDecimal,
                                  OrderID, LiquidityAccountID, TradeID, WasOpened,
                                  HedgedInstrument=InstrumentID, MarketPriceAsk, MarketPriceBid)
```

### 2.2 Timestamp Difference from Stage 5

**What**: Unlike stage 5, stage 6 does not receive an explicit timestamp, creating a subtle timing difference.

**Columns/Parameters Involved**: `Occurred` (implicit - not a parameter)

**Rules**:
- Stage 5 (@Occurred explicit): timestamp = when the execution event occurred at the provider side
- Stage 6 (Occurred = GETUTCDATE() default): timestamp = when the DB row was written (DB server time)
- The difference between stage 5's Occurred and stage 6's Occurred is the latency between provider execution and confirmation receipt by the hedge server

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | int | NO | - | CODE-BACKED | ID of the hedge server that received the provider confirmation. Stored as History.HedgingBreakdownLog.HedgeServerID. Enables filtering the full hedge pipeline for operations handled by a specific server. |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Customer's trading instrument. Stored as both InstrumentID and HedgedInstrument in this stage (same value - direct hedge assumed at confirmation). Implicit FK to Trade.Instrument. |
| 3 | @AmountInUnitsDecimal | decimal(16,6) | NO | - | CODE-BACKED | Size of the confirmed hedge position in units of the instrument. Consistent with the same field in stages 4 and 5 for the same OrderID. |
| 4 | @OrderID | varchar(50) | NO | - | CODE-BACKED | FIX protocol order identifier. Primary correlation key to link stage 6 confirmation with stage 4 (order dispatch) and stage 5 (execution) rows. Used to reconstruct the full hedge lifecycle for a single order. |
| 5 | @LiquidityAccountID | int | NO | - | CODE-BACKED | ID of the liquidity provider account used for this hedge. Implicit FK to liquidity provider account configuration. |
| 6 | @TradeID | varchar(50) | NO | - | CODE-BACKED | Provider's trade identifier for the confirmed execution. Matches the TradeID from stage 5 (LogHedgeProviderExecutedOrder). Used to correlate with provider-side records. |
| 7 | @WasOpened | int | NO | - | CODE-BACKED | Direction of the confirmed hedge. 1=position was opened with the provider (hedge entry); 0=position was closed with the provider (hedge exit). Stored as tinyint in the target table. |
| 8 | @MarketPriceAsk | dtPrice | NO | - | CODE-BACKED | Liquidity provider's ask price at confirmation time. Uses the dtPrice user-defined type. Compared against the execution prices in stage 5 and eToro's prices in stage 4 for slippage analysis. |
| 9 | @MarketPriceBid | dtPrice | NO | - | CODE-BACKED | Liquidity provider's bid price at confirmation time. Uses the dtPrice user-defined type. Paired with MarketPriceAsk for full bid/ask context at confirmation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| all params | History.HedgingBreakdownLog | Write target | Inserts EntryType=6 (confirmation) row |
| @InstrumentID | Trade.Instrument | Implicit | Identifies the instrument being confirmed |
| @LiquidityAccountID | Liquidity provider config | Implicit | Identifies the LP account |
| @MarketPriceAsk, @MarketPriceBid | dbo.dtPrice | Type | Custom price UDT for bid/ask fields |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | (application call) | Application | Called when the FIX confirmation arrives from the liquidity provider. Not referenced by any SSDT procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogHedgeComfirmation (procedure)
└── History.HedgingBreakdownLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.HedgingBreakdownLog | Table | INSERT target - stage 6 confirmation row |
| dbo.dtPrice | User Defined Type | Parameter type for @MarketPriceAsk and @MarketPriceBid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | Application | Calls this procedure when provider confirmation received |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No TRY/CATCH, no RETURN value. EntryType=6 and HedgedInstrument=@InstrumentID are hardcoded in the INSERT.

**Name typo**: The procedure is deployed as `LogHedgeComfirmation` (missing the 'n' in Confirmation). All callers must use this exact spelling.

---

## 8. Sample Queries

### 8.1 Find stage 6 confirmations for a specific OrderID

```sql
SELECT
    EntryID,
    EntryType,
    HedgeServerID,
    InstrumentID,
    OrderID,
    TradeID,
    WasOpened,
    MarketPriceBid,
    MarketPriceAsk,
    Occurred
FROM History.HedgingBreakdownLog WITH (NOLOCK)
WHERE OrderID = 'your_order_id'
ORDER BY EntryType
```

### 8.2 Reconstruct full hedge pipeline for a recent confirmation

```sql
SELECT
    EntryID,
    EntryType,
    HedgeServerID,
    InstrumentID,
    OrderID,
    TradeID,
    WasOpened,
    eToroPriceBid,
    eToroPriceAsk,
    MarketPriceBid,
    MarketPriceAsk,
    Occurred
FROM History.HedgingBreakdownLog WITH (NOLOCK)
WHERE OrderID IN (
    SELECT TOP 5 OrderID
    FROM History.HedgingBreakdownLog WITH (NOLOCK)
    WHERE EntryType = 6
    ORDER BY EntryID DESC
)
ORDER BY OrderID, EntryType
```

### 8.3 Measure confirmation latency (time from execution to confirmation)

```sql
SELECT
    e5.OrderID,
    e5.InstrumentID,
    e5.Occurred AS ExecutionTime,
    e6.Occurred AS ConfirmationTime,
    DATEDIFF(MILLISECOND, e5.Occurred, e6.Occurred) AS LatencyMs
FROM History.HedgingBreakdownLog e5 WITH (NOLOCK)
JOIN History.HedgingBreakdownLog e6 WITH (NOLOCK)
    ON e6.OrderID = e5.OrderID
    AND e6.EntryType = 6
WHERE e5.EntryType = 5
ORDER BY e5.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.LogHedgeComfirmation | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.LogHedgeComfirmation.sql*
