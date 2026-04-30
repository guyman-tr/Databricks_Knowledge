# dbo.sp_alterdiagram

> System diagram stored procedure that updates an existing database diagram in the dbo.sysdiagrams table. Used internally by SQL Server Management Studio.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates diagram definition by name/owner |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a SQL Server system-installed stored procedure that supports the database diagramming feature in SQL Server Management Studio (SSMS). It updates an existing diagram's binary definition, version, and optionally its owner in the dbo.sysdiagrams table.

This procedure has no business logic relationship to WalletDB's crypto wallet operations. It is part of the standard SQL Server diagram infrastructure that gets created automatically when the database diagramming feature is first used. The procedure executes under the security context of 'dbo' (EXECUTE AS 'dbo') to ensure consistent access to the sysdiagrams table regardless of the calling user's permissions.

When invoked, it validates that the specified diagram exists and that the caller has ownership rights before performing the update. If the diagram does not exist or the caller lacks permissions, it raises an error using RAISERROR.

---

## 2. Business Logic

No business logic -- this is a system utility procedure for SSMS diagram management. The procedure performs the following steps:

1. Resolves @owner_id to the current user if NULL is passed.
2. Validates that the caller has ownership of the specified diagram or has appropriate database permissions.
3. Checks that the diagram identified by @diagramname and @owner_id exists in dbo.sysdiagrams.
4. Updates the definition (varbinary(max) blob containing the diagram layout), version, and owner_id columns in dbo.sysdiagrams.
5. Raises errors via RAISERROR if the diagram is not found, if arguments are invalid, or if the caller lacks permissions.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname (IN) | sysname | NO | - | CODE-BACKED | The name of the diagram to update. Must match an existing entry in dbo.sysdiagrams. |
| 2 | @owner_id (IN) | INT | YES | NULL | CODE-BACKED | The owner (principal_id) of the diagram. Defaults to the current user's principal_id when NULL. |
| 3 | @version (IN) | INT | NO | - | CODE-BACKED | The new version number to set for the diagram. Corresponds to the version column in dbo.sysdiagrams. |
| 4 | @definition (IN) | VARBINARY(MAX) | NO | - | CODE-BACKED | The binary blob containing the updated diagram layout and metadata as serialized by SSMS. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Type | Relationship |
|-------------------|------|-------------|
| dbo.sysdiagrams | Table | Reads and writes diagram rows (UPDATE) |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called internally by SQL Server Management Studio when a user saves changes to an existing database diagram.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_alterdiagram
  --> dbo.sysdiagrams (table, read/write)
```

### 6.1 Objects This Depends On

| Object | Type | Details |
|--------|------|---------|
| dbo.sysdiagrams | Table | Target table for diagram storage; reads to validate existence, writes to update definition/version/owner |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Executes under EXECUTE AS 'dbo' security context.
- Validates ownership before allowing updates.
- Uses RAISERROR to report invalid arguments, missing diagrams, or insufficient permissions.

---

## 8. Sample Queries

### 8.1 Update an existing diagram (called by SSMS internally)
```sql
EXEC dbo.sp_alterdiagram
    @diagramname = N'WalletERD',
    @owner_id = NULL,
    @version = 2,
    @definition = 0x -- binary diagram data
```

### 8.2 Update a diagram with explicit owner
```sql
EXEC dbo.sp_alterdiagram
    @diagramname = N'WalletERD',
    @owner_id = 1,
    @version = 3,
    @definition = 0x -- binary diagram data
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a standard SQL Server system procedure.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_alterdiagram | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.sp_alterdiagram.sql*
