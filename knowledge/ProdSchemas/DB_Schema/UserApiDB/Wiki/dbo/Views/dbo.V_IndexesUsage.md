# dbo.V_IndexesUsage

> DBA monitoring view showing index usage statistics (seeks, scans, lookups, updates) with key/included columns for all indexes in the database.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | object_id + index_id |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.V_IndexesUsage is a DBA utility view that combines sys.dm_db_index_usage_stats with sys.indexes, sys.objects, sys.index_columns, and sys.columns to provide a complete picture of index usage. For each index, shows: table name, index name, seeks/scans/lookups/updates counts, index type (PK/Clustered/Unique), key columns (with ASC/DESC), included columns, and filter expression. Used for index optimization and unused index identification.

---

## 2. Business Logic

### 2.1 Index Column Aggregation

**What**: Pivots index column metadata into comma-separated strings using FOR XML PATH.

**Rules**:
- Key columns (is_included_column=0) ordered by key_ordinal, with ASC/DESC suffix
- Included columns (is_included_column=1) ordered alphabetically
- Uses OUTER APPLY with STUFF/FOR XML PATH for string aggregation

---

## 3. Data Overview

N/A - system DMV view (returns one row per index).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | object_id | int | NO | - | CODE-BACKED | Table object ID. |
| 2 | TableName | nvarchar | NO | - | CODE-BACKED | Schema.Table name. |
| 3 | index_id | int | NO | - | CODE-BACKED | Index ID within the table. |
| 4 | IndexName | sysname | YES | - | CODE-BACKED | Index name. |
| 5 | Seeks | bigint | NO | - | CODE-BACKED | Number of index seeks since last restart. |
| 6 | Scans | bigint | NO | - | CODE-BACKED | Number of index scans since last restart. |
| 7 | Lookups | bigint | NO | - | CODE-BACKED | Number of key lookups since last restart. |
| 8 | Updates | bigint | NO | - | CODE-BACKED | Number of index updates (maintenance cost). |
| 9 | Type | nvarchar | YES | - | CODE-BACKED | Index type: PK, Clustered Index, Unique, or combinations. |
| 10 | Columns | nvarchar | YES | - | CODE-BACKED | Comma-separated key columns with ASC/DESC. |
| 11 | Include | nvarchar | YES | - | CODE-BACKED | Comma-separated included columns. |
| 12 | Where | nvarchar | YES | - | CODE-BACKED | Filter expression for filtered indexes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | sys.dm_db_index_usage_stats | RIGHT JOIN | Usage statistics |
| - | sys.indexes | FROM | Index definitions |
| - | sys.objects | JOIN | Table names |
| - | sys.index_columns + sys.columns | CTE | Column details |

### 5.2 Referenced By (other objects point to this)

DBA monitoring queries.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object depends only on system DMVs and catalog views.

### 6.1 Objects This Depends On

System DMVs only (sys.dm_db_index_usage_stats, sys.indexes, sys.objects, sys.index_columns, sys.columns, sys.tables).

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Unused indexes (no seeks)
```sql
SELECT TableName, IndexName, Scans, Updates FROM dbo.V_IndexesUsage WITH (NOLOCK) WHERE Seeks = 0 AND Updates > 0 ORDER BY Updates DESC
```

### 8.2 Most-used indexes
```sql
SELECT TOP 20 TableName, IndexName, Seeks, Scans, Lookups FROM dbo.V_IndexesUsage WITH (NOLOCK) ORDER BY Seeks + Scans + Lookups DESC
```

### 8.3 Indexes with high update cost
```sql
SELECT TableName, IndexName, Updates, Seeks, Type FROM dbo.V_IndexesUsage WITH (NOLOCK) WHERE Updates > Seeks * 10 ORDER BY Updates DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: dbo.V_IndexesUsage | Type: View | Source: UserApiDB/UserApiDB/dbo/Views/dbo.V_IndexesUsage.sql*
