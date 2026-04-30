# dbo.sp_renamediagram

> System procedure that renames an existing SSMS database diagram, with ownership validation, duplicate name checking, and optional ownership reassignment for orphaned diagrams.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Primary output: returns 0 on success, -1 on invalid args, -2 on duplicate name, -3 on not found/permission denied |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

sp_renamediagram handles renaming of saved database diagrams in the SSMS diagram infrastructure. When a user renames a diagram through the SSMS diagram explorer, this procedure is called to update the name in dbo.sysdiagrams.

This procedure exists to support diagram management operations. Without it, users would need to delete and recreate diagrams to change their names. It validates that the new name does not collide with an existing diagram for the same owner.

The procedure resolves the caller's identity, finds the source diagram, validates permissions, checks for name conflicts, then updates the name. For db_owner members with orphaned diagrams (where the original owner principal is invalid), it also reassigns ownership to the calling principal.

---

## 2. Business Logic

### 2.1 Rename with Duplicate Detection and Orphan Recovery

**What**: Renames a diagram while preventing name collisions and recovering ownership of orphaned diagrams.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`, `@new_diagramname`

**Rules**:
- Source diagram must exist and be accessible to the caller (owner or db_owner)
- Target name must not already exist for the resolved owner (returns -2 if duplicate)
- If the original owner's principal_id is invalid (USER_NAME returns NULL) and the caller is db_owner, ownership is transferred to the caller along with the rename
- Both @diagramname and @new_diagramname must be non-NULL (returns -1 if either is NULL)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | NO | - | CODE-BACKED | Current name of the diagram to rename. Must match an existing diagram. |
| 2 | @owner_id | int | YES | NULL | CODE-BACKED | Database principal ID of the diagram owner. If NULL, defaults to the caller's DATABASE_PRINCIPAL_ID(). |
| 3 | @new_diagramname | sysname | NO | - | CODE-BACKED | New name for the diagram. Must be unique among diagrams owned by the same principal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @diagramname, @new_diagramname | dbo.sysdiagrams | DML (SELECT, UPDATE) | Locates source diagram, checks for target name conflict, updates name (and optionally principal_id) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.fn_diagramobjects | - | Reference (object_id) | Checks existence for installation verification (bitmask value 32) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_renamediagram (procedure)
└── dbo.sysdiagrams (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.sysdiagrams | Table | SELECT to find diagram and check conflicts, UPDATE to rename |

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
| EXECUTE AS 'dbo' | Execution Context | Runs under dbo context for consistent permission behavior |

---

## 8. Sample Queries

### 8.1 Rename a diagram (typically called by SSMS)
```sql
EXEC dbo.sp_renamediagram
    @diagramname = 'OldName',
    @owner_id = NULL,
    @new_diagramname = 'NewName'
```

### 8.2 List diagrams to find the one to rename
```sql
EXEC dbo.sp_helpdiagrams
```

### 8.3 Verify rename
```sql
SELECT diagram_id, name FROM dbo.sysdiagrams WITH (NOLOCK) ORDER BY name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_renamediagram | Type: Stored Procedure | Source: RecurringManager/dbo/Stored Procedures/dbo.sp_renamediagram.sql*
