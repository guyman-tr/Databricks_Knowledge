# Hedge.InsertKPIData

> Computes and persists periodic hedge server KPI snapshots: customer vs. account volume by instrument, server-level hedge cost and latency metrics, and volume discrepancy alerts - all written to the primary DB via linked-server synonyms.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to: Hedge.KPIServerLog (via dbo.RW_KKPIServerLog), Hedge.KPIInstrumentLog (via dbo.RW_KPIInstrumentLog), Hedge.EventLog (via dbo.RW_EventLog) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.InsertKPIData` is the hedge KPI collection procedure. Called periodically (typically in 5-minute windows), it computes a comprehensive snapshot of hedge server health for the given time window and persists the results to the primary database.

Created in January 2016 ("Collect KPI Data") and evolved through 2016-2017, it answers the question: **"For the last N minutes, how well was the hedge operation performing?"** Specifically it measures:
- Whether customer position volume and account hedge volume are in sync per instrument
- What the hedge cost was per server
- How fast and successful HBC order execution was
- Whether any instrument had account volume exceeding customer volume (an alert condition)

The procedure is designed to run on the **secondary database** but write to the **primary** via three `dbo.RW_*` synonyms pointing to `[AO-REAL-DB].[etoro].[Hedge].*`. This is the only way to persist KPI data while running on a read-scale replica. All three writes include deduplication guards (NOT EXISTS checks) to prevent double-insertion if the procedure runs multiple times for the same window.

The volume discrepancy alert (EventType=8 in Hedge.EventLog) fires when: (1) account volume > customer volume for an instrument AND (2) the excess is above a monetary threshold (`InstrumentBoundaries.OpenThresholdUSD` converted to major currency).

---

## 2. Business Logic

### 2.1 Customer Volume Calculation (#VolumeCustomer)

**What**: Aggregates total position units transacted by real customers in the window.

**Columns/Parameters Involved**: `@startTime`, `@endTime`

**Rules**:
- UNION of three sources:
  - `Trade.PositionTbl WHERE Occurred BETWEEN @startTime AND @endTime` - positions opened/active in window.
  - `History.Position WHERE CloseOccurred BETWEEN @startTime AND @endTime` - closed positions (exclude test customers: PlayerLevelID=4 from Customer.CustomerStatic).
  - `History.Position WHERE OpenOccurred BETWEEN @startTime AND @endTime` - positions opened historically (exclude test customers).
- Test customers (PlayerLevelID=4) are excluded from History.Position queries to avoid inflating customer-side volume with internal test activity. Note: PlayerLevelID=4 exclusion does NOT apply to Trade.PositionTbl.
- Groups by (HedgeServerID, InstrumentID). Dynamic PK added via EXEC(@PK) with @@SPID suffix to allow parallel executions.

### 2.2 Account Volume Calculation (#VolumeAccount)

**What**: Aggregates total units executed through the hedge account in the window.

**Columns/Parameters Involved**: `@startTime`, `@endTime`

**Rules**:
- UNION of two sources:
  - `Hedge.ExecutionRequestBreakdownLog.AmountInUnits WHERE Occurred BETWEEN @startTime AND @endTime` - all orders sent to LP.
  - `Hedge.ExecutionLog.Units WHERE SendTime BETWEEN @startTime AND @endTime AND OrderState=4` - filled orders only (OrderState=4 = Fill).
- Groups by (HedgeServerID, InstrumentID).

### 2.3 Volume Discrepancy Alert (EventType=8 in Hedge.EventLog)

**What**: Fires an alert when account hedge volume exceeds customer volume by a threshold.

**Columns/Parameters Involved**: `#VolumeAccount.TotalAmountInAccount`, `#VolumeCustomer.TotalAmountByCustomers`, `Hedge.InstrumentBoundaries.OpenThresholdUSD`

**Rules**:
- Alert condition: `TotalAmountInAccount > TotalAmountByCustomers AND (excess * MajorConversion) >= OpenThresholdUSD`.
- `MajorConversion`: Computed via OUTER APPLY on Trade.Instrument + Trade.CurrencyPrice + Trade.GetCurrencyConversionsView to convert the excess to USD.
- Dedup: `NOT EXISTS (SELECT * FROM Hedge.EventLog WHERE Occurred=@startTime AND ServerID=... AND EventType=8 AND Message='InstrumentID=...')`.
- Writes: EventType=8, ServerType=15 (not the standard HedgeServer ServerType=6), Occurred=@startTime.
- Message format: `'InstrumentID={N}'`.

### 2.4 Cancellation Volume (#VolumeCancellation)

**What**: Tracks units cancelled via HBC (not customer-initiated; broker-initiated cancels).

**Columns/Parameters Involved**: `@startTime`, `@endTime`

**Rules**:
- Source: `Hedge.HBCExecutionLog WHERE IsCancelExecution=1` AND `StartTime BETWEEN @startTime AND @endTime`.
- Joins to original execution (via CancelledExecutionID) to get both the cancel and the original entry.
- Computes: `SUM(el1.ExecutionAmountInLots * PTI.Unit + el2.ExecutionAmountInLots * PTI.Unit)` per HedgeServerID.
- Groups by HedgeServerID only (not per instrument like volume customer/account).

### 2.5 HBC Execution Latency (#Latency)

**What**: MIN/AVG/MAX execution time for successful HBC orders in the window.

**Columns/Parameters Involved**: `HBCAvgExecTimeMS`, `HBCMinExecTimeMS`, `HBCMaxExecTimeMS`

**Rules**:
- Source: `Hedge.HBCExecutionLog WHERE IsSuccess=1 AND StartTime BETWEEN @startTime AND @endTime`.
- Computes: `DATEDIFF(millisecond, StartTime, EndTime)` for each row.
- 0 = no successful HBC executions in the period.

### 2.6 Order Success Ratio (#TotalOrder, #OrderSuccess)

**What**: Measures execution success rate for hedge orders.

**Columns/Parameters Involved**: `TotalOrderAttempts`, `TotalOrderSuccess`

**Rules**:
- `TotalOrderAttempts`: COUNT from ExecutionRequestBreakdownLog + ExecutionLog (WHERE SendTime in window) per HedgeServerID.
- `TotalOrderSuccess`: COUNT of matched ExecutionRequestBreakdownLog + ExecutionResponseBreakdownLog (WasOpened=1) UNION ExecutionLog (OrderState=4).
- Success rate = TotalOrderSuccess / TotalOrderAttempts.

### 2.7 Synonym Write Strategy (Primary DB via Secondary)

**What**: All three INSERTs use `dbo.RW_*` synonyms pointing to the primary database.

**Columns/Parameters Involved**: `dbo.RW_KKPIServerLog`, `dbo.RW_KPIInstrumentLog`, `dbo.RW_EventLog`

**Rules**:
- Modified in November 2017: all three INSERTs changed from direct table names to synonyms pointing to `[AO-REAL-DB].[etoro].[Hedge].*`.
- Purpose: enables the procedure to run on the secondary (read-scale) replica while persisting results to the primary.
- Note: KPIServerLog synonym has a double-K typo: `dbo.RW_KKPIServerLog`.

**Diagram**:
```
@startTime / @endTime
     |
     +-- #TestCustomers (PlayerLevelID=4 from Customer.CustomerStatic)
     |
     +-- #VolumeCustomer (PositionTbl + History.Position per instrument, ex-test customers)
     +-- #VolumeAccount  (ExecutionRequestBreakdownLog + ExecutionLog fills per instrument)
     |
     +-- #VolumeCancellation (HBCExecutionLog cancel executions, per server)
     +-- #Latency (HBCExecutionLog successful executions, AVG/MIN/MAX ms)
     +-- #HedgeCost (Hedge.GetHedgeCostPerHS(@startTime, @endTime))
     |
     +-- #deposit, #withdrawal -> #AccountTransactions
     +-- #TotalOrder, #OrderSuccess
     |
     +-- INSERT dbo.RW_KKPIServerLog -> primary: Hedge.KPIServerLog
     |   (one row per active HedgeServer, if any metric non-zero)
     |   (dedup: NOT EXISTS on StartTime + HedgeServerID)
     |
     +-- INSERT dbo.RW_KPIInstrumentLog -> primary: Hedge.KPIInstrumentLog
     |   (one row per active HedgeServer x Instrument)
     |   (dedup: NOT EXISTS on StartTime + HedgeServerID + InstrumentID)
     |
     +-- INSERT dbo.RW_EventLog -> primary: Hedge.EventLog (EventType=8)
         (ONLY for instruments where TotalAmountInAccount > TotalAmountByCustomers
          AND excess * MajorConversion >= OpenThresholdUSD)
         (dedup: NOT EXISTS on Occurred + ServerID + EventType=8 + Message)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @startTime | DATETIME | NO | - | CODE-BACKED | Start of the KPI measurement window (inclusive). Used as BETWEEN lower bound for all queries. Also stored as StartTime in the three output tables and as Occurred in the EventLog alert. Callers typically pass a fixed interval boundary (e.g., 5-minute window start). |
| 2 | @endTime | DATETIME | NO | - | CODE-BACKED | End of the KPI measurement window (exclusive - WHERE ... < @endTime). Used as the upper bound for all queries. Stored as EndTime in the three output tables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CustomerStatic | READ | Identifies test customers (PlayerLevelID=4) to exclude from customer volume |
| - | Trade.PositionTbl | READ | Active customer positions in the time window |
| - | History.Position | READ | Historically closed/opened customer positions in the time window (ex-test customers) |
| - | Hedge.ExecutionRequestBreakdownLog | READ | Account-side volume (all orders sent) + order attempt count |
| - | Hedge.ExecutionLog | READ | Account-side volume (filled orders, OrderState=4) + success count |
| - | Hedge.ExecutionResponseBreakdownLog | READ | Order success indicator (WasOpened=1) for success ratio |
| - | Hedge.HBCExecutionLog | READ | HBC latency (IsSuccess=1) + cancellation volume (IsCancelExecution=1) |
| - | Hedge.AccountTransactions | READ | Deposits (TransactionTypeID=1) and withdrawals (TransactionTypeID=2) for the period |
| - | Trade.HedgeServer | READ | Active servers (IsActive=1) - determines which servers get KPI rows |
| - | Hedge.GetHedgeCostPerHS | FUNCTION | Server-level hedge cost computation (returns ZeroPL, PNL components, Commission) |
| - | Hedge.InstrumentBoundaries | READ | OpenThresholdUSD for per-instrument volume alert threshold |
| - | Trade.Instrument | READ | Instrument attributes for MajorConversion calc (BuyCurrencyID, SellCurrencyID) |
| - | Trade.CurrencyPrice | READ | Current prices for major currency conversion |
| - | Trade.GetCurrencyConversionsView | READ | Currency conversion paths for threshold calculation |
| - | Trade.ProviderToInstrument | READ | PTI.Unit for cancellation volume calculation (lots to units) |
| - | Hedge.KPIServerLog | READ | Dedup check: NOT EXISTS for same StartTime + HedgeServerID |
| - | Hedge.KPIInstrumentLog | READ | Dedup check: NOT EXISTS for same StartTime + HedgeServerID + InstrumentID |
| - | Hedge.EventLog | READ | Dedup check: NOT EXISTS EventType=8 for same Occurred + ServerID + InstrumentID |
| - | dbo.RW_KKPIServerLog | WRITE (synonym) | Insert target for KPIServerLog (note double-K typo) |
| - | dbo.RW_KPIInstrumentLog | WRITE (synonym) | Insert target for KPIInstrumentLog |
| - | dbo.RW_EventLog | WRITE (synonym) | Insert target for EventLog EventType=8 alerts |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.InsertKPIData (procedure)
|-- Customer.CustomerStatic (table) [READ - test customer exclusion]
|-- Trade.PositionTbl (table) [READ - active customer volume]
|-- History.Position (table) [READ - historical customer volume]
|-- Hedge.ExecutionRequestBreakdownLog (table) [READ - account volume + order attempts]
|-- Hedge.ExecutionLog (table) [READ - filled order volume + success count]
|-- Hedge.ExecutionResponseBreakdownLog (table) [READ - order success flag WasOpened]
|-- Hedge.HBCExecutionLog (table) [READ - latency + cancellation volume]
|-- Hedge.AccountTransactions (table) [READ - deposit/withdrawal flows]
|-- Trade.HedgeServer (table) [READ - active server list]
|-- Hedge.InstrumentBoundaries (table) [READ - alert threshold OpenThresholdUSD]
|-- Trade.Instrument (table) [READ - currency conversion basis]
|-- Trade.CurrencyPrice (table) [READ - conversion prices]
|-- Trade.GetCurrencyConversionsView (view) [READ - conversion paths]
|-- Trade.ProviderToInstrument (table) [READ - lot unit size for cancellation volume]
|-- Hedge.GetHedgeCostPerHS (function) [EXEC - server hedge cost aggregates]
|-- Hedge.KPIServerLog (table) [READ - dedup check on primary]
|-- Hedge.KPIInstrumentLog (table) [READ - dedup check on primary]
+-- Hedge.EventLog (table) [READ - dedup check for EventType=8]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Test customer exclusion (PlayerLevelID=4) |
| Trade.PositionTbl | Table | Customer volume: active positions opened in window |
| History.Position | Table | Customer volume: historically closed/opened positions |
| Hedge.ExecutionRequestBreakdownLog | Table | Account volume (all orders) + total order attempt count |
| Hedge.ExecutionLog | Table | Account volume (fills, OrderState=4) + success count |
| Hedge.ExecutionResponseBreakdownLog | Table | Order success: WasOpened=1 matching request entries |
| Hedge.HBCExecutionLog | Table | Latency (IsSuccess=1) and cancellation volume (IsCancelExecution=1) |
| Hedge.AccountTransactions | Table | Deposit (TypeID=1) and withdrawal (TypeID=2) amounts for the period |
| Trade.HedgeServer | Table | Active server list (IsActive=1) drives output rows |
| Hedge.InstrumentBoundaries | Table | OpenThresholdUSD - volume discrepancy alert threshold |
| Trade.Instrument | Table | BuyCurrencyID/SellCurrencyID for major conversion |
| Trade.CurrencyPrice | Table | Current prices for conversion |
| Trade.GetCurrencyConversionsView | View | Currency conversion path resolution |
| Trade.ProviderToInstrument | Table | Unit lot size for cancellation volume calculation |
| Hedge.GetHedgeCostPerHS | Function | Hedge cost and P&L components per server for the period |
| Hedge.KPIServerLog | Table | Dedup check (prevents double-insert for same window) |
| Hedge.KPIInstrumentLog | Table | Dedup check (prevents double-insert per instrument) |
| Hedge.EventLog | Table | Dedup check for EventType=8 alerts |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called periodically from an external scheduler/agent on the secondary DB. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SPID-based PK naming | Concurrency | All temp table PKs use `@@SPID` suffix (e.g., `PK_#VolumeCustomer_{@@SPID}`) to allow multiple concurrent instances of this procedure. |
| dbo.RW_* synonyms | Cross-DB write | All three INSERT targets are synonyms pointing to the primary DB ([AO-REAL-DB]). Procedure must run on the secondary for its reads but writes go to primary via linked server. |
| PlayerLevelID = 4 exclusion | Test data filter | Customers with PlayerLevelID=4 are excluded from History.Position volume (but NOT from Trade.PositionTbl). |
| IsActive = 1 | Server filter | Only active hedge servers (Trade.HedgeServer.IsActive=1) receive KPI rows. |
| NOT EXISTS dedup | Idempotency | All three INSERTs are guarded by NOT EXISTS checks on the destination tables - safe to re-run for the same window. |

---

## 8. Sample Queries

### 8.1 Execute KPI data collection for a 5-minute window
```sql
-- Run on the secondary DB (reads local; writes to primary via synonyms)
EXEC [Hedge].[InsertKPIData]
    @startTime = '2026-03-19 08:00:00',
    @endTime   = '2026-03-19 08:05:00'
```

### 8.2 Check customer vs account volume for a window (preview before inserting)
```sql
-- Customer volume (active positions opened in window)
SELECT HedgeServerID, InstrumentID,
       SUM(AmountInUnitsDecimal) AS CustomerUnits
FROM [Trade].[PositionTbl] WITH (NOLOCK)
WHERE Occurred >= '2026-03-19 08:00:00'
  AND Occurred <  '2026-03-19 08:05:00'
GROUP BY HedgeServerID, InstrumentID
ORDER BY HedgeServerID, InstrumentID
```

### 8.3 Check for volume discrepancy EventType=8 alerts
```sql
SELECT EL.Occurred, EL.ServerID, EL.Message,
       EL.OccurredInsert
FROM [Hedge].[EventLog] EL WITH (NOLOCK)
WHERE EL.EventType = 8
  AND EL.Occurred >= DATEADD(day, -7, GETUTCDATE())
ORDER BY EL.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InsertKPIData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.InsertKPIData.sql*
