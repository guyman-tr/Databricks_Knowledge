# DBA.V_NumRows_Sizes

> DBA monitoring view reporting row counts and storage sizes (in MB) for all tables in the database, sourced from sys.tables, sys.partitions, and sys.allocation_units.

| Property | Value |
|----------|-------|
| **Schema** | DBA |
| **Object Type** | View |
| **Key Identifier** | SchemaName + TableName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DBA.V_NumRows_Sizes is a DBA operational view used for capacity planning, performance monitoring, and growth tracking. It provides a snapshot of row counts and allocated storage sizes for every table in the database, querying SQL Server's internal catalog views. The DateID and ServerName/DBName columns allow the output to be inserted into a central monitoring table that collects metrics across multiple servers and databases over time.

Database administrators and data engineers use this view to identify the largest tables, track row count growth, and detect unexpected data accumulation.

---

## 2. Business Logic

### 2.1 Size Calculation

**What**: Aggregates allocation unit pages to compute table storage in MB.

**Columns/Parameters Involved**: `SizeMB`, `NumRecords`

**Rules**:
- Joins sys.tables → sys.partitions (index_id IN (0,1) for heap or clustered) → sys.allocation_units (type IN (1,2) for IN_ROW and LOB data)
- NumRecords = SUM(rows) from sys.partitions
- SizeMB = SUM(used_pages) * 8 / 1024.0 (each page = 8KB)
- Results grouped by schema + table name
- Uses CONVERT(int, GETDATE(), 112) style for DateID (YYYYMMDD integer)

---

## 3. Data Overview

N/A - metadata view, no user data stored. Returns one row per table in the database.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DateID | int | NO | - | CODE-BACKED | Snapshot date in YYYYMMDD integer format. Used as partition/filter key when inserted into monitoring tables. |
| 2 | ServerName | nvarchar | NO | - | CODE-BACKED | Current SQL Server instance name from @@SERVERNAME. Identifies the source server in multi-server monitoring aggregations. |
| 3 | DBName | nvarchar | NO | - | CODE-BACKED | Current database name from DB_NAME(). Identifies the source database. |
| 4 | SchemaName | nvarchar | NO | - | CODE-BACKED | Schema name of the table (from sys.schemas via SCHEMA_NAME). |
| 5 | TableName | nvarchar | NO | - | CODE-BACKED | Table name from sys.tables.name. |
| 6 | NumRecords | bigint | NO | - | CODE-BACKED | Approximate row count from sys.partitions. Reflects the last statistics update; may be slightly stale. |
| 7 | SizeMB | decimal | NO | - | CODE-BACKED | Allocated storage in megabytes. Calculated as used pages × 8KB / 1024. Includes data and LOB pages. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | sys.tables | System catalog | Table metadata |
| - | sys.partitions | System catalog | Row count and partition info |
| - | sys.allocation_units | System catalog | Page allocation for size calculation |
| - | sys.schemas | System catalog | Schema name resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DBA monitoring jobs | All columns | View read | Collects snapshots into central metrics table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
DBA.V_NumRows_Sizes (view)
  +-- sys.tables (system catalog)
  +-- sys.partitions (system catalog)
  +-- sys.allocation_units (system catalog)
  +-- sys.schemas (system catalog)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| sys.tables | System Catalog View | Source of table metadata |
| sys.partitions | System Catalog View | Source of row counts |
| sys.allocation_units | System Catalog View | Source of page/size data |
| sys.schemas | System Catalog View | Schema name lookup |

### 6.2 Objects That Depend On This

No user-object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (no SCHEMABINDING, no indexed view).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Top 20 tables by size
```sql
SELECT TOP 20 SchemaName, TableName, NumRecords, SizeMB
FROM DBA.V_NumRows_Sizes WITH (NOLOCK)
ORDER BY SizeMB DESC
```

### 8.2 Top 20 tables by row count
```sql
SELECT TOP 20 SchemaName, TableName, NumRecords, SizeMB
FROM DBA.V_NumRows_Sizes WITH (NOLOCK)
ORDER BY NumRecords DESC
```

### 8.3 Collect snapshot into monitoring table
```sql
INSERT INTO DBA.TableSizeHistory (DateID, ServerName, DBName, SchemaName, TableName, NumRecords, SizeMB)
SELECT DateID, ServerName, DBName, SchemaName, TableName, NumRecords, SizeMB
FROM DBA.V_NumRows_Sizes
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: DBA.V_NumRows_Sizes | Type: View | Source: UserApiDB/UserApiDB/DBA/Views/DBA.V_NumRows_Sizes.sql*
