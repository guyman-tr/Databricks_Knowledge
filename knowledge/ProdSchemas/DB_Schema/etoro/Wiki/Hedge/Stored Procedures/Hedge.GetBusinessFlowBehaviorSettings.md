# Hedge.GetBusinessFlowBehaviorSettings

> Returns the complete execution behavior profile for all hedge business flows - the full set of validation flags, processing toggles, and mode settings that control how the hedge engine routes and validates orders through each named pathway.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all 7 business flow behavior profiles |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the hedge engine's configuration loader for its execution behavior system. On startup, the engine calls this procedure to load all named business flow profiles into memory. Each profile (row) is a complete behavioral specification for a distinct order routing pathway.

A "business flow" represents a distinct execution pathway the hedge engine can route through:
- **Legacy (1)**: The original hedge system - full validation suite, factor-based sizing
- **EMS (2)**: Execution Management System - mirrors Legacy but routes via EMS component
- **OMS_CFDs (3)**: Order Management System for CFD instruments - reduced validation, HBC failover enabled
- **PathToVirtu (4)**: Direct routing to Virtu (a market maker) - no factor/spread, provider enforces its own rules
- **PathToDLT (5)**: Direct routing to DLT - alternative spread logic (SpreadLogic=2), HBC validation required
- **OMS_REAL (6)**: OMS for real stock positions - no netting updates, HBC failover allowed
- **RealFutures (7)**: Futures instruments - no spread management, alternative SL/TP handling

The procedure selects all 14 operational columns from `Hedge.BusinessFlowBehavior`. No NOLOCK hint is applied (default READ COMMITTED isolation). No temporal or audit columns are included.

---

## 2. Business Logic

### 2.1 Validation Pipeline Flags (Per-Flow)

**What**: Four boolean flags govern which pre-execution validation stages the hedge engine runs for orders in each flow.

**Columns/Parameters Involved**: `ValidateMinOrderSize`, `ValidateMaxDealSize`, `ValidateMarketRange`, `ValidateCircuitBreakers`

**Rules**:
- `ValidateMaxDealSize`: TRUE for ALL 7 flows - maximum deal size is always enforced by the hedge engine
- `ValidateMarketRange`: TRUE for Legacy and EMS only - direct-provider paths bypass market range checking
- `ValidateCircuitBreakers`: FALSE only for OMS_CFDs and OMS_REAL - those flows delegate circuit breaker responsibility to OMS infrastructure
- `ValidateMinOrderSize`: FALSE for PathToVirtu, PathToDLT, and RealFutures - direct providers enforce minimum order size internally

### 2.2 Execution Processing Flags (Per-Flow)

**What**: Five additional flags/modes control how orders are processed after passing validation.

**Columns/Parameters Involved**: `ApplyFactor`, `ApplySplitLogic`, `ApplyRounding`, `SpreadLogic`, `UpdateNetting`

**Rules**:
- `ApplyFactor`: TRUE only for Legacy and EMS - multiply order size by instrument's hedge factor before sending; OMS/direct-provider flows send exact sizes
- `ApplySplitLogic`: TRUE only for Legacy and EMS - large orders may be split into multiple smaller orders
- `ApplyRounding`: TRUE only for Legacy and EMS - order sizes are rounded per instrument lot size rules
- `UpdateNetting`: FALSE only for OMS_REAL - real stock positions are tracked outside netting tables; all other flows update netting
- `SpreadLogic`: 0=no spread management (PathToVirtu, RealFutures), 1=standard spread (Legacy, EMS, OMS_CFDs, OMS_REAL), 2=alternative spread mode (PathToDLT)

### 2.3 HBC Control Flags (Per-Flow)

**What**: Two flags govern the Hedge Bot Controller (HBC) interaction for each flow.

**Columns/Parameters Involved**: `ValidateHBCExecution`, `AllowHBCFailover`, `SLTPBehavior`

**Rules**:
- `ValidateHBCExecution`: TRUE only for PathToDLT and RealFutures - requires HBC validation before execution
- `AllowHBCFailover`: TRUE only for OMS_CFDs and OMS_REAL - if HBC is unavailable, flow can fall back to alternative execution
- `SLTPBehavior`: 0=standard SL/TP handling; 1=alternative mode (RealFutures only, for futures contract semantics)

**Flow profile summary**:
```
Flow           Factor  Split  SpreadLogic  Netting  ValidateHBC  HBCFailover  SLTPBehavior
Legacy (1)     Y       Y       1 (std)      Y        N            N            0
EMS (2)        Y       Y       1 (std)      Y        N            N            0
OMS_CFDs (3)   N       N       1 (std)      Y        N            Y            0
PathToVirtu(4) N       N       0 (none)     Y        N            N            0
PathToDLT (5)  N       N       2 (alt)      Y        Y            N            0
OMS_REAL (6)   N       N       1 (std)      N        N            Y            0
RealFutures(7) N       N       0 (none)     Y        Y            N            1
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Returns all rows from `Hedge.BusinessFlowBehavior`. Returns 7 rows (one per business flow: Legacy, EMS, OMS_CFDs, PathToVirtu, PathToDLT, OMS_REAL, RealFutures). |

**Output Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| BusinessFlowID | Hedge.BusinessFlowBehavior | PK. Flow identifier: 1=Legacy, 2=EMS, 3=OMS_CFDs, 4=PathToVirtu, 5=PathToDLT, 6=OMS_REAL, 7=RealFutures |
| BusinessFlowName | Hedge.BusinessFlowBehavior | Human-readable name of the flow (e.g., "Legacy", "OMS_CFDs"). Used for display and logging. |
| ApplyFactor | Hedge.BusinessFlowBehavior | bit: 1=multiply order size by instrument hedge factor before sending. TRUE for Legacy/EMS only. |
| ValidateMinOrderSize | Hedge.BusinessFlowBehavior | bit: 1=enforce minimum order size check before execution. FALSE for direct-provider paths (PathToVirtu, PathToDLT, RealFutures). |
| ValidateMaxDealSize | Hedge.BusinessFlowBehavior | bit: 1=enforce maximum deal size limit. TRUE for ALL flows. |
| ValidateMarketRange | Hedge.BusinessFlowBehavior | bit: 1=check execution price within market range tolerance. TRUE for Legacy/EMS only. |
| ValidateCircuitBreakers | Hedge.BusinessFlowBehavior | bit: 1=check circuit breaker thresholds before submitting. FALSE for OMS_CFDs and OMS_REAL. |
| ApplySplitLogic | Hedge.BusinessFlowBehavior | bit: 1=allow large orders to be split into smaller orders. TRUE for Legacy/EMS only. |
| ApplyRounding | Hedge.BusinessFlowBehavior | bit: 1=round order sizes per instrument lot size rules. TRUE for Legacy/EMS only. |
| SpreadLogic | Hedge.BusinessFlowBehavior | Spread management mode: 0=none (PathToVirtu, RealFutures), 1=standard (Legacy, EMS, OMS), 2=alternative (PathToDLT). |
| UpdateNetting | Hedge.BusinessFlowBehavior | bit: 1=update netting tables after execution. FALSE only for OMS_REAL (real stock tracking outside netting). |
| ValidateHBCExecution | Hedge.BusinessFlowBehavior | bit: 1=require HBC validation before execution. TRUE for PathToDLT and RealFutures only. |
| AllowHBCFailover | Hedge.BusinessFlowBehavior | bit: 1=allow fallback to alternative execution if HBC unavailable. TRUE for OMS_CFDs and OMS_REAL only. |
| SLTPBehavior | Hedge.BusinessFlowBehavior | SL/TP processing mode: 0=standard, 1=alternative futures semantics (RealFutures only). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.BusinessFlowBehavior | Direct read | Returns all 14 operational columns for all 7 business flow profiles |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the hedge engine on startup to load its in-memory business flow behavior registry.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetBusinessFlowBehaviorSettings (procedure)
└── Hedge.BusinessFlowBehavior (table) - SELECT source (7 rows)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.BusinessFlowBehavior | Table | SELECT 14 operational columns (BusinessFlowID, name, all flag/mode columns) - all rows, no filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK | Isolation | Uses default READ COMMITTED (no WITH NOLOCK hint) - stricter than most Hedge schema reads |
| No filter | Design | Returns ALL 7 business flow rows - full profile set for engine startup cache population |
| Startup context | Usage | Intended for one-time load at hedge engine startup; the engine caches all profiles in memory |

---

## 8. Sample Queries

### 8.1 View complete behavior profiles for all flows

```sql
SELECT BusinessFlowID, BusinessFlowName,
       ApplyFactor, ValidateMinOrderSize, ValidateMaxDealSize,
       ValidateMarketRange, ValidateCircuitBreakers,
       ApplySplitLogic, ApplyRounding, SpreadLogic,
       UpdateNetting, ValidateHBCExecution, AllowHBCFailover, SLTPBehavior
FROM Hedge.BusinessFlowBehavior WITH (NOLOCK)
ORDER BY BusinessFlowID
```

### 8.2 Find flows that allow HBC failover

```sql
SELECT BusinessFlowID, BusinessFlowName, AllowHBCFailover, ValidateHBCExecution
FROM Hedge.BusinessFlowBehavior WITH (NOLOCK)
WHERE AllowHBCFailover = 1
ORDER BY BusinessFlowID
```

### 8.3 Compare validation enablement across flows

```sql
SELECT BusinessFlowID, BusinessFlowName,
       ValidateMinOrderSize, ValidateMaxDealSize,
       ValidateMarketRange, ValidateCircuitBreakers
FROM Hedge.BusinessFlowBehavior WITH (NOLOCK)
ORDER BY BusinessFlowID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetBusinessFlowBehaviorSettings | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetBusinessFlowBehaviorSettings.sql*
