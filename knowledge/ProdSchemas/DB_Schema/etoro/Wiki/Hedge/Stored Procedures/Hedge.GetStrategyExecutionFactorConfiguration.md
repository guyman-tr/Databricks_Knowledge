# Hedge.GetStrategyExecutionFactorConfiguration

> Returns the execution factor multiplier for all hedge servers, controlling what fraction of the computed target hedge exposure the server actually orders in each execution cycle.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns execution factor for all hedge servers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetStrategyExecutionFactorConfiguration` loads the execution factor for each hedge server. The `ExecutionFactor` is a scalar multiplier applied to the computed target hedge order size, controlling how aggressively the hedge server hedges its exposure in each execution cycle.

An `ExecutionFactor` of 1.0 means the server orders 100% of the computed exposure delta in each cycle (full hedging). A factor of 0.5 means the server orders only 50% of the computed delta, building the hedge position gradually over multiple cycles (partial hedging). This is useful for large positions where placing the full order at once would create market impact - the execution factor allows phased order sizing.

The execution factor is distinct from `SlippageInPercentage` (from smart execution) and from `Threshold` (from order type configuration). It operates at a higher level: it reduces the computed target size before any order type or smart execution logic is applied.

Data flows as follows: on startup, the hedge engine calls this procedure to load the execution factor per server. During each hedge cycle, after computing the target exposure delta (via `Hedge.GetOpenPositionsAmountByHedgeServer` vs `Hedge.GetNetting`), the engine multiplies the delta by the execution factor to get the actual order size submitted to the LP.

---

## 2. Business Logic

### 2.1 Full Table Read - Execution Factor per Server

**What**: Returns exactly two columns for all hedge servers. No filtering, no parameters.

**Columns/Parameters Involved**: `HedgeServerID`, `ExecutionFactor`

**Rules**:
- No WHERE clause - all servers returned
- WITH (NOLOCK): avoids blocking during the configuration load
- ExecutionFactor is a decimal multiplier: 0.0 = hedge nothing, 1.0 = hedge fully, >1.0 = over-hedge (aggressive)
- Applied per cycle: each hedge cycle's order size = exposure_delta * ExecutionFactor
- NULL ExecutionFactor = use application default (likely 1.0)

**Diagram**:
```
Hedge cycle computation:
  1. GetOpenPositionsAmountByHedgeServer() -> customer exposure = 500,000 units long
  2. GetNetting(@LiquidityAccountID=10) -> current hedge = 480,000 units long
  3. Exposure delta = 500,000 - 480,000 = 20,000 units to buy
  4. GetStrategyExecutionFactorConfiguration() -> HedgeServerID=1, ExecutionFactor=0.5
  5. Order size = 20,000 * 0.5 = 10,000 units (50% of delta hedged this cycle)
  6. Next cycle: remaining 10,000 units will be hedged (if exposure hasn't changed)
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
| 1 | HedgeServerID | int | NO | - | VERIFIED | The hedge server identifier. PK of Trade.HedgeServer. One row per hedge server. |
| 2 | ExecutionFactor | decimal | YES | - | VERIFIED | Scalar multiplier applied to the computed exposure delta before order sizing. 1.0=full hedge per cycle. 0.5=half the delta per cycle (gradual buildup). Values above 1.0 overshoot the target (aggressive). NULL indicates the server uses the application's default factor. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Trade.HedgeServer | SELECT | Source of execution factor configuration for all hedge servers. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to load the execution factor for order size computation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetStrategyExecutionFactorConfiguration (procedure)
└── Trade.HedgeServer (table) [cross-schema]
      - Also read by: Hedge.GetServerCircuitBreakerThresholds (circuit breaker cols)
      - Also read by: Hedge.GetStrategyGroupsAndHedgeServerID (StrategyGroup col)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | SELECTed with NOLOCK - source of ExecutionFactor per server |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - loads execution factor at startup to scale hedge order sizes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Trade.HedgeServer has a PK on HedgeServerID. Full-table scan returns all servers. The table is small (one row per hedge server).

### 7.2 Constraints

N/A for Stored Procedure. Trade.HedgeServer is read by three distinct GET procedures that each project a different subset of columns: `GetServerCircuitBreakerThresholds` (circuit breaker columns), `GetStrategyGroupsAndHedgeServerID` (StrategyGroup), and this procedure (ExecutionFactor). This pattern isolates concerns: each startup-phase configuration reader loads only the columns relevant to its subsystem.

---

## 8. Sample Queries

### 8.1 Load execution factors for all servers
```sql
EXEC [Hedge].[GetStrategyExecutionFactorConfiguration];
```

### 8.2 Direct table query
```sql
SELECT  HedgeServerID,
        ExecutionFactor
FROM    [Trade].[HedgeServer] WITH (NOLOCK)
ORDER BY HedgeServerID;
```

### 8.3 Simulate order sizing with execution factor
```sql
-- Given exposure_delta = 20000 units, what order size is placed per server?
SELECT  HedgeServerID,
        ExecutionFactor,
        20000 * ISNULL(ExecutionFactor, 1.0) AS OrderSize
FROM    [Trade].[HedgeServer] WITH (NOLOCK)
ORDER BY HedgeServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetStrategyExecutionFactorConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetStrategyExecutionFactorConfiguration.sql*
