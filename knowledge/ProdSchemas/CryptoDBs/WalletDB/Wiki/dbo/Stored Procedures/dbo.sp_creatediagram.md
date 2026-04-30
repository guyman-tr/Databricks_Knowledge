# dbo.sp_creatediagram

> System diagram stored procedure that creates a new database diagram in the dbo.sysdiagrams table. Used internally by SQL Server Management Studio.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts new diagram row by name/owner |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a SQL Server system-installed stored procedure that supports the database diagramming feature in SQL Server Management Studio (SSMS). It creates a new diagram entry in the dbo.sysdiagrams table by inserting a row with the diagram name, owner, version, and binary definition.

This procedure has no business logic relationship to WalletDB's crypto wallet operations. It is part of the standard SQL Server diagram infrastructure that gets created automatically when the database diagramming feature is first used. The procedure executes under the security context of 'dbo' (EXECUTE AS 'dbo') to ensure consistent access to the sysdiagrams table regardless of the calling user's permissions.

Before inserting, the procedure checks whether a diagram with the same name and owner already exists. If a duplicate is found, it raises an error using RAISERROR to prevent overwriting an existing diagram. Users must use sp_alterdiagram to update existing diagrams.

---

## 2. Business Logic

No business logic -- this is a system utility procedure for SSMS diagram management. The procedure performs the following steps:

1. Resolves @owner_id to the current user's principal_id if NULL is passed.
2. Checks dbo.sysdiagrams for an existing diagram with the same @diagramname and @owner_id combination.
3. If a duplicate is found, raises an error via RAISERROR indicating the diagram name already exists for that owner.
4. If no duplicate exists, inserts a new row into dbo.sysdiagrams with the provided name, owner_id, version, and definition values.
5. The diagram_id (identity column) is automatically assigned by the table.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname (IN) | sysname | NO | - | CODE-BACKED | The name of the new diagram to create. Must be unique per owner in dbo.sysdiagrams. |
| 2 | @owner_id (IN) | INT | YES | NULL | CODE-BACKED | The owner (principal_id) of the diagram. Defaults to the current user's principal_id when NULL. |
| 3 | @version (IN) | INT | NO | - | CODE-BACKED | The version number for the new diagram. Corresponds to the version column in dbo.sysdiagrams. |
| 4 | @definition (IN) | VARBINARY(MAX) | NO | - | CODE-BACKED | The binary blob containing the diagram layout and metadata as serialized by SSMS. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Type | Relationship |
|-------------------|------|-------------|
| dbo.sysdiagrams | Table | Reads to check duplicates, writes to insert new diagram row |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called internally by SQL Server Management Studio when a user creates a new database diagram.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_creatediagram
  --> dbo.sysdiagrams (table, read/write)
```

### 6.1 Objects This Depends On

| Object | Type | Details |
|--------|------|---------|
| dbo.sysdiagrams | Table | Target table for diagram storage; reads to check for duplicates, writes to insert new rows |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Executes under EXECUTE AS 'dbo' security context.
- Enforces uniqueness of diagram name per owner via duplicate check before insert.
- Uses RAISERROR to report duplicate diagram names.

---

## 8. Sample Queries

### 8.1 Create a new diagram (called by SSMS internally)
```sql
EXEC dbo.sp_creatediagram
    @diagramname = N'WalletERD',
    @owner_id = NULL,
    @version = 1,
    @definition = 0x -- binary diagram data
```

### 8.2 Create a diagram with explicit owner
```sql
EXEC dbo.sp_creatediagram
    @diagramname = N'TransactionFlowDiagram',
    @owner_id = 1,
    @version = 1,
    @definition = 0x -- binary diagram data
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a standard SQL Server system procedure.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_creatediagram | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.sp_creatediagram.sql*
