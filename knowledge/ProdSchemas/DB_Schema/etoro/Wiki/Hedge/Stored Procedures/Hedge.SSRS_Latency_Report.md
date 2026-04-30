# Hedge.SSRS_Latency_Report

> SSRS latency report for HBC (Fully Async) hedge executions: computes P90/P99 request latency, provider response latency, total latency, throughput, and fill ratio per liquidity account and hedge server over a specified date range (max 24 hours).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate (time window, max 24 hours) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.SSRS_Latency_Report` is a **read-only reporting stored procedure** designed for SSRS (SQL Server Reporting Services) that measures the end-to-end latency of HBC (Hedge Broker Client / Fully Async) hedge order executions. It gives the Hedge/Trading operations team a statistical view of execution performance - including how quickly orders are processed, how fast liquidity providers respond, and how often orders are filled vs routed - broken down by liquidity account and hedge server.

The report exists to answer operational questions like: "Which LP had the highest P99 latency yesterday?", "What is the average fill ratio per LiquidityAccount this morning?", and "Are any hedge servers processing orders slower than expected?" This data supports SLA monitoring, LP performance reviews, and operational tuning.

Data flows as follows: the caller provides a time window (defaulting to yesterday's UTC date if omitted). The procedure reads from two cross-database synonyms pointing to the eToroLogs database (`dbo.SynHedgeEMSOrders` for EMS order state, `dbo.SyneToroLogsHedgeOrderLog` for order logs), joined with local Hedge tables (`Hedge.ExecutionLog`, `Hedge.HBCExecutionLog`, `Hedge.HBCOrderLog`) and `Trade.LiquidityAccounts` for account names. Results are accumulated into a single `#FinalResult` temp table with a `ResultType` discriminator column and returned to the SSRS report.

---

## 2. Business Logic

### 2.1 Two Parallel Metric Flows

**What**: The report produces two independent sets of metrics - "Fully Async" (HBC, direct EMS path) and "Hedge Server" (via HBC/HBCOrderLog chain) - for the same time window.

**Columns/Parameters Involved**: `ResultType`, `@StartDate`, `@EndDate`

**Rules**:
- `FullyAsnc_*` rows: data sourced from `dbo.SynHedgeEMSOrders` joined to `dbo.SyneToroLogsHedgeOrderLog` and `Hedge.ExecutionLog`. Filtered by `HedgeExecutionModeID = 1` (HBC only).
- `HedgeServer_*` rows: data sourced from `dbo.SynHedgeEMSOrders` joined to `Hedge.HBCExecutionLog` -> `Hedge.HBCOrderLog` -> `Hedge.ExecutionLog` (a deeper join chain through local hedge tables).
- Both flows produce equivalent metric shapes (Metrics 1-6) but track slightly different join paths, enabling comparison.
- `FullyAsnc_7` is unique to the Fully Async flow: overall fill ratio by HedgeServer and OperationalMode.

**Diagram**:
```
FullyAsnc flow:  SynHedgeEMSOrders + SyneToroLogsHedgeOrderLog + Hedge.ExecutionLog
HedgeServer flow: SynHedgeEMSOrders + HBCExecutionLog + HBCOrderLog + ExecutionLog

Both flows -> #FinalResult (ResultType = 'FullyAsnc_1..7' or 'HedgeServer_1..6')
```

### 2.2 Five Latency and Throughput Metrics (Per Flow)

**What**: Each flow produces 5 latency/throughput metrics (numbered 1-5) and a 6th fill-ratio metric.

**Columns/Parameters Involved**: `ResultType`, `Max_*`, `Avg_*`, `P90_*`, `P99_*`

**Rules**:
- **Metric 1 (Request_Process_Time)**: DATEDIFF(ms, EMS.RequestTime, OrderLog.SendTime) - time from hedge execution request to order being sent to LP. Filter: `OrderState > 2 AND OrderStatus = 'Routed'`.
- **Metric 2 (Provider_Response_Latency)**: DATEDIFF(ms, SendTime, ReceivedTime) - time from sending order to receiving LP response. Filter: `OrderState IN (3, 4) AND OrderStatus = 'Routed'`.
- **Metric 3 (Execution_Response_Process_Time)**: DATEDIFF(ms, ReceivedTime, StatusUpdateTime) - time to process LP response. Filter: `OrderState IN (4, 5) AND OrderStatus IN ('Filled', 'Rejected')`.
- **Metric 4 (Total_Latancy)**: Metric 1 + Metric 3 = total internal hedge system latency (excludes LP response time). Computed by joining Metric 1 and Metric 3 temp tables on ExecutionID.
- **Metric 5 (Count_Executions_Per_Second)**: throughput = executions per second per LiquidityAccount.

### 2.3 Date Range Validation and Defaults

**What**: The procedure enforces a maximum 24-hour window and sets sensible defaults.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`

**Rules**:
- `@StartDate = NULL`: defaults to yesterday's UTC date (CAST(GETUTCDATE()-1 AS DATE)).
- `@StartDate provided, @EndDate = NULL`: truncates @StartDate to midnight, sets @EndDate = @StartDate + 1 day.
- `@StartDate AND @EndDate provided`: validates that DATEDIFF(HOUR, @StartDate, @EndDate) <= 24; if > 24, RETURN immediately with no result set.
- This prevents accidental full-history queries on large log tables via the cross-DB synonyms.

### 2.4 Metric 7: Fill Ratio by HedgeServer and OperationalMode

**What**: Only available in the FullyAsnc flow - provides aggregate fill ratio per hedge server and its operational mode.

**Columns/Parameters Involved**: `HedgeServerID`, `OperationalMode`, `Executions_Count_Filled`, `Executions_Count_Filled_Plus_Rejected`, `Overall Fill Ratio`

**Rules**:
- Joins `dbo.SynHedgeEMSOrders` to `Trade.HedgeServer` to get the server's `OperationalMode`.
- Computes: Fill Ratio = Filled / (Filled + Rejected).
- Groups by HedgeServerID and OperationalMode to show performance split by server configuration.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | YES | NULL | CODE-BACKED | Report start boundary (inclusive). If NULL: defaults to yesterday UTC midnight. If provided without @EndDate: truncated to midnight and @EndDate set to next midnight. All EMS order times are in UTC. |
| 2 | @EndDate | DATETIME | YES | NULL | CODE-BACKED | Report end boundary (exclusive). If NULL: auto-set to @StartDate + 1 day. Must be within 24 hours of @StartDate; if the range exceeds 24 hours, the procedure returns immediately with no rows. |

**Result set returned** (`#FinalResult` columns):

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | ResultType | varchar(20) | Row discriminator identifying which metric and flow this row represents. Values: 'FullyAsnc_1'..'FullyAsnc_7', 'HedgeServer_1'..'HedgeServer_6'. |
| 2 | LiquidityAccountID | varchar(70) | Formatted as `{LiquidityAccountID} - {LiquidityAccountName}` (ID + name from Trade.LiquidityAccounts). NULL for Metric 7 rows (which use HedgeServerID instead). |
| 3 | Count_Executions | int | Number of executions included in this metric row for the LP account. NULL for Metric 5 (per-second rows). |
| 4 | Max_Request_Process_Time | varchar(70) | Max Metric 1 latency in ms, formatted as `{value} ({ExecutionID})` showing the worst-case execution. NULL for Metric 2-7 rows. |
| 5 | Avg_Request_Process_Time | int | Average Metric 1 latency in milliseconds. NULL for Metric 2-7 rows. |
| 6 | P90_FullyAsync_Metric1 | int | 90th percentile of Metric 1 latency in ms (PERCENTILE_CONT(0.9)). NULL for other metrics. |
| 7 | P99_FullyAsync_Metric1 | int | 99th percentile of Metric 1 latency in ms. NULL for other metrics. |
| 8 | Max_Provider_Response_Latency | varchar(70) | Max Metric 2 latency (LP response time) in ms with ExecutionID. |
| 9 | Avg_Provider_Response_Latency | int | Average Metric 2 latency in milliseconds. |
| 10 | P90_FullyAsync_Metric2 | int | 90th percentile of Metric 2 latency in ms. |
| 11 | P99_FullyAsync_Metric2 | int | 99th percentile of Metric 2 latency in ms. |
| 12 | Max_Execution_Response_Process_Time | varchar(70) | Max Metric 3 latency (response processing time) in ms with ExecutionID. |
| 13 | Avg_Execution_Response_Process_Time | int | Average Metric 3 latency in milliseconds. |
| 14 | P90_FullyAsync_Metric3 | int | 90th percentile of Metric 3 latency in ms. |
| 15 | P99_FullyAsync_Metric3 | int | 99th percentile of Metric 3 latency in ms. |
| 16 | Max_Total_Latancy | varchar(70) | Max total latency (Metric 1 + Metric 3) in ms with ExecutionID. Note: column name typo "Latancy" preserved from DDL. |
| 17 | Avg_Total_Latancy | int | Average total latency (Metric 1 + Metric 3) in ms. |
| 18 | P90_FullyAsync_Metric4 | int | 90th percentile of total latency in ms. |
| 19 | P99_FullyAsync_Metric4 | int | 99th percentile of total latency in ms. |
| 20 | Max_Count_Executions_Per_Second | decimal(12,2) | Max throughput (executions/second) in any 1-second bucket for this LP account. |
| 21 | Avg_Count_Executions_Per_Second | decimal(12,2) | Average throughput (executions/second) across all 1-second buckets. |
| 22 | P90_FullyAsync_Metric5 | decimal(12,2) | 90th percentile throughput. |
| 23 | P99_FullyAsync_Metric5 | decimal(12,2) | 99th percentile throughput. |
| 24 | Fill Ratio | decimal(12,2) | Metric 6: Filled / Routed ratio for this LP account (0.0 - 1.0). NULL for other metrics. |
| 25 | HedgeServerID | int | Only populated for Metric 7 rows (FullyAsnc_7). FK to Trade.HedgeServer. |
| 26 | OperationalMode | smallint | Only populated for Metric 7 rows. The server's operational mode from Trade.HedgeServer. |
| 27 | Executions_Count_Filled | int | Metric 7 only: number of filled executions for this HedgeServerID/OperationalMode. |
| 28 | Executions_Count_Filled_Plus_Rejected | int | Metric 7 only: filled + rejected = total attempted executions. |
| 29 | Overall Fill Ratio | decimal(12,2) | Metric 7 only: Filled / (Filled + Rejected) for this HedgeServerID/OperationalMode. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (raw data) | dbo.SynHedgeEMSOrders | Synonym (cross-DB) | Synonym for [eToroLogs_Real].[Hedge].[EMSOrders] - source of EMS order lifecycle timestamps |
| (raw data) | dbo.SyneToroLogsHedgeOrderLog | Synonym (cross-DB) | Synonym for [eToroLogs_Real].[Hedge].[OrderLog] - source of SendTime per order |
| (join) | Hedge.ExecutionLog | READER | Provides ReceivedTime, OrderState, LiquidityAccountID via EMSOrderID match |
| (join) | Hedge.HBCExecutionLog | READER | Used in HedgeServer flow to link ExecutionID from EMS to HBC execution data |
| (join) | Hedge.HBCOrderLog | READER | Used in HedgeServer flow to link HBC executions to ExecutionLog via HedgeID |
| (lookup) | Trade.LiquidityAccounts | READER | Resolves LiquidityAccountID to LiquidityAccountName for result set display |
| (lookup) | Trade.HedgeServer | READER | Metric 7 only - provides OperationalMode per HedgeServerID |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. Consumed directly by SSRS report definitions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.SSRS_Latency_Report (procedure)
+-- dbo.SynHedgeEMSOrders (synonym -> cross-DB: eToroLogs_Real.Hedge.EMSOrders) [leaf]
+-- dbo.SyneToroLogsHedgeOrderLog (synonym -> cross-DB: eToroLogs_Real.Hedge.OrderLog) [leaf]
+-- Hedge.ExecutionLog (table) [leaf]
+-- Hedge.HBCExecutionLog (table) [leaf]
+-- Hedge.HBCOrderLog (table) [leaf]
+-- Trade.LiquidityAccounts (table) [cross-schema leaf]
+-- Trade.HedgeServer (table) [cross-schema leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SynHedgeEMSOrders | Synonym | Source of EMS order data (RequestTime, StatusUpdateTime, OrderStatus, HedgeExecutionModeID, HedgeServerID, ExecutionID) |
| dbo.SyneToroLogsHedgeOrderLog | Synonym | Source of SendTime per ExecutionID (order log from eToroLogs database) |
| Hedge.ExecutionLog | Table | Provides ReceivedTime, OrderState, LiquidityAccountID; joined on EMSOrderID = OrderID (with COLLATE Latin1_General_BIN) |
| Hedge.HBCExecutionLog | Table | HedgeServer flow join bridge: ExecutionID from EMS to HBC execution record |
| Hedge.HBCOrderLog | Table | HedgeServer flow join bridge: links HBC execution to ExecutionLog via HedgeID |
| Trade.LiquidityAccounts | Table | Name lookup: LiquidityAccountID -> LiquidityAccountName for result display |
| Trade.HedgeServer | Table | OperationalMode lookup for Metric 7 |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Consumed by SSRS reports externally.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 24-hour max range | Business validation | IF DATEDIFF(HOUR, @StartDate, @EndDate) > 24: RETURN with no result set. Prevents full-history scans on large log tables. |
| COLLATE Latin1_General_BIN | Implicit conversion | JOIN: hl.EMSOrderID = (ol.OrderID COLLATE Latin1_General_BIN) - handles collation mismatch between cross-DB OrderID and local EMSOrderID |
| HedgeExecutionModeID = 1 | Filter | Report scoped to HBC (Fully Async) mode only; other execution modes excluded |

---

## 8. Sample Queries

### 8.1 Run report for yesterday (default)
```sql
EXEC [Hedge].[SSRS_Latency_Report];
-- Defaults to yesterday's UTC date, 00:00:00 - 24:00:00
```

### 8.2 Run report for a specific 6-hour window
```sql
EXEC [Hedge].[SSRS_Latency_Report]
    @StartDate = '2026-03-19 08:00:00',
    @EndDate   = '2026-03-19 14:00:00';
```

### 8.3 Filter the result set to P99 latency metrics only
```sql
-- After calling the procedure, filter from the result set:
SELECT ResultType, LiquidityAccountID,
       Count_Executions,
       P99_FullyAsync_Metric1 AS P99_RequestProcessTime_ms,
       P99_FullyAsync_Metric2 AS P99_ProviderResponseLatency_ms,
       P99_FullyAsync_Metric4 AS P99_TotalLatency_ms
FROM (
    EXEC [Hedge].[SSRS_Latency_Report] @StartDate = '2026-03-19'
) r
WHERE ResultType LIKE 'FullyAsnc_%'
ORDER BY P99_FullyAsync_Metric4 DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.SSRS_Latency_Report | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.SSRS_Latency_Report.sql*
