# Dictionary.HedgeServerExecutionStrategy

> Lookup table defining two hedge server execution strategies — Normal (standard order routing) and Smart (intelligent order splitting/routing for optimized fill quality and reduced market impact).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ExecutionStartegyID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeServerExecutionStrategy defines how the hedge server routes orders to liquidity providers. In Normal mode, orders are sent as single market orders to the configured LP. In Smart mode, the hedge server applies intelligent execution logic — potentially splitting large orders, routing to multiple LPs, or timing orders to minimize market impact and achieve better fill quality.

This table exists because different instruments and market conditions require different execution approaches. A small forex hedge can be executed as a simple market order (Normal). A large stock hedge or an order in an illiquid instrument benefits from smart execution — breaking the order into smaller pieces, timing execution to avoid moving the market, or routing to the LP offering the best current price.

The ExecutionStartegyID is stored in the Hedge.ServerConfiguration table, which defines per-server execution settings. Note: the column name contains a typo ("Startegy" instead of "Strategy") preserved from the original DDL.

---

## 2. Business Logic

### 2.1 Execution Strategy Selection

**What**: Two strategies control how orders are submitted to liquidity providers.

**Columns/Parameters Involved**: `ExecutionStartegyID`, `ExecutionStrategyName`

**Rules**:
- **Normal (0)**: Standard execution — send the full order as a single market order to the primary LP. Simple, fast, but may suffer slippage on large orders. Suitable for liquid instruments with tight spreads.
- **Smart (1)**: Intelligent execution — the hedge server applies algorithms to optimize fill quality. May include order splitting (breaking large orders into smaller tranches), multi-LP routing (sending to the LP with the best current price), or time-weighted execution (spreading execution over time to reduce market impact).
- The strategy is configured per hedge server in Hedge.ServerConfiguration, allowing different strategies for different instrument groups or market segments.

**Diagram**:
```
Normal (0):                      Smart (1):
  Full order                       Full order
     │                                │
     ▼                                ▼
  Single LP                    Smart Execution Engine
     │                          ┌─────┼─────┐
     ▼                          ▼     ▼     ▼
  Market order              Tranche1 Tranche2 Tranche3
     │                        │       │       │
     ▼                        ▼       ▼       ▼
  Fill/Reject               LP-A    LP-B    LP-A
                              │       │       │
                              └───┬───┘───────┘
                                  ▼
                            Aggregated Fill
```

---

## 3. Data Overview

| ExecutionStartegyID | ExecutionStrategyName | Meaning |
|---|---|---|
| 0 | Normal | Standard single-order execution — the full hedge volume is sent as one market order to the configured liquidity provider. Fast execution but exposed to slippage on large orders. Appropriate for liquid instruments. |
| 1 | Smart | Intelligent execution with order splitting, multi-LP routing, and/or time-weighted execution. Reduces market impact and improves fill quality for large orders or illiquid instruments. Higher complexity and slightly higher latency. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionStartegyID | int | NO | - | VERIFIED | Primary key identifying the execution strategy. 0=Normal (single order to single LP), 1=Smart (intelligent splitting/routing). Column name contains legacy typo ("Startegy"). Referenced by Hedge.ServerConfiguration. |
| 2 | ExecutionStrategyName | varchar(50) | NO | - | VERIFIED | Human-readable name of the execution strategy. Displayed in hedge server configuration screens and monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ServerConfiguration | ExecutionStartegyID | Implicit FK | Configures which execution strategy each hedge server instance uses |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ServerConfiguration | Table | References execution strategy for per-server configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExecutionStartegyID | CLUSTERED PK | ExecutionStartegyID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ExecutionStartegyID | PRIMARY KEY | Unique execution strategy identifier |

---

## 8. Sample Queries

### 8.1 List all execution strategies
```sql
SELECT  ExecutionStartegyID,
        ExecutionStrategyName
FROM    [Dictionary].[HedgeServerExecutionStrategy] WITH (NOLOCK)
ORDER BY ExecutionStartegyID;
```

### 8.2 Join to server configuration
```sql
SELECT  sc.ServerID,
        sc.ServerName,
        es.ExecutionStrategyName
FROM    [Hedge].[ServerConfiguration] sc WITH (NOLOCK)
JOIN    [Dictionary].[HedgeServerExecutionStrategy] es WITH (NOLOCK)
        ON sc.ExecutionStartegyID = es.ExecutionStartegyID;
```

### 8.3 Count servers per strategy
```sql
SELECT  es.ExecutionStrategyName,
        COUNT(*) AS ServerCount
FROM    [Hedge].[ServerConfiguration] sc WITH (NOLOCK)
JOIN    [Dictionary].[HedgeServerExecutionStrategy] es WITH (NOLOCK)
        ON sc.ExecutionStartegyID = es.ExecutionStartegyID
GROUP BY es.ExecutionStrategyName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeServerExecutionStrategy | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeServerExecutionStrategy.sql*
