# fiktivo.spafw_RebuildIndices

> Rebuilds all indexes on every base table in the database using a cursor-driven DBCC DBREINDEX loop with a 90% fill factor.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (maintenance utility) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a database maintenance utility procedure that rebuilds all indexes across every base table in the database. It is designed to combat index fragmentation that accumulates over time due to INSERT, UPDATE, and DELETE operations on the affiliate commission tables.

Index fragmentation degrades query performance over time. By periodically running this procedure, the database maintains efficient index structures, which is critical for the high-volume affiliate commission reporting and payment processing workloads.

**Important**: This procedure uses the deprecated DBCC DBREINDEX command rather than the modern ALTER INDEX ... REBUILD syntax. DBCC DBREINDEX was deprecated in SQL Server 2005 and may be removed in future SQL Server versions.

---

## 2. Business Logic

### 2.1 Cursor-Driven Table Iteration

**What**: Iterates over all base tables in the database and rebuilds their indexes.

**Columns/Parameters Involved**: `information_schema.tables.table_name`

**Rules**:
- Declares a cursor over information_schema.tables WHERE table_type = 'base table'
- Iterates through each table name
- Prints "Reindexing " + table name for progress tracking
- Calls DBCC DBREINDEX(@TableName, ' ', 90) for each table
- The second parameter ' ' (space) means rebuild ALL indexes on the table
- The third parameter 90 is the fill factor percentage (90% page fullness)
- Cursor is properly closed and deallocated after processing

### 2.2 Fill Factor Configuration

**What**: Uses a fixed 90% fill factor for all rebuilt indexes.

**Rules**:
- Fill factor of 90 means each index page is filled to 90% capacity
- The remaining 10% is reserved for future inserts/updates
- This is a reasonable general-purpose setting that balances read performance (higher fill = fewer pages to scan) with write performance (lower fill = fewer page splits)
- All tables receive the same fill factor regardless of their access pattern

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | This procedure has no input parameters. It operates on all base tables in the database. |

**Local Variables**:

| # | Variable | Type | Description |
|---|----------|------|-------------|
| 1 | @TableName | VARCHAR(255) | Holds the current table name from the cursor iteration |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | information_schema.tables | System view read | Retrieves list of all base tables in the database |
| (DBCC) | All base tables | Index rebuild | Rebuilds all indexes on each table via DBCC DBREINDEX |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_RebuildIndices (procedure)
    ├── information_schema.tables (system view)
    └── DBCC DBREINDEX (system command, deprecated)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| information_schema.tables | System view | SELECT to enumerate all base tables |
| DBCC DBREINDEX | System command | Rebuilds indexes on each table (deprecated) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Session Settings

- SET ANSI_NULLS OFF
- SET QUOTED_IDENTIFIER OFF

### 7.4 Deprecation Warning

DBCC DBREINDEX is deprecated since SQL Server 2005. The modern replacement is:

```sql
ALTER INDEX ALL ON [TableName] REBUILD WITH (FILLFACTOR = 90, ONLINE = ON)
```

The ONLINE = ON option allows the table to remain accessible during the rebuild, which is important for production workloads.

### 7.5 Performance Considerations

- This procedure rebuilds ALL indexes on ALL tables, regardless of fragmentation level
- Modern best practice is to check sys.dm_db_index_physical_stats first and only rebuild indexes with fragmentation above 30% (reorganize for 10-30%)
- Running this procedure during business hours could cause significant blocking and lock contention
- The cursor approach processes tables sequentially; no parallelism between tables

---

## 8. Sample Queries

### 8.1 Run the index rebuild
```sql
EXEC fiktivo.spafw_RebuildIndices
```

### 8.2 Modern alternative -- check fragmentation first
```sql
-- Check fragmentation levels before rebuilding
SELECT OBJECT_NAME(ips.object_id) AS TableName,
       i.name AS IndexName,
       ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
ORDER BY ips.avg_fragmentation_in_percent DESC
```

### 8.3 Modern alternative -- selective rebuild
```sql
-- Rebuild only heavily fragmented indexes
ALTER INDEX ALL ON dbo.tblaff_Sales_Commissions REBUILD WITH (FILLFACTOR = 90)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 5.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 3/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_RebuildIndices | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_RebuildIndices.sql*
