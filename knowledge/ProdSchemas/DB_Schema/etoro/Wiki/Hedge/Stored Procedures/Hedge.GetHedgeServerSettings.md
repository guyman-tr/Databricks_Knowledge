# Hedge.GetHedgeServerSettings

> Returns operational runtime settings for all hedge servers from Trade.HedgeServer: execution mode, price source, circuit breaker limits, periodic hedge schedule, unit rounding, and OMS partial fill flag. No parameters; full-table read of 12 selected columns. Used by the hedge engine at startup to load execution configuration.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters, returns all hedge servers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHedgeServerSettings is the primary configuration loader for the hedge engine runtime. At startup, the hedge engine calls this procedure to read the operational parameters that govern how each hedge server executes: what operational mode it runs in, which price source to quote, how aggressively to size orders (ExecutionFactor), when to trigger circuit breakers, and the schedule for periodic hedging.

The procedure reads from `Trade.HedgeServer` (cross-schema) - the authoritative table for hedge server configuration. It returns 12 of the ~29 columns in Trade.HedgeServer, specifically the operational runtime settings (not identity/connectivity fields like IPAddress, Port, or temporal audit columns).

Note the naming: this is `Hedge.GetHedgeServerSettings` (schema = Hedge) reading from `Trade.HedgeServer` (schema = Trade). This is a deliberate cross-schema read; the Hedge schema procedures act as the service layer while the Trade schema owns the core hedge server entity.

No parameters; no filtering - all rows including the placeholder HedgeServerID=0 are returned. The calling service is responsible for filtering.

---

## 2. Business Logic

### 2.1 Operational Mode and Price Source

**What**: Controls how the hedge server presents itself operationally and which price feed it uses.

**Columns/Parameters Involved**: `OperationalMode`, `PriceSource`

**Rules**:
- `OperationalMode` (smallint, DEFAULT 1): Execution mode. Observed values: 1 (standard), 2 (alternate mode). Hedge.SSRS_Latency_Report groups latency metrics by OperationalMode.
- `PriceSource` (smallint, DEFAULT 1): Which price feed to use for quoting. DEFAULT 1 = primary source (maps to Dictionary.PriceSourceName; 1=Xignite). Non-default values indicate alternative feeds or internal prices.

### 2.2 Execution Factor and Circuit Breakers

**What**: Risk parameters that control execution sizing and exposure limits.

**Columns/Parameters Involved**: `ExecutionFactor`, `CircuitBreakerWarningLimit`, `CircuitBreakerLimit`

**Rules**:
- `ExecutionFactor` (decimal, DEFAULT 1): Multiplier for order sizing. Must be 0.75-1.0 per Monitor.AlertForDealingExecutionConfigurationManager. Values outside this range trigger monitoring alerts.
- `CircuitBreakerLimit` (decimal): Maximum exposure threshold. Monitor alerts if < 10,000,000 or > 100,000,000.
- `CircuitBreakerWarningLimit` (decimal): Pre-circuit-breaker warning threshold; read by Hedge.GetServerCircuitBreakerThresholds for alert tuning.

### 2.3 Periodic Hedge Schedule

**What**: Configuration for STRATEGY_PERIODIC_BOUNDARIES mode: when and how often to run periodic hedge cycles.

**Columns/Parameters Involved**: `PeriodicHedgeIntervalMinutes`, `PeriodicHedgeHours`

**Rules**:
- `PeriodicHedgeIntervalMinutes` (int): Minutes between periodic hedge runs. NULL = not using periodic mode.
- `PeriodicHedgeHours` (varchar(50)): Schedule string for periodic hedging (e.g., market hours window). NULL = not using periodic mode.
- Relevant when `Trade.HedgeServer.HedgeStrategyModeID = 3` (STRATEGY_PERIODIC_BOUNDARIES). GetHedgeServerSettings does NOT return HedgeStrategyModeID - caller must cross-reference with full HedgeServer data if needed.

### 2.4 Unit Rounding and OMS Partial Fill

**What**: Precision and OMS interaction settings.

**Columns/Parameters Involved**: `UnitRoundingMethod`, `RequestedAlertIntervalSeconds`, `ManagedExposurePeriodSec`, `AllowOMSPricingPartialFill`

**Rules**:
- `UnitRoundingMethod` (tinyint): How unit/lot quantities are rounded before execution. Avoids fractional units at execution layer.
- `RequestedAlertIntervalSeconds` (int, DEFAULT 180): Interval in seconds for requested/alert monitoring reports.
- `ManagedExposurePeriodSec` (int): Period for managed exposure calculations.
- `AllowOMSPricingPartialFill` (bit, DEFAULT 0): Whether OMS is permitted to price on partial fills. 0=no (wait for full fill), 1=yes (price on partial).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (returned resultset - 12 of ~29 Trade.HedgeServer columns):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server identifier. PK of Trade.HedgeServer. Includes all rows (0 = placeholder, active servers). |
| 2 | OperationalMode | smallint | NO | 1 | CODE-BACKED | Execution mode. DEFAULT 1. Observed values: 1 (standard), 2 (alternate). Used in SSRS latency reports. |
| 3 | PriceSource | smallint | NO | 1 | CODE-BACKED | Price feed selection. DEFAULT 1 = primary (Xignite). Instrument-level override available via Hedge.HedgeServerInstrumentConfiguration.PriceSource. |
| 4 | ExecutionFactor | decimal(16,8) | NO | 1 | CODE-BACKED | Order size multiplier. Must be 0.75-1.0. Alerts fire outside this range. |
| 5 | CircuitBreakerWarningLimit | decimal(12,4) | YES | - | CODE-BACKED | Pre-circuit-breaker warning exposure threshold. Triggers early warning alerts. |
| 6 | CircuitBreakerLimit | decimal(14,4) | YES | - | CODE-BACKED | Hard exposure circuit breaker. Monitor alerts if < 10M or > 100M. |
| 7 | PeriodicHedgeIntervalMinutes | int | YES | - | CODE-BACKED | Minutes between periodic hedge cycles (STRATEGY_PERIODIC_BOUNDARIES only). NULL if not in periodic mode. |
| 8 | PeriodicHedgeHours | varchar(50) | YES | - | CODE-BACKED | Hours schedule string for periodic hedging (e.g., market hours). NULL if not in periodic mode. |
| 9 | UnitRoundingMethod | tinyint | YES | - | CODE-BACKED | Lot/unit rounding method code. Controls precision of order sizes sent to liquidity providers. |
| 10 | RequestedAlertIntervalSeconds | int | YES | 180 | CODE-BACKED | Alert/report generation interval in seconds. DEFAULT 180. |
| 11 | ManagedExposurePeriodSec | int | YES | - | CODE-BACKED | Period in seconds for managed exposure window calculations. |
| 12 | AllowOMSPricingPartialFill | bit | NO | 0 | CODE-BACKED | OMS partial fill pricing permission. DEFAULT 0 (no). 1 = allow pricing on partial fills. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Full table read | Trade.HedgeServer | Cross-schema Read | 12 operational setting columns from the authoritative hedge server config table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | Result set | Caller | Configuration load at startup: reads operational mode, circuit breakers, periodic schedule, rounding. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHedgeServerSettings (procedure)
└── Trade.HedgeServer (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | Cross-schema read. 12 operational columns selected. Full table (no WHERE). NOLOCK hint. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine (external) | Application | Primary configuration loader for hedge server runtime settings. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No temp tables. No parameters. Single cross-schema SELECT with NOLOCK. Returns all rows including placeholder HedgeServerID=0.

Note: This procedure does NOT return HedgeStrategyModeID, IsDummy, IPAddress, Port, IsActive, ConsiderOpenRequestsSec - those are available via direct Trade.HedgeServer queries or other procedures.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetHedgeServerSettings;
```

### 8.2 Identify servers near circuit breaker limits

```sql
-- After executing the procedure, filter for risk:
SELECT HedgeServerID, CircuitBreakerLimit, CircuitBreakerWarningLimit
FROM   Trade.HedgeServer WITH (NOLOCK)
WHERE  CircuitBreakerLimit IS NOT NULL
AND    (CircuitBreakerLimit < 10000000 OR CircuitBreakerLimit > 100000000);
```

### 8.3 Find periodic hedge servers

```sql
SELECT HedgeServerID, PeriodicHedgeIntervalMinutes, PeriodicHedgeHours
FROM   Trade.HedgeServer WITH (NOLOCK)
WHERE  PeriodicHedgeIntervalMinutes IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Hedge server runtime config: operational modes, circuit breakers, ExecutionFactor constraints. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHedgeServerSettings | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHedgeServerSettings.sql*
