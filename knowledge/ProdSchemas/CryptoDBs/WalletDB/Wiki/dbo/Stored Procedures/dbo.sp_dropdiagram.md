# dbo.sp_dropdiagram

> System diagram stored procedure that deletes an existing database diagram from the dbo.sysdiagrams table. Used internally by SQL Server Management Studio.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes diagram row by name/owner |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a SQL Server system-installed stored procedure that supports the database diagramming feature in SQL Server Management Studio (SSMS). It deletes a diagram from the dbo.sysdiagrams table by removing the row matching the specified diagram name and owner.

This procedure has no business logic relationship to WalletDB's crypto wallet operations. It is part of the standard SQL Server diagram infrastructure that gets created automatically when the database diagramming feature is first used. The procedure executes under the security context of 'dbo' (EXECUTE AS 'dbo') to ensure consistent access to the sysdiagrams table regardless of the calling user's permissions.

Before deleting, the procedure validates that the caller has ownership rights over the specified diagram. If the diagram does not exist or the caller lacks permissions, it raises an error. The deletion is permanent and removes the diagram definition entirely from the database.

---

## 2. Business Logic

No business logic -- this is a system utility procedure for SSMS diagram management. The procedure performs the following steps:

1. Resolves @owner_id to the current user's principal_id if NULL is passed.
2. Validates that the caller owns the specified diagram or has appropriate database permissions.
3. Locates the diagram row in dbo.sysdiagrams matching @diagramname and @owner_id.
4. If the diagram is not found or ownership validation fails, raises an error via RAISERROR.
5. Deletes the matching row from dbo.sysdiagrams, permanently removing the diagram definition.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname (IN) | sysname | NO | - | CODE-BACKED | The name of the diagram to delete. Must match an existing entry in dbo.sysdiagrams. |
| 2 | @owner_id (IN) | INT | YES | NULL | CODE-BACKED | The owner (principal_id) of the diagram. Defaults to the current user's principal_id when NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Type | Relationship |
|-------------------|------|-------------|
| dbo.sysdiagrams | Table | Reads to validate existence/ownership, writes to delete diagram row |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called internally by SQL Server Management Studio when a user deletes a database diagram.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_dropdiagram
  --> dbo.sysdiagrams (table, read/write)
```

### 6.1 Objects This Depends On

| Object | Type | Details |
|--------|------|---------|
| dbo.sysdiagrams | Table | Target table for diagram storage; reads to validate existence and ownership, writes to delete rows |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Executes under EXECUTE AS 'dbo' security context.
- Validates ownership before allowing deletion.
- Uses RAISERROR to report missing diagrams or insufficient permissions.
- Deletion is permanent -- no soft-delete or recycle bin mechanism.

---

## 8. Sample Queries

### 8.1 Delete a diagram owned by current user (called by SSMS internally)
```sql
EXEC dbo.sp_dropdiagram
    @diagramname = N'WalletERD',
    @owner_id = NULL
```

### 8.2 Delete a diagram with explicit owner
```sql
EXEC dbo.sp_dropdiagram
    @diagramname = N'WalletERD',
    @owner_id = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a standard SQL Server system procedure.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_dropdiagram | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.sp_dropdiagram.sql*
