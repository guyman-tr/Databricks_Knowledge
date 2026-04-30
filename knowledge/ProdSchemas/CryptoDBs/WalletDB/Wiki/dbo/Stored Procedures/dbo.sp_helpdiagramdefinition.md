# dbo.sp_helpdiagramdefinition

> System diagram stored procedure that returns the binary definition of a database diagram from the dbo.sysdiagrams table. Used internally by SQL Server Management Studio.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns diagram definition by name/owner |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a SQL Server system-installed stored procedure that supports the database diagramming feature in SQL Server Management Studio (SSMS). It retrieves the binary definition (layout data) and version of a specified diagram from the dbo.sysdiagrams table.

This procedure has no business logic relationship to WalletDB's crypto wallet operations. It is part of the standard SQL Server diagram infrastructure that gets created automatically when the database diagramming feature is first used. The procedure executes under the security context of 'dbo' (EXECUTE AS 'dbo') to ensure consistent access to the sysdiagrams table regardless of the calling user's permissions.

SSMS calls this procedure when opening a saved diagram for editing. The returned binary definition contains the serialized diagram layout including table positions, relationships displayed, annotation positions, and visual styling. The version column indicates the diagram format version used.

---

## 2. Business Logic

No business logic -- this is a system utility procedure for SSMS diagram management. The procedure performs the following steps:

1. Resolves @owner_id to the current user's principal_id if NULL is passed.
2. Queries dbo.sysdiagrams for the row matching @diagramname and @owner_id.
3. Returns a result set containing the version and definition columns for the matched diagram.
4. If no matching diagram is found, returns an empty result set.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname (IN) | sysname | NO | - | CODE-BACKED | The name of the diagram whose definition to retrieve. |
| 2 | @owner_id (IN) | INT | YES | NULL | CODE-BACKED | The owner (principal_id) of the diagram. Defaults to the current user's principal_id when NULL. |

### Output Columns

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | version | INT | The diagram format version number. |
| 2 | definition | VARBINARY(MAX) | The binary blob containing the serialized diagram layout and metadata. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Type | Relationship |
|-------------------|------|-------------|
| dbo.sysdiagrams | Table | Reads diagram definition and version columns |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called internally by SQL Server Management Studio when opening a saved database diagram.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_helpdiagramdefinition
  --> dbo.sysdiagrams (table, read)
```

### 6.1 Objects This Depends On

| Object | Type | Details |
|--------|------|---------|
| dbo.sysdiagrams | Table | Source table for diagram data; reads version and definition columns |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Executes under EXECUTE AS 'dbo' security context.
- Read-only operation -- does not modify dbo.sysdiagrams.
- Returns an empty result set (not an error) when the specified diagram is not found.

---

## 8. Sample Queries

### 8.1 Retrieve diagram definition for current user (called by SSMS internally)
```sql
EXEC dbo.sp_helpdiagramdefinition
    @diagramname = N'WalletERD',
    @owner_id = NULL
```

### 8.2 Retrieve diagram definition with explicit owner
```sql
EXEC dbo.sp_helpdiagramdefinition
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
*Object: dbo.sp_helpdiagramdefinition | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.sp_helpdiagramdefinition.sql*
