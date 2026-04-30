# Tribe.TablesColumns

> Metadata table storing the column definitions (as JSON/CSV) for each Tribe data table, linked to TablesHierarchy for the full schema map.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

TablesColumns stores column metadata for each Tribe data table. Each row maps a table (via TableHierarchyId and TableName) to its column definitions stored as a serialized string in the Columns field. Used by the schema management system to track column definitions and detect schema changes when new Tribe data files arrive.

Data is created by Tribe.InsertTableColumnsInfo.

---

## 2. Business Logic

### 2.1 Column Definition Storage

**What**: Stores column definitions as serialized text per table.

**Rules**:
- TableHierarchyId links to TablesHierarchy for the full hierarchy context
- Columns stores column names/types as a serialized string
- Used for schema comparison to detect if new files have different columns than expected

---

## 3. Data Overview

N/A - metadata table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | TableHierarchyId | bigint | NO | - | CODE-BACKED | FK to Tribe.TablesHierarchy.Id. Links to the table's position in the JSON hierarchy. |
| 3 | TableName | nvarchar(4000) | YES | - | CODE-BACKED | SQL table name for this column definition set. |
| 4 | Columns | varchar(max) | YES | - | CODE-BACKED | Serialized column definitions (names and types) for the table. |
| 5 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | When this column definition was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TableHierarchyId | Tribe.TablesHierarchy | Implicit FK | Links to hierarchy context |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.InsertTableColumnsInfo | INSERT | Writer | Creates column records |
| Tribe.GetTribeTablesColumns | SELECT | Reader | Reads column metadata |
| Tribe.IsSchemaAlligned | SELECT | Reader | Checks schema alignment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.TablesColumns (table)
└── Tribe.TablesHierarchy (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.TablesHierarchy | Table | Implicit FK from TableHierarchyId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.InsertTableColumnsInfo | Stored Procedure | Writes column records |
| Tribe.GetTribeTablesColumns | Stored Procedure | Reads column metadata |
| Tribe.IsSchemaAlligned | Stored Procedure | Schema comparison |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TablesColumns | CLUSTERED | Id ASC | - | - | Active |
| IX_TablesColumns_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | Created defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 View column definitions with hierarchy
```sql
SELECT tc.TableName, th.FullHierarchy, tc.Columns, tc.Created
FROM Tribe.TablesColumns tc WITH (NOLOCK)
JOIN Tribe.TablesHierarchy th WITH (NOLOCK) ON th.Id = tc.TableHierarchyId
ORDER BY tc.TableName;
```

### 8.2 Find columns for a specific table
```sql
SELECT * FROM Tribe.TablesColumns WITH (NOLOCK) WHERE TableName LIKE '%AccountsActivities%';
```

### 8.3 Recently added column definitions
```sql
SELECT TOP 10 TableName, Created FROM Tribe.TablesColumns WITH (NOLOCK) ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.TablesColumns | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.TablesColumns.sql*
