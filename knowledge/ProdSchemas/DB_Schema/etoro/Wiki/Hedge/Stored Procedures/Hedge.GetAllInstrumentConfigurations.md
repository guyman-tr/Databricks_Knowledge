# Hedge.GetAllInstrumentConfigurations

> Returns the full hedge execution configuration for all instruments - order size thresholds, HBC deal size guards, circuit breaker limits, and manual action controls - used by the hedge engine for bulk configuration load on startup.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full configuration for all 10,468 instruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the hedge engine's primary bulk configuration loader. On startup (or configuration refresh), the hedge engine calls this procedure to load its in-memory instrument configuration matrix - the complete set of order validation rules for every instrument it will process.

The procedure returns 10 of the 14 columns from `Hedge.InstrumentConfiguration`, selecting all business logic columns while excluding temporal metadata (`SysStartTime`, `SysEndTime`) and audit columns (`DbLoginName`, `AppLoginName`). The 10 columns returned cover all four execution control categories:
- **HBC deal size thresholds** (`HBCDealSizeThresholdAlertInEToroUnits`, `HBCMaxDealSizeThresholdRejectInEToroUnits`) - automated order size guards
- **Minimum order size** (`MinOrderSizeForExecutionInEToroUnits`) - floor below which hedge orders are skipped
- **Manual execution cap** (`ManualMaxDealSizeInEToroUnits`) - ceiling for manual execution path
- **Circuit breaker** (`CircuitBreakerWarningLimit`, `CircuitBreakerLimit`) - cumulative exposure safety net
- **Supporting fields** (`SpreadReturnFactor`, `RestrictManualActions`, `LotSizeForView`) - currently uniform across all instruments

The procedure runs with `WITH (NOLOCK)` for read performance, appropriate for a configuration read that may be called frequently and does not require transactional consistency.

For more granular, per-subsystem reads, dedicated procedures serve specific components: `GetInstrumentConfiguration` (HBC thresholds), `GetInstrumentMinOrderSizeForHBC` (minimum order size), `GetCircuitBreakerInstrumentThresholds` (circuit breakers). This procedure serves the full startup load.

---

## 2. Business Logic

### 2.1 Full Configuration Bulk Load

**What**: Returns all 10,468 instrument configuration rows in a single pass - no filtering, no pagination.

**Columns/Parameters Involved**: All 10 selected columns from `Hedge.InstrumentConfiguration`

**Rules**:
- No WHERE clause - every instrument with a configuration row is returned
- Column selection excludes temporal (SysStartTime/SysEndTime) and audit (DbLoginName/AppLoginName) columns
- WITH (NOLOCK) applied - dirty reads accepted for configuration data; avoids blocking on the table during hedge engine restarts
- The hedge engine uses the full result set to populate its in-memory per-instrument validation state

### 2.2 Column Exclusion Pattern

**What**: The procedure intentionally omits 4 of 14 InstrumentConfiguration columns.

**Columns excluded**:
- `DbLoginName` - SQL audit column (computed from `suser_name()`)
- `AppLoginName` - Application audit column (computed from `CONTEXT_INFO()`)
- `SysStartTime` - Temporal system period start
- `SysEndTime` - Temporal system period end

**Columns included**: All 10 operational columns that the hedge engine needs to apply order validation rules.

**Effect**: The result is a clean projection of business logic data without metadata overhead. The hedge engine does not need change-tracking or audit fields for its in-memory state.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Returns all rows from `Hedge.InstrumentConfiguration` for all 10,468 instruments. Used for hedge engine startup configuration load. |

**Output Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| InstrumentID | Hedge.InstrumentConfiguration | PK. The instrument this configuration governs. FK to Trade.Instrument. Standard instruments: 1-100,749; Futures: 200,000-21,100,110. |
| MinOrderSizeForExecutionInEToroUnits | Hedge.InstrumentConfiguration | Minimum hedge order size. Orders below this threshold are not routed. 0 = no minimum (5,039 instruments). Non-zero range up to 83,334 units. |
| HBCDealSizeThresholdAlertInEToroUnits | Hedge.InstrumentConfiguration | HBC warning threshold in eToro units. Orders at or above this size trigger an alert log but still execute. Most equities = 2,000,000. |
| HBCMaxDealSizeThresholdRejectInEToroUnits | Hedge.InstrumentConfiguration | HBC hard rejection threshold in eToro units. Orders at or above this size are refused; no execution occurs. Typically equal to or higher than the alert threshold. |
| ManualMaxDealSizeInEToroUnits | Hedge.InstrumentConfiguration | Maximum deal size for the manual execution path. Distinct from the automated HBC path. Most instruments = 200,000. |
| SpreadReturnFactor | Hedge.InstrumentConfiguration | Multiplier for spread calculations. Currently 1.0000 for all 10,468 instruments - reserved for future per-instrument spread adjustment. |
| CircuitBreakerWarningLimit | Hedge.InstrumentConfiguration | Soft cumulative exposure limit. Triggers a warning before the hard circuit breaker. NULL = not configured (5,441 instruments); 0 = disabled (4,954 instruments); 100,000 = active (73 instruments). |
| CircuitBreakerLimit | Hedge.InstrumentConfiguration | Hard cumulative exposure limit. When reached, halts hedge execution for this instrument. Same distribution as CircuitBreakerWarningLimit. |
| RestrictManualActions | Hedge.InstrumentConfiguration | Flag to restrict manual hedge actions. Currently 0 for all 10,468 instruments - reserved for future per-instrument manual action restriction. |
| LotSizeForView | Hedge.InstrumentConfiguration | Lot size normalization factor for display/reporting. Currently 1.0000 for all 10,468 instruments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.InstrumentConfiguration | Direct read | Returns 10 of 14 columns for all instruments; full configuration matrix for hedge engine startup |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the hedge engine on startup (or configuration refresh) to load its in-memory instrument validation state.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAllInstrumentConfigurations (procedure)
└── Hedge.InstrumentConfiguration (table) - SELECT 10 columns, no filter
    └── Trade.Instrument (table) - FK on InstrumentID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentConfiguration | Table | SELECT 10 operational columns (all rows, no filter). Excludes audit and temporal columns. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No filter | Design | Returns ALL 10,468 rows - designed for full bulk load. Result set size grows with instrument count. |
| WITH (NOLOCK) | Isolation | Applied to Hedge.InstrumentConfiguration - dirty reads accepted for startup configuration load |
| Partial column select | Design | Returns 10 of 14 columns - excludes temporal (SysStartTime, SysEndTime) and audit (DbLoginName, AppLoginName) metadata columns |
| Startup context | Usage | Intended for one-time bulk load at hedge engine startup; not for frequent per-instrument queries (use GetInstrumentConfiguration for targeted reads) |

---

## 8. Sample Queries

### 8.1 Equivalent query for full instrument configuration

```sql
SELECT InstrumentID,
       MinOrderSizeForExecutionInEToroUnits,
       HBCDealSizeThresholdAlertInEToroUnits,
       HBCMaxDealSizeThresholdRejectInEToroUnits,
       ManualMaxDealSizeInEToroUnits,
       SpreadReturnFactor,
       CircuitBreakerWarningLimit,
       CircuitBreakerLimit,
       RestrictManualActions,
       LotSizeForView
FROM Hedge.InstrumentConfiguration WITH (NOLOCK)
ORDER BY InstrumentID
```

### 8.2 Check instruments with asymmetric HBC alert vs reject thresholds

```sql
SELECT InstrumentID,
       HBCDealSizeThresholdAlertInEToroUnits,
       HBCMaxDealSizeThresholdRejectInEToroUnits,
       ManualMaxDealSizeInEToroUnits
FROM Hedge.InstrumentConfiguration WITH (NOLOCK)
WHERE HBCMaxDealSizeThresholdRejectInEToroUnits <> HBCDealSizeThresholdAlertInEToroUnits
ORDER BY InstrumentID
```

### 8.3 Find instruments with minimum order size restrictions

```sql
SELECT InstrumentID,
       MinOrderSizeForExecutionInEToroUnits,
       HBCDealSizeThresholdAlertInEToroUnits
FROM Hedge.InstrumentConfiguration WITH (NOLOCK)
WHERE MinOrderSizeForExecutionInEToroUnits > 0
ORDER BY MinOrderSizeForExecutionInEToroUnits DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAllInstrumentConfigurations | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAllInstrumentConfigurations.sql*
