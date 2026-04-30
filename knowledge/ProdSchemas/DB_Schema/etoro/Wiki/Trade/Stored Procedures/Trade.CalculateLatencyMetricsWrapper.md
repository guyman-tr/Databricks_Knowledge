# Trade.CalculateLatencyMetricsWrapper

> Day-by-day wrapper that calls Trade.CalculateLatencyMetrics for each day in a date range (max 30 days) and returns a consolidated result set of daily latency metrics.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @fromDate, @toDate date range |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CalculateLatencyMetricsWrapper is a convenience wrapper that produces daily latency metric breakdowns over a date range. While Trade.CalculateLatencyMetrics analyzes a single time window, this wrapper iterates day-by-day from @fromDate to @toDate, calling the inner procedure once per day and collecting all results into a single output.

This procedure exists because latency analysis often needs to compare metrics across multiple days to spot trends - e.g., whether P99 latency is degrading over time, or whether a deployment on a specific date impacted execution speed. Without this wrapper, analysts would have to call CalculateLatencyMetrics manually for each day.

The wrapper enforces a 30-day maximum range to prevent excessive resource consumption (each inner call queries position and order execution data). It uses WITH RECOMPILE because the date range and optional filters vary widely between calls, making a single cached plan suboptimal.

---

## 2. Business Logic

### 2.1 Date Range Validation

**What**: Prevents excessively large queries by capping the date range.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`

**Rules**:
- If DATEDIFF(DAY, @fromDate, @toDate) > 30, raises error 'Date range should not exceed 30 days' (severity 16) and returns immediately
- This protects against accidental multi-month scans that would be very expensive

### 2.2 Day-by-Day Iteration

**What**: Loops through each calendar day in the range, calling the inner procedure.

**Columns/Parameters Involved**: `@startOfDay`, `@endOfDay`, `@fromDate`, `@toDate`

**Rules**:
- For each day: startOfDay = midnight, endOfDay = 23:59:59 of that day
- Calls Trade.CalculateLatencyMetrics with the day boundaries and all filter parameters passed through
- INSERT...EXEC captures the inner procedure's result set into #Results
- Increments by 1 day until @fromDate > @toDate

### 2.3 Filter Pass-Through

**What**: All optional filters are passed directly to the inner procedure unchanged.

**Columns/Parameters Involved**: `@IsHBC`, `@IsAsync`, `@ExecutionType`, `@OperationType`

**Rules**:
- @IsHBC: NULL=no filter, 1=HBC only, 0=non-HBC only
- @IsAsync: NULL=no filter, 1=async only, 0=sync only
- @ExecutionType: 'Manual', 'Copy', 'SLTP', or NULL for all
- @OperationType: 'Open', 'Close', or NULL for all
- See Trade.CalculateLatencyMetrics documentation for full filter semantics

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | DATETIME | NO | - | VERIFIED | Start of the analysis date range (inclusive). Each day from this date forward is analyzed individually. |
| 2 | @toDate | DATETIME | NO | - | VERIFIED | End of the analysis date range (inclusive). Must be within 30 days of @fromDate or the procedure raises an error. |
| 3 | @IsHBC | BIT | YES | NULL | VERIFIED | Hedge-By-Close filter. 1=only HBC executions (ForexPriceRateID > 0), 0=only non-HBC, NULL=all. Passed through to Trade.CalculateLatencyMetrics. |
| 4 | @IsAsync | BIT | YES | NULL | VERIFIED | Async execution filter. 1=only async executions, 0=only sync, NULL=all. Passed through to Trade.CalculateLatencyMetrics. |
| 5 | @ExecutionType | VARCHAR(100) | YES | NULL | VERIFIED | Execution type filter: 'Manual' (user-initiated), 'Copy' (copy-trade), 'SLTP' (stop-loss/take-profit triggered). NULL=no filter. Passed through to Trade.CalculateLatencyMetrics. |
| 6 | @OperationType | VARCHAR(100) | YES | NULL | VERIFIED | Operation type filter: 'Open' (position opens) or 'Close' (position closes). NULL=both. Passed through to Trade.CalculateLatencyMetrics. |

### Output Columns (via #Results)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 7 | Date | DATE | NO | - | VERIFIED | The calendar date this row's metrics represent. One row per day in the range. |
| 8 | Count_All | INT | YES | - | VERIFIED | Total number of positions/operations measured across all traffic for this day. |
| 9 | Avg_All | DECIMAL(30,6) | YES | - | VERIFIED | Average latency in milliseconds across all positions for this day. |
| 10 | P90_All | DECIMAL(30,6) | YES | - | VERIFIED | 90th percentile latency (ms) - 90% of executions completed within this time. |
| 11 | P99_All | DECIMAL(30,6) | YES | - | VERIFIED | 99th percentile latency (ms) - tail latency indicator for near-worst-case performance. |
| 12 | Count_Max3Minutes | INT | YES | - | VERIFIED | Number of positions in the peak 3-minute traffic window for this day. |
| 13 | Avg_Max3Minutes | DECIMAL(30,6) | YES | - | VERIFIED | Average latency (ms) during the peak 3-minute window. Reveals latency under load. |
| 14 | P90_Max3Minutes | DECIMAL(30,6) | YES | - | VERIFIED | 90th percentile latency during peak traffic window. |
| 15 | P99_Max3Minutes | DECIMAL(30,6) | YES | - | VERIFIED | 99th percentile latency during peak traffic window. Critical for SLA monitoring. |
| 16 | Count_Regular | INT | YES | - | VERIFIED | Number of positions outside the peak window (regular traffic). |
| 17 | Avg_Regular | DECIMAL(30,6) | YES | - | VERIFIED | Average latency (ms) during regular (non-peak) traffic. Baseline performance indicator. |
| 18 | P90_Regular | DECIMAL(30,6) | YES | - | VERIFIED | 90th percentile latency during regular traffic. |
| 19 | P99_Regular | DECIMAL(30,6) | YES | - | VERIFIED | 99th percentile latency during regular traffic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (calls) | Trade.CalculateLatencyMetrics | EXEC (INSERT...EXEC) | Calls the inner metrics procedure once per day in the date range, capturing results |

### 5.2 Referenced By (other objects point to this)

No other stored procedures call this wrapper. It is invoked ad-hoc by DBAs and analysts.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CalculateLatencyMetricsWrapper (procedure)
+-- Trade.CalculateLatencyMetrics (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CalculateLatencyMetrics | Stored Procedure | Called via INSERT...EXEC for each day in the range |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | Ad-hoc execution by analysts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Plan Hint | Forces fresh plan compilation each call because filter combinations vary widely |
| 30-day range limit | Validation | RAISERROR if date range exceeds 30 days to prevent expensive scans |

---

## 8. Sample Queries

### 8.1 Daily latency for manual opens in January 2025

```sql
EXEC Trade.CalculateLatencyMetricsWrapper
    @fromDate = '2025-01-01',
    @toDate = '2025-01-31',
    @ExecutionType = 'Manual',
    @OperationType = 'Open';
```

### 8.2 Compare HBC vs non-HBC close latency for a week

```sql
EXEC Trade.CalculateLatencyMetricsWrapper
    @fromDate = '2025-03-01',
    @toDate = '2025-03-07',
    @IsHBC = 1,
    @OperationType = 'Close';
```

### 8.3 All metrics unfiltered for a single day

```sql
EXEC Trade.CalculateLatencyMetricsWrapper
    @fromDate = '2025-03-15',
    @toDate = '2025-03-15';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See [Trade.CalculateLatencyMetrics](Trade.CalculateLatencyMetrics.md) for the full inner procedure documentation.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 13 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CalculateLatencyMetricsWrapper | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CalculateLatencyMetricsWrapper.sql*
