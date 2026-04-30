# dbo.sp_renamediagram

> System diagram stored procedure that renames an existing database diagram in the dbo.sysdiagrams table. Used internally by SQL Server Management Studio.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Renames diagram by updating name column |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a SQL Server system-installed stored procedure that supports the database diagramming feature in SQL Server Management Studio (SSMS). It renames an existing diagram in the dbo.sysdiagrams table by updating the name column from the current name to a new name.

This procedure has no business logic relationship to WalletDB's crypto wallet operations. It is part of the standard SQL Server diagram infrastructure that gets created automatically when the database diagramming feature is first used. The procedure executes under the security context of 'dbo' (EXECUTE AS 'dbo') to ensure consistent access to the sysdiagrams table regardless of the calling user's permissions.

Before renaming, the procedure validates that the new name does not collide with an existing diagram for the same owner. If a diagram with the new name already exists, the rename is rejected to prevent accidental overwrites. The procedure also validates ownership of the original diagram.

---

## 2. Business Logic

No business logic -- this is a system utility procedure for SSMS diagram management. The procedure performs the following steps:

1. Resolves @owner_id to the current user's principal_id if NULL is passed.
2. Validates that the caller owns the diagram identified by @diagramname and @owner_id.
3. Checks dbo.sysdiagrams to ensure no existing diagram with @new_diagramname exists for the same owner.
4. If a name collision is detected, raises an error via RAISERROR.
5. Updates the name column in dbo.sysdiagrams from @diagramname to @new_diagramname for the matching row.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname (IN) | sysname | NO | - | CODE-BACKED | The current name of the diagram to rename. Must match an existing entry in dbo.sysdiagrams. |
| 2 | @new_diagramname (IN) | sysname | NO | - | CODE-BACKED | The new name for the diagram. Must not collide with an existing diagram name for the same owner. |
| 3 | @owner_id (IN) | INT | YES | NULL | CODE-BACKED | The owner (principal_id) of the diagram. Defaults to the current user's principal_id when NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Type | Relationship |
|-------------------|------|-------------|
| dbo.sysdiagrams | Table | Reads to validate existence and check name collisions, writes to update diagram name |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called internally by SQL Server Management Studio when a user renames a database diagram.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_renamediagram
  --> dbo.sysdiagrams (table, read/write)
```

### 6.1 Objects This Depends On

| Object | Type | Details |
|--------|------|---------|
| dbo.sysdiagrams | Table | Target table for diagram storage; reads to validate and check collisions, writes to update name |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Executes under EXECUTE AS 'dbo' security context.
- Validates ownership before allowing the rename operation.
- Enforces name uniqueness per owner -- prevents renaming to an already-used name.
- Uses RAISERROR to report name collisions, missing diagrams, or insufficient permissions.

---

## 8. Sample Queries

### 8.1 Rename a diagram (called by SSMS internally)
```sql
EXEC dbo.sp_renamediagram
    @diagramname = N'WalletERD',
    @new_diagramname = N'WalletERD_v2',
    @owner_id = NULL
```

### 8.2 Rename a diagram with explicit owner
```sql
EXEC dbo.sp_renamediagram
    @diagramname = N'OldDiagramName',
    @new_diagramname = N'NewDiagramName',
    @owner_id = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a standard SQL Server system procedure.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_renamediagram | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.sp_renamediagram.sql*
