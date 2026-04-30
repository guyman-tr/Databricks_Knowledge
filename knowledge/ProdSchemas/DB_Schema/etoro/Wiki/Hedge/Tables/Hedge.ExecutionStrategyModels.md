# Hedge.ExecutionStrategyModels

> Plugin registry table that maps named execution strategy models to their .NET assembly and class implementations, enabling the Smart Execution engine to dynamically load and apply different order pricing algorithms.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ModelID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No (on [DICTIONARY] filegroup) |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

`Hedge.ExecutionStrategyModels` is the strategy registry for the Smart Execution system. It lists the available execution strategies the hedge engine can use when routing orders - each identified by a human-readable name and pointing to the .NET class that implements the strategy's pricing logic. The four registered strategies correspond to different order price targeting approaches: bid price, mid price, ask price, and straight market order.

This table exists because the Smart Execution system is built as a plugin architecture. Rather than hard-coding order pricing logic into the hedge engine, the strategies are implemented as .NET classes in a separate assembly (`ExecutionStrategyManager.Models.dll`) and registered here. This allows new strategies to be added by inserting a row and deploying a new assembly version, without changing core hedge engine code.

Data flows as follows: on startup, the Smart Execution component reads both this table (for the strategy class references) and `Hedge.ExecutionStrategyModelConfigurations` (for per-strategy priority, delay, and direction-specific slippage parameters). It then instantiates the registered classes via reflection and uses them to execute limit orders in priority order, falling back through strategies until one succeeds or the market order strategy executes.

---

## 2. Business Logic

### 2.1 Plugin Architecture via Assembly/Class References

**What**: The `Assembly` and `Class` columns together form a fully-qualified .NET type reference used by the hedge engine to dynamically load execution strategy implementations.

**Columns/Parameters Involved**: `Name`, `Assembly`, `Class`

**Rules**:
- `Assembly` is the filename of the .NET DLL (e.g., `ExecutionStrategyManager.Models.dll`) containing the strategy implementations
- `Class` is the fully-qualified class name within that assembly (e.g., `ExecutionStrategyManager.Models.LimitBid`)
- All 4 current strategies use the same assembly - strategies are co-deployed in one DLL
- The application loads the class via reflection (`Assembly.Load(Assembly).GetType(Class)`) and casts to an execution strategy interface
- Adding a new strategy requires: inserting a row here, implementing the class, and deploying the assembly

**Diagram**:
```
Hedge.ExecutionStrategyModels
    ModelID=1, Assembly=ExecutionStrategyManager.Models.dll, Class=...LimitBid
         |
         v
    [Hedge Engine: Assembly.Load(dll).GetType(class)]
         |
         v
    IExecutionStrategy.Execute(order, price)
         |
         +-- LimitBid   -> submit limit order at bid price
         +-- LimitMid   -> submit limit order at mid (spread midpoint)
         +-- LimitAsk   -> submit limit order at ask price
         +-- Market     -> submit market order (fallback)
```

### 2.2 Relationship to ExecutionStrategyModelConfigurations

**What**: This table defines WHAT strategies exist; `Hedge.ExecutionStrategyModelConfigurations` defines HOW each strategy should be run (priority, delay, slippage tolerance, direction).

**Columns/Parameters Involved**: `ModelID`

**Rules**:
- ModelID is the FK target in `Hedge.ExecutionStrategyModelConfigurations` (no explicit FK constraint, but the relationship is enforced by the application)
- Each ModelID can have two rows in configurations: one for IsBuy=1 (buy orders) and one for IsBuy=0 (sell orders), allowing asymmetric strategy parameters per direction
- `GetSmartExecutionConfigurations` reads the configurations table to retrieve the full strategy schedule; the strategy class itself is loaded from this (models) table

---

## 3. Data Overview

| ModelID | Name | Assembly | Class | Meaning |
|---|---|---|---|---|
| 1 | LimitOrderBid | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.LimitBid | Attempts to fill the order at the bid price. Favorable for sells; used as a tighter price target for buy orders. |
| 2 | LimitOrderMid | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.LimitMid | Targets the mid-point of the bid-ask spread. Balances fill probability against price improvement. |
| 3 | LimitOrderAsk | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.LimitAsk | Attempts to fill at the ask price. Favorable for buys; highest fill probability among limit strategies. |
| 4 | MarketOrder | ExecutionStrategyManager.Models.dll | ExecutionStrategyManager.Models.Market | Market order with no price constraint. Guaranteed fill at current market price; used as final fallback when limit strategies do not fill within their timeout. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ModelID | int IDENTITY(1,1) | NO | auto-increment | VERIFIED | Primary key. Auto-generated integer identifier for the execution strategy model. Referenced by `Hedge.ExecutionStrategyModelConfigurations.ModelID` to link behavior parameters to their strategy. Values 1-4 map to LimitBid, LimitMid, LimitAsk, MarketOrder. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable name for the strategy (e.g., "LimitOrderBid", "MarketOrder"). Used as a display label and log identifier by the hedge engine when reporting which strategy executed an order. |
| 3 | Assembly | varchar(100) | NO | - | CODE-BACKED | Filename of the .NET assembly DLL containing the strategy class (e.g., "ExecutionStrategyManager.Models.dll"). All current strategies reside in the same assembly. Used by the hedge engine at startup to load the DLL via Assembly.Load(). |
| 4 | Class | varchar(100) | NO | - | CODE-BACKED | Fully-qualified .NET class name within the assembly (e.g., "ExecutionStrategyManager.Models.LimitBid"). The hedge engine calls Type.GetType(Class) to instantiate the strategy via reflection. Must implement the execution strategy interface expected by the Smart Execution framework. |
| 5 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. Captures the SQL Server login executing the DML via `suser_name()`. Not filterable in WHERE clauses. Populated on all writes. |
| 6 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity passed via `CONTEXT_INFO()` as VARCHAR(500). NULL when context is not set by the calling application. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. Managed by SQL Server SYSTEM_VERSIONING. Original rows date from 2022-03-28 (initial Smart Execution deployment). |
| 8 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for all currently active rows. Historical versions in History.ExecutionStrategyModels have real end timestamps. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ExecutionStrategyModelConfigurations | ModelID | Implicit FK (no constraint) | Each configuration row specifies behavior parameters (priority, delay, slippage) for one of the strategy models registered here |
| History.ExecutionStrategyModels | (temporal) | Temporal History | Stores historical row versions automatically via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionStrategyModelConfigurations | Table | References ModelID to configure per-strategy execution parameters (priority, delay, slippage) for each direction (buy/sell) |
| History.ExecutionStrategyModels | Table | Temporal shadow table storing all historical versions of strategy registrations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExecutionStrategyModels | CLUSTERED PK | ModelID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ExecutionStrategyModels | PRIMARY KEY | ModelID - uniqueness of strategy registrations |
| DF_ExecutionStrategyModels_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_ExecutionStrategyModels_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ExecutionStrategyModels |
| Tr_T_ExecutionStrategyModels_INSERT | TRIGGER | No-op self-UPDATE on INSERT to force temporal history capture |

---

## 8. Sample Queries

### 8.1 View all registered execution strategy models

```sql
SELECT
    esm.ModelID,
    esm.Name,
    esm.Assembly,
    esm.Class,
    esm.SysStartTime
FROM Hedge.ExecutionStrategyModels esm WITH (NOLOCK)
ORDER BY esm.ModelID
```

### 8.2 View strategy models with their execution configurations

```sql
SELECT
    esm.ModelID,
    esm.Name,
    esmc.IsBuy,
    esmc.Priority,
    esmc.ExecutionDelaySeconds,
    esmc.SlippageInPercentage
FROM Hedge.ExecutionStrategyModels esm WITH (NOLOCK)
JOIN Hedge.ExecutionStrategyModelConfigurations esmc WITH (NOLOCK)
    ON esm.ModelID = esmc.ModelID
ORDER BY esm.ModelID, esmc.IsBuy DESC
```

### 8.3 Check change history for strategy registrations

```sql
SELECT
    h.ModelID,
    h.Name,
    h.Assembly,
    h.Class,
    h.SysStartTime,
    h.SysEndTime,
    h.DbLoginName
FROM History.ExecutionStrategyModels h WITH (NOLOCK)
ORDER BY h.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

Two Confluence pages titled "Smart Execution (Limit orders)" were found in the DROD space but are not accessible. No extractable knowledge from Atlassian sources.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct (1 via sibling table) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExecutionStrategyModels | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExecutionStrategyModels.sql*
