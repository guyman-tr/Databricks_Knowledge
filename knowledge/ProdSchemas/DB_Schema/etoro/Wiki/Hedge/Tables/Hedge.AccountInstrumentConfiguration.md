# Hedge.AccountInstrumentConfiguration

> Per-account, per-instrument execution configuration table defining limit order price rounding precision and optional execution unit throttling parameters for hedge orders placed through specific accounts.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (AccountID, InstrumentID) - composite PK CLUSTERED |
| **Partition** | No (on [DICTIONARY] filegroup) |
| **Indexes** | 1 (composite PK only) |

---

## 1. Business Meaning

`Hedge.AccountInstrumentConfiguration` stores execution parameters that vary by both account AND instrument - configurations that need to be applied specifically when routing hedge orders for a given instrument through a specific account.

The primary active field is `LimitRoundPrecision`: the number of decimal places to which limit order prices are rounded when submitting to a provider. Different instruments have different tick sizes, and different providers have different price precision requirements. For example, a Forex instrument might require 4 or 5 decimal places, while certain equity instruments need only 1 or 2.

The execution unit throttling columns (`MaxExecutionUnitsThreshold`, `MaxExecutionUnitsLowerBound`, `MaxExecutionUnitsUpperBound`, `ExecutionUnitsStep`, `MaxRequestedPerInterval`, `IntervalPeriodSeconds`) are designed capabilities for rate limiting and order sizing constraints per account/instrument, but are currently NULL across all 147 rows - these features are designed but not yet operationally configured.

Data: 147 rows across 3 AccountIDs (1, 10, 308) and 86 instruments. The consumer `Hedge.GetInstrumentAccountConfiguration` returns all columns to the hedge engine on startup.

---

## 2. Business Logic

### 2.1 Limit Order Price Rounding

**What**: `LimitRoundPrecision` specifies how many decimal places the hedge engine uses when rounding limit order prices for this account/instrument combination.

**Columns/Parameters Involved**: `LimitRoundPrecision`, `AccountID`, `InstrumentID`

**Rules**:
- DEFAULT is -1, indicating no rounding override (use provider/instrument default)
- Actual values in use: 1 (1 decimal place), 2 (2 decimal places), 4 (4 decimal places)
- Higher precision values = more decimal places preserved in limit prices (e.g., 4 for equities with fractional pricing)
- Per-account, per-instrument - the same instrument can have different rounding for different accounts
- smallint type supports negative values (e.g., -1 as sentinel for "no override")

### 2.2 Execution Unit Throttling (Designed, Not Active)

**What**: A set of columns designed to enforce per-account, per-instrument order rate and size limits. Currently all NULL.

**Columns/Parameters Involved**: `MaxExecutionUnitsThreshold`, `MaxExecutionUnitsLowerBound`, `MaxExecutionUnitsUpperBound`, `ExecutionUnitsStep`, `MaxRequestedPerInterval`, `IntervalPeriodSeconds`

**Rules** (design intent):
- `MaxExecutionUnitsThreshold`: maximum single-order execution size (in units) before triggering band-based sizing
- `MaxExecutionUnitsLowerBound`/`UpperBound`: band for desired execution size when threshold is crossed
- `ExecutionUnitsStep`: granularity step for execution unit sizing
- `MaxRequestedPerInterval` + `IntervalPeriodSeconds`: rate limiting - max number of orders allowed within a time window
- All currently NULL = no throttling configured for any account/instrument pair

---

## 3. Data Overview

| AccountID | InstrumentCount | LimitRoundPrecision Values | MaxUnits Configured | Meaning |
|---|---|---|---|---|
| 1 | ~16 | 1, 2, 4 (varies by instrument) | All NULL | Account 1 - instruments with precision overrides only |
| 10 | ~64 | 2, 4 (varies) | All NULL | Account 10 (ZBFX Price2 Execution) - instruments with precision overrides |
| 308 | ~67 | varies | All NULL | Account 308 - instruments with precision overrides |

Total: 147 rows, 3 accounts, 86 instruments. All throttling columns are NULL.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountID | int | NO | - | CODE-BACKED | The hedge account this configuration applies to. Part of composite PK. Implicit reference to Hedge.Accounts.ID (no FK constraint). Values present: 1, 10 (ZBFX Price2), 308. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this configuration applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). InstrumentIDs range into the 1,000,000+ range (OMS/platform instruments). |
| 3 | MaxExecutionUnitsThreshold | int | YES | - | CODE-BACKED | Maximum single hedge order size (in execution units) before band-based sizing logic applies. Currently NULL for all rows - feature designed but not active. |
| 4 | MaxExecutionUnitsUpperBound | int | YES | - | CODE-BACKED | Upper bound of the desired execution size band when MaxExecutionUnitsThreshold is exceeded. Currently NULL. |
| 5 | MaxExecutionUnitsLowerBound | int | YES | - | CODE-BACKED | Lower bound of the desired execution size band when MaxExecutionUnitsThreshold is exceeded. Currently NULL. |
| 6 | ExecutionUnitsStep | int | YES | - | CODE-BACKED | Step granularity for execution unit sizing increments. Currently NULL. |
| 7 | MaxRequestedPerInterval | int | YES | - | CODE-BACKED | Rate limit: maximum number of orders allowed within IntervalPeriodSeconds. Currently NULL for all rows - rate limiting not active. |
| 8 | IntervalPeriodSeconds | int | YES | - | CODE-BACKED | Time window in seconds for the MaxRequestedPerInterval rate limit. Currently NULL. |
| 9 | LimitRoundPrecision | smallint | NO | -1 | VERIFIED | Number of decimal places for limit order price rounding for this account/instrument pair. -1=no override (use default). Active values: 1, 2, 4. Determines tick-size compliance for limit orders submitted to providers. |
| 10 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 11 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.AccountInstrumentConfiguration. |
| 12 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 13 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. AccountID and InstrumentID are application-managed without explicit FK enforcement.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetInstrumentAccountConfiguration | (table ref) | READER | SELECTs all columns; returns full configuration to hedge engine on startup |
| History.AccountInstrumentConfiguration | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AccountInstrumentConfiguration (table)
  (no FK dependencies - leaf table)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetInstrumentAccountConfiguration | Stored Procedure | READER - full configuration load for hedge engine |
| History.AccountInstrumentConfiguration | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountInstrumentConfiguration | CLUSTERED PK | AccountID ASC, InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AccountInstrumentConfiguration | PRIMARY KEY | (AccountID, InstrumentID) - one config per account/instrument pair |
| DEFAULT LimitRoundPrecision | DEFAULT | LimitRoundPrecision = -1 (no rounding override) |
| DEFAULT SysStartTime | DEFAULT | SysStartTime = getutcdate() |
| DEFAULT SysEndTime | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.AccountInstrumentConfiguration |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| Tr_T_AccountInstrumentConfiguration_INSERT | INSERT | No-op self-UPDATE to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all active precision configurations

```sql
SELECT
    aic.AccountID,
    aic.InstrumentID,
    aic.LimitRoundPrecision,
    aic.MaxRequestedPerInterval,
    aic.IntervalPeriodSeconds
FROM Hedge.AccountInstrumentConfiguration aic WITH (NOLOCK)
WHERE aic.LimitRoundPrecision != -1  -- Only rows with precision overrides
ORDER BY aic.AccountID, aic.LimitRoundPrecision
```

### 8.2 Find instruments with different precision across accounts

```sql
SELECT
    InstrumentID,
    COUNT(DISTINCT LimitRoundPrecision) AS PrecisionVariants,
    STRING_AGG(CAST(AccountID AS VARCHAR) + ':' + CAST(LimitRoundPrecision AS VARCHAR), ', ')
        WITHIN GROUP (ORDER BY AccountID) AS AccountPrecisions
FROM Hedge.AccountInstrumentConfiguration WITH (NOLOCK)
GROUP BY InstrumentID
HAVING COUNT(DISTINCT LimitRoundPrecision) > 1
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.AccountInstrumentConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.AccountInstrumentConfiguration.sql*
