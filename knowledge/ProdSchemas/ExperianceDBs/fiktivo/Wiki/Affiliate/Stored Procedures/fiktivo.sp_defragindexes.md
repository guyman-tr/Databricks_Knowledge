# fiktivo.sp_defragindexes

> Database maintenance utility that defragments all indexes on all user tables using DBCC INDEXDEFRAG with a nested cursor approach.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Index defragmentation for all user tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_defragindexes is a database maintenance procedure that performs online index defragmentation across all user tables in the specified database. Index fragmentation accumulates over time as data is inserted, updated, and deleted, leading to degraded query performance and increased I/O costs. This procedure addresses that by systematically defragmenting every index.

Unlike index rebuilds, DBCC INDEXDEFRAG performs an online operation that does not hold long-term locks, making it suitable for execution during periods of reduced activity without requiring full downtime. However, it is less thorough than a full rebuild and may not fully resolve heavily fragmented indexes.

The procedure uses system tables (sysobjects and sysindexes) to enumerate all user tables and their indexes, iterating through them with nested cursors. This is a legacy pattern predating modern DMVs like sys.dm_db_index_physical_stats, but remains functional.

---

## 2. Business Logic

### 2.1 Nested Cursor Index Defragmentation

**What**: Iterates all user tables and their indexes, applying DBCC INDEXDEFRAG to each.

**Columns/Parameters Involved**: `@DBName`

**Rules**:
- Outer cursor: Selects table names from sysobjects WHERE xtype = 'U' (user tables)
- Inner cursor: Selects index names from sysindexes for each table
- Executes DBCC INDEXDEFRAG(@DBName, tablename, indexname) for each table/index combination
- If @DBName is empty, uses the current database context

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DBName | VARCHAR(30) (IN) | NO | '' | CODE-BACKED | The name of the database to defragment. Defaults to empty string, which uses the current database context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | sysobjects | SELECT | Enumerates all user tables (xtype = 'U') |
| - | sysindexes | SELECT | Enumerates all indexes for each user table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.sp_defragindexes (procedure)
├── sysobjects (system table)
└── sysindexes (system table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| sysobjects | System Table | SELECT to enumerate user tables |
| sysindexes | System Table | SELECT to enumerate indexes per table |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Defragment all indexes in the current database
```sql
EXEC fiktivo.sp_defragindexes
```

### 8.2 Defragment all indexes in a specific database
```sql
EXEC fiktivo.sp_defragindexes @DBName = 'fiktivo'
```

### 8.3 Check index fragmentation before running defrag
```sql
SELECT
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i WITH (NOLOCK) ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
ORDER BY ips.avg_fragmentation_in_percent DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 6.5/10 (Elements: 10.0/10, Logic: 4.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_defragindexes | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_defragindexes.sql*
