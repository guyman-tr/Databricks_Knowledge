# History.ExecutionResponseBreakdownLog

> Legacy archived version of the hedge execution response log - records the liquidity provider's response to a hedge order request (confirming fill, recording actual execution prices, and LP trade/order reference IDs). Paired with History.ExecutionRequestBreakdownLog. Superseded by Hedge.ExecutionResponseBreakdownLog (which added MarketPriceRateID and ParentHedgeID columns).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | EntryID (int, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (NONCLUSTERED PK on EntryID, CLUSTERED on Occurred) |

---

## 1. Business Meaning

This table is a **legacy archive of hedge execution response records**, representing the original version of `Hedge.ExecutionResponseBreakdownLog` before the `MarketPriceRateID` and `ParentHedgeID` columns were added (circa 2012 per the SP change log). The active table is now `Hedge.ExecutionResponseBreakdownLog`.

Each row represents a single **hedge order response event**: when eToro's hedge engine received confirmation (or rejection) back from a liquidity provider (LP) after sending an order. The record captures:
- **Whether it filled**: WasOpened
- **LP references**: TradeID, OrderID (the LP's own identifiers for the trade)
- **Three timestamps**: Occurred (log write), OccurredAtProvider (LP confirmed), OccurredAtServer (hedge server received response)
- **Prices**: eToro's internal bid/ask, LP's quoted bid/ask, and the actual EXECUTION price (which may differ from the quoted price due to slippage)

The response log **completes the TCA (Transaction Cost Analysis) picture** by providing the actual execution prices:
- `ProviderPriceBid/Ask` - what the LP quoted at request time (also in the request log)
- `ExecutionPriceBid/Ask` - what the LP actually executed at (may differ due to slippage/requotes)
- `eToroPriceBid/Ask` - eToro's internal price at response time (fetched from Trade.CurrencyPrice at INSERT)

Together with `History.ExecutionRequestBreakdownLog`, this pair enables full TCA: measuring the spread between eToro's observed price, the LP's quoted price, and the actual fill price.

**Relationship to Hedge schema**:
- `Hedge.ExecutionResponseBreakdownLog` is the current active table (22 columns including MarketPriceRateID, ParentHedgeID, plus a filtered NC index on HedgeID WHERE WasOpened=1)
- `History.ExecutionResponseBreakdownLog` is the legacy version (20 columns, no MarketPriceRateID or ParentHedgeID)
- `Hedge.LogHedgeExecutionResponse` SP writes to `Hedge.ExecutionResponseBreakdownLog` (not this table)
- This History table is no longer written by any SP in SSDT

The table has **0 rows** in this staging environment.

---

## 2. Business Logic

### 2.1 Hedge Execution Response Logging

**What**: When the hedge engine receives an LP response, it calls `Hedge.LogHedgeExecutionResponse` which logs the outcome with a real-time price snapshot.

**Columns/Parameters Involved**: All columns

**Rules** (from `Hedge.LogHedgeExecutionResponse`):
- `eToroPriceBid` / `eToroPriceAsk`: Retrieved from `Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID` at the moment of logging - eToro's live price at response time.
- `ExecutionPriceBid` / `ExecutionPriceAsk`: The actual fill prices from the LP (NULL if order was rejected).
- `WasOpened = 1`: The LP filled the order. A corresponding position is open at the LP.
- `WasOpened = 0`: The LP rejected or failed to fill the order (TradeID/OrderID may still be populated by the provider).
- `Occurred`: Defaults to `GETUTCDATE()` - when the log record was written.
- `OccurredAtProvider`: When the LP's system processed the order.
- `OccurredAtServer`: When the hedge server received and processed the LP response.

### 2.2 Request-Response Pairing via HedgeID

**What**: `HedgeID` links each response to its corresponding request in the ExecutionRequestBreakdownLog tables.

**Rules**:
- One `HedgeID` = one execution cycle (one request + one response, ideally).
- `Hedge.InsertKPIData` counts successful executions by joining on HedgeID: `ExecutionResponseBreakdownLog JOIN ExecutionRequestBreakdownLog ON er.HedgeID=es.HedgeID`.
- The Hedge version adds a filtered NC index `Idx_Hedge_ExecutionResponseBreakdownLog_HedgeID` on HedgeID WHERE WasOpened=1 for fast successful-fill lookups.
- Missing response record for a HedgeID = order went unanswered or was lost in transit.

### 2.3 TCA Price Analysis

**What**: Three price pairs enable Transaction Cost Analysis across the full execution lifecycle.

**Columns/Parameters Involved**: `eToroPriceBid`, `eToroPriceAsk`, `ProviderPriceBid`, `ProviderPriceAsk`, `ExecutionPriceBid`, `ExecutionPriceAsk`

**Rules** (from `Hedge.Report_TCA` and `Hedge.Report_TCA_Test`):
- **Request time prices** (from ExecutionRequestBreakdownLog): eToro's price when request was sent + LP's quoted price at request.
- **Response time prices** (this table): eToro's price when response arrived + LP's quoted price at response + LP's actual execution price.
- Slippage = `ExecutionPrice - ProviderPrice` - measures how much the LP moved from their quote to actual fill.
- Total cost = `ExecutionPrice - eToroPriceAtResponse` - measures total spread vs eToro's benchmark.
- `ISNULL(Res.ExecutionPriceBid, Res.ExecutionPriceAsk) AS ExecutionPrice` in the TCA report - uses bid side for sells, ask side for buys.

### 2.4 Legacy Status - Schema Migration

**What**: This table was the original log destination before the Hedge schema version was created.

**Rules**:
- History version (20 columns) vs Hedge version (22 columns): missing `MarketPriceRateID` (bigint NULL) and `ParentHedgeID` (int NULL).
- `ParentHedgeID` in the Hedge version supports composite/child hedge orders where one parent hedge spawns multiple sub-orders.
- `MarketPriceRateID` links to a market data snapshot for precise TCA attribution.
- All current SP consumers use `Hedge.ExecutionResponseBreakdownLog`; no SP in SSDT references `History.ExecutionResponseBreakdownLog`.

---

## 3. Data Overview

The table contains **0 rows** in this staging environment. A representative production row:

| EntryID | HedgeID | InstrumentID | WasOpened | TradeID | ExecutionPriceBid | ExecutionPriceAsk | Occurred |
|---|---|---|---|---|---|---|---|
| 88241 | 55432 | 4 | 1 | T-LP1-882312 | 3245.07 | NULL | 2011-06-15 14:23:12 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EntryID | int | NO | - | CODE-BACKED | Surrogate PK. IDENTITY(1,1) in the Hedge version (NOT FOR REPLICATION); carried as-is in this archive. NONCLUSTERED PK allows CLUSTERED index on Occurred. |
| 2 | HedgeID | int | NO | - | CODE-BACKED | The hedge execution event identifier. Joins to History.ExecutionRequestBreakdownLog.HedgeID to pair request with response. Core key for TCA and KPI analysis. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | The instrument that was hedged. Used for TCA aggregation by instrument and KPI reporting. |
| 4 | HedgeServerID | int | NO | - | VERIFIED | The hedge server that processed this response. FK to Trade.HedgeServer (FK_ExecutionResponseBreakdownLog_HedgeServer). Used for per-server KPI metrics. |
| 5 | LiquidityAccountID | int | NO | - | VERIFIED | The LP account that returned this response. FK to Trade.LiquidityAccounts (FK_ExecutionResponseBreakdownLog_LiquidityAccounts). Used to evaluate per-LP fill rates and slippage. |
| 6 | Occurred | datetime | NO | - | VERIFIED | UTC datetime when this log record was inserted (default = GETUTCDATE()). CLUSTERED index leading column for time-range queries. |
| 7 | AmountInUnits | decimal(16,6) | NO | - | VERIFIED | The filled order size in instrument units. Should match the request AmountInUnits for full fills; may differ for partial fills. |
| 8 | IsBuy | bit | NO | - | VERIFIED | 1 = buy order, 0 = sell order. Must match the corresponding request. |
| 9 | WasOpened | bit | NO | - | VERIFIED | 1 = the LP successfully filled the order (position opened). 0 = the LP rejected or failed to fill. The Hedge version has a filtered NC index on HedgeID WHERE WasOpened=1 for fast fill lookups. |
| 10 | TradeID | varchar(50) | NO | - | VERIFIED | The LP's own trade identifier for this execution. Enables reconciliation with LP confirmation reports and broker statements. |
| 11 | OrderID | varchar(50) | NO | - | VERIFIED | The LP's own order identifier. May differ from TradeID (order ID is assigned when order is placed; trade ID when it fills). Used for LP dispute resolution. |
| 12 | OccurredAtProvider | datetime | NO | - | VERIFIED | The LP's timestamp when the order was processed. Compared with OccurredAtServer and Occurred to measure communication latency (provider processing time, network round-trip). |
| 13 | OccurredAtServer | datetime | NO | - | VERIFIED | The hedge server's timestamp when it received and processed the LP response. Difference from OccurredAtProvider = network latency. |
| 14 | IsManual | bit | NO | - | VERIFIED | 1 = this was a manual hedge operation (operator-initiated), 0 = automated. Corresponds to IsManualRequest in the request log. |
| 15 | eToroPriceBid | decimal(16,8) | NO | - | VERIFIED | eToro's internal bid price at response logging time. Sourced from Trade.CurrencyPrice at INSERT. Represents eToro's market view when confirmation arrived. Used as TCA benchmark. |
| 16 | eToroPriceAsk | decimal(16,8) | NO | - | VERIFIED | eToro's internal ask price at response logging time. Used as TCA benchmark for buy orders. |
| 17 | ProviderPriceBid | decimal(16,8) | NO | - | VERIFIED | The LP's quoted bid price in the response message. May differ from the quoted price at request time (markets move). |
| 18 | ProviderPriceAsk | decimal(16,8) | NO | - | VERIFIED | The LP's quoted ask price in the response message. |
| 19 | ExecutionPriceBid | decimal(16,8) | YES | - | VERIFIED | The actual fill price on the bid side (for sell orders). NULL if WasOpened=0 or if execution was at ask. Key TCA metric: ExecutionPriceBid vs ProviderPriceBid = actual bid-side slippage. |
| 20 | ExecutionPriceAsk | decimal(16,8) | YES | - | VERIFIED | The actual fill price on the ask side (for buy orders). NULL if WasOpened=0 or if execution was at bid. Key TCA metric: ExecutionPriceAsk vs ProviderPriceAsk = actual ask-side slippage. |

**Missing columns** (present in `Hedge.ExecutionResponseBreakdownLog` but NOT in this legacy version):
- `MarketPriceRateID` (bigint NULL) - market price snapshot ID at response time
- `ParentHedgeID` (int NULL) - links sub-orders to their parent composite hedge

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (FK_ExecutionResponseBreakdownLog_HedgeServer) | The hedge server that processed this response |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_ExecutionResponseBreakdownLog_LiquidityAccounts) | The LP account that returned this response |
| HedgeID | History.ExecutionRequestBreakdownLog | Implicit | The corresponding request that triggered this response |
| InstrumentID | Trade.InstrumentMetaData | Implicit | The instrument that was hedged |

### 5.2 Referenced By (other objects point to this)

No objects in SSDT reference this History table. All current readers use `Hedge.ExecutionResponseBreakdownLog`.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExecutionResponseBreakdownLog (table)
- Legacy archive - receives no new data
- Equivalent (older) version of Hedge.ExecutionResponseBreakdownLog
- Paired with History.ExecutionRequestBreakdownLog (HedgeID join key)
- FK deps: Trade.HedgeServer, Trade.LiquidityAccounts

Active version: Hedge.ExecutionResponseBreakdownLog
- Written by: Hedge.LogHedgeExecutionResponse (SP)
- Read by: Hedge.InsertKPIData, Hedge.Report_TCA, Hedge.Report_TCA_Test
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK - HedgeServerID must exist |
| Trade.LiquidityAccounts | Table | FK - LiquidityAccountID must exist |

### 6.2 Objects That Depend On This

No active dependencies. See `Hedge.ExecutionResponseBreakdownLog` for the current version's consumers.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryExecutionResponseBreakdownLog | NONCLUSTERED (PK) | EntryID ASC | - | - | Active |
| IX_HistoryExecutionResponseBreakdownLog_Occurred | CLUSTERED | Occurred ASC | - | - | Active |

**Note**: The Hedge version adds a third filtered NC index `Idx_Hedge_ExecutionResponseBreakdownLog_HedgeID` (HedgeID WHERE WasOpened=1) - not present on this legacy version.

**Filegroup**: [PRIMARY] - no DATA_COMPRESSION specified (default = none, unlike the Hedge version which uses PAGE).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryExecutionResponseBreakdownLog | PRIMARY KEY (NONCLUSTERED) | Uniqueness on EntryID |
| FK_ExecutionResponseBreakdownLog_HedgeServer | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer |
| FK_ExecutionResponseBreakdownLog_LiquidityAccounts | FOREIGN KEY | LiquidityAccountID -> Trade.LiquidityAccounts |

---

## 8. Sample Queries

### 8.1 TCA - actual execution price vs eToro price
```sql
SELECT resp.HedgeID, resp.InstrumentID, resp.LiquidityAccountID,
       resp.Occurred, resp.WasOpened, resp.AmountInUnits,
       resp.eToroPriceBid, resp.eToroPriceAsk,
       resp.ProviderPriceBid, resp.ProviderPriceAsk,
       resp.ExecutionPriceBid, resp.ExecutionPriceAsk,
       ISNULL(resp.ExecutionPriceBid, resp.ExecutionPriceAsk) AS ExecutionPrice,
       ISNULL(resp.ExecutionPriceAsk, resp.ExecutionPriceBid) - resp.eToroPriceAsk AS AskSlippage
FROM [History].[ExecutionResponseBreakdownLog] resp
WHERE resp.WasOpened = 1
  AND resp.Occurred BETWEEN '2011-01-01' AND '2012-01-01'
ORDER BY resp.Occurred
```

### 8.2 Fill rate by LP and instrument
```sql
SELECT LiquidityAccountID, InstrumentID,
       COUNT(*) AS TotalResponses,
       SUM(CAST(WasOpened AS INT)) AS FilledCount,
       CAST(SUM(CAST(WasOpened AS INT)) AS FLOAT) / COUNT(*) * 100 AS FillRatePct
FROM [History].[ExecutionResponseBreakdownLog]
WHERE Occurred BETWEEN '2011-01-01' AND '2012-01-01'
GROUP BY LiquidityAccountID, InstrumentID
ORDER BY FillRatePct ASC
```

### 8.3 Full TCA paired view (request + response)
```sql
SELECT req.HedgeID, req.InstrumentID, req.LiquidityAccountID,
       req.AmountInUnits, req.IsBuy,
       req.eToroPriceBid AS ReqeToroBid, req.eToroPriceAsk AS ReqeToroAsk,
       req.ProviderPriceBid AS ReqProvBid, req.ProviderPriceAsk AS ReqProvAsk,
       resp.WasOpened, resp.ExecutionPriceBid, resp.ExecutionPriceAsk,
       ISNULL(resp.ExecutionPriceBid, resp.ExecutionPriceAsk) AS FillPrice,
       resp.TradeID, resp.OrderID
FROM [History].[ExecutionRequestBreakdownLog] req
LEFT JOIN [History].[ExecutionResponseBreakdownLog] resp ON req.HedgeID = resp.HedgeID
WHERE req.Occurred BETWEEN '2011-01-01' AND '2012-01-01'
ORDER BY req.Occurred
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9.5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table has 0 rows in staging. Legacy version of Hedge.ExecutionResponseBreakdownLog - no longer written*
*Object: History.ExecutionResponseBreakdownLog | Type: Table | Source: etoro/etoro/History/Tables/History.ExecutionResponseBreakdownLog.sql*
