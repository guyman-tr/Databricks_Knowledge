# Hedge.GetPeriodicConfiguration

> Returns all periodic hedge evaluation schedules (instrument + interval in minutes) so the hedge engine can configure recurring position re-evaluation timers for specific instruments.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all rows from Hedge.PeriodicInstrumentConfigurations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetPeriodicConfiguration` loads the periodic hedge evaluation schedule for all configured instruments. By default the hedge engine is event-driven (triggered by new client positions or executions), but some instruments benefit from periodic re-evaluation at defined intervals - for example, repricing stale limit orders, rebalancing accumulated exposure drift, or checking round-trip hedge costs on a cadence.

This procedure provides the hedge engine with the full list of `(InstrumentID, PeriodicIntervalMinutes)` pairs. The engine uses these pairs to configure internal timers: for each row returned, it sets up a recurring evaluation that fires every `PeriodicIntervalMinutes` minutes for that instrument. One instrument can appear multiple times with different intervals if multiple periodic processes apply.

Data flows as follows: on startup, the hedge engine calls this procedure to discover which instruments have periodic schedules. It creates one timer per row. When a timer fires, the engine runs a targeted exposure re-evaluation for that instrument - equivalent to an event-driven evaluation but without a triggering trade. This is useful for instruments with slow-moving but continuously accumulating exposure that may not generate frequent individual trade events.

**Current state**: The underlying `Hedge.PeriodicInstrumentConfigurations` table is currently empty (0 rows). This procedure returns an empty result set in production. Periodic evaluation is supported by the architecture but not currently active for any instrument.

---

## 2. Business Logic

### 2.1 Full Table Read - Periodic Evaluation Schedule

**What**: Returns every row from Hedge.PeriodicInstrumentConfigurations without filtering. The hedge engine receives the complete set of periodic schedules in one call.

**Columns/Parameters Involved**: `InstrumentID`, `PeriodicIntervalMinutes`

**Rules**:
- No WHERE clause - all rows returned regardless of instrument or interval value
- No ordering specified - caller receives rows in composite PK order (InstrumentID, PeriodicIntervalMinutes)
- One instrument can appear multiple times with different intervals (composite PK allows this)
- An empty result set (current production state) means no periodic evaluation is active
- The hedge engine treats a missing entry as "no periodic schedule" and relies solely on event-driven evaluation

**Diagram**:
```
Hedge engine startup:
  GetPeriodicConfiguration()
       |
       v
  Returns: (currently empty)
  If populated:
    (InstrumentID=1, PeriodicIntervalMinutes=5)   -> timer fires every 5 min for EUR/USD
    (InstrumentID=1, PeriodicIntervalMinutes=60)  -> timer fires every 60 min for EUR/USD
    (InstrumentID=5, PeriodicIntervalMinutes=15)  -> timer fires every 15 min for USD/JPY
       |
       v
  Engine creates timers per row, each triggering targeted hedge evaluation
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters.*

**Output columns** (from Hedge.PeriodicInstrumentConfigurations):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | The instrument to evaluate periodically. Implicit FK to Trade.Instrument. Can appear multiple times if multiple interval schedules apply to the same instrument. |
| 2 | PeriodicIntervalMinutes | int | NO | - | VERIFIED | Recurring evaluation cadence in minutes. The hedge engine creates a timer for this instrument that fires every N minutes. Multiple intervals per instrument are supported via the composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.PeriodicInstrumentConfigurations | SELECT | Full table read; returns all periodic evaluation schedules for all instruments. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to configure recurring instrument evaluation timers. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetPeriodicConfiguration (procedure)
└── Hedge.PeriodicInstrumentConfigurations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PeriodicInstrumentConfigurations | Table | SELECTed in full - source of all periodic evaluation schedules |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - called at startup to set up periodic hedge evaluation timers per instrument |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. The underlying table has a single composite PK index on (InstrumentID, PeriodicIntervalMinutes). With 0 current rows, performance is not a concern. If the table grows to thousands of rows, the full-table scan is still fast as the data is configuration-sized.

### 7.2 Constraints

N/A for Stored Procedure. The table uses SQL Server SYSTEM_VERSIONING (temporal table). This procedure reads only the current (live) rows, not historical versions. The temporal history is stored in History.PeriodicInstrumentConfigurations but is not queried here.

---

## 8. Sample Queries

### 8.1 Load all periodic evaluation schedules
```sql
EXEC [Hedge].[GetPeriodicConfiguration];
```

### 8.2 Direct table query (equivalent)
```sql
SELECT  InstrumentID,
        PeriodicIntervalMinutes
FROM    [Hedge].[PeriodicInstrumentConfigurations] WITH (NOLOCK)
ORDER BY InstrumentID, PeriodicIntervalMinutes;
```

### 8.3 Check historical periodic configurations (temporal table)
```sql
SELECT  InstrumentID,
        PeriodicIntervalMinutes,
        SysStartTime,
        SysEndTime
FROM    [History].[PeriodicInstrumentConfigurations]
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetPeriodicConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetPeriodicConfiguration.sql*
