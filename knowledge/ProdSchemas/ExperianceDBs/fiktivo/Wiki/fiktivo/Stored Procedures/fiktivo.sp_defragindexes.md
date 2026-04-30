# fiktivo.sp_defragindexes

> Maintenance utility that defragments all indexes across all user tables in a specified database using DBCC INDEXDEFRAG.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (maintenance utility, no output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a database maintenance utility that iterates through all user tables and their indexes in a specified database and runs `DBCC INDEXDEFRAG` on each one. Index fragmentation occurs naturally as data is inserted, updated, and deleted, causing index pages to become disordered. Defragmenting indexes improves query performance by reorganizing the physical storage of index data.

This procedure exists to automate routine index maintenance. Without regular defragmentation, query performance would degrade over time as indexes become increasingly fragmented, leading to more I/O operations and slower data retrieval. This is particularly important for the affiliate commission system's high-write tables (Sales, Leads, Commissions).

The procedure is typically scheduled as a maintenance job (e.g., SQL Agent job) to run during off-peak hours. It uses cursors to iterate through `sysobjects` (to find user tables) and `sysindexes` (to find their indexes), then dynamically executes DBCC INDEXDEFRAG for each index.

---

## 2. Business Logic

### 2.1 Index Defragmentation Loop

**What**: Iterates through all user tables and indexes in the target database, defragmenting each one.

**Columns/Parameters Involved**: `@DBName`

**Rules**:
- Opens a cursor over sysobjects WHERE xtype = 'U' (user tables) to get all table names
- For each table, opens a nested cursor over sysindexes to get all index IDs
- Executes DBCC INDEXDEFRAG(@DBName, tablename, indexid) for each table-index pair
- Skips system tables (only processes user tables)
- Runs sequentially through all indexes -- no parallelism

**Diagram**:
```
sp_defragindexes(@DBName)
    |
    v
CURSOR: sysobjects WHERE xtype='U'
    |
    +--> For each User Table:
    |       |
    |       v
    |    CURSOR: sysindexes for this table
    |       |
    |       +--> For each Index:
    |               |
    |               v
    |            DBCC INDEXDEFRAG(@DBName, table, index)
    |
    v
All indexes defragmented
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DBName (IN) | NVARCHAR(128) | NO | - | CODE-BACKED | The name of the database whose indexes should be defragmented. Passed to DBCC INDEXDEFRAG as the first argument. Must be a valid database name accessible from the current server. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Cursor source | sysobjects | System catalog read | Reads user table names (xtype='U') from the system catalog |
| Cursor source | sysindexes | System catalog read | Reads index IDs for each user table from the system catalog |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (uses only system catalog views and DBCC commands).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| sysobjects | System catalog | Cursor source for user table names |
| sysindexes | System catalog | Cursor source for index IDs per table |
| DBCC INDEXDEFRAG | System command | Performs the actual index defragmentation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Defragment all indexes in the affiliate database
```sql
EXEC fiktivo.sp_defragindexes @DBName = 'AffiliateDB'
```

### 8.2 Check index fragmentation before running defrag
```sql
SELECT OBJECT_NAME(ips.object_id) AS TableName,
       i.name AS IndexName,
       ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE ips.avg_fragmentation_in_percent > 10
ORDER BY ips.avg_fragmentation_in_percent DESC
```

### 8.3 Check fragmentation after defrag for verification
```sql
SELECT OBJECT_NAME(ips.object_id) AS TableName,
       i.name AS IndexName,
       ips.avg_fragmentation_in_percent,
       ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE ips.page_count > 100
ORDER BY ips.avg_fragmentation_in_percent DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 5.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.sp_defragindexes | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.sp_defragindexes.sql*
