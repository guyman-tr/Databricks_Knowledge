# Hedge.HBCExecutionLog

> HBC (Hedge By Customer) execution audit log: one row per HBC hedge execution attempt, capturing requested vs executed lots, eToro rate vs LP rate, timing, and success/failure outcome; parent of Hedge.HBCOrderLog (individual orders within an execution).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ExecutionID bigint (CLUSTERED PK, externally assigned) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK on ExecutionID, filtered NC on StartTime WHERE IsSuccess=1) |

---

## 1. Business Meaning

Hedge.HBCExecutionLog is the primary audit log for **HBC (Hedge By Customer)** executions. HBC is eToro's order-based hedging path (as distinct from CBH = Customer Based Hedging, the exposure-based path). In HBC, hedging is triggered directly by customer trade events (opens/closes), routing through the ExecutionAPI component of the HedgeServer.

**HBC execution flow** (from Atlassian - HedgeServer Overview):
1. ExecutionAPI receives a hedge order request from HAPI, LAPI, or the Dealing Desk (via WCF or RabbitMQ).
2. Rate validation: the current provider rate (bid for sell, ask for buy) must be within MarketRange of the customer's view rate (configured in Trade.ProviderToInstrument).
3. Unit conversion: eToro units are divided by UnitRatio (Hedge.ProviderUnitConversionRatio) to get provider units, then rounded to whole lots (lot size from DB > provider FIX message > default).
4. The rounded lot amount is sent to the liquidity provider as a NOS (New Order Single) over FIX.
5. On receiving the execution response (Fill/Partial), the result is logged here and child orders are logged in Hedge.HBCOrderLog.

**RequestAmountInLots != ExecutionAmountInLots** is normal and expected: HBC rounds to the nearest whole lot (over-hedges). The discrepancy monitoring procedure `Hedge.GetHBCEstimationsDiscrepencies` validates that ExecutionAmountInLots matches the sum of customer position lot counts (joining via InitExecutionID/EndExecutionID in Trade position data) - any mismatch indicates a reconciliation issue.

**Relationship to other tables** (Atlassian confirmed):
- `Hedge.HBCOrderLog`: Child table - one HBCExecutionLog row has 1+ HBCOrderLog rows (individual FIX orders). If execution creation fails, rows appear in HBCExecutionLog (IsSuccess=0) but NOT in HBCOrderLog.
- `Hedge.ExecutionLog`: HBC responses are ALSO logged in ExecutionLog. Join: `HBCOrderLog.HedgeID = ExecutionLog.OrderID`.

This environment contains 51,747 rows spanning 2023-03-08 to 2023-11-07, all on LiquidityAccountID=10 (ZBFX Price2 Execution) and HedgeServerID=1. Success rate: ~94% (48,970/51,747). 152 distinct instruments. Data appears to be an archive (last activity Nov 2023).

---

## 2. Business Logic

### 2.1 Lot Rounding: Requested vs Executed

**What**: The hedge server receives a float amount of lots to hedge but must submit whole lots to the provider. ExecutionAmountInLots is always a whole number; RequestAmountInLots is the pre-rounding float.

**Columns/Parameters Involved**: `RequestAmountInLots`, `ExecutionAmountInLots`

**Rules**:
- RequestAmountInLots: The exact lot amount calculated from exposure before lot-size rounding. E.g., 2.46 lots.
- ExecutionAmountInLots: The actual lots submitted to the provider after ceiling/floor rounding. E.g., 3 lots (rounded up to over-hedge).
- Default rounding: **always round to over-hedge** (ceiling for buys, ceiling for sells from the provider's perspective).
- `IsUsingSmartRounding` config: if true, rounds up only if `(providerUnits % lotsize) / lotsize >= 0.5`; otherwise always rounds up.
- InstrumentID=100000 example: RequestAmountInLots=0.02, ExecutionAmountInLots=1 - extreme rounding for NOP aggregate/crypto.

### 2.2 Rate Columns and Spread

**What**: Three rate snapshots capture the pricing lifecycle of an HBC execution.

**Columns/Parameters Involved**: `InitialRate`, `ExecutionRate`, `LPExecutionRate`

**Rules** (all use dbo.dtPrice type - decimal(16,5) or similar custom precision):
- `InitialRate`: The eToro market rate at the time the hedge order was initiated. The customer's reference rate.
- `ExecutionRate`: The rate eToro records for this execution. For manual executions, this may be spread-adjusted (UseSpreadedExecutionRate config). For limit executions, adjusted according to SL/TP rate calculation logic.
- `LPExecutionRate`: The actual fill rate returned by the liquidity provider. Nullable - NULL if execution failed (IsSuccess=0).
- Slippage = LPExecutionRate - ExecutionRate. If this diverges significantly, it may trigger FailReason="allowed rate difference exceeded".
- Rate conversion: eToro rate -> provider rate via `RateConversionFactor` in Trade.LiquidityProviderContracts (multiply on response).

### 2.3 IsSuccess and FailReason

**What**: Execution outcome and root cause for failures.

**Columns/Parameters Involved**: `IsSuccess`, `FailReason`

**Observed FailReasons** (distribution in data):
| FailReason | Count |
|-----------|-------|
| unrecoverable error during execution | 1,584 |
| execution time exceeded | 649 |
| liquidity provider not available for hedging | 341 |
| allowed rate difference exceeded | 125 |
| execution amount larger then deal size reject threshold | 8 |

- `execution time exceeded`: HedgeRequestTimeStampForDiffSecs config controls the timeout; crypto timeout = configured% (RequestTimeoutPercentageFromDiffsecs) of that value.
- `allowed rate difference exceeded`: Current rate moved too far from customer view rate (MarketRange validation).
- `liquidity provider not available for hedging`: Provider circuit breaker or connection issue.
- IsSuccess=true even with ExecutionAmountInLots != RequestAmountInLots (rounding is expected, not a failure).

### 2.4 Cancel Executions

**What**: Hedge cancellations are logged as separate execution rows, not as updates to the original.

**Columns/Parameters Involved**: `IsCancelExecution`, `CancelledExecutionID`

**Rules**:
- `IsCancelExecution = 1`: This row is a cancellation of a previous execution.
- `CancelledExecutionID`: The ExecutionID of the original execution being cancelled. DEFAULT 0 = not a cancellation.
- 78 cancel rows observed (31 buy + 39 sell, plus 8 failed cancel attempts).
- Cancellations come via RabbitMQ from HedgeAPI.

### 2.5 ShouldWaitForConfirm (Manual Request Flag)

**What**: Flags whether this execution should wait for a confirmation before completing.

**Columns/Parameters Involved**: `ShouldWaitForConfirm`

**Rules**:
- Corresponds to the `@IsManualRequest` parameter in `Hedge.LogHBCExecution` (parameter was renamed from `@ShouldWaitForConfirm` - column name retained).
- `IsHBCFillOrKill` config: if false, HBC completes on first Execution Report (even partial); if true, waits for terminal state.
- NULL in older rows; true for manual hedge orders from the Dealing Desk.

### 2.6 External ExecutionID (No IDENTITY)

**What**: ExecutionID is assigned by the calling application, not auto-generated.

**Columns/Parameters Involved**: `ExecutionID`

**Rules**:
- ExecutionID is a bigint provided by the LogHBCExecution caller (HedgeServer application).
- Range observed: 12,056,956 to 13,797,342 (suggesting a global counter shared with other execution systems).
- This ID links HBCExecutionLog to customer positions: `Trade.GetPositionDataSlim.InitExecutionID` and `EndExecutionID` reference this ID.

---

## 3. Data Overview

51,747 rows | 2023-03-08 to 2023-11-07 | 1 LiquidityAccount (ID=10, ZBFX Price2) | 152 distinct instruments

| IsSuccess | IsBuy | IsCancelExecution | Count |
|---|---|---|---|
| true | true | false | 32,776 (63%) |
| true | false | false | 16,194 (31%) |
| false | true | false | 2,144 (4%) |
| false | false | false | 555 (1%) |
| true | false | true | 39 |
| true | true | true | 31 |
| false | true | true | 8 |

| ExecutionID | HedgeServerID | LiquidityAccountID | InstrumentID | RequestAmountInLots | ExecutionAmountInLots | ExecutionRate | StartTime | EndTime |
|---|---|---|---|---|---|---|---|---|
| 13797342 | 1 | 10 | 100000 | 0.020000 | 1.000000 | 34933.7025 | 2023-11-07 11:40:01 | 2023-11-07 11:40:01 |
| 13797341 | 1 | 10 | 1111 | 2.460000 | 3.000000 | 219.4175 | 2023-11-07 11:38:47 | 2023-11-07 11:38:47 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionID | bigint | NO | - | CODE-BACKED | Externally assigned execution identifier (no IDENTITY - assigned by HedgeServer application). CLUSTERED PK. Links to Trade position data via InitExecutionID/EndExecutionID. Range 12M-13.8M in this environment suggests shared counter with other execution subsystems. |
| 2 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer. The hedge server instance that performed this execution. All rows in this environment use HedgeServerID=1. |
| 3 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts. The liquidity account (provider connection) used. All rows: LiquidityAccountID=10 (ZBFX Price2 Execution). HBC in this environment routes exclusively through ZBFX. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | The instrument being hedged. Implicit reference to Trade.Instrument. InstrumentID=100000 appears for NOP aggregate crypto executions. 152 distinct values. |
| 5 | IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=BUY hedge (eToro is buying from provider to hedge net short customer exposure), 0=SELL hedge. ~95% are buys (63%) or sells (31%). |
| 6 | IsSuccess | bit | NO | - | CODE-BACKED | Whether the execution completed successfully. 94% true. False rows have FailReason populated. Note: execution can succeed even if ExecutionAmountInLots != RequestAmountInLots (lot rounding is expected). |
| 7 | RequestAmountInLots | decimal(16,6) | NO | - | CODE-BACKED | The pre-rounding lot amount calculated from the exposure/order. May be fractional (e.g., 2.46). This is the "ideal" amount before lot-size adjustment. |
| 8 | ExecutionAmountInLots | decimal(16,6) | NO | - | CODE-BACKED | The actual lot amount submitted to the provider after whole-lot rounding. Always a whole number in practice (e.g., 3.000000). Discrepancy vs RequestAmountInLots is intentional (over-hedge by rounding up). Validated by GetHBCEstimationsDiscrepencies against customer position sum. |
| 9 | ExecutionRate | dbo.dtPrice | NO | - | CODE-BACKED | The eToro-side execution rate recorded for this hedge. May be spread-adjusted for manual executions or limit-adjusted for TP/SL executions. Uses dbo.dtPrice custom type (high-precision decimal). |
| 10 | StartTime | datetime | NO | - | CODE-BACKED | UTC datetime when the hedge execution was initiated (order sent to provider). Clustered index column (filtered NC WHERE IsSuccess=1). |
| 11 | EndTime | datetime | NO | - | CODE-BACKED | UTC datetime when the execution completed (fill received or failure detected). EndTime - StartTime = execution latency. Used by GetHBCEstimationsDiscrepencies to filter recent executions. |
| 12 | FailReason | varchar(250) | YES | - | CODE-BACKED | Human-readable failure reason for IsSuccess=0 rows. Common values: "unrecoverable error during execution", "execution time exceeded", "liquidity provider not available for hedging", "allowed rate difference exceeded", "execution amount larger then deal size reject threshold". NULL for successful executions. |
| 13 | LPExecutionRate | dbo.dtPrice | YES | - | CODE-BACKED | The actual fill rate returned by the liquidity provider. NULL if IsSuccess=0. The difference from ExecutionRate represents slippage. Rate is converted back to eToro units via RateConversionFactor in Trade.LiquidityProviderContracts. |
| 14 | MarketRateIDAtExecutionEnd | bigint | YES | - | CODE-BACKED | Reference to the market rate record at the time execution completed. Used for audit - captures the prevailing market rate at fill time for post-trade analysis. |
| 15 | ShouldWaitForConfirm | bit | YES | - | CODE-BACKED | Maps to @IsManualRequest parameter in LogHBCExecution (column name was not updated when parameter renamed). True for manual hedge orders from the Dealing Desk that require explicit confirmation before completing. NULL for older rows and standard executions. |
| 16 | InitialRate | dbo.dtPrice | YES | - | CODE-BACKED | The eToro market rate at hedge initiation time (customer's reference rate). Nullable - may be absent for cancel executions. Enables comparison of rate at order creation vs rate at fill (InitialRate vs LPExecutionRate). |
| 17 | IsCancelExecution | bit | NO | 0 | CODE-BACKED | 1 if this row represents a cancellation of a previous execution. DEFAULT 0. 78 cancel rows in data. Cancellation requests arrive via RabbitMQ from HedgeAPI. |
| 18 | CancelledExecutionID | bigint | NO | 0 | CODE-BACKED | For IsCancelExecution=1 rows: the ExecutionID of the original execution being cancelled. DEFAULT 0 for normal (non-cancel) executions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (WITH CHECK) | FK_HBCExecutionLog_HedgeServer |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (WITH CHECK) | FK_HBCExecutionLog_LiquidityAccounts |
| InstrumentID | Trade.Instrument | Implicit (no DDL FK) | Instrument being hedged |
| ExecutionID | Trade.GetPositionDataSlim (view) | Implicit | Position data links InitExecutionID/EndExecutionID back to this ExecutionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.HBCOrderLog | ExecutionID | Child (FK) | Individual FIX orders for this execution (1+ orders per execution) |
| Hedge.LogHBCExecution | ExecutionID | Writer | Inserts HBCExecutionLog + HBCOrderLog in a single transaction |
| Hedge.GetHBCEstimationsDiscrepencies | ExecutionID | Reader | Reconciliation: validates ExecutionAmountInLots against customer position lots |
| Hedge.InsertKPIData | ExecutionID | Reader | KPI calculation uses execution data for performance metrics |
| Hedge.SSRS_Latency_Report | StartTime/EndTime | Reader | Latency analysis uses HBC execution timing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HBCExecutionLog (table)
  - FK: Trade.HedgeServer (HedgeServerID)
  - FK: Trade.LiquidityAccounts (LiquidityAccountID)
  - Implicit: Trade.Instrument (InstrumentID)
  - Child: Hedge.HBCOrderLog (ExecutionID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCOrderLog | Table | Child table: individual FIX orders per execution |
| Hedge.LogHBCExecution | Procedure | Writer: inserts execution + child orders in transaction |
| Hedge.GetHBCEstimationsDiscrepencies | Procedure | Reader: execution vs position lot reconciliation |
| Hedge.GetHBCEstimationsDiscrepencies_Child | Procedure | Reader: cross-server variant |
| Hedge.GetHBCEstimationsDiscrepencies_Child_ss | Procedure | Reader: cross-server snapshot isolation variant |
| Hedge.GetHBCEstimationsDiscrepencies_Flat | Procedure | Reader: flat output variant |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HBCExecutionLog | CLUSTERED PK | ExecutionID ASC | - | - | Active (PAGE compression, PRIMARY filegroup) |
| Idx_Hedge_HBCExecutionLog_StartTime | NONCLUSTERED | StartTime ASC | HedgeServerID, EndTime | WHERE IsSuccess=1 | Active (FILLFACTOR=90, PRIMARY filegroup) |

The filtered NC index (WHERE IsSuccess=1) optimizes time-range queries on successful executions - the primary use case for reconciliation and latency queries.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HBCExecutionLog | PRIMARY KEY (CLUSTERED) | ExecutionID - unique per execution |
| FK_HBCExecutionLog_HedgeServer | FOREIGN KEY (WITH CHECK) | HedgeServerID -> Trade.HedgeServer |
| FK_HBCExecutionLog_LiquidityAccounts | FOREIGN KEY (WITH CHECK) | LiquidityAccountID -> Trade.LiquidityAccounts |
| DF for IsCancelExecution | DEFAULT | IsCancelExecution = 0 |
| DF for CancelledExecutionID | DEFAULT | CancelledExecutionID = 0 |

---

## 8. Sample Queries

### 8.1 Recent HBC execution success rate by instrument
```sql
SELECT TOP 20 InstrumentID,
       SUM(CASE WHEN IsSuccess = 1 THEN 1 ELSE 0 END) AS SuccessCount,
       SUM(CASE WHEN IsSuccess = 0 THEN 1 ELSE 0 END) AS FailCount,
       AVG(CAST(ExecutionAmountInLots - RequestAmountInLots AS float)) AS AvgLotRoundingDelta
FROM Hedge.HBCExecutionLog WITH (NOLOCK)
WHERE StartTime > DATEADD(day, -7, GETUTCDATE())
  AND IsCancelExecution = 0
GROUP BY InstrumentID
ORDER BY SuccessCount DESC;
```

### 8.2 Execution latency (successful executions)
```sql
SELECT TOP 100 ExecutionID, InstrumentID, IsBuy,
       RequestAmountInLots, ExecutionAmountInLots,
       DATEDIFF(ms, StartTime, EndTime) AS LatencyMS,
       ExecutionRate, LPExecutionRate
FROM Hedge.HBCExecutionLog WITH (NOLOCK)
WHERE StartTime > DATEADD(hour, -1, GETUTCDATE())
  AND IsSuccess = 1
  AND IsCancelExecution = 0
ORDER BY StartTime DESC;
```

### 8.3 Failure analysis by reason
```sql
SELECT FailReason, COUNT(1) AS FailCount,
       MIN(StartTime) AS FirstOccurred, MAX(StartTime) AS LastOccurred
FROM Hedge.HBCExecutionLog WITH (NOLOCK)
WHERE IsSuccess = 0
GROUP BY FailReason
ORDER BY FailCount DESC;
```

### 8.4 Link HBC execution to child orders and ExecutionLog
```sql
SELECT el.ExecutionID, el.RequestAmountInLots, el.ExecutionAmountInLots,
       ol.OrderID, ol.HedgeID, ol.OrderState,
       exl.OrderID AS ExecutionLogOrderID, exl.LogTime
FROM Hedge.HBCExecutionLog el WITH (NOLOCK)
JOIN Hedge.HBCOrderLog ol WITH (NOLOCK) ON ol.ExecutionID = el.ExecutionID
LEFT JOIN Hedge.ExecutionLog exl WITH (NOLOCK) ON exl.OrderID = ol.HedgeID
WHERE el.ExecutionID = 13797341;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Findings |
|--------|------|-------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | HBC = order-based execution path (HAPI/LAPI/Dealing Desk -> ExecutionAPI -> HedgeServer -> FIX). HBCExecutionLog: "All HBC executions will be logged here". HBCOrderLog is child (join on HedgeID=ExecutionLog.OrderID). IsHBCFillOrKill config controls partial fill behavior. GetHBCEstimationsDiscrepencies validates ExecutionAmountInLots vs position lots. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.4/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HBCExecutionLog | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.HBCExecutionLog.sql*
