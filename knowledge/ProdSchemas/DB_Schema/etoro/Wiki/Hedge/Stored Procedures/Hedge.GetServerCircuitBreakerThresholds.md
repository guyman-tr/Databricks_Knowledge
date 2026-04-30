# Hedge.GetServerCircuitBreakerThresholds

> Returns the circuit breaker warning and hard limit thresholds for all hedge servers, enabling the hedge engine to halt or warn on order submission when P&L loss or exposure drift exceeds configured safety limits.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns circuit breaker thresholds for all hedge servers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetServerCircuitBreakerThresholds` loads the safety circuit breaker configuration for each hedge server. A circuit breaker is a hard safety mechanism that stops automated hedge order submission when cumulative losses or exposure deviations exceed a defined threshold. This prevents runaway hedge algorithms from creating unbounded positions or losses in the event of market data errors, connectivity issues, or algorithmic faults.

Two thresholds are defined per server:
- **CircuitBreakerWarningLimit**: a soft threshold that triggers a warning alert or a more cautious execution mode
- **CircuitBreakerLimit**: the hard threshold at which the hedge server halts all automated order submission until manually reset by an operator

Data flows as follows: on startup, the hedge engine calls this procedure to load both thresholds into its runtime configuration. After each hedge order execution (or at a regular monitoring interval), the engine computes its cumulative metric (typically unrealized P&L deviation or total order value) and compares it against these limits. If the metric exceeds `CircuitBreakerWarningLimit`, the engine logs a warning or reduces order sizing. If it exceeds `CircuitBreakerLimit`, the engine enters a "halted" state and requires manual intervention to resume.

The data is sourced from `Trade.HedgeServer`, the master registry of hedge server configurations. The circuit breaker thresholds are stored alongside other server properties (like StrategyGroup and ExecutionFactor) in that table.

---

## 2. Business Logic

### 2.1 Circuit Breaker Threshold Load

**What**: Returns exactly the two safety threshold columns for all hedge servers. No filtering, no parameters.

**Columns/Parameters Involved**: `HedgeServerID`, `CircuitBreakerWarningLimit`, `CircuitBreakerLimit`

**Rules**:
- No WHERE clause - all servers returned regardless of active/inactive state
- SET TRAN ISOLATION LEVEL READ UNCOMMITTED: avoids blocking during the configuration load
- Two thresholds: warning (soft) and hard limit
- The interpretation of the threshold value (e.g., USD amount, percentage, trade count) depends on the hedge engine's implementation; the DB stores the raw numeric values

**Diagram**:
```
Hedge engine monitoring loop:
  GetServerCircuitBreakerThresholds()
       |
       v
  Cache: HedgeServerID=1, CircuitBreakerWarningLimit=500000, CircuitBreakerLimit=1000000

  After each order execution:
    ComputeMetric() = 450000 -> NORMAL (below warning)
    ComputeMetric() = 600000 -> WARNING (above warning, below hard limit)
    ComputeMetric() = 1100000 -> CIRCUIT BREAKER TRIPPED -> halt all orders
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters.*

**Output columns** (from Trade.HedgeServer):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | VERIFIED | The hedge server identifier. PK of Trade.HedgeServer. Each row represents one hedge server instance's circuit breaker configuration. |
| 2 | CircuitBreakerWarningLimit | decimal | YES | - | VERIFIED | Soft threshold. When the hedge engine's monitored metric exceeds this value, a warning is raised or execution mode shifts to conservative. Does not halt order submission. Used as an early warning before the hard limit is reached. |
| 3 | CircuitBreakerLimit | decimal | YES | - | VERIFIED | Hard threshold. When the monitored metric exceeds this value, the hedge server halts all automated order submission. Requires manual operator intervention to reset. The ultimate safety stop for algorithmic hedge execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Trade.HedgeServer | SELECT | Source of circuit breaker threshold configuration for all hedge servers. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to load circuit breaker thresholds for the execution safety monitor. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetServerCircuitBreakerThresholds (procedure)
└── Trade.HedgeServer (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | SELECTed at READ UNCOMMITTED - source of circuit breaker warning and hard limit thresholds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - loaded at startup for the execution safety circuit breaker monitor |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Trade.HedgeServer has a PK on HedgeServerID. The full-table scan returns all servers; there is no filtering by HedgeServerID in this procedure. The table is small (one row per hedge server).

### 7.2 Constraints

N/A for Stored Procedure. SET TRAN ISOLATION LEVEL READ UNCOMMITTED is set session-wide. This is appropriate for a configuration read where stale data is acceptable. The circuit breaker thresholds in Trade.HedgeServer are also returned by other procedures (`Hedge.GetStrategyExecutionFactorConfiguration` returns ExecutionFactor, `Hedge.GetStrategyGroupsAndHedgeServerID` returns StrategyGroup) - this procedure specifically projects only the circuit breaker columns.

---

## 8. Sample Queries

### 8.1 Load circuit breaker thresholds for all servers
```sql
EXEC [Hedge].[GetServerCircuitBreakerThresholds];
```

### 8.2 Direct table query showing all safety thresholds
```sql
SELECT  HedgeServerID,
        CircuitBreakerWarningLimit,
        CircuitBreakerLimit
FROM    [Trade].[HedgeServer] WITH (NOLOCK)
ORDER BY HedgeServerID;
```

### 8.3 Check servers with no circuit breaker configured (NULL limits)
```sql
SELECT  HedgeServerID,
        CircuitBreakerWarningLimit,
        CircuitBreakerLimit
FROM    [Trade].[HedgeServer] WITH (NOLOCK)
WHERE   CircuitBreakerWarningLimit IS NULL
   OR   CircuitBreakerLimit IS NULL
ORDER BY HedgeServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetServerCircuitBreakerThresholds | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetServerCircuitBreakerThresholds.sql*
