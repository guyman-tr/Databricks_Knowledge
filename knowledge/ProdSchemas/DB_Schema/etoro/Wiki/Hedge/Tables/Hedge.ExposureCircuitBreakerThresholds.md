# Hedge.ExposureCircuitBreakerThresholds

> Per-instrument, direction-aware circuit breaker configuration table that defines separate USD-denominated alert and trigger thresholds for over-hedged vs under-hedged exposure states.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, IsOverHedged) - composite PK CLUSTERED |
| **Partition** | No (on [PRIMARY] filegroup, FILLFACTOR=95) |
| **Indexes** | 1 (composite PK only) |

---

## 1. Business Meaning

`Hedge.ExposureCircuitBreakerThresholds` extends the circuit breaker concept with direction awareness. Unlike `Hedge.InstrumentConfiguration.CircuitBreakerLimit` (a single undirected limit), this table distinguishes between two opposite risk states:

- **Over-hedged** (`IsOverHedged=1`): eToro holds more hedge than required by client exposure. The risk is opportunity cost and over-hedging loss.
- **Under-hedged** (`IsOverHedged=0`): eToro holds less hedge than required. The risk is unhedged client exposure creating balance-sheet risk.

For each state, separate alert and trigger thresholds allow asymmetric risk tolerance: for example, a $10M under-hedge might be more dangerous than a $10M over-hedge, requiring a tighter trigger threshold.

**Current state**: The table has 0 rows (current and history empty) and no stored procedures read from it (no reader procedure found in the Hedge schema). This table appears to have been designed and created but not yet integrated into the active hedge engine flow.

---

## 2. Business Logic

### 2.1 Direction-Aware Circuit Breaker

**What**: Two rows per instrument define separate circuit breaker thresholds for each exposure direction (over-hedged and under-hedged).

**Columns/Parameters Involved**: `InstrumentID`, `IsOverHedged`, `CircuitBreakerAlertThresholdUSD`, `CircuitBreakerTriggerThresholdUSD`

**Rules**:
- `IsOverHedged=1` row: thresholds for when hedge exceeds required coverage
- `IsOverHedged=0` row: thresholds for when hedge is short of required coverage
- `CircuitBreakerAlertThresholdUSD`: soft warning - generate an alert but continue operating
- `CircuitBreakerTriggerThresholdUSD`: hard stop - halt hedge execution for this instrument
- Values are USD money type (4 decimal precision)
- Each instrument can have 0, 1, or 2 rows (one per direction)

**Diagram**:
```
ExposureCircuitBreakerThresholds row structure:
  InstrumentID=X, IsOverHedged=0 (under-hedge CB thresholds)
  InstrumentID=X, IsOverHedged=1 (over-hedge CB thresholds)

For each direction:
  |exposure| < Alert   -> normal operation
  |exposure| >= Alert  -> generate warning alert
  |exposure| >= Trigger -> circuit breaker trips, halt execution
```

---

## 3. Data Overview

| InstrumentID | IsOverHedged | Alert Threshold | Trigger Threshold | Meaning |
|---|---|---|---|---|
| (no rows) | - | - | - | Table currently empty - no circuit breaker thresholds configured |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this circuit breaker applies to. Part of composite PK. No FK constraint - implicit reference to Trade.Instrument. |
| 2 | IsOverHedged | bit | NO | - | VERIFIED | Direction flag. 1=over-hedged circuit breaker (excess hedge above required), 0=under-hedged circuit breaker (deficit hedge below required). Together with InstrumentID forms the composite PK, allowing distinct thresholds per direction. |
| 3 | CircuitBreakerAlertThresholdUSD | money | NO | - | VERIFIED | USD exposure amount at which a soft alert is triggered. When the direction-specific exposure exceeds this value, an alert is generated but execution continues. Money type (accurate to $0.0001). |
| 4 | CircuitBreakerTriggerThresholdUSD | money | NO | - | VERIFIED | USD exposure amount at which the circuit breaker trips. When exceeded, hedge execution for this instrument halts. Should be >= CircuitBreakerAlertThresholdUSD. Money type. |
| 5 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 6 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 8 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.ExposureCircuitBreakerThresholds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. InstrumentID implicitly references Trade.Instrument but is not enforced in DDL.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ExposureCircuitBreakerThresholds | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

Note: No stored procedures in the Hedge schema currently read from this table. The table was created without an active reader procedure, suggesting the feature is designed but not yet operationally integrated.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExposureCircuitBreakerThresholds (table)
  (no FK dependencies - leaf table)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ExposureCircuitBreakerThresholds | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExposureCircuitBreakerThresholds | CLUSTERED PK | InstrumentID ASC, IsOverHedged ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ExposureCircuitBreakerThresholds | PRIMARY KEY | (InstrumentID, IsOverHedged) - one row per instrument per direction |
| DF_ExposureCircuitBreakerThresholds_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_ExposureCircuitBreakerThresholds_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ExposureCircuitBreakerThresholds |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| TRG_T_ExposureCircuitBreakerThresholds | INSERT | No-op self-UPDATE to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all circuit breaker thresholds by direction

```sql
SELECT
    ecbt.InstrumentID,
    ecbt.IsOverHedged,
    CASE ecbt.IsOverHedged WHEN 1 THEN 'Over-Hedged' ELSE 'Under-Hedged' END AS Direction,
    ecbt.CircuitBreakerAlertThresholdUSD,
    ecbt.CircuitBreakerTriggerThresholdUSD
FROM Hedge.ExposureCircuitBreakerThresholds ecbt WITH (NOLOCK)
ORDER BY ecbt.InstrumentID, ecbt.IsOverHedged
```

### 8.2 Find instruments with asymmetric thresholds (different alert vs trigger levels)

```sql
SELECT
    InstrumentID,
    IsOverHedged,
    CircuitBreakerAlertThresholdUSD,
    CircuitBreakerTriggerThresholdUSD,
    CircuitBreakerTriggerThresholdUSD - CircuitBreakerAlertThresholdUSD AS AlertBuffer
FROM Hedge.ExposureCircuitBreakerThresholds WITH (NOLOCK)
WHERE CircuitBreakerAlertThresholdUSD <> CircuitBreakerTriggerThresholdUSD
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no reader procedure found) | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.ExposureCircuitBreakerThresholds | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.sql*
