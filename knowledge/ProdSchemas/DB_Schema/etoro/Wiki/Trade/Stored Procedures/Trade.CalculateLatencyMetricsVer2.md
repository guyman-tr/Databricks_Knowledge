# Trade.CalculateLatencyMetricsVer2

> Version 2 of the trading latency metrics calculator that excludes SL/TP from close analysis and includes parameter echo in the output for audit trail purposes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @fromDate, @toDate, optional filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is Version 2 of the trading execution latency metrics calculator. Like the original `Trade.CalculateLatencyMetrics`, it measures the time between trade request and execution for open and close operations, segmenting results into all-traffic, peak-traffic, and regular-traffic buckets.

The key differences from Version 1 are: (1) SL/TP close operations (ActionType IN (1, 5)) are **completely excluded** from close latency analysis rather than conditionally excluded based on async status, and (2) the output includes a `@parmter` string that echoes all input parameter values for audit/debugging purposes.

The business purpose, segmentation logic, and metrics (count, average, P90, P99) are identical to Version 1. Both versions may coexist to allow A/B comparison during rollout of the refined SL/TP exclusion logic.

---

## 2. Business Logic

### 2.1 SL/TP Complete Exclusion

**What**: Version 2 excludes all SL/TP close operations from close latency, not just non-async ones.

**Rules**:
- V1: Excludes SL/TP only when `ActionType IN (1,5) AND OrderExecutionTime IS NULL` (non-async SL/TP)
- V2: Excludes all `ActionType NOT IN (1, 5)` for closes - SL/TP are always excluded regardless of async status
- This provides a cleaner view of user-initiated close latency without SL/TP noise

### 2.2 Parameter Echo for Audit

**What**: Returns input parameters as a concatenated string in the output.

**Rules**:
- @parmter variable built via CONCAT with all parameter values (NULLs converted to 'null')
- Included in the SELECT output alongside metrics
- Enables audit trail: which parameters produced which metrics

### 2.3 Latency Computation and Segmentation

Same as Trade.CalculateLatencyMetrics (Version 1). See that procedure's documentation for full details.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | DATETIME | NO | - | CODE-BACKED | Start of the analysis time window. |
| 2 | @toDate | DATETIME | NO | - | CODE-BACKED | End of the analysis time window. |
| 3 | @IsHBC | BIT | YES | NULL | CODE-BACKED | Filter: NULL = all, 0 = regular execution, 1 = Hedge-By-Close. |
| 4 | @IsAsync | BIT | YES | NULL | CODE-BACKED | Filter: NULL = all, 0 = sync, 1 = async. |
| 5 | @ExecutionType | VARCHAR(100) | YES | NULL | CODE-BACKED | Filter: NULL = all, 'Manual', 'Copy', 'SLTP'. |
| 6 | @OperationType | VARCHAR(100) | YES | NULL | CODE-BACKED | Filter: NULL = all, 'Open', 'Close'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | History.PositionSlim | READER | Closed positions |
| OUTER APPLY | History.OrderExecutionData | READER | Async execution timestamps |
| SELECT | Trade.PositionTbl | READER | Still-open positions |

### 5.2 Referenced By (other objects point to this)

No SQL-level dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CalculateLatencyMetricsVer2 (procedure)
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

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Procedure hint | Fresh plan per execution |
| ActionType NOT IN (1,5) | Business filter | V2 completely excludes SL/TP from close analysis |

---

## 8. Sample Queries

### 8.1 Run V2 latency metrics for yesterday

```sql
EXEC Trade.CalculateLatencyMetricsVer2
    @fromDate = '2026-03-14 00:00:00',
    @toDate = '2026-03-14 23:59:59';
```

### 8.2 Compare V1 and V2 close metrics

```sql
-- Run both and compare Count_All for close operations
EXEC Trade.CalculateLatencyMetrics
    @fromDate = '2026-03-14', @toDate = '2026-03-15', @OperationType = 'Close';
EXEC Trade.CalculateLatencyMetricsVer2
    @fromDate = '2026-03-14', @toDate = '2026-03-15', @OperationType = 'Close';
```

### 8.3 Manual open latency for async trades

```sql
EXEC Trade.CalculateLatencyMetricsVer2
    @fromDate = '2026-03-14', @toDate = '2026-03-15',
    @IsAsync = 1, @ExecutionType = 'Manual', @OperationType = 'Open';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CalculateLatencyMetricsVer2 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CalculateLatencyMetricsVer2.sql*
