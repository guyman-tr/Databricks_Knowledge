# Trade.SSRS_NonAsyncLatencyReport

> SSRS latency monitoring procedure that measures position open and close processing latency (milliseconds) for the synchronous (non-async) trading path, with percentile statistics (P90, P99) and optional hedge server latency breakdown.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @fromDate / @toDate (same-day window required) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the data source for the non-async (synchronous) position latency SSRS report used by trading operations and engineering teams to monitor SLA compliance on position processing speed. It measures the round-trip latency from when a position was requested (`RequestOccurred` / `RequestCloseOccurred`) to when it was executed (`Occurred` / `CloseOccurred`) in milliseconds.

The procedure exists because the trading platform has strict latency SLAs: positions should open and close within defined millisecond thresholds. This report identifies when those SLAs are being breached by surfacing P90 and P99 latency statistics - if P99 is above the SLA threshold, 1% of customers are experiencing degraded performance. Operations uses this report to detect performance regressions immediately after deployment or during market-open spikes.

Data flows as follows: positions from the current trading window (`@fromDate` to `@toDate`) are loaded from both live (`Trade.PositionTbl`) and recently-closed (`History.Position_Active`) tables. Latency is calculated as the absolute millisecond difference between request and execution timestamps. Results are stored in a #Result temp table with 6 `ResultType` rows returned as a single wide result set. The `@All_HBC_CBH` flag allows filtering by price routing type (HBC = no forex rate, CBH = with forex rate).

---

## 2. Business Logic

### 2.1 Same-Day Guard

**What**: Restricts the report to intraday windows only - prevents expensive historical queries.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`

**Rules**:
- If `DATEDIFF(DAY, @fromDate, @toDate) > 0`, the procedure returns immediately with no data.
- The window must fit within a single calendar day (midnight-to-midnight boundary).
- Designed for real-time and intraday monitoring, not historical trend analysis.

### 2.2 Latency Calculation Method

**What**: Defines how position processing latency is measured.

**Columns/Parameters Involved**: `RequestOccurred`, `Occurred` (open), `RequestCloseOccurred`, `CloseOccurred` (close)

**Rules**:
- Open latency: `ABS(DATEDIFF(MILLISECOND, RequestOccurred, Occurred))` - time from request to position creation.
- Close latency: `ABS(DATEDIFF(MILLISECOND, RequestCloseOccurred, CloseOccurred))` - time from close request to close execution.
- `ABS()` is used to handle any timestamp ordering anomalies.
- For each group, statistics are computed: Count, Max, Min, Avg, P90, P99 (using `PERCENTILE_CONT`).

**Diagram**:
```
Position Open flow (latency measurement):
  RequestOccurred  ->  [processing]  ->  Occurred
  |<--- Latency (ms) = ABS(DATEDIFF(MILLISECOND, ...)) --->|

Position Close flow:
  RequestCloseOccurred  ->  [processing]  ->  CloseOccurred
  |<--- Close Latency (ms) ------------->|
```

### 2.3 HBC vs CBH Routing Filter

**What**: Allows filtering by price routing mode to compare latency between two trade execution paths.

**Columns/Parameters Involved**: `@All_HBC_CBH`, `InitForexPriceRateID`, `EndForexPriceRateID`

**Rules**:
- `@All_HBC_CBH = 1` (default): All positions regardless of routing.
- `@All_HBC_CBH = 2` (HBC): Positions where `InitForexPriceRateID = 0` (no forex price rate applied at open).
- `@All_HBC_CBH = 3` (CBH): Positions where `InitForexPriceRateID > 0` (forex price rate applied at open).
- The same filter applies to close data using `EndForexPriceRateID`.
- This allows operations to compare latency between the two routing paths to isolate performance differences.

### 2.4 Open Action Type Segmentation (ResultType 3)

**What**: Breaks down open latency by the specific mechanism used to open the position.

**Columns/Parameters Involved**: `OpenActionType`, `OrderType`, `MirrorID`, `OrderID`

**Rules**:
- 'Entry Order Execution': OrderID > 0 AND MirrorID = 0 AND OrderType IN (13, 16) - limit order fills for manual positions
- 'Entry Order Execution in mirror': OrderID > 0 AND OrderType IN (13, 16) AND MirrorID > 0 - limit order fills in copy trades
- 'Manual Open': No OrderForOpen match AND OrderType IN (17, 18) AND MirrorID = 0 - direct market opens
- 'Open Open / Add Fund': OrderID IS NULL AND OpenActionType IN (3, 8) - re-open or fund allocation
- 'Hierarchical Open': OrderID IS NULL AND OpenActionType IN (1) - copy trade hierarchy open
- 'Rate Order Execution': OrderID > 0 AND OrderType IN (0, 15) - rate-based limit orders

### 2.5 Close Action Type Segmentation (ResultType 6)

**What**: Breaks down close latency by the specific close mechanism.

**Columns/Parameters Involved**: `ActionType`, `ExitOrderID`, `ExitOrderType`, `MirrorID`

**Rules**:
- 'Exit Order Execution': ExitOrderID > 0 AND MirrorID = 0 AND ExitOrderType IS NULL
- 'Exit Order Execution in mirror': ExitOrderID > 0 AND ExitOrderType IS NULL AND MirrorID > 0 (noted as "No data!!!" in comment - currently produces 0 rows)
- 'Manual Close': ExitOrderID = 0 AND ActionType IN (0, 8, 19) AND MirrorID = 0
- 'Close in mirror': ExitOrderID = 0 AND ActionType IN (13, 14, 17, 18, 23) AND MirrorID > 0
- 'Hierarchical Close': ActionType IN (9) AND ExitOrderID = 0

### 2.6 Optional Hedge Server Latency

**What**: When enabled, also measures the time from position request to hedge server execution.

**Columns/Parameters Involved**: `@ShowHedgeLatency`, `ExecutionID`, `Latency_Request_Hedge`

**Rules**:
- When `@ShowHedgeLatency = 1`: joins to `eToroLogs_Real.Hedge.ResponseExecutionLog` on `ExecutionID` to get `ExecutionTime` on the hedge server.
- Hedge latency = `ABS(DATEDIFF(MILLISECOND, RequestOccurred, h.ExecutionTime))`.
- When `@ShowHedgeLatency = 0` (default): `Latency_Request_Hedge` is NULL for all rows.
- ResultType 2 shows non-hierarchical open hedge latency (OpenActionType <> 1).
- ResultType 5 shows non-hierarchical close hedge latency (OpenActionType <> 9).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | DATETIME | NO | - | CODE-BACKED | Start of the monitoring window. Positions with Occurred (open) or CloseOccurred (close) >= @fromDate are included. Must be on the same calendar day as @toDate or the procedure returns nothing. |
| 2 | @toDate | DATETIME | NO | - | CODE-BACKED | End of the monitoring window. Must be on the same calendar day as @fromDate (DATEDIFF(DAY) must be 0). Typically GETDATE() or a specific end-of-window time. |
| 3 | @ShowHedgeLatency | BIT | NO | 0 | CODE-BACKED | When 1, joins to eToroLogs_Real.Hedge.ResponseExecutionLog to calculate hedge server latency (time from request to hedge execution). When 0 (default), Latency_Request_Hedge columns are all NULL. Adds significant query cost when enabled. |
| 4 | @All_HBC_CBH | TINYINT | NO | 1 | CODE-BACKED | Price routing filter: 1=All positions, 2=HBC only (InitForexPriceRateID = 0, no forex rate applied), 3=CBH only (InitForexPriceRateID > 0, forex rate applied). Allows isolating latency by routing path. |

### Output Columns (Wide Result Set - #Result)

The procedure returns a single wide result set with one row per ResultType (6 rows total). Most columns are NULL for ResultTypes that don't apply.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ResultType | TINYINT | NO | - | CODE-BACKED | Row identifier: 1=Open summary, 2=Open hedge summary, 3=Open by action, 4=Close summary, 5=Close hedge summary, 6=Close by action. Multiple rows may share the same ResultType (ResultType 3 and 6 have one row per action category). |
| 2 | Result1 - Open Positions Count | INT | YES | - | CODE-BACKED | (ResultType 1) Total non-async positions opened in the window. |
| 3 | Result1 - Max_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 1) Maximum open latency in milliseconds. |
| 4 | Result1 - Min_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 1) Minimum open latency in milliseconds. |
| 5 | Result1 - Avg_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 1) Average open latency in milliseconds. |
| 6 | Result1 - P90 | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 1) 90th percentile open latency in milliseconds. 90% of positions opened faster than this value. |
| 7 | Result1 - P99 | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 1) 99th percentile open latency in milliseconds. SLA breach indicator - if above threshold, 1% of opens are slow. |
| 8 | Result2 - Non Hierarchical Open Positions Count | INT | YES | - | CODE-BACKED | (ResultType 2) Count of non-hierarchical (non-copy) positions in the open window. |
| 9 | Result2 - Max_Latency_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 2) Max hedge latency for non-hierarchical opens. NULL when @ShowHedgeLatency = 0. |
| 10 | Result2 - Min_Latency_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 2) Min hedge latency for non-hierarchical opens. NULL when @ShowHedgeLatency = 0. |
| 11 | Result2 - Avg_Latency_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 2) Avg hedge latency for non-hierarchical opens. NULL when @ShowHedgeLatency = 0. |
| 12 | Result2 - P90_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 2) P90 hedge latency for non-hierarchical opens (OpenActionType <> 1). |
| 13 | Result2 - P99_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 2) P99 hedge latency for non-hierarchical opens. |
| 14 | Result3 - Open Action | VARCHAR(50) | YES | - | CODE-BACKED | (ResultType 3) Action category label: 'Entry Order Execution', 'Entry Order Execution in mirror', 'Manual Open', 'Open Open / Add Fund', 'Hierarchical Open', 'Rate Order Execution'. |
| 15 | Result3 - Positions Count | INT | YES | - | CODE-BACKED | (ResultType 3) Count of opens for this action category. |
| 16 | Result3 - Max_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 3) Max latency for this open action category in milliseconds. |
| 17 | Result3 - Min_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 3) Min latency for this open action category. |
| 18 | Result3 - Avg_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 3) Avg latency for this open action category. |
| 19 | Result3 - P90 | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 3) P90 latency for this open action category. |
| 20 | Result3 - P99 | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 3) P99 latency for this open action category. |
| 21 | Result4 - Close Positions Count | INT | YES | - | CODE-BACKED | (ResultType 4) Total non-async positions closed in the window. |
| 22 | Result4 - Max_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 4) Maximum close latency in milliseconds. |
| 23 | Result4 - Min_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 4) Minimum close latency. |
| 24 | Result4 - Avg_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 4) Average close latency. |
| 25 | Result4 - P90 | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 4) P90 close latency. |
| 26 | Result4 - P99 | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 4) P99 close latency in milliseconds. SLA breach indicator for close performance. |
| 27 | Result5 - Non Hierarchical Close Positions Count | INT | YES | - | CODE-BACKED | (ResultType 5) Count of non-hierarchical close positions (OpenActionType <> 9). |
| 28 | Result5 - Max_Latency_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 5) Max hedge latency for non-hierarchical closes. NULL when @ShowHedgeLatency = 0. |
| 29 | Result5 - Min_Latency_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 5) Min hedge latency. NULL when @ShowHedgeLatency = 0. |
| 30 | Result5 - Avg_Latency_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 5) Avg hedge latency. NULL when @ShowHedgeLatency = 0. |
| 31 | Result5 - P90_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 5) P90 hedge latency. |
| 32 | Result5 - P99_Request_Hedge | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 5) P99 hedge latency. |
| 33 | Result6 - Close Action | VARCHAR(50) | YES | - | CODE-BACKED | (ResultType 6) Close action category label: 'Exit Order Execution', 'Exit Order Execution in mirror', 'Manual Close', 'Close in mirror', 'Hierarchical Close'. |
| 34 | Result6 - Positions Count | INT | YES | - | CODE-BACKED | (ResultType 6) Count of closes for this action category. |
| 35 | Result6 - Max_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 6) Max latency for this close action category. |
| 36 | Result6 - Min_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 6) Min latency for this close action category. |
| 37 | Result6 - Avg_Latency | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 6) Avg latency for this close action category. |
| 38 | Result6 - P90 | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 6) P90 latency for this close action category. |
| 39 | Result6 - P99 | DECIMAL(30,6) | YES | - | CODE-BACKED | (ResultType 6) P99 latency for this close action category. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (open positions) | Trade.PositionTbl | Lookup (READ) | StatusID=1 (open) positions with Occurred in window |
| (closed positions today) | Trade.PositionTbl | Lookup (READ) | StatusID=2 (closed) positions with CloseOccurred in window |
| (open positions - history) | History.Position_Active | Lookup (READ) | Already-moved-to-history positions opened in window |
| (closed positions - history) | History.Position_Active | Lookup (READ) | Already-moved-to-history positions closed in window |
| OrderID | History.OrderForOpen | Existence check (LEFT JOIN) | Determines if position was opened via a queued order (for Manual Open classification) |
| ExecutionID | eToroLogs_Real.Hedge.ResponseExecutionLog | Lookup (cross-DB JOIN) | Hedge server execution time for hedge latency calculation (only when @ShowHedgeLatency = 1) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called directly from SSRS report server. Referenced in UsersPermissions/DATA_READER.sql (EXECUTE permission grant).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SSRS_NonAsyncLatencyReport (procedure)
├── Trade.PositionTbl (table)
├── History.Position_Active (view - cross-schema)
├── History.OrderForOpen (table - cross-schema)
└── eToroLogs_Real.eToroLogs_Real.Hedge.ResponseExecutionLog (table - cross-database, @ShowHedgeLatency=1 only)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source for open (StatusID=1) and close (StatusID=2) latency calculations |
| History.Position_Active | View (cross-schema) | Source for positions already moved to history within the window |
| History.OrderForOpen | Table (cross-schema) | LEFT JOIN to classify Manual Open positions (no matching OrderForOpen) |
| eToroLogs_Real.Hedge.ResponseExecutionLog | Table (cross-database) | INNER JOIN for hedge server execution timestamps (when @ShowHedgeLatency = 1) |

### 6.2 Objects That Depend On This

No dependents found. Called directly from SSRS report server.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Multiple temp table indexes created for performance:
- #tblPositionsOpenWithoutHedge: IX_ExecutionID
- #tblPositionsOpenWithHedge: IX_Latency, IX_Latency_Request_Hedge, IX_OpenActionType, IX_OrderID, IX_MirrorID, IX_OrderType
- #tblPositionsWithoutHedgeClose: IX_ExecutionID
- #tblPositionsWithHedgeClose: IX_Latency, IX_Latency_Request_Hedge, IX_ExitOrderID, IX_MirrorID, IX_ExitOrderType, IX_ActionType
All primary CTEs use `OPTION(RECOMPILE)` for plan freshness.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get latency report for today's market open window (all routing)

```sql
EXEC Trade.SSRS_NonAsyncLatencyReport
    @fromDate = '2026-03-17 08:00:00',
    @toDate = '2026-03-17 12:00:00',
    @ShowHedgeLatency = 0,
    @All_HBC_CBH = 1
```

### 8.2 Get CBH-only latency (positions with forex price rate applied)

```sql
EXEC Trade.SSRS_NonAsyncLatencyReport
    @fromDate = '2026-03-17 08:00:00',
    @toDate = '2026-03-17 16:00:00',
    @ShowHedgeLatency = 0,
    @All_HBC_CBH = 3
```

### 8.3 Get full latency including hedge server round-trip

```sql
EXEC Trade.SSRS_NonAsyncLatencyReport
    @fromDate = '2026-03-17 08:00:00',
    @toDate = '2026-03-17 16:00:00',
    @ShowHedgeLatency = 1,
    @All_HBC_CBH = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 39 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SSRS_NonAsyncLatencyReport | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SSRS_NonAsyncLatencyReport.sql*
