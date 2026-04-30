# Trade.CalculateLatencyMetrics

> Calculates trading execution latency metrics (count, average, P90, P99) for position open and close operations across three segments: all positions, peak-traffic 3-minute window, and regular traffic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @fromDate, @toDate, optional filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure measures the execution latency of the trading platform - how long it takes from a customer's trade request to actual execution. This is a critical performance indicator: lower latency means better customer experience and more accurate execution prices. Regulatory requirements also mandate execution quality reporting.

The procedure analyzes both open and close operations across the specified time window, computing latency as the millisecond difference between RequestOccurred and ExecutionTime. It supports filtering by: HBC (Hedge-By-Close) vs regular execution, async vs sync execution, execution type (Manual/Copy/SLTP), and operation type (Open/Close).

Results are segmented into three groups: (1) ALL positions in the time window, (2) the PEAK 3-minute window (the minute with the highest position count + 2 adjacent minutes), and (3) REGULAR traffic (everything outside the peak window). This segmentation reveals whether latency degrades under peak load.

---

## 2. Business Logic

### 2.1 Latency Calculation

**What**: Measures the time between trade request and execution.

**Columns/Parameters Involved**: `RequestOccurred`/`RequestCloseOccurred`/`RequestOpenOccurred`, `ExecutionTime` (from OrderExecutionData or position occurred)

**Rules**:
- For closes: `Latency = ABS(DATEDIFF(MS, RequestCloseOccurred, ISNULL(OrderExecutionTime, CloseOccurred)))`
- For opens (closed positions): Uses RequestOpenOccurred -> OpenOccurred
- For opens (still open): Uses RequestOccurred -> Occurred from PositionTbl
- Async execution: Uses OrderExecutionTime from History.OrderExecutionData when available
- Sync execution: Falls back to position Open/CloseOccurred
- IsHBC: Determined by ForexPriceRateID > 0 (0 = regular, 1 = HBC)

### 2.2 Execution Type Classification

**What**: Categorizes each position by how it was opened/closed.

**Rules**:
- Close ActionType mapping: 0,8,15,16,19 = Manual; 1,5 = SLTP; 13,17,18,21,23 = Copy; else = Other
- Open: MirrorID = 0 -> Manual; else -> Copy
- ActionType 9 (hierarchical) is excluded from all analysis
- SL/TP non-async positions are excluded from close latency

### 2.3 Peak Window Segmentation

**What**: Separates metrics into peak and regular traffic periods.

**Rules**:
- Counts positions per minute across the time window
- Identifies the minute with the highest count
- Peak window = that minute + next 2 minutes (3-minute span)
- All positions outside this window are "regular"
- Metrics computed separately for each segment

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | DATETIME | NO | - | CODE-BACKED | Start of the analysis time window. |
| 2 | @toDate | DATETIME | NO | - | CODE-BACKED | End of the analysis time window. |
| 3 | @IsHBC | BIT | YES | NULL | CODE-BACKED | Filter: NULL = all, 0 = regular execution, 1 = Hedge-By-Close execution. |
| 4 | @IsAsync | BIT | YES | NULL | CODE-BACKED | Filter: NULL = all, 0 = synchronous, 1 = asynchronous (has OrderExecutionData). |
| 5 | @ExecutionType | VARCHAR(100) | YES | NULL | CODE-BACKED | Filter: NULL = all, 'Manual' = user-initiated, 'Copy' = CopyTrader, 'SLTP' = stop loss/take profit. |
| 6 | @OperationType | VARCHAR(100) | YES | NULL | CODE-BACKED | Filter: NULL = all, 'Open' = position opens, 'Close' = position closes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | History.PositionSlim | READER | Closed positions for latency analysis |
| OUTER APPLY | History.OrderExecutionData | READER | Async execution timestamps |
| SELECT | Trade.PositionTbl | READER | Still-open positions opened in window |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CalculateLatencyMetricsWrapper | - | Caller | Wrapper that calls this for multiple date ranges |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CalculateLatencyMetrics (procedure)
+-- History.PositionSlim (table)
+-- History.OrderExecutionData (table)
+-- Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table | READER - closed position data |
| History.OrderExecutionData | Table | READER - async execution timestamps |
| Trade.PositionTbl | Table | READER - still-open positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CalculateLatencyMetricsWrapper | Stored Procedure | Calls this for batch date range analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Procedure hint | Fresh plan per execution due to varying date ranges and filters |
| PERCENTILE_CONT | Windowed function | Used for P90 and P99 percentile calculations |

---

## 8. Sample Queries

### 8.1 Calculate latency metrics for yesterday

```sql
EXEC Trade.CalculateLatencyMetrics
    @fromDate = '2026-03-14 00:00:00',
    @toDate = '2026-03-14 23:59:59';
```

### 8.2 Calculate latency for manual close operations only

```sql
EXEC Trade.CalculateLatencyMetrics
    @fromDate = '2026-03-14 00:00:00',
    @toDate = '2026-03-14 23:59:59',
    @ExecutionType = 'Manual',
    @OperationType = 'Close';
```

### 8.3 Calculate latency for async HBC trades

```sql
EXEC Trade.CalculateLatencyMetrics
    @fromDate = '2026-03-14 00:00:00',
    @toDate = '2026-03-14 23:59:59',
    @IsHBC = 1,
    @IsAsync = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CalculateLatencyMetrics | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CalculateLatencyMetrics.sql*
