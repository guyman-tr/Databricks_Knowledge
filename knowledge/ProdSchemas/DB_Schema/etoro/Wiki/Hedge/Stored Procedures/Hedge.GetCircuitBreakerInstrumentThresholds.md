# Hedge.GetCircuitBreakerInstrumentThresholds

> Returns per-instrument circuit breaker limits (warning and hard) for all instruments, used by the circuit breaker subsystem to determine when to halt hedge execution based on cumulative exposure.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns circuit breaker config for all 10,468 instruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the dedicated reader for the circuit breaker subsystem. It returns the two circuit breaker threshold columns plus the instrument identifier from `Hedge.InstrumentConfiguration`, providing the circuit breaker component of the hedge engine with the exact data it needs - nothing more.

Circuit breakers are a safety mechanism: when cumulative hedge exposure on an instrument accumulates past the warning limit, an alert is raised; when the hard limit is reached, hedge execution for that instrument is halted entirely.

Of the 10,468 instruments configured:
- **5,441** have `CircuitBreakerLimit = NULL` - circuit breaker not configured
- **4,954** have `CircuitBreakerLimit = 0` - circuit breaker explicitly disabled
- **73** have `CircuitBreakerLimit = 100,000` - circuit breaker active

The procedure runs with `SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED` (equivalent to `WITH (NOLOCK)`) - appropriate for a high-frequency configuration read that does not require transactional consistency.

This is the narrowest reader of `Hedge.InstrumentConfiguration`. It intentionally returns only 3 of 14 columns, keeping the circuit breaker subsystem's data footprint minimal. For the full instrument configuration, use `Hedge.GetAllInstrumentConfigurations`. For HBC thresholds, use `Hedge.GetInstrumentConfiguration`.

---

## 2. Business Logic

### 2.1 Circuit Breaker Threshold Interpretation

**What**: Returns the two cumulative exposure limits per instrument that define when circuit breaker actions are triggered.

**Columns/Parameters Involved**: `CircuitBreakerWarningLimit`, `CircuitBreakerLimit`

**Rules**:
- `CircuitBreakerWarningLimit`: when cumulative exposure reaches this level, a soft alert is raised. Triggers a warning before the hard limit.
- `CircuitBreakerLimit`: when cumulative exposure reaches this level, hedge execution for this instrument is halted.
- NULL: the circuit breaker is not configured for this instrument - the subsystem skips circuit breaker logic
- 0: circuit breaker explicitly disabled - no halt will occur regardless of exposure
- Non-zero (100,000 in current data): circuit breaker is active at the configured threshold
- Both values are in the same unit as the exposure measurement

**Decision diagram**:
```
CircuitBreakerLimit is NULL -> no circuit breaker logic for this instrument
CircuitBreakerLimit = 0    -> circuit breaker disabled (always passes)
CircuitBreakerLimit > 0:
  exposure >= CircuitBreakerLimit        -> HARD HALT: stop hedge execution
  exposure >= CircuitBreakerWarningLimit -> SOFT ALERT: log warning, continue
  exposure < CircuitBreakerWarningLimit  -> OK, no action
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Returns 3 columns for all 10,468 instruments from `Hedge.InstrumentConfiguration`. Running with READ UNCOMMITTED isolation for performance. |

**Output Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| InstrumentID | Hedge.InstrumentConfiguration | PK. The instrument this circuit breaker configuration governs. FK to Trade.Instrument. |
| CircuitBreakerLimit | Hedge.InstrumentConfiguration | Hard halt threshold (decimal(14,4)). NULL=not configured (5,441 instruments); 0=disabled (4,954); 100,000=active (73 instruments). When cumulative exposure reaches this value, hedge execution halts for the instrument. |
| CircuitBreakerWarningLimit | Hedge.InstrumentConfiguration | Soft alert threshold (decimal(12,4)). Triggers a warning log before the hard CircuitBreakerLimit is reached. Same distribution as CircuitBreakerLimit. NULL or 0 when circuit breaker not configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.InstrumentConfiguration | Direct read | Returns 3 columns (InstrumentID, CircuitBreakerLimit, CircuitBreakerWarningLimit) for all instruments |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the hedge engine's circuit breaker subsystem to load its per-instrument halt thresholds on startup or refresh.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetCircuitBreakerInstrumentThresholds (procedure)
└── Hedge.InstrumentConfiguration (table) - SELECT 3 columns, no filter
    └── Trade.Instrument (table) - FK on InstrumentID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentConfiguration | Table | SELECT InstrumentID, CircuitBreakerLimit, CircuitBreakerWarningLimit - all rows, no filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READ UNCOMMITTED | Isolation | SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED - dirty reads allowed for high-frequency configuration polling |
| No filter | Design | Returns ALL 10,468 instrument rows - full circuit breaker configuration load |
| Narrow projection | Design | Returns only 3 of 14 InstrumentConfiguration columns - circuit breaker subsystem concern only |
| NULL semantics | Business Rule | NULL CircuitBreakerLimit = no circuit breaker for that instrument; 0 = explicitly disabled; callers must distinguish NULL from 0 |

---

## 8. Sample Queries

### 8.1 View active circuit breakers

```sql
SELECT InstrumentID, CircuitBreakerWarningLimit, CircuitBreakerLimit
FROM Hedge.InstrumentConfiguration WITH (NOLOCK)
WHERE CircuitBreakerLimit > 0
ORDER BY InstrumentID
```

### 8.2 Circuit breaker status summary

```sql
SELECT
    SUM(CASE WHEN CircuitBreakerLimit IS NULL THEN 1 ELSE 0 END) AS NotConfigured,
    SUM(CASE WHEN CircuitBreakerLimit = 0 THEN 1 ELSE 0 END) AS Disabled,
    SUM(CASE WHEN CircuitBreakerLimit > 0 THEN 1 ELSE 0 END) AS Active
FROM Hedge.InstrumentConfiguration WITH (NOLOCK)
```

### 8.3 Instruments where warning threshold equals hard limit

```sql
SELECT InstrumentID, CircuitBreakerWarningLimit, CircuitBreakerLimit
FROM Hedge.InstrumentConfiguration WITH (NOLOCK)
WHERE CircuitBreakerLimit > 0
  AND CircuitBreakerWarningLimit = CircuitBreakerLimit
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetCircuitBreakerInstrumentThresholds | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetCircuitBreakerInstrumentThresholds.sql*
