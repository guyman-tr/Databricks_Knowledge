# Hedge.ExecutionFactorConfiguration

> Per-strategy, per-instrument execution scaling configuration that defines a decimal multiplier controlling what fraction of the required hedge exposure is actually executed, enabling partial or amplified hedging by strategy and instrument.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (StrategyID, InstrumentID) - composite PK CLUSTERED |
| **Partition** | No (on [DICTIONARY] filegroup) |
| **Indexes** | 1 (composite PK only) |

---

## 1. Business Meaning

`Hedge.ExecutionFactorConfiguration` stores a per-strategy, per-instrument `ExecutionFactor` multiplier that scales the hedge engine's execution size. Rather than hedging 100% of client exposure at all times, a strategy can be configured to hedge a smaller or larger fraction for specific instruments:

- `ExecutionFactor = 1.0`: hedge the full required exposure (1:1 ratio)
- `ExecutionFactor = 0.5`: hedge only 50% of exposure (partial hedge - deliberate under-hedging)
- `ExecutionFactor = 1.2`: hedge 120% of exposure (over-hedge buffer)

This supports strategies where different risk tolerances or liquidity considerations justify different hedge ratios for individual instruments.

`IsActive` controls whether a given factor is currently applied (only active rows are returned by `Hedge.GetStrategyInstrumentExecutionFactorConfiguration`).

Note: `Hedge.GetStrategyExecutionFactorConfiguration` (similarly named) actually reads from `Trade.HedgeServer.ExecutionFactor` - a server-level factor rather than this instrument-level configuration table.

**Current state**: The table has 0 rows in both current and history tables. No instrument-level execution factors are currently configured.

---

## 2. Business Logic

### 2.1 Execution Scaling

**What**: Scales hedge execution size by a decimal factor for a specific strategy/instrument combination.

**Columns/Parameters Involved**: `StrategyID`, `InstrumentID`, `ExecutionFactor`, `IsActive`

**Rules**:
- Only rows with `IsActive=1` are returned and applied by the engine
- `IsActive=0` rows remain as inactive configurations (soft-delete, historical record preserved)
- `ExecutionFactor` is decimal(16,8): supports high-precision fractional multipliers
- DEFAULT for IsActive is 0 (inactive by default - new configs must be explicitly activated)
- StrategyID has no FK constraint - application-managed reference to hedge strategy
- InstrumentID has no FK constraint - implicit reference to Trade.Instrument
- `GetStrategyInstrumentExecutionFactorConfiguration` returns InstrumentID + StrategyID + ExecutionFactor WHERE IsActive=1

---

## 3. Data Overview

| StrategyID | InstrumentID | ExecutionFactor | IsActive | Meaning |
|---|---|---|---|---|
| (no rows) | - | - | - | Table currently empty - no instrument-level execution factors configured |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StrategyID | int | NO | - | CODE-BACKED | The hedge strategy this execution factor applies to. Part of composite PK. No FK constraint - application-managed. One strategy can have different factors for different instruments. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this execution factor applies to. Part of composite PK. No FK constraint - implicit reference to Trade.Instrument. |
| 3 | ExecutionFactor | decimal(16,8) | NO | - | VERIFIED | Scaling multiplier for hedge execution size. 1.0=full hedge, 0.5=50% partial hedge, 1.2=120% over-hedge buffer. High precision (8 decimal places) supports fractional calibration. Applied only when IsActive=1. |
| 4 | IsActive | bit | YES | 0 | VERIFIED | Whether this factor is currently applied. 1=active (returned by GetStrategyInstrumentExecutionFactorConfiguration and applied by engine), 0=inactive (soft-deleted or staged, not applied). DEFAULT 0 - new configs require explicit activation. |
| 5 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 6 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 8 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.ExecutionFactorConfiguration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. StrategyID and InstrumentID are application-managed without explicit FK enforcement.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetStrategyInstrumentExecutionFactorConfiguration | (table ref) | READER | SELECTs InstrumentID + StrategyID + ExecutionFactor WHERE IsActive=1; returns active scaling factors to hedge engine |
| History.ExecutionFactorConfiguration | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

Note: `Hedge.GetStrategyExecutionFactorConfiguration` (similarly named) reads from `Trade.HedgeServer.ExecutionFactor`, not from this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExecutionFactorConfiguration (table)
  (no FK dependencies - leaf table)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetStrategyInstrumentExecutionFactorConfiguration | Stored Procedure | READER - returns active execution factors for hedge engine scaling |
| History.ExecutionFactorConfiguration | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_executionFactorConfiguration | CLUSTERED PK | StrategyID ASC, InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_executionFactorConfiguration | PRIMARY KEY | (StrategyID, InstrumentID) - one factor per strategy/instrument pair |
| DEFAULT IsActive | DEFAULT | IsActive = 0 (inactive by default; must be explicitly activated) |
| DF_ExecutionFactorConfiguration_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_ExecutionFactorConfiguration_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ExecutionFactorConfiguration |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| Tr_T_ExecutionFactorConfiguration_INSERT | INSERT | No-op self-UPDATE to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all active execution factors

```sql
SELECT
    efc.StrategyID,
    efc.InstrumentID,
    efc.ExecutionFactor,
    efc.IsActive
FROM Hedge.ExecutionFactorConfiguration efc WITH (NOLOCK)
WHERE efc.IsActive = 1
ORDER BY efc.StrategyID, efc.InstrumentID
```

### 8.2 Find instruments configured for partial hedging (factor < 1.0)

```sql
SELECT
    efc.StrategyID,
    efc.InstrumentID,
    efc.ExecutionFactor
FROM Hedge.ExecutionFactorConfiguration efc WITH (NOLOCK)
WHERE efc.IsActive = 1
  AND efc.ExecutionFactor < 1.0
ORDER BY efc.ExecutionFactor ASC
```

### 8.3 Compare server-level vs instrument-level execution factors

```sql
-- Server-level factors (from Trade.HedgeServer)
SELECT HedgeServerID, ExecutionFactor AS ServerFactor FROM Trade.HedgeServer WITH (NOLOCK)
-- Instrument-level factors (from this table, active only)
SELECT StrategyID, InstrumentID, ExecutionFactor AS InstrumentFactor
FROM Hedge.ExecutionFactorConfiguration WITH (NOLOCK)
WHERE IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.ExecutionFactorConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExecutionFactorConfiguration.sql*
