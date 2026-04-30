# History.InstrumentGroupsMapping

> SQL Server temporal history table storing prior row versions of Hedge.InstrumentGroupsMapping, capturing the history of which financial instruments were assigned to which hedge instrument groups and whether those assignments were active.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.InstrumentGroupsMapping is the SQL Server system-versioning history table for Hedge.InstrumentGroupsMapping. It is declared as `HISTORY_TABLE = [History].[InstrumentGroupsMapping]` in the Hedge.InstrumentGroupsMapping DDL. Whenever a row in Hedge.InstrumentGroupsMapping is updated or deleted, the prior version is automatically written here.

Hedge.InstrumentGroupsMapping assigns individual financial instruments to hedge strategy instrument groups (defined in Hedge.InstrumentGroups). Each row represents one instrument-group assignment and tracks whether that assignment is currently active. The history table preserves the full timeline of every assignment: when instruments were added to groups, when they were deactivated within groups, and when group memberships were reorganized.

Unlike most other temporal history tables in this batch, Hedge.InstrumentGroupsMapping has NO INSERT trigger - history rows are generated only on genuine UPDATE or DELETE operations on the active table. This means there are no zero-duration INSERT artifact rows here; every row represents a genuine state change. The table currently holds 255 rows, reflecting instrument group reorganizations over time.

Data evidence shows a bulk migration event: multiple instruments had simultaneous version cuts on 2026-02-12 11:54:48, suggesting a mass group reassignment operation at that time.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server writes superseded row versions from Hedge.InstrumentGroupsMapping into this table on every UPDATE or DELETE.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `InstrumentID`, `GroupID`, `IsActive`

**Rules**:
- Unlike other temporal tables in this schema, Hedge.InstrumentGroupsMapping has NO insert trigger - only genuine UPDATEs and DELETEs produce history rows
- All history rows represent genuine state changes (IsActive flag changes, group reassignments, or removals)
- The CLUSTERED INDEX on (SysEndTime, SysStartTime) optimizes FOR SYSTEM_TIME AS OF queries

### 2.2 Group Assignment Lifecycle

**What**: An instrument can be assigned to multiple groups simultaneously. The IsActive flag controls whether an assignment is currently used by the hedge engine.

**Columns/Parameters Involved**: `InstrumentID`, `GroupID`, `IsActive`

**Rules**:
- PK of active table is (InstrumentID, GroupID) - one row per instrument-group pair
- IsActive=1: assignment is active; hedge engine applies this group's strategy to this instrument
- IsActive=0: assignment exists but is inactive - the instrument is in the group record but not being hedged by it
- An instrument can appear in multiple groups at once (different GroupIDs)
- Evidence from data: instrument 1048319 had both GroupID=101 (IsActive=false) and GroupID=201 (IsActive=true) closed at the same time (2026-02-12) - simultaneous group reassignment

### 2.3 Mass Reorganization Events

**What**: Bulk group reassignments produce many simultaneous history rows with matching SysEndTime timestamps.

**Rules**:
- When a large-scale group reorganization occurs (e.g., batch reassignment of all instruments in a category), all affected rows get the same SysEndTime
- Evidence: 2026-02-12 11:54:48 appears as the SysEndTime for many rows - a mass reassignment occurred at this timestamp
- The prior state of all these assignments is preserved in this history table for auditing

---

## 3. Data Overview

255 rows total. Sample history versions (most recently closed assignments):

| InstrumentID | GroupID | IsActive | SysStartTime | SysEndTime | Meaning |
|-------------|---------|---------|-------------|------------|---------|
| 1048319 | 201 | true | 2025-11-20 | 2026-02-12 | Instrument 1048319 was actively assigned to group 201 from Nov 2025 until the mass reorganization on Feb 12 2026 |
| 1048319 | 101 | false | 2025-11-20 | 2026-02-12 | Same instrument had an inactive assignment in group 101 - both assignments closed simultaneously during bulk reorganization |
| 1048303 | 201 | true | 2025-11-20 | 2026-02-12 | Another instrument reassigned in the same batch event |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Financial instrument ID. Identifies which instrument's group assignment this historical version represents. Implicit FK to Trade.Instrument. PK component of the active table. |
| 2 | GroupID | int | NO | - | VERIFIED | Hedge instrument group ID. Identifies which hedge strategy group this instrument was assigned to at this version. FK to Hedge.InstrumentGroups in active table. PK component of the active table. See History.InstrumentGroups for group definitions. |
| 3 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | Materialized SQL Server login name (suser_name()) at the time this row version was closed. In active table this is computed; stored here as snapshot. Identifies which DB login made the group assignment change. |
| 4 | AppLoginName | varchar(500) | YES | - | VERIFIED | Materialized application identity (context_info()) at version close time. Stored here as a snapshot. NULL if not set by the writing application. |
| 5 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of the validity window for this history row. Set by SQL Server temporal engine. Since there is no INSERT trigger, all rows represent genuine state changes - SysStartTime is always strictly less than SysEndTime. |
| 6 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of the validity window for this history row. Set to the UTC time of the UPDATE/DELETE that closed this version. Matching SysEndTime values across multiple rows indicate a bulk group reorganization event. |
| 7 | IsActive | bit | NO | - | VERIFIED | Whether this instrument-group assignment was active at this version: 1=active (hedge engine applying this group's strategy), 0=inactive (assignment paused or being transitioned). DEFAULT 1 in active table. History captures both activations and deactivations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The financial instrument whose group assignment history is captured. |
| GroupID | Hedge.InstrumentGroups | Implicit | The hedge strategy group. FK mirrors active table's FK_InstrumentGroupsMapping_GroupID. See History.InstrumentGroups for the history of group definitions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InstrumentGroupsMapping | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | Declares this as its HISTORY_TABLE. All closed row versions flow here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InstrumentGroupsMapping (table)
  - leaf node: no code-level dependencies
  - auto-populated by SQL Server from: Hedge.InstrumentGroupsMapping (temporal parent)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentGroupsMapping | Table | Declares this as its HISTORY_TABLE for SYSTEM_VERSIONING. All temporal version rows flow here. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentGroupsMapping | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

DATA_COMPRESSION=PAGE on [MAIN] filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION=PAGE | Storage option | Page-level compression applied to all data and index pages. |

No explicit FKs or check constraints. Integrity maintained through SYSTEM_VERSIONING contract.

---

## 8. Sample Queries

### 8.1 View all group assignment history for a specific instrument
```sql
SELECT InstrumentID, GroupID, IsActive, SysStartTime, SysEndTime
FROM History.InstrumentGroupsMapping WITH (NOLOCK)
WHERE InstrumentID = 1048319
ORDER BY SysStartTime;
```

### 8.2 Use FOR SYSTEM_TIME ALL to see all versions via the active table
```sql
SELECT InstrumentID, GroupID, IsActive, SysStartTime, SysEndTime
FROM Hedge.InstrumentGroupsMapping WITH (NOLOCK)
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1048319
ORDER BY SysStartTime;
```

### 8.3 Find all instruments affected by the Feb 12 2026 mass reorganization
```sql
SELECT InstrumentID, GroupID, IsActive, SysStartTime, SysEndTime
FROM History.InstrumentGroupsMapping WITH (NOLOCK)
WHERE SysEndTime >= '2026-02-12 11:54:40'
  AND SysEndTime <= '2026-02-12 11:55:00'
ORDER BY InstrumentID, GroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no INSERT trigger) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentGroupsMapping | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentGroupsMapping.sql*
