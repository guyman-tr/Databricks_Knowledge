# History.HistoryCEPRuleToPosition

> SQL Server temporal history table auto-populated by system versioning on History.CEPRuleToPosition_Archive, storing prior row versions when int-era CEP rule-to-position assignments are updated or deleted.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.HistoryCEPRuleToPosition is the SQL Server system-versioning history table for History.CEPRuleToPosition_Archive. It is declared as `HISTORY_TABLE = History.HistoryCEPRuleToPosition` in the CEPRuleToPosition_Archive DDL. When SQL Server temporal versioning closes a row version in the Archive table (i.e., an UPDATE or DELETE occurs on a row in CEPRuleToPosition_Archive), the old row values are automatically written here with the SysStartTime and SysEndTime stamped to capture the precise validity window.

This table is never written by application code directly - it is exclusively managed by SQL Server's temporal versioning engine. It exists to preserve the audit trail for CEP rule-to-position assignments: if a row in CEPRuleToPosition_Archive is ever modified or removed, the previous state is retrievable via `FOR SYSTEM_TIME AS OF` queries or by directly reading this history table.

Currently the table holds 0 rows because all rows in CEPRuleToPosition_Archive were bulk-loaded on 2021-09-13 and have never been updated or deleted since. The Archive's rows all have SysEndTime = '9999-12-31', meaning no temporal version cuts have occurred. If Archive rows are ever modified, versions will flow into this table automatically.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server automatically moves superseded row versions from History.CEPRuleToPosition_Archive into this table when rows in the Archive are updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- When a row in CEPRuleToPosition_Archive is updated: the old version is written here with the original SysStartTime and the current timestamp as SysEndTime
- When a row in CEPRuleToPosition_Archive is deleted: the deleted version is written here with SysEndTime = deletion timestamp
- Rows here are immutable once written - SQL Server never modifies history table rows
- The CLUSTERED INDEX on (SysEndTime ASC, SysStartTime ASC) is the standard SQL Server temporal history table index, optimizing FOR SYSTEM_TIME AS OF range scans

**Diagram**:
```
CEPRuleToPosition_Archive (live table)
  SysStartTime = row creation time
  SysEndTime   = 9999-12-31 (currently active)
          |
          | ON UPDATE or DELETE
          v
HistoryCEPRuleToPosition (history table)
  SysStartTime = original creation time
  SysEndTime   = timestamp of change (closed version)
```

### 2.2 Computed Columns Materialized in History

**What**: The Archive table has DbLoginName and AppLoginName as computed (non-persisted) columns. In the temporal history table, these are stored as regular nullable columns with the materialized snapshot values.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- SQL Server evaluates computed columns at the time the row version is closed and stores the resulting values in the history table
- DbLoginName captures the SQL login that last modified the row before the version was closed
- AppLoginName captures the application-layer context_info() set before the last write
- Both are NULL-able in the history table because computed column evaluation may yield NULL

---

## 3. Data Overview

No rows exist in this table (0 rows as of 2026-03-19). History.CEPRuleToPosition_Archive was bulk-loaded in 2021 and has never been updated or deleted - no temporal versions have been cut. Sample data will only appear after Archive rows are modified.

| PositionID | RuleID | HedgeServerID | Ocurred | SysStartTime | SysEndTime | Meaning |
|-----------|--------|--------------|---------|-------------|-----------|---------|
| (no rows) | - | - | - | - | - | Table is empty - no temporal versions generated from CEPRuleToPosition_Archive yet |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | int | NO | - | VERIFIED | Trade position ID (int era, values ~1-200M). FK to the closed version of the row in History.CEPRuleToPosition_Archive. Implicit FK to Trade.PositionTbl int-era positions. Inherited from Archive: see History.CEPRuleToPosition_Archive.PositionID. |
| 2 | RuleID | int | NO | - | VERIFIED | ID of the CEP rule that was applied to the position. Inherited from Archive: all Archive rows have RuleID=-1 (sentinel = no CEP rule matched at assignment time). FK to CEP.Rules. Inherited from History.CEPRuleToPosition_Archive.RuleID. |
| 3 | HedgeServerID | int | NO | - | VERIFIED | ID of the hedge server that processed the rule event. Observed in Archive: values 1 and 8. Implicit FK to History.HedgeServer. Inherited from History.CEPRuleToPosition_Archive.HedgeServerID. |
| 4 | Ocurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the CEP rule was applied to the position. Note: column name has a typo ("Ocurred" not "Occurred") - consistent across all CEP tables in this schema. Inherited from History.CEPRuleToPosition_Archive.Ocurred. |
| 5 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Materialized snapshot of the SQL Server login name (suser_name()) at the time the row version was closed. In the Archive table this is a computed column; here it is stored as the evaluated value captured by temporal versioning. NULL if not available at version close time. |
| 6 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Materialized snapshot of the application-layer login (context_info()) at the time the row version was closed. In the Archive table this is a computed column; here it is stored as the evaluated value. NULL if context_info was not set before the last write. |
| 7 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of the validity window for this historical row version. Set by SQL Server temporal engine to the SysStartTime value from the Archive row at the moment the version was closed. Used by FOR SYSTEM_TIME AS OF queries to determine which version was active at a given point in time. |
| 8 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of the validity window for this historical row version. Set by SQL Server temporal engine to the timestamp when the Archive row was updated or deleted, closing this version. The CLUSTERED INDEX is ordered by (SysEndTime, SysStartTime) to optimize temporal range scans. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl (int-era) | Implicit | The trade position whose CEP rule assignment version is stored here. Int PositionIDs (~1-200M). |
| RuleID | CEP.Rules | Implicit | The CEP rule referenced in the closed Archive row. |
| HedgeServerID | History.HedgeServer | Implicit | The hedge server that processed the CEP rule event. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CEPRuleToPosition_Archive | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | SQL Server temporal engine writes all closed row versions from the Archive into this table automatically. This table is declared as the HISTORY_TABLE for CEPRuleToPosition_Archive. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HistoryCEPRuleToPosition (table)
  - leaf node: no code-level dependencies (auto-managed by SQL Server temporal engine)
```

### 6.1 Objects This Depends On

No dependencies. This table is created with no foreign keys, computed columns, or UDT references. It is managed entirely by SQL Server temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CEPRuleToPosition_Archive | Table | Declares this as its HISTORY_TABLE via SYSTEM_VERSIONING. All temporal version rows flow into this table. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_HistoryCEPRuleToPosition | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage option | Page-level compression applied to all data and index pages. Matches the Archive table compression setting. |

---

## 8. Sample Queries

### 8.1 Read all temporal versions for a specific position (Archive + History)
```sql
SELECT PositionID, RuleID, HedgeServerID, Ocurred, SysStartTime, SysEndTime, 'Archive' AS Source
FROM History.CEPRuleToPosition_Archive WITH (NOLOCK)
WHERE PositionID = 119770983
UNION ALL
SELECT PositionID, RuleID, HedgeServerID, Ocurred, SysStartTime, SysEndTime, 'History' AS Source
FROM History.HistoryCEPRuleToPosition WITH (NOLOCK)
WHERE PositionID = 119770983
ORDER BY SysStartTime;
```

### 8.2 Check whether any temporal history versions have been generated
```sql
SELECT COUNT(*) AS HistoryRowCount,
       MIN(SysEndTime) AS EarliestVersionClosed,
       MAX(SysEndTime) AS LatestVersionClosed
FROM History.HistoryCEPRuleToPosition WITH (NOLOCK);
```

### 8.3 Use FOR SYSTEM_TIME AS OF to query Archive at a historical point in time
```sql
-- Reads from Archive + HistoryCEPRuleToPosition automatically
SELECT PositionID, RuleID, HedgeServerID, Ocurred, SysStartTime, SysEndTime
FROM History.CEPRuleToPosition_Archive WITH (NOLOCK)
FOR SYSTEM_TIME AS OF '2022-01-01 00:00:00'
ORDER BY Ocurred DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CEP Schema](https://etoro-jira.atlassian.net/wiki/spaces/MT/pages/1973846017/CEP+Schema) | Confluence | CEP (Complex Event Processing) schema architecture context, confirmed CEP rule assignment table design and purpose. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HistoryCEPRuleToPosition | Type: Table | Source: etoro/etoro/History/Tables/History.HistoryCEPRuleToPosition.sql*
