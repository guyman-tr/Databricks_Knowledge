# dbo.Job_LogicApp_RebuildIndexesWithFragmentation

> DBA maintenance procedure triggered by Azure Logic App that identifies and rebuilds database indexes with fragmentation above 30% and sufficient page count.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Primary output: rebuilt index count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This stored procedure is an automated index maintenance job triggered by an Azure Logic App on a scheduled basis. It identifies all database indexes that have fragmentation above 30% and more than 100 pages, then rebuilds each one with ONLINE=ON to avoid blocking production queries. Index fragmentation degrades query performance over time as data is inserted, updated, and deleted.

Without this procedure, index fragmentation would accumulate until queries become slow, potentially affecting customer-facing crypto transaction processing. The ONLINE rebuild mode ensures zero downtime - reads and writes continue during the rebuild. The EXECUTE AS OWNER security context ensures the procedure has sufficient permissions to rebuild indexes across all schemas.

The procedure works by querying sys.dm_db_index_physical_stats for the current database, filtering to fragmented indexes, loading them into a temp table, then iterating through each one to execute a dynamic ALTER INDEX REBUILD statement.

---

## 2. Business Logic

### 2.1 Fragmentation-Based Index Selection

**What**: Only indexes meeting both fragmentation and size thresholds are rebuilt.

**Columns/Parameters Involved**: `avg_fragmentation_in_percent`, `page_count`, `is_disabled`

**Rules**:
- Fragmentation > 30%: Below this, SQL Server's optimizer handles it efficiently
- Page count > 100: Very small indexes are not worth rebuilding (overhead exceeds benefit)
- Disabled indexes excluded: Cannot rebuild a disabled index
- Heap indexes excluded (type <> 0): Only clustered and nonclustered indexes are rebuilt
- ONLINE=ON: Allows concurrent DML during rebuild (no table locks)

**Diagram**:
```
Logic App (scheduled trigger)
  |
  +--> EXEC dbo.Job_LogicApp_RebuildIndexesWithFragmentation
         |
         +--> Query sys.dm_db_index_physical_stats
         +--> Filter: fragmentation > 30%, pages > 100, enabled
         +--> For each qualifying index:
                ALTER INDEX [name] ON [schema].[table] REBUILD WITH (ONLINE=ON)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no parameters) | - | - | - | - | - | This procedure takes no input parameters. It operates on all indexes in the current database. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (logic) | sys.dm_db_index_physical_stats | System DMV | Queries fragmentation statistics for all indexes |
| (logic) | sys.tables | System catalog | Gets table names for the ALTER INDEX statement |
| (logic) | sys.schemas | System catalog | Gets schema names for qualified table references |
| (logic) | sys.indexes | System catalog | Gets index names and filters out heaps/disabled |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. It is called externally by an Azure Logic App on a schedule.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no schema dependencies (uses only system DMVs and catalogs).

### 6.1 Objects This Depends On

No schema dependencies. Uses sys.dm_db_index_physical_stats, sys.tables, sys.schemas, sys.indexes.

### 6.2 Objects That Depend On This

No dependents found. Called externally by Azure Logic App.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS OWNER | Security | Runs under the database owner's security context to ensure ALTER INDEX permissions on all schemas |

---

## 8. Sample Queries

### 8.1 Execute the maintenance job
```sql
EXEC dbo.Job_LogicApp_RebuildIndexesWithFragmentation
```

### 8.2 Preview which indexes would be rebuilt (without rebuilding)
```sql
SELECT dbschemas.name AS [Schema], dbtables.name AS [Table],
       dbindexes.name AS [Index],
       indexstats.avg_fragmentation_in_percent AS Fragmentation,
       indexstats.page_count AS Pages
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
JOIN sys.tables dbtables ON dbtables.object_id = indexstats.object_id
JOIN sys.schemas dbschemas ON dbtables.schema_id = dbschemas.schema_id
JOIN sys.indexes dbindexes ON dbindexes.object_id = indexstats.object_id
  AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
  AND dbindexes.type <> 0
  AND avg_fragmentation_in_percent > 30
  AND is_disabled = 0
  AND indexstats.page_count > 100
ORDER BY avg_fragmentation_in_percent DESC
```

### 8.3 Check recent index rebuild activity
```sql
SELECT TOP 10 object_name(object_id) AS TableName,
       name AS IndexName, type_desc, is_disabled
FROM sys.indexes
WHERE is_disabled = 0 AND type <> 0
ORDER BY name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Job_LogicApp_RebuildIndexesWithFragmentation | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.Job_LogicApp_RebuildIndexesWithFragmentation.sql*
