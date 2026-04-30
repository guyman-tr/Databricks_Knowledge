# History.InstrumentGroups

> SQL Server temporal history table storing prior row versions of Hedge.InstrumentGroups, preserving the audit trail for changes to instrument group definitions used in hedging strategy configuration.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.InstrumentGroups is the SQL Server system-versioning history table for Hedge.InstrumentGroups, declared as `HISTORY_TABLE = [History].[InstrumentGroups]` in the Hedge.InstrumentGroups DDL. Whenever a row in Hedge.InstrumentGroups is updated or deleted, the prior version is automatically written here by the SQL Server temporal engine.

Hedge.InstrumentGroups is a lookup/reference table that defines named groups of financial instruments used within the hedging system. Instrument groups allow the hedge engine to apply configuration, exposure rules, and strategies to sets of related instruments rather than managing each one individually. Each group has a unique GroupID, a human-readable GroupName, and an optional Description.

Unlike most other temporal tables in this batch, Hedge.InstrumentGroups has NO insert trigger - there is no TRG_T_InstrumentGroups INSERT trigger that forces an immediate history record. This means history rows are only generated on genuine UPDATE or DELETE operations. The table currently has 0 history rows, indicating the group definitions have been stable (no updates or deletions since temporal versioning was enabled on this table).

Both the live table (Hedge.InstrumentGroups) and this history table reside on the [MAIN] filegroup, which is the primary storage filegroup for the Hedge schema data.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server writes superseded row versions from Hedge.InstrumentGroups into this table on each UPDATE or DELETE.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `GroupID`, `GroupName`

**Rules**:
- Unlike other temporal tables in the History schema, Hedge.InstrumentGroups has NO insert trigger - history rows are generated only by genuine UPDATEs or DELETEs
- A history row captures: which GroupID had which GroupName and Description, and exactly when that configuration was valid (SysStartTime to SysEndTime)
- The CLUSTERED INDEX on (SysEndTime, SysStartTime) optimizes FOR SYSTEM_TIME AS OF queries
- 0 rows currently indicates all current groups have been in place since temporal versioning was activated - no group renames or deletions have occurred

### 2.2 Computed Columns Materialized in History

**What**: Hedge.InstrumentGroups has DbLoginName and AppLoginName as computed (non-persisted) columns. This history table stores their evaluated values at each version close.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- DbLoginName: suser_name() at the time the group row was updated/deleted
- AppLoginName: context_info() - context of the writing application, typically NULL for direct SQL configuration changes

---

## 3. Data Overview

0 rows. No temporal versions have been generated - Hedge.InstrumentGroups definitions have not been updated or deleted since temporal versioning was enabled.

| GroupID | GroupName | Description | SysStartTime | SysEndTime | Meaning |
|--------|----------|------------|-------------|-----------|---------|
| (no rows) | - | - | - | - | All current instrument group definitions remain unchanged since versioning was activated. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int | NO | - | VERIFIED | Auto-increment primary key of the instrument group in Hedge.InstrumentGroups. PK of the source table. Multiple history rows for the same GroupID would appear if the group's name or description was changed. |
| 2 | GroupName | varchar(124) | NO | - | VERIFIED | Human-readable name for the instrument group as it existed during this version's validity window. Used by hedging configuration and reporting to reference the group by name. |
| 3 | Description | varchar(256) | YES | - | CODE-BACKED | Optional description of the instrument group's purpose or membership criteria. NULL when no description was set. Captured at version close time. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Materialized snapshot of suser_name() at the time this group version was superseded. Identifies who renamed or deleted the group. Computed in source; stored here. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Materialized snapshot of context_info() at version close time. Typically NULL for direct SQL configuration changes. Computed in source; stored here. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of the validity window for this group name/description version. Set by SQL Server temporal engine. No insert trigger on source table - no SysStart=SysEnd artifacts expected here. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of the validity window. Set by SQL Server temporal engine to the timestamp of the UPDATE or DELETE that superseded this group definition. CLUSTERED INDEX ordered (SysEndTime, SysStartTime) for temporal scan performance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It stores historical snapshots of group definitions with no foreign keys.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InstrumentGroups | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | All UPDATE/DELETE versions from Hedge.InstrumentGroups are written here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InstrumentGroups (table)
  - leaf node: no code-level dependencies (auto-managed by SQL Server temporal engine)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentGroups | Table | Declares this as its HISTORY_TABLE via SYSTEM_VERSIONING. |
| History.InstrumentGroupsMapping | Table | Depends on this table's source (Hedge.InstrumentGroups) for the GroupID FK - mapping of instruments to groups. See History.InstrumentGroupsMapping. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentGroups | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage option | Page-level compression on all data and index pages. |
| Filegroup [MAIN] | Storage option | Both source and history table use the [MAIN] filegroup (Hedge schema primary storage). |

---

## 8. Sample Queries

### 8.1 Check if any instrument groups have changed names since temporal versioning was enabled
```sql
SELECT GroupID, GroupName, Description, SysStartTime, SysEndTime, DbLoginName
FROM History.InstrumentGroups WITH (NOLOCK)
ORDER BY GroupID, SysStartTime;
```

### 8.2 Use FOR SYSTEM_TIME ALL to see all versions including live rows
```sql
SELECT GroupID, GroupName, Description, SysStartTime, SysEndTime
FROM Hedge.InstrumentGroups WITH (NOLOCK)
FOR SYSTEM_TIME ALL
ORDER BY GroupID, SysStartTime;
```

### 8.3 Find what name a specific group had at a point in time
```sql
-- Shows the group's name as it was on a historical date
SELECT GroupID, GroupName, Description, SysStartTime, SysEndTime
FROM Hedge.InstrumentGroups WITH (NOLOCK)
FOR SYSTEM_TIME AS OF '2023-01-01 00:00:00'
WHERE GroupID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentGroups | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentGroups.sql*
