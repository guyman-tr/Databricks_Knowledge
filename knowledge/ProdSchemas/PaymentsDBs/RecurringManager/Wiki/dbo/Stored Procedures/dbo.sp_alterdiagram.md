# dbo.sp_alterdiagram

> System procedure that updates an existing SSMS database diagram's binary definition and version, with ownership validation to prevent unauthorized modifications.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Primary output: returns 0 on success, -1 on invalid args, -3 on permission denied |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_alterdiagram is one of seven system procedures that manage SSMS database diagrams stored in dbo.sysdiagrams. It handles the "save" operation when a user modifies an existing diagram in the SSMS visual designer - updating the binary definition blob and optionally the version number.

This procedure exists because SSMS stores diagram data inside the database itself (in dbo.sysdiagrams) rather than externally. Without it, users could not save changes to existing diagrams through the SSMS diagram designer. It is never called directly by application code or business procedures.

When a user saves a modified diagram in SSMS, the client calls sp_alterdiagram with the diagram name, the updated binary layout, and the new version. The procedure validates ownership (only the owner or db_owner can modify), applies invalid-principal recovery for db_owner members, then updates the definition. It uses EXECUTE AS 'dbo' for consistent permission behavior.

---

## 2. Business Logic

### 2.1 Ownership-Based Access Control

**What**: Only the diagram owner or db_owner role members can modify a diagram, with automatic ownership recovery for orphaned diagrams.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`, `@version`, `@definition`

**Rules**:
- The caller's DATABASE_PRINCIPAL_ID() is resolved via EXECUTE AS CALLER
- If @owner_id is NULL, defaults to the caller's principal
- Diagram is looked up by (principal_id, name) combination
- If the found diagram's principal_id differs from the caller AND the caller is NOT db_owner, access is denied (-3)
- If db_owner and the original principal_id is invalid (USER_NAME returns NULL), the diagram is reassigned to the calling principal
- Definition is always updated; version is updated only if @version is non-NULL

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | NO | - | CODE-BACKED | Name of the diagram to update. Must match an existing diagram owned by @owner_id. If NULL, raises error 'Invalid ARG' and returns -1. |
| 2 | @owner_id | int | YES | NULL | CODE-BACKED | Database principal ID of the diagram owner. If NULL, defaults to the caller's DATABASE_PRINCIPAL_ID(). Allows db_owner members to update diagrams owned by other users. |
| 3 | @version | int | NO | - | CODE-BACKED | New version number for the diagram format. Updated only if non-NULL. Tracks the SSMS diagram serialization format version. |
| 4 | @definition | varbinary(max) | NO | - | CODE-BACKED | Updated binary-serialized diagram layout data. Contains the complete visual representation (table positions, relationship lines, zoom, display settings) as produced by the SSMS diagram designer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @diagramname, @owner_id | dbo.sysdiagrams | DML (SELECT, UPDATE) | Looks up diagram by (principal_id, name), then updates definition and optionally version and principal_id |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.fn_diagramobjects | - | Reference (object_id) | Checks existence for installation verification (bitmask value 64) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_alterdiagram (procedure)
└── dbo.sysdiagrams (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.sysdiagrams | Table | SELECT to find diagram, UPDATE to modify definition/version/principal_id |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.fn_diagramobjects | Function | Checks existence via object_id() |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS 'dbo' | Execution Context | Runs under dbo context for consistent permission checks on sysdiagrams |

---

## 8. Sample Queries

### 8.1 View which diagrams exist before altering
```sql
EXEC dbo.sp_helpdiagrams
```

### 8.2 Alter a diagram (typically called by SSMS, not manually)
```sql
-- SSMS calls this internally when saving a diagram
EXEC dbo.sp_alterdiagram
    @diagramname = 'MyDiagram',
    @owner_id = NULL,
    @version = 1,
    @definition = 0x -- binary data from SSMS
```

### 8.3 Check diagram installation status
```sql
SELECT dbo.fn_diagramobjects() AS InstalledBitmask
-- Bit 64 = sp_alterdiagram exists
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.3/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_alterdiagram | Type: Stored Procedure | Source: RecurringManager/dbo/Stored Procedures/dbo.sp_alterdiagram.sql*
