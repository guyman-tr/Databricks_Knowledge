# Hedge.ExecutionResponseBreakdownLog

> Fill-side complement to ExecutionRequestBreakdownLog: captures the actual execution prices and provider timestamps when a hedge order is filled or rejected, paired on HedgeID for Transaction Cost Analysis (TCA) slippage measurement.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | EntryID IDENTITY (NONCLUSTERED PK + CLUSTERED on Occurred + filtered NC on HedgeID WHERE WasOpened=1) |
| **Partition** | No |
| **Indexes** | 3 active (NONCLUSTERED PK + CLUSTERED on Occurred + filtered NC on HedgeID) - all PAGE compressed |

---

## 1. Business Meaning

Hedge.ExecutionResponseBreakdownLog is the "fill side" of the eToro hedge TCA (Transaction Cost Analysis) framework. Where `Hedge.ExecutionRequestBreakdownLog` captures the prices at the moment an order is sent, this table captures the prices at the moment the provider responds with an execution confirmation or rejection.

When paired with ExecutionRequestBreakdownLog (joined on HedgeID), this table completes the full TCA picture:
- `REQUEST`: prices at the time the order was sent to the market
- `RESPONSE`: prices at the time the order was filled by the market

The difference between these is **slippage** - the adverse (or favorable) price movement between request and response, measured in both pips and monetary cost. This powers `Hedge.Report_TCA`, the hedge desk's primary cost analysis tool.

Key data specific to the response side (not present in the request table):
- `ExecutionPriceBid` / `ExecutionPriceAsk`: The **actual execution price** from the provider (distinct from ProviderPriceBid/Ask, which was the quoted price at request time - slippage = ExecutionPrice - ProviderPrice at request)
- `WasOpened`: Whether the order was successfully opened (1) or rejected/not opened (0)
- `TradeID` / `OrderID`: Provider-assigned trade identifiers for reconciliation
- `OccurredAtProvider`: The provider's own timestamp for the fill event

The table is empty in this environment (0 rows). In production it mirrors the ExecutionRequestBreakdownLog row volume.

---

## 2. Business Logic

### 2.1 TCA Response Capture

**What**: On every fill/rejection response from a liquidity provider, a row is inserted with the provider's execution confirmation data and a fresh eToro price snapshot.

**Columns/Parameters Involved**: `HedgeID`, `ExecutionPriceBid`, `ExecutionPriceAsk`, `WasOpened`, `TradeID`, `OrderID`

**Rules**:
- Called by `Hedge.LogHedgeExecutionResponse` on every execution response.
- Like the request side: `eToroPriceBid` and `eToroPriceAsk` are fetched at insert time from `Trade.CurrencyPrice WHERE InstrumentID = @InstrumentID`. This second eToro price snapshot captures any price movement between request and response.
- `ExecutionPriceBid` / `ExecutionPriceAsk`: The actual fill prices returned by the provider in the execution report. These may differ from `ProviderPriceBid` / `ProviderPriceAsk` (the quoted prices at request time) due to market movement during the order's time-in-market (slippage).
- `WasOpened = 1`: The provider successfully opened/filled the position. The filtered NC index on HedgeID WHERE WasOpened=1 optimizes the common case of looking up successful fills by HedgeID.
- `WasOpened = 0`: The provider rejected or could not fill the order (or it was a close/sell response where WasOpened=false means position was closed).

### 2.2 Slippage Calculation in Report_TCA

**What**: Report_TCA joins request and response on HedgeID to compute execution quality metrics.

**Columns/Parameters Involved**: `ProviderPriceBid`, `ProviderPriceAsk`, `ExecutionPriceBid`, `ExecutionPriceAsk`, `IsBuy`, `WasOpened`, `AmountInUnits`

**Rules**:
- **ExecToRequestDelayPipsDiff** (slippage pips, request-side):
  - Buy: `-(Req.ProviderPriceAsk - Res.ExecutionPriceAsk) * 10^Precision` (negative = adverse)
  - Sell: `(Req.ProviderPriceBid - Res.ExecutionPriceBid) * 10^Precision`
- **ExecToResponseDiffCost** (slippage cost, response-side):
  - Compares ExecutionPrice vs. ProviderPrice AT RESPONSE TIME (how much the fill deviated from the quote at response)
- **eToroToExecutionDiffCost** (total eToro cost):
  - Compares eToro's displayed price vs actual execution price - includes both spread capture and slippage
- Fill direction logic: `(Res.IsBuy=1 AND Res.WasOpened=1) OR (Res.IsBuy=0 AND Res.WasOpened=0)` = opened position; otherwise = closed.

### 2.3 Three-Timestamp Architecture

**What**: Three timestamps capture the response at three different points in time, enabling granular latency decomposition.

**Columns/Parameters Involved**: `Occurred`, `OccurredAtServer`, `OccurredAtProvider`

**Rules**:
- `Occurred`: DB server UTC time at row insert. DEFAULT = GETUTCDATE(). Clustered index key.
- `OccurredAtServer`: The hedge server's reported time when the execution response was received and processed. Used in SSRS_Latency_Report as ReceivedTime analog.
- `OccurredAtProvider`: The liquidity provider's own timestamp for when the trade was executed. Most precise time reference for the actual market event. Used for latency measurement and trade reconciliation with provider statements.
- Latency sequence: `OccurredAtProvider` (market event) -> `OccurredAtServer` (server received) -> `Occurred` (DB inserted).

### 2.4 Parent-Child Hedge Relationships

**What**: ParentHedgeID enables linking child execution orders back to a parent hedge order in multi-leg or split-fill scenarios.

**Columns/Parameters Involved**: `ParentHedgeID`, `HedgeID`

**Rules**:
- `ParentHedgeID` = NULL for standalone orders.
- `ParentHedgeID` is populated when a single parent hedge request spawns multiple child execution orders (e.g., an order split across multiple providers or executed in tranches).
- The SSRS_Latency_Report Hedge Server flow joins on `hbcl.HedgeID = hl.OrderID` (using ExecutionLog.OrderID), not directly on this ParentHedgeID - the hierarchy is tracked at a different level for HBC flows.

---

## 3. Data Overview

0 rows in this environment. Representative rows based on schema and procedure analysis:

| EntryID | HedgeID | InstrumentID | WasOpened | IsBuy | ProviderPriceBid | ProviderPriceAsk | ExecutionPriceBid | ExecutionPriceAsk | OccurredAtProvider | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|
| 2001 | 50001 | 1 | 1 | 1 | 1.08455 | 1.08465 | 1.08458 | 1.08468 | 2026-03-19 09:00:01.350 | BUY filled. ExecutionAsk (1.08468) > ProviderAsk at request (1.08465) = 0.3 pip adverse slippage. WasOpened=1. |
| 2002 | 50002 | 1 | 1 | 0 | 1.08440 | 1.08450 | 1.08443 | 1.08453 | 2026-03-19 09:00:05.280 | SELL filled. ExecutionBid (1.08443) > ProviderBid at request (1.08440) = 0.3 pip favorable fill (price moved up between request and fill). WasOpened=1. |
| 2003 | 50004 | 1 | 0 | 1 | 1.08460 | 1.08470 | null | null | 2026-03-19 09:01:00.100 | BUY rejected. WasOpened=0. ExecutionPrices are null (no fill). TradeID = provider rejection code. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EntryID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment surrogate key. NOT FOR REPLICATION. NONCLUSTERED PK - physical ordering is by Occurred (clustered). |
| 2 | HedgeID | int | NO | - | CODE-BACKED | Join key to Hedge.ExecutionRequestBreakdownLog - pairs each response with its originating request for TCA analysis. A filtered NC index on HedgeID WHERE WasOpened=1 enables fast lookup of successful fills. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | The instrument that was hedged. Implicitly references Trade.Instrument. Needed for precision lookup and conversion factor in TCA calculations (e.g., JPY pairs use different pip multipliers). |
| 4 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). The hedge server that processed this execution response. |
| 5 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts(LiquidityAccountID). The provider account that filled (or rejected) the order. |
| 6 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | DB server UTC time at row insert. DEFAULT = GETUTCDATE(). Clustered index key for time-window queries. |
| 7 | AmountInUnits | decimal(16,6) | NO | - | CODE-BACKED | The filled quantity in instrument units. For partial fills, this is the amount of THIS response (may be less than the original request AmountInUnits). |
| 8 | IsBuy | bit | NO | - | CODE-BACKED | 1=the hedge was buying (opening a long hedge), 0=selling. Combined with WasOpened to determine the effective position direction: (IsBuy=1 AND WasOpened=1) = long open; (IsBuy=0 AND WasOpened=0) = long close. |
| 9 | WasOpened | bit | NO | - | CODE-BACKED | 1=the position was successfully opened/executed by the provider; 0=rejected or it was a closing response. The filtered NC index on HedgeID WHERE WasOpened=1 serves fast fill lookups by ignoring rejections. |
| 10 | TradeID | varchar(50) | NO | - | CODE-BACKED | Provider-assigned trade confirmation ID. The unique identifier the provider uses for this execution in their systems. Used for reconciliation with provider trade statements and dispute resolution. |
| 11 | OrderID | varchar(50) | NO | - | CODE-BACKED | Provider-assigned order ID from the execution confirmation. May differ from TradeID (OrderID is for the order; TradeID is for the specific trade/fill event). |
| 12 | OccurredAtProvider | datetime | NO | - | CODE-BACKED | The provider's own timestamp for when this execution occurred. The authoritative market event time. Used for trade reconciliation with provider records. Precision is datetime (milliseconds). |
| 13 | OccurredAtServer | datetime | NO | - | CODE-BACKED | The hedge server's reported time when it received and processed the execution response. Used in SSRS_Latency_Report for Metric 2 (Provider_Response_Latency = SendTime to ReceivedTime). |
| 14 | IsManual | bit | NO | - | CODE-BACKED | 1=manually triggered execution; 0=automated. Mirrors ExecutionRequestBreakdownLog.IsManualRequest. Report_TCA filters `IsManual<>1` to exclude manual executions from automated TCA metrics. |
| 15 | eToroPriceBid | decimal(16,8) | NO | - | CODE-BACKED | eToro's internal bid price at the time of the RESPONSE (fetched from Trade.CurrencyPrice at insert, same mechanism as request side). Captures any price movement between request and fill. |
| 16 | eToroPriceAsk | decimal(16,8) | NO | - | CODE-BACKED | eToro's internal ask price at the time of the RESPONSE. Comparing Req.eToroPriceAsk vs Res.eToroPriceAsk shows how much eToro's displayed price moved during the order's lifetime. |
| 17 | ProviderPriceBid | decimal(16,8) | NO | - | CODE-BACKED | The provider's quoted bid price at the time of the RESPONSE. Used in ExecToResponseDiffCost calculation: how much did the execution price deviate from the provider's quote at response time. |
| 18 | ProviderPriceAsk | decimal(16,8) | NO | - | CODE-BACKED | The provider's quoted ask price at the time of the RESPONSE. |
| 19 | ExecutionPriceBid | decimal(16,8) | YES | - | CODE-BACKED | The actual bid price at which the position was executed. NULL for rejections (WasOpened=0). The key slippage column: `(Req.ProviderPriceAsk - Res.ExecutionPriceAsk) * units` = execution slippage cost. |
| 20 | ExecutionPriceAsk | decimal(16,8) | YES | - | CODE-BACKED | The actual ask price at which the position was executed. NULL for rejections. For BUY fills: `Res.ExecutionPriceAsk` is the price paid. The difference from `Req.ProviderPriceAsk` at request time is the adverse slippage. |
| 21 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | ID of the market price rate snapshot at response time. Allows cross-referencing with the rate used at request time (ExecutionRequestBreakdownLog.MarketPriceRateID). bigint per FB 17303 upgrade from INT. |
| 22 | ParentHedgeID | int | YES | - | CODE-BACKED | Optional reference to a parent hedge order. Populated when this response is a child order in a multi-leg execution. NULL for standalone orders. Enables reconstruction of complex order hierarchies in TCA analysis. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK | FK_ExecutionResponseBreakdownLog_HedgeServer |
| LiquidityAccountID | Trade.LiquidityAccounts | FK | FK_ExecutionResponseBreakdownLog_LiquidityAccounts |
| HedgeID | Hedge.ExecutionRequestBreakdownLog | Logical join key | Pairs response with originating request for TCA - no DDL FK |
| InstrumentID | Trade.Instrument | Implicit (no DDL FK) | Instrument being hedged |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.LogHedgeExecutionResponse | - | Writer | Inserts one row per provider execution response |
| Hedge.Report_TCA | HedgeID join | Reader | TCA analysis - pairs with ExecutionRequestBreakdownLog for slippage measurement |
| Hedge.Report_TCA_Test | HedgeID join | Reader | Test variant of Report_TCA |
| Hedge.SSRS_Latency_Report | ReceivedTime (=OccurredAtServer) | Reader | Provider round-trip latency (SendTime -> ReceivedTime) |
| Hedge.InsertKPIData | Occurred + OccurredAtServer | Reader | KPI volume analysis on fill records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExecutionResponseBreakdownLog (table)
  - FK: Trade.HedgeServer (HedgeServerID)
  - FK: Trade.LiquidityAccounts (LiquidityAccountID)
  - Implicit: Trade.Instrument (InstrumentID)
  - Logical pair: Hedge.ExecutionRequestBreakdownLog (HedgeID join for TCA)
  - Writer reads: Trade.CurrencyPrice (eToro prices fetched at insert time)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID |
| Trade.CurrencyPrice | Table | Read at insert time by LogHedgeExecutionResponse to capture eToro bid/ask at response time |
| dbo.dtPrice | User Defined Type | ProviderPriceBid/Ask, ExecutionPriceBid/Ask column types |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.LogHedgeExecutionResponse | Procedure | Primary writer |
| Hedge.Report_TCA | Procedure | TCA slippage analysis (paired with ExecutionRequestBreakdownLog) |
| Hedge.Report_TCA_Test | Procedure | Test variant |
| Hedge.SSRS_Latency_Report | Procedure | Latency metrics reader |
| Hedge.InsertKPIData | Procedure | KPI volume reader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeExecutionResponseBreakdownLog | NONCLUSTERED PK | EntryID ASC | - | - | Active (PAGE compression) |
| IX_HedgeExecutionResponseBreakdownLog_Occurred | CLUSTERED | Occurred ASC | - | - | Active (PAGE compression) |
| Idx_Hedge_ExecutionResponseBreakdownLog_HedgeID | NONCLUSTERED (filtered) | HedgeID ASC | - | WHERE WasOpened=1 | Active (PAGE compression) |

**Filtered index design**: The HedgeID NC index only includes rows where WasOpened=1. Since TCA analysis on successful fills (looking up a fill by HedgeID) is more common than looking up rejections, this partial index is smaller and faster than a full index. Rejection rows (WasOpened=0) are not indexed by HedgeID - range queries by Occurred are used for those.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeExecutionResponseBreakdownLog | PRIMARY KEY (NONCLUSTERED) | EntryID - unique per response event |
| FK_ExecutionResponseBreakdownLog_HedgeServer | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_ExecutionResponseBreakdownLog_LiquidityAccounts | FOREIGN KEY | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| DF_ExecutionResponseBreakdownLog_Occurred | DEFAULT | Occurred = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Full TCA slippage by instrument (last 24h fills)
```sql
SELECT Req.InstrumentID,
       COUNT(1) AS FillCount,
       AVG(CASE WHEN Req.IsBuy = 1
                THEN (Req.ProviderPriceAsk - Res.ExecutionPriceAsk) * POWER(10, 4)
                ELSE (Res.ExecutionPriceBid - Req.ProviderPriceBid) * POWER(10, 4) END) AS AvgSlippagePips
FROM Hedge.ExecutionRequestBreakdownLog Req WITH (NOLOCK)
JOIN Hedge.ExecutionResponseBreakdownLog Res WITH (NOLOCK)
  ON Req.HedgeID = Res.HedgeID
WHERE Req.OccurredAtServer > DATEADD(day, -1, GETUTCDATE())
  AND Res.WasOpened = 1
  AND Req.IsManualRequest = 0
GROUP BY Req.InstrumentID
ORDER BY FillCount DESC;
```

### 8.2 Fill rate by liquidity account
```sql
SELECT LiquidityAccountID,
       COUNT(1) AS TotalResponses,
       SUM(CASE WHEN WasOpened = 1 THEN 1 ELSE 0 END) AS Fills,
       CAST(SUM(CASE WHEN WasOpened = 1 THEN 1.0 ELSE 0 END) / COUNT(1) AS decimal(5,3)) AS FillRate
FROM Hedge.ExecutionResponseBreakdownLog WITH (NOLOCK)
WHERE OccurredAtServer > DATEADD(day, -1, GETUTCDATE())
  AND IsManual = 0
GROUP BY LiquidityAccountID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for Hedge.ExecutionResponseBreakdownLog.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExecutionResponseBreakdownLog | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExecutionResponseBreakdownLog.sql*
