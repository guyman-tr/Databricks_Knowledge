# fiktivo.spafw_RebuildIndices

> Database maintenance utility that rebuilds all indexes on all base tables using DBCC DBREINDEX with a 90% fill factor.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Full index rebuild for all base tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

spafw_RebuildIndices is a database maintenance procedure that performs a full rebuild of all indexes across every base table in the database. Index rebuilds are more thorough than defragmentation: they completely reconstruct the index B-tree, resetting fragmentation to zero and reclaiming wasted space. This is essential for maintaining optimal query performance in high-transaction databases.

The procedure uses a 90% fill factor during the rebuild, which leaves 10% free space on each index page. This headroom accommodates future inserts and updates without immediately causing page splits, striking a balance between read performance (fuller pages) and write performance (fewer page splits).

Unlike the online defragmentation approach used by sp_defragindexes, DBCC DBREINDEX is an offline operation that holds schema locks during execution. This procedure should be scheduled during maintenance windows when the database can tolerate brief periods of reduced availability.

---

## 2. Business Logic

### 2.1 Cursor-Based Index Rebuild

**What**: Iterates all base tables and rebuilds their indexes with a 90% fill factor.

**Columns/Parameters Involved**: None (parameterless)

**Rules**:
- Cursor over INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'
- Executes DBCC DBREINDEX(tablename, '', 90) for each table
- The empty string for index name means all indexes on the table are rebuilt
- Fill factor of 90 leaves 10% free space per page for future growth

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (none) | - | - | - | - | This procedure takes no parameters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | INFORMATION_SCHEMA.TABLES | SELECT | Enumerates all base tables in the database |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_RebuildIndices (procedure)
└── INFORMATION_SCHEMA.TABLES (system view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| INFORMATION_SCHEMA.TABLES | System View | SELECT to enumerate all base tables for index rebuild |

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

### 8.1 Rebuild all indexes in the database
```sql
EXEC fiktivo.spafw_RebuildIndices
```

### 8.2 Check current index fragmentation levels before rebuild
```sql
SELECT
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i WITH (NOLOCK) ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
ORDER BY ips.avg_fragmentation_in_percent DESC
```

### 8.3 List all base tables that would be affected
```sql
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES WITH (NOLOCK)
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 6.5/10 (Elements: 10.0/10, Logic: 4.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_RebuildIndices | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_RebuildIndices.sql*
