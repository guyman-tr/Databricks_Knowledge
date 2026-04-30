# History.SevisionCriticalInstruments

> System-versioned temporal history table for Trade.SevisionCriticalInstruments, recording all past states of the list of instruments designated as critical for Sevision monitoring.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (SysEndTime, SysStartTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `Trade.SevisionCriticalInstruments` (source declares `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[SevisionCriticalInstruments])`). SQL Server automatically archives superseded rows here when instruments are added to or removed from the critical list.

`Trade.SevisionCriticalInstruments` is a simple registry of instruments flagged as **critical for Sevision monitoring**. Sevision is eToro's monitoring and alerting pipeline (accessible to SplunkUser). `Monitor.GetSevisionCriticalInstruments` reads this list to expose the currently critical instruments to the monitoring system. Only instruments in this list receive Sevision-level monitoring attention.

The history table is currently empty (0 rows), indicating no instrument additions or removals have occurred since the current state was established. The live source table has 1 active entry (InstrumentID=7, added January 4, 2023).

---

## 2. Business Logic

### 2.1 Critical Instrument Registry

**What**: Defines which instruments receive elevated monitoring via Sevision.

**Columns/Parameters Involved**: `InstrumentID`, `UserName`

**Rules**:
- Each row in the source represents one instrument designated as critical for Sevision monitoring
- `Monitor.GetSevisionCriticalInstruments` returns `SELECT InstrumentID FROM Trade.SevisionCriticalInstruments` - the full current list
- `UserName` = `suser_name()` computed column - records who last modified the entry (the SQL Server login at time of change)
- Temporal history (-> this table) tracks every addition or removal of instruments from the critical list

---

## 3. Data Overview

History table: 0 rows. No changes recorded since the current list was established.

Current state of source table:
| InstrumentID | UserName | SysStartTime | SysEndTime |
|---|---|---|---|
| 7 | McpUserRO | 2023-01-04 12:23:45 | 9999-12-31 (active) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The instrument designated as critical for Sevision monitoring. PK in the source table. Implicit FK to Trade.Instrument. Only one entry currently: InstrumentID=7 (active since 2023-01-04). Each row in history represents a past state of this instrument's presence in the critical list. |
| 2 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC instant when this instrument became (or re-became) part of the critical list. Automatically managed by SQL Server temporal system versioning. |
| 3 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC instant when this instrument was removed from the critical list (or the state was superseded). Automatically set by SQL Server. Leading key of the clustered index. |
| 4 | UserName | nvarchar(128) | YES | - | CODE-BACKED | Computed in source as `suser_name()` - the SQL Server login that modified this entry. Stored as a plain value in history. Provides accountability for critical instrument list changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.SevisionCriticalInstruments | Temporal History | Each row is a past state of the critical instrument entry; InstrumentID identifies which instrument. |
| InstrumentID | Trade.Instrument | Implicit FK | The instrument being monitored; no formal FK defined in DDL. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SevisionCriticalInstruments | HISTORY_TABLE | Temporal History | Active source table; SQL Server archives expired rows here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SevisionCriticalInstruments (table)
  (temporal history - no code-level dependencies; populated by SQL Server from Trade.SevisionCriticalInstruments)
```

---

### 6.1 Objects This Depends On

No dependencies. Temporal history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SevisionCriticalInstruments | Table | Active source table; expired rows archived here by SQL Server. |

Note: `Monitor.GetSevisionCriticalInstruments` reads the live source table to expose the critical instrument list to Sevision/Splunk monitoring.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_SevisionCriticalInstruments | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE on both table and clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression for archival data. |

---

## 8. Sample Queries

### 8.1 View all past critical instrument list changes
```sql
SELECT
    InstrumentID,
    UserName,
    SysStartTime AS AddedToList,
    SysEndTime AS RemovedFromList
FROM [History].[SevisionCriticalInstruments] WITH (NOLOCK)
ORDER BY SysEndTime DESC
```

### 8.2 Get current critical instruments list
```sql
SELECT InstrumentID, UserName, SysStartTime AS AddedAt
FROM [Trade].[SevisionCriticalInstruments] WITH (NOLOCK)
ORDER BY InstrumentID
```

### 8.3 Point-in-time critical instrument list
```sql
SELECT InstrumentID, UserName
FROM [Trade].[SevisionCriticalInstruments]
FOR SYSTEM_TIME AS OF @PointInTime
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SevisionCriticalInstruments | Type: Table | Source: etoro/etoro/History/Tables/History.SevisionCriticalInstruments.sql*
