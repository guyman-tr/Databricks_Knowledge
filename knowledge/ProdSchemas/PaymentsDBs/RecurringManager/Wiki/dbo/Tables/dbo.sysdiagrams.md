# dbo.sysdiagrams

> SQL Server system table that stores database diagram definitions created through SQL Server Management Studio (SSMS), enabling visual representation of table relationships.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | diagram_id (INT, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) + 1 unique constraint |

---

## 1. Business Meaning

sysdiagrams is a SQL Server system infrastructure table that stores visual database diagram definitions created through SSMS (SQL Server Management Studio). Each row represents a single saved diagram, containing the binary serialized layout data and metadata about ownership.

This table exists because SSMS persists database diagrams as binary blobs within the database itself rather than in external files. The diagrams provide visual documentation of table relationships and are created by developers or DBAs using the SSMS diagram designer. Without this table, SSMS would have no persistent storage for database diagrams.

The table is managed entirely by SSMS and the companion dbo.sp_*diagram stored procedures (sp_creatediagram, sp_alterdiagram, sp_dropdiagram, sp_helpdiagrams, sp_helpdiagramdefinition, sp_renamediagram, sp_upgraddiagrams). These procedures handle CRUD operations and enforce ownership rules. The table is currently empty in this database, indicating no SSMS diagrams have been saved.

---

## 2. Business Logic

### 2.1 Diagram Ownership Model

**What**: Each diagram is owned by the database principal (user) who created it, with db_owner members having elevated access.

**Columns/Parameters Involved**: `principal_id`, `name`, `diagram_id`

**Rules**:
- Each diagram is uniquely identified by the combination of owner (principal_id) and diagram name - enforced by UK_principal_name
- Only the diagram owner or db_owner members can modify/delete a diagram
- The sp_*diagram procedures enforce ownership checks via EXECUTE AS CALLER and IS_MEMBER('db_owner')
- db_owner members can reassign diagram ownership when the original owner's principal becomes invalid

**Diagram**:
```
[SSMS User] --creates--> sp_creatediagram --INSERT--> sysdiagrams
[SSMS User] --opens----> sp_helpdiagramdefinition --SELECT--> sysdiagrams
[SSMS User] --saves----> sp_alterdiagram --UPDATE--> sysdiagrams
[SSMS User] --deletes--> sp_dropdiagram --DELETE--> sysdiagrams
[SSMS User] --renames--> sp_renamediagram --UPDATE--> sysdiagrams
```

---

## 3. Data Overview

Table is currently empty (0 rows). No SSMS database diagrams have been saved in the RecurringManager database.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | name | sysname (nvarchar(128)) | NO | - | CODE-BACKED | User-assigned name for the database diagram (e.g., "Recurring Payment Flow", "Scheduler Tables"). Must be unique per owner, enforced by UK_principal_name constraint. Used as the display name in SSMS diagram explorer. |
| 2 | principal_id | int | NO | - | CODE-BACKED | Database principal ID of the user who owns the diagram. Maps to sys.database_principals. Combined with name in UK_principal_name to allow different users to have diagrams with the same name. The sp_*diagram procedures resolve this via DATABASE_PRINCIPAL_ID() for the calling user. |
| 3 | diagram_id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. Internal identifier used by SSMS and the sp_*diagram procedures to locate specific diagrams for read/update/delete operations. Not exposed to end users. |
| 4 | version | int | YES | - | CODE-BACKED | Diagram format version number. Tracks the SSMS diagram serialization format. Set to 0 for diagrams migrated from the legacy dtproperties format by sp_upgraddiagrams. Updated when the diagram is saved via sp_alterdiagram. |
| 5 | definition | varbinary(max) | YES | - | CODE-BACKED | Binary-serialized diagram layout data. Contains the complete visual representation including table positions, relationship lines, zoom level, and display settings as created by the SSMS diagram designer. Opaque binary format - only interpretable by SSMS. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. principal_id implicitly references sys.database_principals but no FK constraint is declared.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.sp_alterdiagram | - | DML (UPDATE) | Updates diagram definition and version |
| dbo.sp_creatediagram | - | DML (INSERT) | Creates new diagram records |
| dbo.sp_dropdiagram | - | DML (DELETE) | Removes diagram records |
| dbo.sp_helpdiagramdefinition | - | DML (SELECT) | Reads diagram definition for SSMS |
| dbo.sp_helpdiagrams | - | DML (SELECT) | Lists diagrams for SSMS explorer |
| dbo.sp_renamediagram | - | DML (UPDATE) | Renames diagrams and reassigns ownership |
| dbo.sp_upgraddiagrams | - | DML (INSERT) | Migrates diagrams from legacy dtproperties format |
| dbo.fn_diagramobjects | - | Reference (object_id) | Checks existence of sysdiagrams via object_id() for installation verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.sp_alterdiagram | Stored Procedure | Updates diagram definition (UPDATE) |
| dbo.sp_creatediagram | Stored Procedure | Creates new diagrams (INSERT) |
| dbo.sp_dropdiagram | Stored Procedure | Deletes diagrams (DELETE) |
| dbo.sp_helpdiagramdefinition | Stored Procedure | Reads diagram binary data (SELECT) |
| dbo.sp_helpdiagrams | Stored Procedure | Lists all diagrams (SELECT) |
| dbo.sp_renamediagram | Stored Procedure | Renames diagrams (UPDATE) |
| dbo.sp_upgraddiagrams | Stored Procedure | Migrates legacy diagrams (INSERT) |
| dbo.fn_diagramobjects | Function | Checks table existence for installation status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | diagram_id ASC | - | - | Active |
| UK_principal_name | NONCLUSTERED UNIQUE | principal_id ASC, name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (diagram_id) | PRIMARY KEY | Ensures each diagram has a unique identity for CRUD operations |
| UK_principal_name | UNIQUE | Prevents the same user from having two diagrams with the same name |

---

## 8. Sample Queries

### 8.1 List all saved diagrams with owner names
```sql
SELECT d.diagram_id, d.name AS DiagramName, dp.name AS OwnerName, d.version
FROM dbo.sysdiagrams d WITH (NOLOCK)
JOIN sys.database_principals dp WITH (NOLOCK) ON d.principal_id = dp.principal_id
ORDER BY d.name
```

### 8.2 Check if diagram infrastructure is installed
```sql
SELECT dbo.fn_diagramobjects() AS InstalledObjectsBitmask
-- Returns bitmask: 1=sp_upgraddiagrams, 2=sysdiagrams, 4=sp_helpdiagrams,
-- 8=sp_helpdiagramdefinition, 16=sp_creatediagram, 32=sp_renamediagram,
-- 64=sp_alterdiagram, 128=sp_dropdiagram. Full install = 255.
```

### 8.3 Find diagrams for the current user
```sql
SELECT diagram_id, name, version
FROM dbo.sysdiagrams WITH (NOLOCK)
WHERE principal_id = DATABASE_PRINCIPAL_ID()
ORDER BY name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sysdiagrams | Type: Table | Source: RecurringManager/dbo/Tables/dbo.sysdiagrams.sql*
