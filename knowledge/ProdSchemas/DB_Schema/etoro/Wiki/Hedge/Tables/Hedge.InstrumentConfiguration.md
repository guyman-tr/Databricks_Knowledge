# Hedge.InstrumentConfiguration

> Per-instrument hedge execution parameter table storing order size thresholds, circuit breaker limits, and HBC deal size guards that the hedge engine applies when routing and validating hedge orders for each instrument.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, FK to Trade.Instrument, PK CLUSTERED) |
| **Partition** | No (on [PRIMARY] filegroup) |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

`Hedge.InstrumentConfiguration` is the per-instrument configuration table for hedge order execution. Every tradeable instrument has exactly one row here, defining four categories of execution control parameters:

1. **HBC deal size thresholds** - the Hedge Bot Controller (HBC) validates incoming hedge orders against `HBCDealSizeThresholdAlertInEToroUnits` (warning) and `HBCMaxDealSizeThresholdRejectInEToroUnits` (hard reject). Orders exceeding the alert threshold generate a warning log; orders exceeding the reject threshold are refused outright before execution.

2. **Minimum order size** - `MinOrderSizeForExecutionInEToroUnits` sets a floor: hedge orders smaller than this value are not routed for execution (too small to hedge efficiently).

3. **Manual execution cap** - `ManualMaxDealSizeInEToroUnits` caps the maximum deal size that can be submitted via the manual order execution path. Distinct from the automated HBC path.

4. **Circuit breaker** - `CircuitBreakerLimit` and `CircuitBreakerWarningLimit` are safety thresholds that halt or warn when cumulative hedge exposure on an instrument approaches dangerous levels. Currently configured on 73 of 10,468 instruments (all at 100,000).

`SpreadReturnFactor`, `RestrictManualActions`, and `LotSizeForView` are present in the schema but uniformly 1, 0, and 1 respectively across all 10,468 rows - these columns appear reserved for future use or not yet operationally differentiated.

Data flows: `Hedge.GetAllInstrumentConfigurations` returns the full row to the hedge engine on startup. Dedicated procedures `GetInstrumentConfiguration`, `GetInstrumentMinOrderSizeForHBC`, and `GetCircuitBreakerInstrumentThresholds` serve specific subsystems. All writes are dual-tracked to both the temporal history table and `History.AuditHistory` via DML triggers.

---

## 2. Business Logic

### 2.1 HBC Deal Size Threshold Hierarchy

**What**: HBC (Hedge Bot Controller) applies a two-level deal size check to each outgoing hedge order: a warning level and a hard reject level.

**Columns/Parameters Involved**: `HBCDealSizeThresholdAlertInEToroUnits`, `HBCMaxDealSizeThresholdRejectInEToroUnits`, `InstrumentID`

**Rules**:
- Order size < Alert threshold: normal execution, no warning
- Order size >= Alert threshold but < Reject threshold: execution proceeds but HBC generates an alert log entry
- Order size >= Reject threshold: HBC rejects the order entirely; no hedge execution occurs
- Both thresholds are in "eToro units" (the platform's internal monetary unit denomination)
- Most equity instruments have alert=2,000,000 and reject=2,000,000 (equal thresholds = alert is also the reject level)
- The DEFAULT values in the DDL (30,000,000) are rarely the actual values - most instruments have per-instrument overrides loaded at DB setup

**Diagram**:
```
Order arrives -> HBC checks size:
  size < Alert    -> OK, route normally
  size >= Alert   -> WARN + log to HBCOrderLog/HBCExecutionLog
  size >= Reject  -> HARD REJECT, order not sent to provider
```

### 2.2 Circuit Breaker Safety Net

**What**: Per-instrument circuit breaker that halts hedge execution when cumulative exposure reaches configured limits.

**Columns/Parameters Involved**: `CircuitBreakerLimit`, `CircuitBreakerWarningLimit`

**Rules**:
- NULL: circuit breaker not configured for this instrument (5,441 instruments)
- Zero: circuit breaker explicitly disabled (4,954 instruments)
- Non-zero: circuit breaker active at the configured value (73 instruments; all currently set to 100,000)
- `CircuitBreakerWarningLimit` triggers a soft alert; `CircuitBreakerLimit` triggers a hard halt
- Dedicated reader: `Hedge.GetCircuitBreakerInstrumentThresholds` returns only these two columns + InstrumentID

### 2.3 Minimum Order Size for Execution

**What**: Floor threshold below which hedge orders are not routed (too small to hedge meaningfully or cost-effectively).

**Columns/Parameters Involved**: `MinOrderSizeForExecutionInEToroUnits`

**Rules**:
- 0 = no minimum enforced (5,039 instruments; order always eligible for routing)
- Non-zero = hedge orders smaller than this value are dropped/skipped (5,429 instruments have a minimum, range up to 83,334 units)
- Standard instruments average ~42 units; Futures instruments average ~2 units
- Dedicated reader: `Hedge.GetInstrumentMinOrderSizeForHBC` returns this column to the HBC component

---

## 3. Data Overview

| InstrumentID | Min order | HBC Alert | HBC Reject | ManualMax | CB Limit | LotSizeView | Meaning |
|---|---|---|---|---|---|---|---|
| 1-10 (equities) | 0 | 2,000,000 | 2,000,000 | 200,000 | 0 | 1 | Standard equity - no min order, 2M threshold, CB disabled |
| 8 | 0 | 2,000,000 | 9,999,999 | 200,000 | 0 | 1 | Equity with elevated reject threshold (instrument-specific override) |
| 200000+ (Futures) | ~2 | varies | varies | varies | NULL/0 | 1 | Futures instrument - small min order size reflecting contract units |
| 1001488+ | 0 | varies | varies | varies | 100,000 | 1 | Instrument with active circuit breaker configured at 100,000 |

Totals: 10,468 rows (10,163 standard instruments ID 1-100,749; 305 futures ID 200,000-21,100,110).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Primary key and FK to Trade.Instrument(InstrumentID). One row per instrument. All 10,468 instruments have exactly one configuration row. Futures instruments appear in the 200,000+ range; standard equities in 1-100,749. |
| 2 | MinOrderSizeForExecutionInEToroUnits | decimal(19,5) | YES | 1 | VERIFIED | Minimum hedge order size before execution is attempted. Orders below this value are skipped. 0 = no minimum (5,039 instruments). Non-zero values range up to 83,334 units; average ~42 for equities, ~2 for futures. Read by `GetInstrumentMinOrderSizeForHBC`. |
| 3 | HBCDealSizeThresholdAlertInEToroUnits | int | NO | 30000000 | VERIFIED | HBC (Hedge Bot Controller) warning threshold in eToro units. Orders at or above this size trigger an alert log entry but still execute. Most equity instruments set to 2,000,000. Range 0-20,000,000 in data. Read by `GetInstrumentConfiguration`. |
| 4 | HBCMaxDealSizeThresholdRejectInEToroUnits | int | NO | 30000000 | VERIFIED | HBC hard rejection threshold in eToro units. Orders at or above this size are refused outright - no execution occurs. Typically equal to or higher than the alert threshold. Range 0-9,999,999 in data. Read by `GetInstrumentConfiguration`. |
| 5 | ManualMaxDealSizeInEToroUnits | int | YES | - | VERIFIED | Maximum deal size permitted via the manual order execution path (distinct from automated HBC path). No NULL values in data (0 null rows). Most instruments set to 200,000. |
| 6 | SpreadReturnFactor | decimal(10,4) | NO | 1 | CODE-BACKED | Multiplier applied to spread calculations. DEFAULT 1; all 10,468 rows have value 1.0000 - this column is currently uniform and appears reserved for future per-instrument spread adjustment. Read by `GetAllInstrumentConfigurations`. |
| 7 | CircuitBreakerLimit | decimal(14,4) | YES | - | VERIFIED | Hard cumulative exposure limit. When reached, the circuit breaker halts hedge execution for this instrument. NULL=not configured (5,441 rows); 0=disabled (4,954 rows); 100,000=active (73 rows). Read by `GetCircuitBreakerInstrumentThresholds`. |
| 8 | CircuitBreakerWarningLimit | decimal(12,4) | YES | - | VERIFIED | Soft cumulative exposure limit. When reached, generates a warning before the hard limit triggers. Typically equal to or less than CircuitBreakerLimit. NULL or 0 when circuit breaker not configured. Read by `GetCircuitBreakerInstrumentThresholds`. |
| 9 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML via `suser_name()`. |
| 10 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from `CONTEXT_INFO()`. NULL when not set. |
| 11 | SysStartTime | datetime2(7) | NO | sysutcdatetime() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. Managed by SQL Server SYSTEM_VERSIONING. |
| 12 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for all current rows. Historical versions in History.HedgeInstrumentConfiguration. |
| 13 | RestrictManualActions | smallint | NO | 0 | CODE-BACKED | Flag to restrict manual hedge actions for this instrument. DEFAULT 0; all 10,468 rows have value 0 - this column is currently uniform and appears reserved for future per-instrument manual action restriction. |
| 14 | LotSizeForView | decimal(10,4) | NO | 1 | CODE-BACKED | Lot size normalization factor for display/reporting purposes. DEFAULT 1; all 10,468 rows have value 1.0000 - currently uniform across all instruments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_HedgeInstrumentConfiguration_Instrument) | Each configuration row governs exactly one instrument; the instrument must exist in Trade.Instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetAllInstrumentConfigurations | (table ref) | READER | SELECTs all columns; returns full configuration to hedge engine on startup |
| Hedge.GetInstrumentConfiguration | (table ref) | READER | SELECTs InstrumentID + HBC thresholds (alert + reject); serves HBC component |
| Hedge.GetInstrumentMinOrderSizeForHBC | (table ref) | READER | SELECTs InstrumentID + MinOrderSizeForExecutionInEToroUnits; serves HBC minimum order check |
| Hedge.GetCircuitBreakerInstrumentThresholds | (table ref) | READER | SELECTs InstrumentID + CircuitBreakerLimit + CircuitBreakerWarningLimit; serves circuit breaker subsystem |
| History.HedgeInstrumentConfiguration | (temporal) | Temporal History | Stores all historical configuration versions via SYSTEM_VERSIONING |
| History.AuditHistory | (trigger) | Audit Log | DML triggers (Insert/Update/Delete) write column-level change records to History.AuditHistory |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.InstrumentConfiguration (table)
  └── Trade.Instrument (table) [FK - InstrumentID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK_HedgeInstrumentConfiguration_Instrument - every InstrumentID must reference a valid instrument |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetAllInstrumentConfigurations | Stored Procedure | READER - full configuration load for hedge engine startup |
| Hedge.GetInstrumentConfiguration | Stored Procedure | READER - HBC deal size thresholds |
| Hedge.GetInstrumentMinOrderSizeForHBC | Stored Procedure | READER - minimum order size for HBC validation |
| Hedge.GetCircuitBreakerInstrumentThresholds | Stored Procedure | READER - circuit breaker limits per instrument |
| History.HedgeInstrumentConfiguration | Table | Temporal shadow table |
| History.AuditHistory | Table | Audit log via DML triggers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeInstrumentConfiguration | CLUSTERED PK | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeInstrumentConfiguration | PRIMARY KEY | InstrumentID - one configuration row per instrument |
| FK_HedgeInstrumentConfiguration_Instrument | FOREIGN KEY | InstrumentID must reference Trade.Instrument(InstrumentID) |
| DF_HedgeInstrumentConfiguration_MinOrderSize | DEFAULT | MinOrderSizeForExecutionInEToroUnits = 1 |
| DF_HedgeInstrumentConfiguration_DealSizeAlert | DEFAULT | HBCDealSizeThresholdAlertInEToroUnits = 30000000 |
| DF_HedgeInstrumentConfiguration_MaxDealSize | DEFAULT | HBCMaxDealSizeThresholdRejectInEToroUnits = 30000000 |
| Default_HedgeInstrumentConfiguration_SpreadReturnFactor | DEFAULT | SpreadReturnFactor = 1 |
| DF_HedgeInstrumentConfiguration_RestrictManualActions | DEFAULT | RestrictManualActions = 0 |
| DF_HedgeInstrumentConfiguration_LotSizeForView | DEFAULT | LotSizeForView = 1 |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.HedgeInstrumentConfiguration |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| AuditDelete_Hedge_InstrumentConfiguration | DELETE | Writes column-level DELETE records to History.AuditHistory for 6 audited columns |
| AuditInsert_Hedge_InstrumentConfiguration | INSERT | Writes column-level INSERT records to History.AuditHistory; includes no-op self-UPDATE to force temporal history capture |
| AuditUpdate_Hedge_InstrumentConfiguration | UPDATE | Writes column-level UPDATE records (old/new values) to History.AuditHistory for changed columns only |

---

## 8. Sample Queries

### 8.1 View full configuration for a specific instrument

```sql
SELECT
    ic.InstrumentID,
    ic.MinOrderSizeForExecutionInEToroUnits,
    ic.HBCDealSizeThresholdAlertInEToroUnits,
    ic.HBCMaxDealSizeThresholdRejectInEToroUnits,
    ic.ManualMaxDealSizeInEToroUnits,
    ic.CircuitBreakerWarningLimit,
    ic.CircuitBreakerLimit,
    ic.RestrictManualActions
FROM Hedge.InstrumentConfiguration ic WITH (NOLOCK)
WHERE ic.InstrumentID = 1
```

### 8.2 Find instruments with active circuit breakers

```sql
SELECT
    ic.InstrumentID,
    ic.CircuitBreakerWarningLimit,
    ic.CircuitBreakerLimit
FROM Hedge.InstrumentConfiguration ic WITH (NOLOCK)
WHERE ic.CircuitBreakerLimit > 0
ORDER BY ic.CircuitBreakerLimit DESC
```

### 8.3 Find instruments with non-default HBC thresholds

```sql
SELECT
    ic.InstrumentID,
    ic.HBCDealSizeThresholdAlertInEToroUnits,
    ic.HBCMaxDealSizeThresholdRejectInEToroUnits,
    ic.ManualMaxDealSizeInEToroUnits
FROM Hedge.InstrumentConfiguration ic WITH (NOLOCK)
WHERE ic.HBCMaxDealSizeThresholdRejectInEToroUnits <> ic.HBCDealSizeThresholdAlertInEToroUnits
ORDER BY ic.InstrumentID
```

### 8.4 View configuration change history for an instrument

```sql
SELECT
    h.InstrumentID,
    h.ColumnName,
    h.OldValue,
    h.NewValue,
    h.Operation,
    h.AuditDate,
    h.UserName
FROM History.AuditHistory h WITH (NOLOCK)
WHERE h.SchemaName = 'Hedge'
  AND h.TableName = 'InstrumentConfiguration'
  AND h.PK_Value = '1'  -- specific InstrumentID
ORDER BY h.AuditDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.InstrumentConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.InstrumentConfiguration.sql*
