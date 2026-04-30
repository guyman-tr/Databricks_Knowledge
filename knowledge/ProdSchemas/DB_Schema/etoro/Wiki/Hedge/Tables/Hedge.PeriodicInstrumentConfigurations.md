# Hedge.PeriodicInstrumentConfigurations

> Configuration table assigning periodic hedge execution intervals (in minutes) to instruments, enabling the hedge engine to schedule recurring evaluation of specific instruments at defined cadences.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, PeriodicIntervalMinutes) - composite PK CLUSTERED |
| **Partition** | No (on [DICTIONARY] filegroup, FILLFACTOR=95) |
| **Indexes** | 1 (composite PK only) |

---

## 1. Business Meaning

`Hedge.PeriodicInstrumentConfigurations` controls which instruments are subject to periodic hedge evaluation and at what frequency. Rather than reacting only to new client orders, the hedge engine can also periodically re-evaluate its hedge positions for specific instruments - checking exposure drift, repricing limits, or triggering rebalancing at scheduled intervals.

The composite PK `(InstrumentID, PeriodicIntervalMinutes)` allows one instrument to appear on multiple periodic schedules simultaneously - for example, a single instrument could be evaluated every 5 minutes for one process and every 60 minutes for another.

The single consumer is `Hedge.GetPeriodicConfiguration`, which returns all `(InstrumentID, PeriodicIntervalMinutes)` pairs to the hedge engine for scheduling.

**Current state**: Both the current table and history table are empty. Periodic hedge evaluation has either never been configured in this environment or all assignments were removed.

---

## 2. Business Logic

### 2.1 Periodic Evaluation Scheduling

**What**: Assigns one or more time intervals (in minutes) to instruments for recurring hedge evaluation.

**Columns/Parameters Involved**: `InstrumentID`, `PeriodicIntervalMinutes`

**Rules**:
- One row = one periodic evaluation schedule for one instrument
- An instrument can have multiple rows with different intervals (composite PK allows this)
- `PeriodicIntervalMinutes` defines the recurring cadence in minutes (e.g., 5 = every 5 minutes)
- No FK constraint on InstrumentID - application-managed reference to Trade.Instrument
- No FK on PeriodicIntervalMinutes - arbitrary integer values chosen by operators
- Table is currently empty (0 rows in current and history)

---

## 3. Data Overview

| InstrumentID | PeriodicIntervalMinutes | Meaning |
|---|---|---|
| (no rows) | (no rows) | Table is currently empty - no instruments have periodic evaluation configured |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The instrument to evaluate periodically. Part of the composite PK. No FK constraint - implicit reference to Trade.Instrument. An instrument can appear multiple times with different intervals. |
| 2 | PeriodicIntervalMinutes | int | NO | - | VERIFIED | The recurring evaluation interval in minutes. Part of the composite PK. An instrument can have multiple interval rows (e.g., 5 min and 60 min for different processes). |
| 3 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 4 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 6 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.PeriodicInstrumentConfigurations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. InstrumentID implicitly references Trade.Instrument but is not enforced in DDL.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetPeriodicConfiguration | (table ref) | READER | SELECTs InstrumentID + PeriodicIntervalMinutes; returns all periodic schedules to the hedge engine |
| History.PeriodicInstrumentConfigurations | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.PeriodicInstrumentConfigurations (table)
  (no FK dependencies - leaf table)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetPeriodicConfiguration | Stored Procedure | READER - returns periodic evaluation schedules to hedge engine |
| History.PeriodicInstrumentConfigurations | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_PeriodicInsturmentConfig | CLUSTERED PK | InstrumentID ASC, PeriodicIntervalMinutes ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_PeriodicInsturmentConfig | PRIMARY KEY | (InstrumentID, PeriodicIntervalMinutes) - one row per instrument/interval pair |
| DF_PeriodicInstrumentConfigurations_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_PeriodicInstrumentConfigurations_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.PeriodicInstrumentConfigurations |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| TRG_T_PeriodicInstrumentConfigurations | INSERT | No-op self-UPDATE to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all periodic evaluation schedules

```sql
SELECT
    pic.InstrumentID,
    pic.PeriodicIntervalMinutes
FROM Hedge.PeriodicInstrumentConfigurations pic WITH (NOLOCK)
ORDER BY pic.PeriodicIntervalMinutes, pic.InstrumentID
```

### 8.2 Find instruments with multiple periodic intervals

```sql
SELECT
    pic.InstrumentID,
    COUNT(*) AS IntervalCount,
    STRING_AGG(CAST(pic.PeriodicIntervalMinutes AS VARCHAR), ', ')
        WITHIN GROUP (ORDER BY pic.PeriodicIntervalMinutes) AS Intervals
FROM Hedge.PeriodicInstrumentConfigurations pic WITH (NOLOCK)
GROUP BY pic.InstrumentID
HAVING COUNT(*) > 1
ORDER BY pic.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 9.0/10, Logic: 7.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.PeriodicInstrumentConfigurations | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.PeriodicInstrumentConfigurations.sql*
