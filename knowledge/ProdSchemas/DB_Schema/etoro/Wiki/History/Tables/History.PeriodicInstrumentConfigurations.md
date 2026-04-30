# History.PeriodicInstrumentConfigurations

> SQL Server temporal history table storing prior row versions of Hedge.PeriodicInstrumentConfigurations, preserving the audit trail for changes to periodic price calculation interval settings per instrument.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No (on DICTIONARY filegroup) |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.PeriodicInstrumentConfigurations is the SQL Server system-versioning history table for Hedge.PeriodicInstrumentConfigurations (declared as `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[PeriodicInstrumentConfigurations])`). Whenever a configuration row is updated or deleted, the prior version is automatically written here.

Hedge.PeriodicInstrumentConfigurations defines the periodic price update interval for specific instruments in the hedging engine. Each row maps an instrument (InstrumentID) to the interval in minutes at which the hedging engine recalculates or fetches prices for that instrument. This is used by Hedge.GetPeriodicConfiguration to determine how frequently the hedge process should re-evaluate each instrument's price data. The history table captures every change to these intervals over time.

The same INSERT-capture trigger pattern applies: `TRG_T_PeriodicInstrumentConfigurations` fires on INSERT and performs a self-UPDATE to force the temporal engine to record the INSERT. Table currently has 0 rows in the live environment.

---

## 2. Business Logic

### 2.1 Temporal History Pattern

**What**: This table captures prior versions of Hedge.PeriodicInstrumentConfigurations configuration rows.

**Columns/Parameters Involved**: `InstrumentID`, `PeriodicIntervalMinutes`, `SysStartTime`, `SysEndTime`

**Rules**:
- The composite PK in the source table is (InstrumentID, PeriodicIntervalMinutes) - a single instrument can be configured with multiple interval settings simultaneously.
- SysStartTime=SysEndTime: INSERT-capture record from the trigger.
- DbLoginName/AppLoginName are computed at write time in the source table.

---

## 3. Data Overview

Table is currently empty in the live database - exists for temporal versioning of Hedge.PeriodicInstrumentConfigurations. No live rows to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Trading instrument identifier from the composite key. Part of the (InstrumentID, PeriodicIntervalMinutes) unique configuration identity. Implicit FK to Trade/Dictionary instrument tables. |
| 2 | PeriodicIntervalMinutes | int | NO | - | CODE-BACKED | The interval in minutes between periodic price recalculations for this instrument in the hedging engine. Combined with InstrumentID as the composite key - allows multiple intervals per instrument. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change, computed from SUSER_NAME() in the source table. Captured at write time for audit. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context info at change time, from CONTEXT_INFO(). Identifies which application or service made the configuration change. |
| 5 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration version became active. Set by the SQL Server temporal engine. |
| 6 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration version was superseded. SysStartTime=SysEndTime indicates an INSERT-capture record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source table) | Hedge.PeriodicInstrumentConfigurations | Temporal History | This table is the declared HISTORY_TABLE. |
| InstrumentID | Trade/Dictionary instrument tables | Implicit | The instrument whose periodic interval is configured. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.PeriodicInstrumentConfigurations | HISTORY_TABLE | Temporal system versioning | All row version changes are automatically written here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PeriodicInstrumentConfigurations | Table | Source of all history writes via SQL Server temporal system versioning |
| Hedge.GetPeriodicConfiguration | Stored Procedure | READER of source table - reads current periodic configuration for the hedge engine |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PeriodicInstrumentConfigurations | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. Temporal history tables have no PK or FK constraints.

---

## 8. Sample Queries

### 8.1 View change history for a specific instrument's periodic configuration

```sql
SELECT InstrumentID, PeriodicIntervalMinutes, DbLoginName, SysStartTime, SysEndTime
FROM History.PeriodicInstrumentConfigurations WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY SysStartTime;
```

### 8.2 Compare all current configurations to their historical values

```sql
SELECT c.InstrumentID, c.PeriodicIntervalMinutes AS CurrentInterval,
       COUNT(h.InstrumentID) AS VersionCount
FROM Hedge.PeriodicInstrumentConfigurations c WITH (NOLOCK)
LEFT JOIN History.PeriodicInstrumentConfigurations h WITH (NOLOCK)
    ON h.InstrumentID = c.InstrumentID AND h.PeriodicIntervalMinutes = c.PeriodicIntervalMinutes
GROUP BY c.InstrumentID, c.PeriodicIntervalMinutes
ORDER BY c.InstrumentID;
```

### 8.3 Find all configuration changes in the last 30 days

```sql
SELECT InstrumentID, PeriodicIntervalMinutes, DbLoginName, SysStartTime, SysEndTime
FROM History.PeriodicInstrumentConfigurations WITH (NOLOCK)
WHERE SysStartTime >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PeriodicInstrumentConfigurations | Type: Table | Source: etoro/etoro/History/Tables/History.PeriodicInstrumentConfigurations.sql*
