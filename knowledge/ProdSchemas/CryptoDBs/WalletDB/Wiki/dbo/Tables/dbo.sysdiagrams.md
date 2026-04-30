# dbo.sysdiagrams

> System table storing SQL Server Management Studio database diagram definitions, used by the SSMS visual designer to persist ER diagram layouts.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | diagram_id (int, IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK CLUSTERED on diagram_id) |

---

## 1. Business Meaning

This is a standard SQL Server system table that stores database diagram definitions created in SQL Server Management Studio (SSMS). Each row represents a saved diagram that visually maps tables and their relationships. It is not a business table - it exists solely to support the SSMS diagram designer feature.

The table has 1 row, indicating a single diagram has been saved for the WalletDB database. The diagram system includes a full set of supporting stored procedures (sp_creatediagram, sp_alterdiagram, sp_dropdiagram, etc.) and a utility function (fn_diagramobjects).

No business logic references this table. It is consumed exclusively by the SSMS diagram management procedures in the dbo schema.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a system infrastructure table.

---

## 3. Data Overview

| diagram_id | name | principal_id | version | Meaning |
|---|---|---|---|---|
| 1 | (diagram name) | (owner id) | (version) | The single saved database diagram for WalletDB, owned by a specific database principal |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | name | sysname | NO | - | CODE-BACKED | Diagram display name. Unique per owner (enforced by UK_principal_name constraint). |
| 2 | principal_id | int | NO | - | CODE-BACKED | Database principal (user) who owns the diagram. Combined with name forms a unique constraint. |
| 3 | diagram_id | int | NO | IDENTITY | CODE-BACKED | Auto-incrementing diagram identifier. Primary key. |
| 4 | version | int | YES | - | CODE-BACKED | Diagram format version number. Tracks compatibility with SSMS diagram feature versions. |
| 5 | definition | varbinary(max) | YES | - | CODE-BACKED | Binary serialization of the diagram layout. Contains table positions, relationship lines, colors, and visual formatting as stored by SSMS. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.sp_creatediagram | - | WRITER | Creates new diagram entries |
| dbo.sp_alterdiagram | - | MODIFIER | Updates diagram definition, version, owner |
| dbo.sp_dropdiagram | - | DELETER | Removes diagram entries |
| dbo.sp_helpdiagramdefinition | - | READER | Reads diagram version and definition |
| dbo.sp_helpdiagrams | - | READER | Lists available diagrams |
| dbo.sp_renamediagram | - | MODIFIER | Renames diagram entries |
| dbo.sp_upgraddiagrams | - | WRITER | Creates/upgrades the sysdiagrams table structure |
| dbo.fn_diagramobjects | - | READER | Checks existence of diagram system objects |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.sp_creatediagram | Stored Procedure | INSERT - creates new diagrams |
| dbo.sp_alterdiagram | Stored Procedure | UPDATE - modifies diagrams |
| dbo.sp_dropdiagram | Stored Procedure | DELETE - removes diagrams |
| dbo.sp_helpdiagramdefinition | Stored Procedure | SELECT - reads diagram definitions |
| dbo.sp_helpdiagrams | Stored Procedure | SELECT - lists diagrams |
| dbo.sp_renamediagram | Stored Procedure | UPDATE - renames diagrams |
| dbo.sp_upgraddiagrams | Stored Procedure | CREATE/INSERT - upgrades diagram infrastructure |
| dbo.fn_diagramobjects | Function | Checks object existence via object_id() |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | diagram_id | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UK_principal_name | UNIQUE | principal_id, name - each user can only have one diagram with a given name |

---

## 8. Sample Queries

### 8.1 List all saved diagrams
```sql
SELECT diagram_id, name, principal_id, version
FROM dbo.sysdiagrams WITH (NOLOCK)
```

### 8.2 Find diagrams by owner
```sql
SELECT d.diagram_id, d.name, dp.name AS OwnerName
FROM dbo.sysdiagrams d WITH (NOLOCK)
JOIN sys.database_principals dp ON dp.principal_id = d.principal_id
```

### 8.3 Check diagram definition size
```sql
SELECT diagram_id, name, DATALENGTH(definition) AS DefinitionBytes
FROM dbo.sysdiagrams WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sysdiagrams | Type: Table | Source: WalletDB/dbo/Tables/dbo.sysdiagrams.sql*
