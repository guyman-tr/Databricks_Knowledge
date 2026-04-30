# Saga.PurgeTable

> Generic partition-based data retention procedure that truncates old weekly partitions from any partitioned table, enabling efficient cleanup of high-volume saga event and status data.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Dynamic: operates on any partitioned table by name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

PurgeTable is a generic data retention utility that truncates old partitions from any partitioned table in the database. It accepts a table name and a time span (in weeks), identifies all partitions with boundary values older than the threshold, and truncates them one by one. This is orders of magnitude faster than row-by-row DELETE operations since partition truncation is an O(1) metadata operation.

Without this procedure, high-volume tables like `Saga.SagaEvents` would grow unbounded, consuming storage and degrading query performance. The partition-based approach allows instant cleanup without transaction log pressure.

The procedure is designed to be called by a scheduled job or maintenance process. The commented test code in the procedure uses `'Saga.SagaEvents'` as the example target, confirming its primary use case. It can operate on any table partitioned by the `DatePartitionFunctionByWeek2040` scheme.

---

## 2. Business Logic

### 2.1 Partition-Based Purging Algorithm

**What**: Identifies and truncates partitions with data older than the specified retention window.

**Columns/Parameters Involved**: `@Table`, `@TimeSpan`

**Rules**:
- Calculates threshold: `@time = DATEADD(WEEK, -@TimeSpan, GETUTCDATE())`
- Queries sys.partitions JOIN sys.partition_range_values to find partitions with `value < @time` and `rows > 0`
- Iterates through qualifying partitions and executes `TRUNCATE TABLE ... WITH (PARTITIONS ({N}))` for each
- Uses `sp_executesql` for the dynamic TRUNCATE statement
- Only targets partitions with rows (skips empty partitions)
- Processes partitions in ascending order (oldest first)

### 2.2 Dynamic Table Targeting

**What**: Accepts any schema.table name as input, enabling reuse across multiple partitioned tables.

**Columns/Parameters Involved**: `@Table`

**Rules**:
- Parses @Table into schema and table components using string manipulation (CHARINDEX on '.')
- The schema and table names are used both for sys metadata queries and the TRUNCATE statement
- Primary target: Saga.SagaEvents (partitioned by Created on DatesToFilegroup weekly scheme)
- Could also target any other table using the same partition function

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Table | nvarchar(50) | NO | - | CODE-BACKED | Fully qualified table name in 'Schema.TableName' format. Parsed into schema and table components. Example: 'Saga.SagaEvents'. |
| 2 | @TimeSpan | int | NO | - | CODE-BACKED | Retention window in weeks. Partitions with boundary values older than GETUTCDATE() minus @TimeSpan weeks will be truncated. Example: 2 = truncate partitions older than 2 weeks. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Table | Saga.SagaEvents (primary target) | Dynamic TRUNCATE | Truncates old partitions from the specified table |
| - | sys.tables, sys.partitions, sys.partition_functions, sys.partition_range_values | Metadata query | Reads partition metadata to identify qualifying partitions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.PurgeTable (procedure)
├── sys.tables (system catalog)
├── sys.indexes (system catalog)
├── sys.schemas (system catalog)
├── sys.partitions (system catalog)
├── sys.partition_schemes (system catalog)
├── sys.partition_functions (system catalog)
└── sys.partition_range_values (system catalog)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| sys.tables / sys.partitions / sys.partition_functions | System catalog views | Queried to identify partitions eligible for truncation |
| Saga.SagaEvents | Table | Primary purge target (referenced in comments) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Purge SagaEvents older than 2 weeks
```sql
EXEC Saga.PurgeTable @Table = 'Saga.SagaEvents', @TimeSpan = 2
```

### 8.2 Preview which partitions would be truncated
```sql
DECLARE @time datetime2(7) = DATEADD(WEEK, -2, GETUTCDATE())

SELECT p.partition_number, r.value AS [Boundary Value], t.name, p.rows
FROM sys.tables AS t
JOIN sys.indexes AS i ON t.object_id = i.object_id
JOIN sys.schemas AS sc ON t.schema_id = sc.schema_id
JOIN sys.partitions AS p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.partition_schemes AS s ON i.data_space_id = s.data_space_id
JOIN sys.partition_functions AS f ON s.function_id = f.function_id
LEFT JOIN sys.partition_range_values AS r ON f.function_id = r.function_id AND r.boundary_id = p.partition_number
WHERE p.rows > 0 AND i.type <= 1
AND t.name = 'SagaEvents' AND sc.name = 'Saga'
AND r.value < @time
ORDER BY p.partition_number ASC
```

### 8.3 Check partition row counts for a table
```sql
SELECT p.partition_number, r.value AS [Boundary], p.rows
FROM sys.tables AS t
JOIN sys.indexes AS i ON t.object_id = i.object_id
JOIN sys.schemas AS sc ON t.schema_id = sc.schema_id
JOIN sys.partitions AS p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.partition_schemes AS s ON i.data_space_id = s.data_space_id
JOIN sys.partition_functions AS f ON s.function_id = f.function_id
LEFT JOIN sys.partition_range_values AS r ON f.function_id = r.function_id AND r.boundary_id = p.partition_number
WHERE i.type <= 1 AND t.name = 'SagaEvents' AND sc.name = 'Saga'
AND p.rows > 0
ORDER BY p.partition_number ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.PurgeTable | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.PurgeTable.sql*
