# History.CompoundProperties

> SQL Server temporal history table for CEP.CompoundProperties - automatically captures superseded compound property definitions whenever a property is updated or deleted.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime ASC, SysStartTime ASC) - clustered index (temporal history pattern) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEnd/SysStart) |

---

## 1. Business Meaning

History.CompoundProperties is the SQL Server temporal versioning history table for CEP.CompoundProperties. It automatically captures the previous state of any compound property definition whenever it is modified (UPDATE) or deleted (DELETE) in the live CEP.CompoundProperties table.

CEP.CompoundProperties defines named compound properties used in the Complex Event Processing (CEP) rules engine. A compound property aggregates multiple individual conditions into a reusable named concept (e.g., "IsHighValueCustomer" = combine AUM threshold + activity level + account age). These compound properties are then referenced by CEP rules.

9,505 rows - tracking the full change history of compound property definitions.

Note: CEP.CompoundProperties also has trigger-based logging to History.CEP_LOG_CompoundProperties (a SEPARATE table) via triggers CEPCompoundPropertiesDelete and CEPCompoundPropertiesUpdate. Both mechanisms run in parallel.

---

## 2. Business Logic

### 2.1 Temporal Versioning

**What**: SQL Server SYSTEM_VERSIONING automatically writes superseded rows here.

**Rules**:
- CEP.CompoundProperties has `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[CompoundProperties])`
- On UPDATE: the old row is moved here, SysEndTime = update time
- On DELETE: the row is moved here, SysEndTime = delete time
- SysStartTime/SysEndTime = the validity period of that row version in the live table
- No manual writes - managed entirely by SQL Server temporal mechanism

### 2.2 Parallel Audit Mechanism

CEP.CompoundProperties has two history mechanisms:
1. **Temporal (this table)**: automatic, captures all changes with SysStart/SysEnd window
2. **Trigger-based**: History.CEP_LOG_CompoundProperties receives explicit INSERT on DELETE/UPDATE from triggers, storing simpler change records

---

## 3. Data Overview

9,505 historical row versions. Tracks all modifications to compound property definitions over time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CompoundPropertyID | int | NO | - | VERIFIED | ID of the compound property. Matches CEP.CompoundProperties.CompoundPropertyID (IDENTITY in live table). |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Name of the compound property definition at this version. |
| 3 | ValidFrom | datetime | YES | - | VERIFIED | Application-level timestamp when this property version became valid. Updated by trigger on each change. |
| 4 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login that made the change. Not a computed column here (stored as nvarchar in history). |
| 5 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application login from context_info() at change time. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Temporal row start: when this version became current in CEP.CompoundProperties. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | Temporal row end: when this version was superseded. Clustered index lead column. |
| 8 | HostName | nvarchar(128) | YES | - | VERIFIED | Server hostname at change time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CompoundPropertyID | CEP.CompoundProperties | Temporal (system) | History of the live table. Managed by SQL Server. |

### 5.2 Referenced By (other objects point to this)

Temporal history tables are not typically referenced directly. Query via `FOR SYSTEM_TIME` on CEP.CompoundProperties.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CompoundProperties (temporal history table)
  <- CEP.CompoundProperties (SYSTEM_VERSIONING source)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| CEP.CompoundProperties | Table | Live table - this is its temporal history |

### 6.2 Objects That Depend On This

No direct dependencies. Queried via temporal syntax on CEP.CompoundProperties.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_CompoundProperties | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

DATA_COMPRESSION = PAGE.

---

## 8. Sample Queries

### 8.1 View current and historical states of a compound property
```sql
SELECT CompoundPropertyID, Name, ValidFrom, SysStartTime, SysEndTime
FROM CEP.CompoundProperties
FOR SYSTEM_TIME ALL
WHERE CompoundPropertyID = 42
ORDER BY SysStartTime;
```

### 8.2 Get historical compound property definitions at a point in time
```sql
SELECT CompoundPropertyID, Name, ValidFrom
FROM CEP.CompoundProperties
FOR SYSTEM_TIME AS OF '2024-01-01T00:00:00'
ORDER BY CompoundPropertyID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal auto-managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CompoundProperties | Type: Table | Source: etoro/etoro/History/Tables/History.CompoundProperties.sql*
