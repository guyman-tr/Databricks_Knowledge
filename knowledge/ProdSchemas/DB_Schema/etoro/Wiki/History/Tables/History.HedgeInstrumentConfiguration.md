# History.HedgeInstrumentConfiguration

> SQL Server system-versioned temporal history table for Hedge.InstrumentConfiguration, recording every change to the per-instrument hedge configuration including order size limits, HBC deal size thresholds, circuit breaker parameters, spread settings, and manual trading restrictions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Hedge.InstrumentConfiguration`. SQL Server's system-versioning manages this table transparently: whenever a row in `Hedge.InstrumentConfiguration` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Hedge.InstrumentConfiguration` stores the hedging engine's per-instrument risk and execution parameters. Each instrument that eToro hedges with a liquidity provider has one configuration row defining:
- **Order size controls**: minimum order size for execution and maximum deal sizes for alert/reject thresholds
- **HBC (Hedge Book Control) thresholds**: deal-size alerting and rejection limits that govern how large a single hedge order can be before the system alerts operators or rejects the order outright
- **Circuit breaker limits**: exposure thresholds that trip a circuit breaker to pause hedging when market conditions are abnormal
- **Spread controls**: a factor applied when calculating spread return to customers
- **Manual trading restrictions**: a flag preventing manual trading actions on the instrument

The INSERT trigger on `Hedge.InstrumentConfiguration` fires a no-op UPDATE to force SQL Server to write the newly inserted row into this history table, capturing initial configuration creation as a zero-duration row (SysStartTime = SysEndTime).

**Note**: The table does not exist in this environment (dev/staging) - it is a production configuration table.

---

## 2. Business Logic

### 2.1 HBC Deal Size Controls

**What**: The Hedge Book Control (HBC) system enforces size limits on individual hedge orders to prevent outsized orders from reaching liquidity providers.

**Columns/Parameters Involved**: `HBCDealSizeThresholdAlertInEToroUnits`, `HBCMaxDealSizeThresholdRejectInEToroUnits`, `ManualMaxDealSizeInEToroUnits`

**Rules**:
- `HBCDealSizeThresholdAlertInEToroUnits`: deal sizes above this threshold trigger an alert to operators; DEFAULT 30,000,000 eToro units
- `HBCMaxDealSizeThresholdRejectInEToroUnits`: deal sizes above this threshold are rejected outright; DEFAULT 30,000,000 eToro units
- `ManualMaxDealSizeInEToroUnits`: optional override for manually-submitted hedge orders; NULL means the standard threshold applies
- "eToro Units" is eToro's internal unit denomination for instrument position sizes; the conversion to real-world lots/units is instrument-specific

### 2.2 Minimum Order Size for Execution

**What**: Some instruments require a minimum order size to be routable to a liquidity provider. Orders below this threshold cannot be hedged.

**Columns/Parameters Involved**: `MinOrderSizeForExecutionInEToroUnits`

**Rules**:
- decimal(19,5) - high precision to accommodate fractional unit instruments (e.g., crypto)
- DEFAULT 1 - effectively no minimum for most instruments
- NULL: the column is nullable (the source has DEFAULT 1, but the history table stores whatever was in the source row at the time of change)

### 2.3 Circuit Breaker Configuration

**What**: Circuit breakers halt hedging for an instrument when exposure or price movement exceeds configured limits, protecting eToro from abnormal market conditions.

**Columns/Parameters Involved**: `CircuitBreakerLimit`, `CircuitBreakerWarningLimit`

**Rules**:
- `CircuitBreakerLimit`: decimal(14,4) - the exposure or deviation level at which the circuit breaker trips and hedging is paused
- `CircuitBreakerWarningLimit`: decimal(12,4) - a lower threshold that triggers a warning before the full circuit breaker trips
- Both are NULL in many rows - circuit breakers are configured only for instruments that require them
- The companion temporal table `History.ExposureCircuitBreakerThresholds` stores per-instrument circuit breaker thresholds at a more granular level; this column is the instrument-level override

### 2.4 Spread Return and View Lot Size

**What**: SpreadReturnFactor controls how much of the spread is returned to customers. LotSizeForView is a display-only denominator for showing position sizes in conventional lot units.

**Columns/Parameters Involved**: `SpreadReturnFactor`, `LotSizeForView`

**Rules**:
- `SpreadReturnFactor`: decimal(10,4), DEFAULT 1 - multiplier applied to the spread in spread-return calculations. 1.0 = full spread applies; values less than 1 indicate partial spread return to the customer
- `LotSizeForView`: decimal(10,4), DEFAULT 1 - used in display/reporting to show position sizes in conventional lot units (e.g., 100,000 for FX standard lots). Does not affect execution logic.

### 2.5 Manual Action Restriction

**What**: `RestrictManualActions` is a flag that can prevent manual trading operations on an instrument via the hedging engine's management tools.

**Columns/Parameters Involved**: `RestrictManualActions`

**Rules**:
- smallint DEFAULT 0 (unrestricted)
- When set to a non-zero value, manual hedging actions (open/close via management UI) are blocked for this instrument
- Provides a per-instrument safety control for risk management

### 2.6 INSERT Trigger Capture Pattern

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `AuditInsert_Hedge_InstrumentConfiguration` fires a no-op UPDATE (SET InstrumentID=InstrumentID) on InstrumentID match to force SQL Server to capture the newly inserted row in temporal history
- Zero-duration rows (SysStartTime = SysEndTime) mark INSERT captures
- The same INSERT/UPDATE/DELETE triggers also write individual column changes to `History.AuditHistory` (separate per-column audit log)
- DbLoginName: suser_name() computed column in source
- AppLoginName: CONVERT(varchar(500), context_info()) computed column in source

---

## 3. Data Overview

| Scale | Value |
|-------|-------|
| Total rows | N/A - table not present in this environment |
| Source table | Hedge.InstrumentConfiguration (one row per instrument) |
| Filegroup | [PRIMARY] |

In production, history row count grows with each configuration change. Given that this is risk configuration data (not frequent trading data), history rows accumulate slowly as operators tune thresholds.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument whose hedge configuration is recorded. PK in source (not IDENTITY). FK to Trade.Instrument. One row per instrument in the current table. |
| 2 | MinOrderSizeForExecutionInEToroUnits | decimal(19,5) | YES | - | CODE-BACKED | Minimum order size (in eToro's internal unit denomination) required for this instrument to be routed to a liquidity provider for hedging. Source DEFAULT=1. High precision (19,5) supports fractional-unit instruments like crypto. |
| 3 | HBCDealSizeThresholdAlertInEToroUnits | int | NO | - | CODE-BACKED | HBC (Hedge Book Control) alert threshold in eToro units. Single hedge orders exceeding this size trigger an operator alert. Source DEFAULT=30,000,000. The HBC system protects liquidity providers from oversized orders. |
| 4 | HBCMaxDealSizeThresholdRejectInEToroUnits | int | NO | - | CODE-BACKED | HBC reject threshold in eToro units. Single hedge orders exceeding this size are automatically rejected by the HBC system. Source DEFAULT=30,000,000. Alert threshold is typically lower than or equal to reject threshold. |
| 5 | ManualMaxDealSizeInEToroUnits | int | YES | - | CODE-BACKED | Optional override for maximum deal size on manually-submitted hedge orders. NULL means the standard HBC thresholds apply. When set, provides a tighter constraint for manual operations than the automated threshold. |
| 6 | SpreadReturnFactor | decimal(10,4) | NO | - | CODE-BACKED | Multiplier applied in spread return calculations. Source DEFAULT=1. 1.0 = full market spread applies to the customer; values approaching 0 indicate greater spread subsidization. Affects customer cost of trading. |
| 7 | CircuitBreakerLimit | decimal(14,4) | YES | - | CODE-BACKED | The exposure or deviation threshold at which the circuit breaker trips and hedging is suspended for this instrument. NULL for instruments without circuit breaker protection. High precision (14,4) for large exposure values. |
| 8 | CircuitBreakerWarningLimit | decimal(12,4) | YES | - | CODE-BACKED | Warning threshold below the full circuit breaker limit. Triggers operator alerts before the circuit breaker trips. NULL when not configured. |
| 9 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Computed column in source, materialized here. Identifies which service account made the configuration change. |
| 10 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info() at time of change. Computed column in source, materialized here. May identify the operator email or service that triggered the update. |
| 11 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this instrument configuration version became active. For INSERT-trigger-captured rows, equals SysEndTime. |
| 12 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. |
| 13 | RestrictManualActions | smallint | NO | - | CODE-BACKED | Flag controlling whether manual hedging operations are permitted for this instrument. Source DEFAULT=0 (unrestricted). Non-zero values block manual open/close actions via management tools. |
| 14 | LotSizeForView | decimal(10,4) | NO | - | CODE-BACKED | Display denominator for converting eToro internal units to conventional lot sizes for reporting and UI display. Source DEFAULT=1. Example: setting to 100,000 displays FX positions in standard lots. Does not affect execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The instrument whose hedge configuration is tracked. FK enforced on source. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InstrumentConfiguration | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here; INSERT trigger also writes initial creation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HedgeInstrumentConfiguration (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentConfiguration | Table | Source temporal table; INSERT/UPDATE/DELETE trigger also writes to History.AuditHistory |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_HedgeInstrumentConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [PRIMARY] filegroup) |

### 7.2 Constraints

None on history table. Source table has:
- CLUSTERED PK on InstrumentID
- FK_HedgeInstrumentConfiguration_Instrument: InstrumentID -> Trade.Instrument(InstrumentID)
- DEFAULT constraints: MinOrderSizeForExecutionInEToroUnits=1, HBCDealSizeThresholdAlertInEToroUnits=30000000, HBCMaxDealSizeThresholdRejectInEToroUnits=30000000, SpreadReturnFactor=1, RestrictManualActions=0, LotSizeForView=1

### 7.3 Notes

- Dual audit pattern: SQL Server temporal versioning captures full row state per version; in ADDITION, three triggers (INSERT/UPDATE/DELETE: AuditInsert/AuditUpdate/AuditDelete_Hedge_InstrumentConfiguration) write individual column changes to History.AuditHistory with old/new values and operation type
- The INSERT trigger fires the no-op UPDATE to capture INSERT events in temporal history (same pattern as other Hedge temporal tables)
- Stored on [PRIMARY] rather than a dedicated Hedge filegroup
- `Trade.CheckValidInstruments` procedure provisions default configuration values for new instruments by inserting to Hedge.InstrumentConfiguration with the source table's default values

---

## 8. Sample Queries

### 8.1 Configuration for an instrument on a specific date

```sql
SELECT
    ic.InstrumentID,
    ic.MinOrderSizeForExecutionInEToroUnits,
    ic.HBCDealSizeThresholdAlertInEToroUnits,
    ic.HBCMaxDealSizeThresholdRejectInEToroUnits,
    ic.ManualMaxDealSizeInEToroUnits,
    ic.SpreadReturnFactor,
    ic.CircuitBreakerLimit,
    ic.CircuitBreakerWarningLimit,
    ic.RestrictManualActions,
    ic.LotSizeForView
FROM Hedge.InstrumentConfiguration FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' ic WITH (NOLOCK)
WHERE ic.InstrumentID = @InstrumentID;
```

### 8.2 Change history for an instrument's hedge configuration

```sql
SELECT
    h.InstrumentID,
    h.HBCDealSizeThresholdAlertInEToroUnits,
    h.HBCMaxDealSizeThresholdRejectInEToroUnits,
    h.CircuitBreakerLimit,
    h.CircuitBreakerWarningLimit,
    h.RestrictManualActions,
    h.SpreadReturnFactor,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    h.AppLoginName AS ChangedByApp,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSecs
FROM History.HedgeInstrumentConfiguration h WITH (NOLOCK)
WHERE h.InstrumentID = @InstrumentID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysStartTime;
```

### 8.3 All instruments with circuit breakers configured (current)

```sql
SELECT
    ic.InstrumentID,
    ic.CircuitBreakerWarningLimit,
    ic.CircuitBreakerLimit,
    ic.HBCDealSizeThresholdAlertInEToroUnits,
    ic.HBCMaxDealSizeThresholdRejectInEToroUnits
FROM Hedge.InstrumentConfiguration ic WITH (NOLOCK)
WHERE ic.CircuitBreakerLimit IS NOT NULL
ORDER BY ic.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

Confluence pages found for related HBC (Hedge Book Control) configuration topics:
- "CM - Crypto HBC Configuration" - Confluence page about crypto instrument HBC thresholds (access restricted in this environment)
- "Outliers management and logic - Risk Policy" - Risk policy documentation referencing deal size thresholds

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.9/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 2 Confluence (access restricted) + 0 Jira | Procedures: 1 analyzed (Trade.CheckValidInstruments) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HedgeInstrumentConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.HedgeInstrumentConfiguration.sql*
