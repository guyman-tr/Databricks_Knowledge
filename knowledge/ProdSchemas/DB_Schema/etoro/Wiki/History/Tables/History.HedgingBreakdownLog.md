# History.HedgingBreakdownLog

> Append-only diagnostic event log tracing the end-to-end lifecycle of hedge operations through 6 stages: from customer order through hedge exposure query, provider order submission, trade execution, and confirmation.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PK_HedgingBreakdownLog: CLUSTERED on EntryID (IDENTITY int) |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 2 (CLUSTERED PK on EntryID, NONCLUSTERED on Occurred) |

---

## 1. Business Meaning

This table is a diagnostic event log that records every stage of the hedging pipeline, allowing engineers and risk managers to trace exactly what happened during a hedge operation from the moment a customer order arrives until confirmation comes back from the liquidity provider.

Each hedge operation generates multiple rows in sequence, one per stage. By querying all entries for a given `OrderID` or `PositionID`, the full end-to-end flow can be reconstructed:

| Stage | EntryType | Who Writes | What Happens |
|-------|-----------|------------|--------------|
| 1 | Customer sends an order | Application code | Customer's buy/sell order enters the hedging pipeline |
| 2 | Customer trade status change | Application code | Customer position opens or closes; hedge event triggered |
| 3 | Hedge Server makes a Hedge Exposure Query | Trade.HedgeExposureQuery | Server calculates net exposure and determines hedge size needed |
| 4 | Hedge Server sends Provider an order | History.LogHedgeServerOrderToProvider | Hedge order dispatched to liquidity provider via FIX |
| 5 | Trade executed by Provider | History.LogHedgeProviderExecutedOrder | Provider confirms trade execution with execution prices |
| 6 | Confirmation arrives from Provider | History.LogHedgeComfirmation | Final confirmation received; execution audit complete |

A key diagnostic use case: comparing `eToroPriceBid`/`eToroPriceAsk` (stage 4, eToro's internal price at order time) with `MarketPriceBid`/`MarketPriceAsk` (stages 4-6, actual provider market prices) reveals slippage and price discrepancies across the hedge execution.

`HedgedInstrument` may differ from `InstrumentID` when eToro uses a proxy instrument for hedging (cross-hedging), such as using an index future to hedge multiple correlated stock positions.

0 rows in this environment - this is a live trading diagnostic log.

---

## 2. Business Logic

### 2.1 Six-Stage Hedging Pipeline

**What**: The hedging pipeline follows a defined sequence of 6 event types, each written by a specific system component.

**Columns/Parameters Involved**: `EntryType`, `OrderID`, `TradeID`, `PositionID`, `WasOpened`

**Rules**:
- FK: EntryType -> Dictionary.HedgeBreakdownType(ID) - FK is WITH NOCHECK (added retroactively; pre-existing rows may not match)
- EntryTypes 1-2 are written by application code (not SQL procedures in this repo)
- EntryType 3: written by `Trade.HedgeExposureQuery` / `Trade.HedgeExposureQueryWithActiveParent` - inserts InstrumentID, HedgeServerID, AmountInUnitsDecimal, HedgedInstrument, HedgedAmountInUnitsDecimal
- EntryType 4: written by `History.LogHedgeServerOrderToProvider` - inserts eToro's current Bid/Ask prices (from Trade.CurrencyPrice) and the provider's market Bid/Ask
- EntryType 5: written by `History.LogHedgeProviderExecutedOrder` - inserts the execution prices and FIX TradeID; Occurred is explicit (not DEFAULT)
- EntryType 6: written by `History.LogHedgeComfirmation` - final confirmation; does NOT use an explicit Occurred (relies on DEFAULT GETUTCDATE())
- `WasOpened`: tinyint indicating direction: non-null for stages 5-6 (1=position opened with provider, 0=closed)

### 2.2 Price Comparison: eToro vs. Market

**What**: EntryType 4 captures both eToro's internal price and the market price at the moment the order is dispatched, enabling slippage analysis.

**Columns/Parameters Involved**: `eToroPriceBid`, `eToroPriceAsk`, `MarketPriceBid`, `MarketPriceAsk`

**Rules**:
- `eToroPriceBid` / `eToroPriceAsk`: eToro's internal instrument prices from `Trade.CurrencyPrice` at the time of EntryType 4 (order dispatch). Only populated for EntryType 4.
- `MarketPriceBid` / `MarketPriceAsk`: actual bid/ask from the liquidity provider, populated for EntryTypes 4, 5, and 6
- Comparing eToro prices (stage 4) with market execution prices (stage 5) shows slippage
- All price columns use `dbo.dtPrice` UDT

### 2.3 Cross-Hedging Instrument Tracking

**What**: When eToro hedges a position using a proxy instrument (rather than the exact instrument), both the original and the hedging instrument are recorded.

**Columns/Parameters Involved**: `InstrumentID`, `HedgedInstrument`, `AmountInUnitsDecimal`, `HedgedAmountInUnitsDecimal`

**Rules**:
- `InstrumentID`: the customer's instrument (what the customer is trading)
- `HedgedInstrument`: the actual instrument used for hedging at the provider (may be the same as InstrumentID or a proxy)
- When InstrumentID = HedgedInstrument: direct hedge (instrument hedged directly)
- When InstrumentID != HedgedInstrument: cross-hedge (e.g., hedging a stock with an index)
- `AmountInUnitsDecimal`: customer exposure in units of InstrumentID
- `HedgedAmountInUnitsDecimal`: units actually hedged at the provider in terms of HedgedInstrument
- `NetUSDExposure`: the net USD exposure at this point in the pipeline

---

## 3. Data Overview

| Scale | Value |
|-------|-------|
| Total rows | 0 (dev/staging - no live trading) |
| Filegroup | [PRIMARY] |
| Index on Occurred | For time-range queries on recent hedge activity |

In production, this table accumulates hedge lifecycle events continuously during trading hours. Row volume is proportional to hedge activity - each hedged customer trade generates 4-6 rows (stages 3-6, plus stages 1-2 from app code).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EntryID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-incrementing. NOT FOR REPLICATION. One row per pipeline stage event. |
| 2 | EntryType | int | NO | - | VERIFIED | Pipeline stage identifier. FK to Dictionary.HedgeBreakdownType(ID) WITH NOCHECK. 1=Customer order, 2=Trade status change, 3=Hedge Exposure Query, 4=Order to Provider, 5=Provider Executed, 6=Provider Confirmation. |
| 3 | MarketPriceBid | dbo.dtPrice | YES | - | CODE-BACKED | Bid price from the liquidity provider at this pipeline stage. NULL for stage 3 (pre-order). dbo.dtPrice UDT. |
| 4 | MarketPriceAsk | dbo.dtPrice | YES | - | CODE-BACKED | Ask price from the liquidity provider. NULL for stage 3. |
| 5 | eToroPriceBid | dbo.dtPrice | YES | - | CODE-BACKED | eToro's internal instrument bid price from Trade.CurrencyPrice at order dispatch time. Only populated for EntryType=4 (LogHedgeServerOrderToProvider). Used to assess price discrepancy vs market. |
| 6 | eToroPriceAsk | dbo.dtPrice | YES | - | CODE-BACKED | eToro's internal ask price from Trade.CurrencyPrice. Only populated for EntryType=4. |
| 7 | Occurred | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp of this pipeline event. DEFAULT GETUTCDATE() - UTC (unlike History.HedgeFail which uses GETDATE()). For stage 5, passed explicitly by the caller. |
| 8 | InstrumentID | int | YES | - | CODE-BACKED | The financial instrument being hedged (the customer's instrument). Implicit FK to Trade.Instrument. |
| 9 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Customer exposure in units of InstrumentID that needs to be hedged. |
| 10 | PositionID | bigint | YES | - | CODE-BACKED | The customer position ID (bigint) that triggered this hedge pipeline. Implicit FK to Trade.Position. NULL for stages that don't have position-level context (e.g., stage 3 aggregate queries). |
| 11 | HedgeServerID | int | YES | - | CODE-BACKED | The hedge server processing this event. Implicit FK to Trade.HedgeServer. |
| 12 | OrderID | varchar(50) | YES | - | CODE-BACKED | FIX ClOrdID or order identifier assigned to the hedge order. Links stages 4, 5, and 6 for the same hedge order. |
| 13 | ParentOrderID | int | YES | - | CODE-BACKED | Parent order chain identifier. int (not varchar like HedgeFail.TradeID) - internal numeric order hierarchy. NULL for stages without a parent order context. |
| 14 | LiquidityAccountID | int | YES | - | CODE-BACKED | The liquidity account used for this hedge event. Implicit FK to Trade.LiquidityAccounts. |
| 15 | TradeID | varchar(50) | YES | - | CODE-BACKED | FIX ExecID or trade identifier returned by the liquidity provider. Populated for stages 5-6 after provider execution. |
| 16 | WasOpened | tinyint | YES | - | CODE-BACKED | Direction of the hedge operation: non-zero=position opened with provider, 0=position closed. Populated for stages 5-6. NULL for earlier stages. |
| 17 | HedgedInstrument | int | YES | - | CODE-BACKED | The actual instrument used at the provider for hedging. May differ from InstrumentID when cross-hedging. Set to InstrumentID by most writers (direct hedge). |
| 18 | HedgedAmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Units actually hedged at the provider (in terms of HedgedInstrument). Only populated for stage 3 (exposure query result). |
| 19 | NetUSDExposure | decimal(16,6) | YES | - | CODE-BACKED | Net USD exposure at the time of this log entry. NULL in most observed write paths (not populated by SQL procedures). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EntryType | Dictionary.HedgeBreakdownType | FK (WITH NOCHECK) | Hedge pipeline stage. FK added retroactively; pre-existing rows may not match. 6 pipeline stages. |
| InstrumentID | Trade.Instrument | Implicit | Customer's financial instrument. |
| HedgedInstrument | Trade.Instrument | Implicit | Instrument used for hedging at provider. May differ from InstrumentID (cross-hedge). |
| HedgeServerID | Trade.HedgeServer | Implicit | Hedge server processing the event. |
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | Liquidity account used for execution. |
| PositionID | Trade.Position | Implicit | Customer position triggering the hedge. bigint FK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeExposureQuery | - | Writer (EntryType=3) | Logs the hedge exposure query result |
| Trade.HedgeExposureQueryWithActiveParent | - | Writer (EntryType=3) | Alternate exposure query with parent position context |
| History.LogHedgeServerOrderToProvider | - | Writer (EntryType=4) | Logs the outbound FIX order to provider with price snapshot |
| History.LogHedgeProviderExecutedOrder | - | Writer (EntryType=5) | Logs provider execution with market prices |
| History.LogHedgeComfirmation | - | Writer (EntryType=6) | Logs final provider confirmation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HedgingBreakdownLog (table)
- no code-level dependencies (leaf table)
- written by Trade.HedgeExposureQuery, History.LogHedgeServerOrderToProvider,
  History.LogHedgeProviderExecutedOrder, History.LogHedgeComfirmation
- EntryTypes 1-2 written by application code (not in SSDT repo)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeExposureQuery | Stored Procedure | Writer - stage 3 (exposure query) |
| Trade.HedgeExposureQueryWithActiveParent | Stored Procedure | Writer - stage 3 variant |
| History.LogHedgeServerOrderToProvider | Stored Procedure | Writer - stage 4 (order to provider) |
| History.LogHedgeProviderExecutedOrder | Stored Procedure | Writer - stage 5 (provider execution) |
| History.LogHedgeComfirmation | Stored Procedure | Writer - stage 6 (confirmation) |
| Monitor.MAXIDs | Stored Procedure | Reader - monitoring max IDs for replication lag/health |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgingBreakdownLog | CLUSTERED | EntryID ASC | - | - | Active (no DATA_COMPRESSION specified - default) |
| IX_HedgingBreakdownLog_Occurred | NONCLUSTERED | Occurred ASC | - | - | Active - supports time-range diagnostic queries |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgingBreakdownLog | CLUSTERED PK | EntryID IDENTITY - sequential append |
| DF_HistoryHedgingBreakdownLog_Occured | DEFAULT | Occurred = GETUTCDATE() (UTC, note spelling: "Occured" in constraint name) |
| FK_HistoryHegingBreakdownLog_DictionaryHedgeBreakdownType | FK WITH NOCHECK | EntryType -> Dictionary.HedgeBreakdownType(ID) - retroactively added, not enforced on historical data |

### 7.3 Notes

- NOT a temporal table - standalone append-only diagnostic log
- FK WITH NOCHECK: the FK constraint was added after rows were already inserted; pre-existing EntryType values may not exist in Dictionary.HedgeBreakdownType
- Occurred uses GETUTCDATE() (UTC), unlike History.HedgeFail which uses GETDATE() (local time)
- Two typos in constraint/procedure names: constraint "DF_HistoryHedgingBreakdownLog_Occured" (missing 'r'), FK "FK_HistoryHegingBreakdownLog..." (missing 'd'), procedure "LogHedgeComfirmation" (missing 'n') - these are cosmetic legacy issues
- EntryType=4 is the only type that captures eToro internal prices (from Trade.CurrencyPrice at dispatch time); this makes it the key record for slippage analysis
- PositionID is bigint (matches Trade.Position PK type), while ParentOrderID is int - different order hierarchy identifiers
- Monitor.MAXIDs reads this table to track the maximum EntryID for replication health monitoring

---

## 8. Sample Queries

### 8.1 Full pipeline trace for a specific order

```sql
SELECT
    hbl.EntryID,
    hbl.EntryType,
    hbt.HedgeBreakdownName AS StageName,
    hbl.InstrumentID,
    hbl.AmountInUnitsDecimal,
    hbl.eToroPriceBid,
    hbl.eToroPriceAsk,
    hbl.MarketPriceBid,
    hbl.MarketPriceAsk,
    hbl.WasOpened,
    hbl.TradeID,
    hbl.Occurred
FROM History.HedgingBreakdownLog hbl WITH (NOLOCK)
JOIN Dictionary.HedgeBreakdownType hbt WITH (NOLOCK) ON hbt.ID = hbl.EntryType
WHERE hbl.OrderID = @OrderID
ORDER BY hbl.EntryID;
```

### 8.2 Recent hedge activity with slippage (stage 4 vs stage 5 prices)

```sql
SELECT
    s4.OrderID,
    s4.InstrumentID,
    s4.HedgeServerID,
    s4.LiquidityAccountID,
    s4.eToroPriceBid AS InternalBid,
    s4.MarketPriceBid AS OrderBid,
    s5.MarketPriceBid AS ExecutionBid,
    s5.MarketPriceBid - s4.MarketPriceBid AS BidSlippage,
    s4.Occurred AS OrderTime,
    s5.Occurred AS ExecutionTime
FROM History.HedgingBreakdownLog s4 WITH (NOLOCK)
JOIN History.HedgingBreakdownLog s5 WITH (NOLOCK)
    ON s5.OrderID = s4.OrderID AND s5.EntryType = 5
WHERE s4.EntryType = 4
  AND s4.Occurred >= DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY s4.Occurred DESC;
```

### 8.3 Hedge events by type in the last hour

```sql
SELECT
    hbt.HedgeBreakdownName AS StageName,
    COUNT(*) AS EventCount,
    MIN(hbl.Occurred) AS FirstOccurred,
    MAX(hbl.Occurred) AS LastOccurred
FROM History.HedgingBreakdownLog hbl WITH (NOLOCK)
JOIN Dictionary.HedgeBreakdownType hbt WITH (NOLOCK) ON hbt.ID = hbl.EntryType
WHERE hbl.Occurred >= DATEADD(HOUR, -1, GETUTCDATE())
GROUP BY hbl.EntryType, hbt.HedgeBreakdownName
ORDER BY hbl.EntryType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed (Trade.HedgeExposureQuery, History.LogHedgeServerOrderToProvider, History.LogHedgeProviderExecutedOrder, History.LogHedgeComfirmation, Monitor.MAXIDs) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HedgingBreakdownLog | Type: Table | Source: etoro/etoro/History/Tables/History.HedgingBreakdownLog.sql*
