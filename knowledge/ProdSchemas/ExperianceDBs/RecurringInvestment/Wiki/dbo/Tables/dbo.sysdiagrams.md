# dbo.sysdiagrams

> Standard SQL Server system table that stores database diagram definitions created in SSMS or Visual Studio.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | diagram_id (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + UK_principal_name unique) |

---

## 1. Business Meaning

This is a standard SQL Server system table that stores database diagram definitions. Database diagrams are visual representations of table relationships created using SQL Server Management Studio (SSMS) or Visual Studio. This table is automatically created when the first diagram is saved and is part of the diagram infrastructure managed by the sp_*diagram* stored procedures.

This table has no business logic relevance to the Recurring Investment feature. It exists purely as infrastructure for developer tooling.

Data is created by SSMS when a developer saves a database diagram, and read back when opening diagrams.

---

## 2. Business Logic

No business logic. Standard SQL Server system table for diagram storage.

---

## 3. Data Overview

N/A - system infrastructure table. Contents are binary diagram definitions not meaningful for business documentation.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | name | sysname | NO | - | CODE-BACKED | Name of the database diagram as specified by the user in SSMS. |
| 2 | principal_id | int | NO | - | CODE-BACKED | Database principal ID of the diagram owner. Maps to sys.database_principals. |
| 3 | diagram_id | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing unique identifier for the diagram. Primary key. |
| 4 | version | int | YES | - | CODE-BACKED | Diagram format version number. |
| 5 | definition | varbinary(max) | YES | - | CODE-BACKED | Binary blob containing the diagram layout definition (table positions, relationship lines, visual properties). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.sp_creatediagram | - | Writer | Inserts new diagrams |
| dbo.sp_alterdiagram | - | Modifier | Updates diagram definitions |
| dbo.sp_dropdiagram | - | Deleter | Removes diagrams |
| dbo.sp_helpdiagrams | - | Reader | Lists diagrams |
| dbo.sp_helpdiagramdefinition | - | Reader | Retrieves diagram definitions |
| dbo.sp_renamediagram | - | Modifier | Renames diagrams |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.sp_creatediagram | Stored Procedure | INSERT INTO |
| dbo.sp_alterdiagram | Stored Procedure | UPDATE |
| dbo.sp_dropdiagram | Stored Procedure | DELETE FROM |
| dbo.sp_helpdiagrams | Stored Procedure | SELECT FROM |
| dbo.sp_helpdiagramdefinition | Stored Procedure | SELECT FROM |
| dbo.sp_renamediagram | Stored Procedure | UPDATE |
| dbo.sp_upgraddiagrams | Stored Procedure | CREATE TABLE (if not exists) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED PK | diagram_id | - | - | Active |
| UK_principal_name | UNIQUE NC | principal_id, name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UK_principal_name | UNIQUE | Ensures each user can only have one diagram with a given name |

---

## 8. Sample Queries

### 8.1 List all diagrams
```sql
SELECT diagram_id, name, USER_NAME(principal_id) AS Owner FROM dbo.sysdiagrams WITH (NOLOCK) ORDER BY name
```

### 8.2 Check if diagrams exist
```sql
SELECT COUNT(*) AS DiagramCount FROM dbo.sysdiagrams WITH (NOLOCK)
```

### 8.3 Find diagrams by owner
```sql
SELECT name, diagram_id FROM dbo.sysdiagrams WITH (NOLOCK) WHERE principal_id = DATABASE_PRINCIPAL_ID()
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Standard SQL Server system table.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sysdiagrams | Type: Table | Source: RecurringInvestment/dbo/Tables/dbo.sysdiagrams.sql*
