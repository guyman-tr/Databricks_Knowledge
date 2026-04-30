# dbo.sysdiagrams

> SQL Server system table storing database diagram metadata for the visual diagram designer in SSMS.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | diagram_id (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + unique on principal_id+name) |

---

## 1. Business Meaning

dbo.sysdiagrams is a SQL Server system table that stores database diagram definitions created in SSMS (SQL Server Management Studio). Each diagram has a name, an owner (principal_id), a version, and the binary diagram definition. Standard SQL Server infrastructure - not application-specific.

---

## 2. Business Logic

No business logic. SQL Server diagram storage infrastructure.

---

## 3. Data Overview

N/A - system metadata.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | name | sysname | NO | - | CODE-BACKED | Diagram name. Unique per principal. |
| 2 | principal_id | int | NO | - | CODE-BACKED | Database principal (user) who owns the diagram. |
| 3 | diagram_id | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing diagram ID. |
| 4 | version | int | YES | - | CODE-BACKED | Diagram format version. |
| 5 | definition | varbinary(max) | YES | - | CODE-BACKED | Binary representation of the diagram layout. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.sp_creatediagram | diagram_id | SP writes | Creates diagrams |
| dbo.sp_alterdiagram | diagram_id | SP writes | Modifies diagrams |
| dbo.sp_dropdiagram | diagram_id | SP deletes | Deletes diagrams |
| dbo.sp_helpdiagrams | diagram_id | SP reads | Lists diagrams |
| dbo.fn_diagramobjects | - | Function | Checks diagram infrastructure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.sp_* diagram procedures | Stored Procedures | CRUD operations |
| dbo.fn_diagramobjects | Function | Checks existence |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | diagram_id | - | - | Active |
| UK_principal_name | NC UNIQUE | principal_id, name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UK_principal_name | UNIQUE | One diagram name per principal |

---

## 8. Sample Queries

### 8.1 List all diagrams
```sql
SELECT diagram_id, name, principal_id, version FROM dbo.sysdiagrams WITH (NOLOCK)
```

### 8.2 Diagrams for current user
```sql
SELECT name, diagram_id FROM dbo.sysdiagrams WITH (NOLOCK) WHERE principal_id = USER_ID()
```

### 8.3 Check if diagrams exist
```sql
SELECT COUNT(*) AS DiagramCount FROM dbo.sysdiagrams WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.sysdiagrams | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.sysdiagrams.sql*
