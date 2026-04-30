# Hedge.Report_TCA

> Full Transaction Cost Analysis report: aggregates hedge execution costs by (HedgeServerID, LiquidityAccount) for a given date range, decomposing total transaction cost into SpreadCost (LP spread), Slippage (execution vs quoted price delay), InternalCost (eToro markup), and ExternalCost (response-side slippage). Reads from ExecutionRequest/ResponseBreakdownLog pairs joined on HedgeID.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Start DATETIME, @End DATETIME; DATA_READER has EXECUTE; 5 temp tables + NC index |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.Report_TCA` is eToro's primary hedge Transaction Cost Analysis (TCA) report. For a given date range, it measures the full cost of executing hedge orders against each liquidity provider, decomposing the total cost into four components that serve different business purposes:

| Cost Component | Meaning | Business Use |
|---------------|---------|-------------|
| **SpreadCost** | LP's bid/ask spread charged per execution | How much eToro pays for the provider's liquidity (unavoidable LP cost) |
| **Slippage** | Price moved adversely between request and fill | Execution quality: negative = market moved against eToro during fill delay |
| **InternalCost** | eToro markup over the provider mid price | eToro's earned spread vs what it paid the LP (eToro's margin) |
| **TotalTransactionCost** | eToro price at request vs actual execution price | End-to-end cost vs the price customers see |
| **ExternalCost** | Response-side slippage (quoted vs filled at response time) | Pure LP execution quality independent of request-response timing |

The procedure was refactored on 2013-02-21 by Yitzchak Wahnon to pre-load the breakdown log tables into `#Req` and `#Res` temp tables, improving performance over the earlier direct FULL JOIN approach.

**Why the extended date ranges?** The procedure expands @Start and @End by ±1-2 days when querying the breakdown logs. This handles edge cases where `Occurred` (DB timestamp) and `OccurredAtServer` (application timestamp) straddle the window boundaries due to clock skew or timezone differences. The final filter uses `RequestTime BETWEEN @Start AND @End` to enforce the true requested window.

---

## 2. Business Logic

### 2.1 Multi-Stage Pipeline Architecture

**What**: The procedure uses a 5-stage temp table pipeline to separate the expensive FULL JOIN from the aggregation pass.

**Stages**:
1. **#Spreads**: Load current LP spread data from Trade.Spread (SpreadGroupID=0 = default group). Used for `ProviderSpread` computation.
2. **#Res** (pre-load): ExecutionResponseBreakdownLog for extended date range.
3. **#Req** (pre-load): ExecutionRequestBreakdownLog for extended date range.
4. **#A** (raw pairs): FULL JOIN of #Res and #Req on HedgeID + all TCA metric computations (pips and cost for each metric pair).
5. **#Main** (cost staging): adds SpreadCost, MidToMidCost, RoundingCost from #A + NC index created for aggregation performance.
6. **Final SELECT**: aggregated by (HedgeServerID, LiquidityAccountName) over the true @Start-@End window.

### 2.2 TCA Metrics Calculated

**What**: Five pairs of (pips, cost) metrics decompose execution quality into distinct components.

**Metric 1: ExecToRequestDelay (Slippage)**
- **Pips**: `-(ProviderPriceAsk_req - ExecutionPriceAsk_res) * 10^Precision` for buys; `(ProviderPriceBid_req - ExecutionPriceBid_res) * 10^Precision` for sells
- **Cost**: Pips * Units * USD conversion factor. Negative = adverse = market moved against eToro during order lifetime
- **Meaning**: Pure slippage - did the fill price differ from the quoted price at request time?

**Metric 2: ExecToResponseDelay (External LP quality)**
- **Pips**: `-(ProviderPriceAsk_res - ExecutionPriceAsk_res) * 10^Precision` for buys
- **Cost**: ExecToResponseDiffCost
- **Meaning**: Did the LP fill at the price they quoted at response time? Isolates LP execution quality from network delay.

**Metric 3: eToroToRequest (eToro markup)**
- **Pips**: `-(eToroPriceAsk - ProviderPriceAsk_req) * 10^Precision` for buys; `(eToroPriceBid - ProviderPriceBid_req) * 10^Precision` for sells
- **Cost**: eToroToRequestDiffCost
- **Meaning**: eToro's spread over the provider at request time - the customer-facing price vs LP quoted price.

**Metric 4: eToroToExecution (TotalTransactionCost)**
- **Pips**: eToro price at request vs actual execution price
- **Cost**: eToroToExecutionDiffCost = TotalTransactionCost
- **Meaning**: End-to-end cost from eToro's perspective (what customers see vs what eToro paid the LP)

**Metric 5: MidToMid (eToro mid vs provider mid)**
- `MideToroToMidProviderPips`: `(eToroBid - ceiling(midProvider * 10^Precision) / 10^Precision) * 10^Precision`
- Uses ceiling rounding of provider mid. Measures eToro's mid-market markup.

### 2.3 USD Conversion for Instrument Groups

**What**: Instruments quoted in non-USD currencies require a conversion divisor to express cost in USD.

**Columns/Parameters Involved**: `InstrumentID IN (4,5,6)`, `eToroPriceBid`

**Rules**:
- InstrumentID NOT IN (4,5,6): direct computation (USD-denominated or USD-base pairs)
- InstrumentID IN (4,5,6): USD/JPY, USD/CHF, USD/CAD - divide by eToroPriceBid for USD conversion
- InstrumentID IN (17,18,19): cross pairs with JPY - multiply by 100 for pip adjustment (JPY pairs have 2dp precision vs 4dp for most pairs)

### 2.4 Exclusions and Filters

**What**: Several hardcoded exclusions ensure the TCA summary reflects only meaningful institutional executions.

**Rules**:
- `LA.LiquidityAccountID NOT IN (22,23)`: excludes internal/test LP accounts
- `LiquidityAccountName NOT IN ('Currenex AUSRetailFX3 Execution', 'Currenex AUSRetailFX1 Execution')`: excludes Australia retail FX accounts from the TCA summary
- `IsManual <> 1`: excludes dealer desk manual executions from automated TCA
- `Req.Occurred >= '20120417'`: historical data cutoff (pre-April 2012 data excluded)
- `Res.AmountInUnits IS NOT NULL`: excludes failed executions (no fill amount)
- `Res.ProviderPriceBid * Res.ProviderPriceAsk <> 0`: excludes rows with zero provider prices

### 2.5 Direction/WasOpened Logic

**What**: Determines whether a response represents an "open" or "close" execution, affecting the sign convention.

**Rules**:
- `(Res.IsBuy=1 AND Res.WasOpened=1) OR (Res.IsBuy=0 AND Res.WasOpened=0)`: "true open" direction = use ASK prices for buys
- Otherwise (closing or reverse): use BID prices
- `(Req.IsBuy=1 AND Res.IsBuy=Res.WasOpened) OR (Req.IsBuy=0 AND Res.WasOpened<>Res.IsBuy)`: the WHERE clause filter for consistent request/response direction pairing

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Start | DATETIME | NO | - | CODE-BACKED | Start of the analysis window. RequestTime BETWEEN @Start AND @End in final filter. Response/Occurrence windows are expanded by ±1-2 days internally to capture edge cases. |
| 2 | @End | DATETIME | NO | - | CODE-BACKED | End of the analysis window (exclusive in intermediate queries, inclusive in final filter via BETWEEN). |

Result set columns (final aggregated output):

| # | Column | Description |
|---|--------|-------------|
| 1 | ExecutionTime | GETUTCDATE() at execution time of the report |
| 2 | From | @Start parameter |
| 3 | To | @End parameter |
| 4 | HedgeServerID | Hedge server that executed the orders |
| 5 | LiquidityAccountName | LP account name (from Trade.LiquidityAccounts) |
| 6 | SpreadCost | Total LP spread cost for the period (negative = eToro pays the spread) |
| 7 | InternalCost | eToro's net margin = TotalTransactionCost - Slippage - SpreadCost |
| 8 | Slippage | Total slippage cost (ExecToRequestDelayCost) - adverse price movement during execution |
| 9 | TotalTransactionCost | Total cost from eToro's price to actual LP execution (eToroToExecutionDiffCost) |
| 10 | ExternalCost | LP execution quality measure (ExecToResponseDiffCost) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.ExecutionRequestBreakdownLog | Reader (NOLOCK) | Pre-loaded into #Req; request-side TCA snapshots |
| - | Hedge.ExecutionResponseBreakdownLog | Reader (NOLOCK) | Pre-loaded into #Res; response-side TCA snapshots (fill data) |
| - | Trade.Spread | Reader | Spread data for SpreadGroupID=0 -> ProviderSpread computation |
| - | Trade.SpreadToGroup | Reader | Maps SpreadGroupID=0 to SpreadIDs |
| - | Trade.ProviderToInstrument | Reader (NOLOCK) | Precision (pip precision) per instrument |
| - | Trade.GetInstrument | Reader (NOLOCK) | Instrument name |
| - | Trade.LiquidityAccounts | Reader (NOLOCK) | LP account name and ID |
| - | Trade.LiquidityProviders | Reader (NOLOCK) | LP provider name |

### 5.2 Referenced By (other objects point to this)

DATA_READER role holds EXECUTE. Used by hedge desk and BI analysts for LP cost analysis and execution quality monitoring.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.Report_TCA (procedure)
|-- Hedge.ExecutionRequestBreakdownLog (table) [READ - request-side price snapshots]
|-- Hedge.ExecutionResponseBreakdownLog (table) [READ - response-side price + fill data]
|-- Trade.Spread (table) [READ - LP spreads for SpreadGroupID=0]
|-- Trade.SpreadToGroup (table) [READ - SpreadGroupID=0 membership]
|-- Trade.ProviderToInstrument (table) [READ - pip Precision per instrument]
|-- Trade.GetInstrument (view/table) [READ - instrument names]
|-- Trade.LiquidityAccounts (table) [READ - LP account names]
+-- Trade.LiquidityProviders (table) [READ - LP provider names]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionRequestBreakdownLog | Table | Pre-loaded into #Req; request-side TCA data |
| Hedge.ExecutionResponseBreakdownLog | Table | Pre-loaded into #Res; response-side/fill TCA data |
| Trade.Spread | Table | ProviderSpread = LP bid/ask spread |
| Trade.SpreadToGroup | Table | SpreadGroupID=0 filter for current spreads |
| Trade.ProviderToInstrument | Table | Precision: pip decimal places per instrument |
| Trade.GetInstrument | View/Table | Instrument name lookup |
| Trade.LiquidityAccounts | Table | LP account name and ID |
| Trade.LiquidityProviders | Table | LP provider name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DATA_READER (role) | Permission | EXECUTE - TCA analysis access |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Extended date ranges | Window expansion | All intermediate queries use @Start-1day to @End+1day to capture boundary rows. Final filter tightens back to @Start/@End. |
| NC index on #Main | Performance | Created after #Main population: `(LiquidityAccountName, RequestTime, ProviderBidAtRequest, IsManual) INCLUDE (...)`. Enables the GROUP BY aggregation efficiently. |
| FULL JOIN on HedgeID | Pair matching | Ensures unpaired requests (timed out) and unpaired responses (edge cases) appear in #A with NULLs for the missing side. Final filters exclude these via AmountInUnits IS NOT NULL. |
| InstrumentID IN (4,5,6) conversion | USD normalization | JPY, CHF, CAD base pair costs divided by eToroPriceBid to convert to USD. |

---

## 8. Sample Queries

### 8.1 Run TCA report for a specific date range
```sql
EXEC [Hedge].[Report_TCA]
    @Start = '2026-03-01 00:00:00',
    @End   = '2026-03-07 23:59:59'
-- Returns: per (HedgeServerID, LiquidityAccountName) TCA summary:
--   SpreadCost | InternalCost | Slippage | TotalTransactionCost | ExternalCost
```

### 8.2 Run for a single day
```sql
EXEC [Hedge].[Report_TCA]
    @Start = '2026-03-19 00:00:00',
    @End   = '2026-03-19 23:59:59'
```

### 8.3 Check which LP accounts are covered in the breakdown logs
```sql
SELECT DISTINCT LA.LiquidityAccountName, COUNT(1) AS Executions
FROM Hedge.ExecutionResponseBreakdownLog r WITH (NOLOCK)
JOIN Trade.LiquidityAccounts LA WITH (NOLOCK) ON LA.LiquidityAccountID = r.LiquidityAccountID
WHERE r.Occurred >= DATEADD(day, -7, GETUTCDATE())
GROUP BY LA.LiquidityAccountName
ORDER BY Executions DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.Report_TCA | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.Report_TCA.sql*
