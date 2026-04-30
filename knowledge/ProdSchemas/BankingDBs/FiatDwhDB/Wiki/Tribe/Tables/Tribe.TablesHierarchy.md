# Tribe.TablesHierarchy

> Metadata table that stores the JSON hierarchy structure of Tribe provider API response tables, mapping each table to its position in the nested JSON object tree.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

TablesHierarchy is a metadata table that records the JSON nesting structure of Tribe provider API responses. Each row maps a table name to its full hierarchy path in the original JSON document. This metadata enables the system to reconstruct the original JSON structure from the flattened SQL tables and to generate correct DDL scripts for new tables.

The Tribe schema stores provider data that arrives as nested JSON files. These are flattened into parent-child SQL tables. TablesHierarchy documents which table represents which level of the JSON nesting (e.g., "AccountsActivities -> AccountActivity -> RiskActions").

Data is created by Tribe.InsertTableHierarchy, which checks if a table name already exists before inserting (idempotent upsert on TableName).

---

## 2. Business Logic

### 2.1 JSON-to-SQL Hierarchy Mapping

**What**: Maps flattened SQL table names to their position in the original nested JSON structure.

**Columns/Parameters Involved**: `TableName`, `FullHierarchy`

**Rules**:
- TableName stores the SQL table name (e.g., "AccountsActivities_AccountActivity-833937")
- FullHierarchy stores the JSON path (e.g., "AccountsActivities -> AccountActivity")
- One row per table - InsertTableHierarchy prevents duplicates

---

## 3. Data Overview

N/A - metadata table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Referenced by TablesColumns.TableHierarchyId. |
| 2 | TableName | nvarchar(4000) | YES | - | CODE-BACKED | SQL table name in the Tribe schema (e.g., "AccountsActivities_AccountActivity-833937"). |
| 3 | FullHierarchy | nvarchar(4000) | YES | - | CODE-BACKED | Full JSON nesting path for this table (e.g., "AccountsActivities -> AccountActivity"). |
| 4 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | When this hierarchy record was created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.TablesColumns | TableHierarchyId | Implicit FK | Column metadata references hierarchy |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.TablesColumns | Table | References via TableHierarchyId |
| Tribe.InsertTableHierarchy | Stored Procedure | Inserts hierarchy records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TablesHierarchy | CLUSTERED | Id ASC | - | - | Active |
| IX_TablesHierarchy_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | Created defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 View all table hierarchies
```sql
SELECT TableName, FullHierarchy, Created FROM Tribe.TablesHierarchy WITH (NOLOCK) ORDER BY TableName;
```

### 8.2 Find hierarchy for a specific table
```sql
SELECT * FROM Tribe.TablesHierarchy WITH (NOLOCK) WHERE TableName LIKE '%AccountsActivities%';
```

### 8.3 Join with column metadata
```sql
SELECT th.TableName, th.FullHierarchy, tc.Columns
FROM Tribe.TablesHierarchy th WITH (NOLOCK)
JOIN Tribe.TablesColumns tc WITH (NOLOCK) ON tc.TableHierarchyId = th.Id
ORDER BY th.TableName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.TablesHierarchy | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.TablesHierarchy.sql*
