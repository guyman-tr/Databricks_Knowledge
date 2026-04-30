# Trade.SSRS_AsyncLatencyReport

> SSRS report procedure that computes async order execution latency statistics (P90/P99, min/max/avg) for open and close position events within a single-day window, segmented by HBC/CBH routing and broken down by open/close action type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @fromDate, @toDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers a SQL Server Reporting Services (SSRS_) dashboard for monitoring asynchronous order execution latency in the trading platform. It measures how long it takes from when a position open/close is requested to when it is actually executed - a key trading infrastructure health metric.

The report covers only **async** order flows (OrderType/ExitOrderType IN (17,18) for opens, (19,20) for closes), which represents the asynchronous execution path where an order is submitted and executed in a separate pass. The time from `RequestOccurred` to `Occurred` (or `CloseOccurred`) is the end-to-end latency measured in milliseconds.

A secondary latency metric (`Latency_PreEms`) measures from request to `OrderExecutionTime` in `History.OrderExecutionData` - the latency up to but not including the EMS (Execution Management System), isolating the database/engine component of total latency.

The `@All_HBC_CBH` parameter allows filtering by execution routing:
- **HBC (Host-Based Calculation)**: InitForexPriceRateID = 0 - price computed by the host/trading server
- **CBH (Central Brokerage Hub)**: InitForexPriceRateID > 0 - price sourced from a central brokerage hub

The output is a single wide `#Result` table with 6 ResultTypes, returned in one SELECT for SSRS consumption.

---

## 2. Business Logic

### 2.1 Single-Day Constraint

**What**: The procedure refuses to run if the date range spans more than one day.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`

**Rules**:
- IF datediff(DAY, @fromDate, @toDate) > 0 -> RETURN (silent exit, no results)
- This is a performance safeguard: the procedure loads ALL positions opened/closed in the window into temp tables. Multi-day ranges would create unmanageable temp table sizes.

### 2.2 Open Position Data Pipeline

**What**: Loads all async open positions in the date range from both current and historical tables.

**Columns/Parameters Involved**: `Trade.PositionTbl.StatusID`, `Trade.PositionTbl.InitForexPriceRateID`, `Trade.PositionTbl.OrderType`

**Rules**:
- Source 1: `Trade.PositionTbl` WHERE StatusID=1 (open) AND Occurred BETWEEN @fromDate AND @toDate
- Source 2: `History.Position_Active` WHERE OpenOccurred BETWEEN @fromDate AND @toDate
- HBC filter: InitForexPriceRateID = 0
- CBH filter: InitForexPriceRateID > 0
- Async open orders: OrderType IN (17,18) -> joined to History.OrderForOpen + History.OrderExecutionData

### 2.3 Close Position Data Pipeline

**What**: Loads all async close positions in the date range.

**Columns/Parameters Involved**: `Trade.PositionTbl.StatusID`, `Trade.PositionTbl.EndForexPriceRateID`, `Trade.PositionTbl.ExitOrderType`

**Rules**:
- Source 1: `Trade.PositionTbl` WHERE StatusID=2 (closed) AND CloseOccurred BETWEEN @fromDate AND @toDate
- Source 2: `History.Position_Active` WHERE CloseOccurred BETWEEN @fromDate AND @toDate
- HBC filter on close: EndForexPriceRateID = 0
- CBH filter on close: EndForexPriceRateID > 0
- Async close orders: ExitOrderType IN (19,20) -> joined to History.OrderForClose + History.OrderExecutionData

### 2.4 Latency Calculation

**What**: Two latency metrics computed as millisecond differences.

**Columns/Parameters Involved**: `RequestOccurred`/`RequestCloseOccurred`, `Occurred`/`CloseOccurred`, `History.OrderExecutionData.OrderExecutionTime`

**Rules**:
- End-to-end Latency: CAST(ABS(DATEDIFF(MILLISECOND, RequestOccurred, Occurred)) AS DECIMAL(30,6))
- Pre-EMS Latency: CAST(ABS(DATEDIFF(MILLISECOND, RequestOccurred, OrderExecutionTime)) AS DECIMAL(30,6))
- ABS() handles occasional negative diffs from clock skew

### 2.5 IsOrderOwner Flag

**What**: Identifies positions where the opening order's CID matches the position's CID.

**Columns/Parameters Involved**: `History.OrderForOpen.CID`, `Trade.PositionTbl.CID`

**Rules**:
- IsOrderOwner = IIF(PositionCID = ofo.CID, 1, 0)
- Result 2 (order-owner opens) and Result 5 (order-owner closes) filter WHERE IsOrderOwner = 1
- Non-owners represent copy-trade positions where the triggering order belonged to the leader (ParentCID), not the follower

### 2.6 Open Action Type Breakdown (ResultType 3)

**What**: Segments open latency by the mechanism that triggered the position open.

| Action Label | Filter Condition | Meaning |
|-------------|-----------------|---------|
| Entry Order Execution | MirrorID=0, TriggeringOrderID>0, TriggeringOrderType IN (17,18) | Direct async market order (non-mirror) |
| Entry Order Execution in mirror | MirrorID>0, TriggeringOrderID>0, TriggeringOrderType IN (17,18) | Copy-trade follower position opened by leader order |
| Manual Open | TriggeringOrderID=0, MirrorID=0 | Direct manual position open (no order) |
| Open Open / Add Fund | OpenActionType IN (3,8) | Mirror add-fund or copy re-open action |
| Hierarchical Open | OpenActionType IN (1) | Hierarchical/copy open (from Dictionary.OpenPositionActionType) |
| Rate Order Execution | TriggeringOrderID>0, TriggeringOrderType IN (0,15) | Rate/limit order execution |

### 2.7 Close Action Type Breakdown (ResultType 6)

**What**: Segments close latency by the mechanism that triggered the position close.

| Action Label | Filter Condition | Meaning |
|-------------|-----------------|---------|
| Exit Order Execution | TriggeringOrderID>0, MirrorID=0, TriggeringOrderType IN (19,20) | Direct async exit order (non-mirror) |
| Exit Order Execution in mirror | TriggeringOrderID>0, MirrorID>0, TriggeringOrderType IN (19,20), ActionType<>9 | Copy-trade position closed by exit order |
| Manual Close | TriggeringOrderID=0, ActionType IN (0,8,19), MirrorID=0 | Direct manual close |
| Close in mirror | TriggeringOrderID=0, ActionType IN (13,14,17,18,23), MirrorID>0 | Mirror stop/detach close actions |
| Hierarchical Close | ActionType IN (9) | Hierarchical/copy close (from Dictionary.ClosePositionActionType) |
| SL/TP Close | ActionType IN (1,5) | Stop-loss or take-profit triggered close |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | datetime | NO | - | CODE-BACKED | Start of the reporting window (inclusive). Range must be within a single calendar day (DATEDIFF(DAY) must equal 0). |
| 2 | @toDate | datetime | NO | - | CODE-BACKED | End of the reporting window (inclusive). Must be the same calendar day as @fromDate. |
| 3 | @All_HBC_CBH | tinyint | YES | 1 | CODE-BACKED | Execution routing filter: 1=ALL positions, 2=HBC only (InitForexPriceRateID=0), 3=CBH only (InitForexPriceRateID>0). |

**Output columns (single wide result set, one row per ResultType):**

| ResultType | Key Columns | Description |
|-----------|-------------|-------------|
| 1 | Result1 - Open Positions Count, Max/Min/Avg/P90/P99 Latency | All async open positions: aggregate latency statistics |
| 2 | Result2 - Order For Open Count, Max/Min/Avg/P90/P99 + PreEms variants | Order-owner async opens: both end-to-end and pre-EMS latency |
| 3 | Result3 - Open Action, Positions Count, Max/Min/Avg/P90/P99 | Open latency drilled by action type (6 rows) |
| 4 | Result4 - Close Positions Count, Max/Min/Avg/P90/P99 Latency | All async close positions: aggregate latency statistics |
| 5 | Result5 - Order For Close Count, Max/Min/Avg/P90/P99 + PreEms variants | Order-owner async closes: both end-to-end and pre-EMS latency |
| 6 | Result6 - Close Action, Positions Count, Max/Min/Avg/P90/P99 | Close latency drilled by action type (6 rows) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Occurred, StatusID=1 | Trade.PositionTbl | Reader | Open positions in date range (current) |
| CloseOccurred, StatusID=2 | Trade.PositionTbl | Reader | Closed positions in date range (current) |
| OpenOccurred | History.Position_Active | Reader | Open positions in date range (historical/archived) |
| CloseOccurred | History.Position_Active | Reader | Closed positions in date range (historical/archived) |
| OrderID | History.OrderForOpen | Reader | Joined for TriggeringOrderType + TriggeringOrderID + CID on open side |
| ExitOrderID | History.OrderForClose | Reader | Joined for TriggeringOrderType + TriggeringOrderID + CID on close side |
| OrderID | History.OrderExecutionData | Reader | Joined for OrderExecutionTime (pre-EMS latency calculation) |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| SSRS Report: Async Latency Report | SSRS Report | Calls this procedure to populate report dataset |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SSRS_AsyncLatencyReport (procedure)
+-- Trade.PositionTbl (table) [open + close positions in date range]
+-- History.Position_Active (table) [archived open + close positions]
+-- History.OrderForOpen (table) [triggering order info for opens]
+-- History.OrderForClose (table) [triggering order info for closes]
+-- History.OrderExecutionData (table) [order execution timestamps for pre-EMS latency]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source for current open (StatusID=1) and recently closed (StatusID=2) positions |
| History.Position_Active | Table | Source for archived positions that opened/closed in the reporting window |
| History.OrderForOpen | Table | Provides TriggeringOrderType, TriggeringOrderID, CID for async open order analysis |
| History.OrderForClose | Table | Provides TriggeringOrderType, TriggeringOrderID, CID for async close order analysis |
| History.OrderExecutionData | Table | Provides OrderExecutionTime for pre-EMS latency calculation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SSRS Report: Async Latency Report | SSRS Report | Primary data source for execution latency dashboard |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

Temp tables use several non-clustered indexes to support PERCENTILE_CONT calculations:
- `#AsyncPositionDataOpen`: IX_Latency, IX_Latency_PreEms, IX_IsOrderOwner, IX_MirrorID, IX_TriggeringOrderID, IX_TriggeringOrderType, IX_OpenActionType
- `#AsyncPositionDataClose`: IX_Latency, IX_Latency_PreEms, IX_IsOrderOwner, IX_TriggeringOrderID, IX_MirrorID, IX_TriggeringOrderType, IX_ActionType

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Single-day limit | Guard | datediff(DAY, @fromDate, @toDate) > 0 -> RETURN; prevents large temp table loads |
| OrderType IN (17,18) | Filter | Only async open order types are included in the async latency analysis |
| ExitOrderType IN (19,20) | Filter | Only async close order types are included |
| OPTION(RECOMPILE) | Performance | Forces query plan recompilation for parameter-sensitive temp table queries |

---

## 8. Sample Queries

### 8.1 Run report for today, all routing types

```sql
EXEC Trade.SSRS_AsyncLatencyReport
    @fromDate    = '2026-03-17 00:00:00',
    @toDate      = '2026-03-17 23:59:59',
    @All_HBC_CBH = 1; -- ALL
```

### 8.2 Run for CBH only

```sql
EXEC Trade.SSRS_AsyncLatencyReport
    @fromDate    = '2026-03-17 06:00:00',
    @toDate      = '2026-03-17 18:00:00',
    @All_HBC_CBH = 3; -- CBH only
```

### 8.3 Interpret ResultType values

```sql
-- ResultType meanings:
-- 1: All async opens aggregate (Count + P90/P99 latency)
-- 2: Order-owner async opens (direct + pre-EMS latency)
-- 3: Open action drill-down (6 rows: Entry, Mirror, Manual, Add Fund, Hierarchical, Rate Order)
-- 4: All async closes aggregate
-- 5: Order-owner async closes (direct + pre-EMS latency)
-- 6: Close action drill-down (6 rows: Exit, Mirror Exit, Manual, Mirror Close, Hierarchical, SL/TP)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SSRS_AsyncLatencyReport | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SSRS_AsyncLatencyReport.sql*
