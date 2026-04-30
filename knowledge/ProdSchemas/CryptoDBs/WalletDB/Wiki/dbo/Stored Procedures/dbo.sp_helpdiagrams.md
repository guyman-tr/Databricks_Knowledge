# dbo.sp_helpdiagrams

> System diagram stored procedure that lists available database diagrams from the dbo.sysdiagrams table. Used internally by SQL Server Management Studio.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Lists diagrams with optional name/owner filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a SQL Server system-installed stored procedure that supports the database diagramming feature in SQL Server Management Studio (SSMS). It returns a list of available diagrams from the dbo.sysdiagrams table, optionally filtered by diagram name and/or owner.

This procedure has no business logic relationship to WalletDB's crypto wallet operations. It is part of the standard SQL Server diagram infrastructure that gets created automatically when the database diagramming feature is first used. The procedure executes under the security context of 'dbo' (EXECUTE AS 'dbo') to ensure consistent access to the sysdiagrams table regardless of the calling user's permissions.

SSMS calls this procedure when populating the database diagrams node in Object Explorer, showing users which diagrams are available for viewing or editing. When called without parameters, it returns all diagrams accessible to the current user. When parameters are supplied, the results are filtered accordingly.

---

## 2. Business Logic

No business logic -- this is a system utility procedure for SSMS diagram management. The procedure performs the following steps:

1. Resolves @owner_id to the current user's principal_id if NULL is passed and @diagramname is also NULL (list all for current user).
2. Queries dbo.sysdiagrams with optional filtering by @diagramname and/or @owner_id.
3. Returns a result set containing diagram metadata (name, diagram_id, owner_id, version).
4. If no diagrams match the filter criteria, returns an empty result set.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname (IN) | sysname | YES | NULL | CODE-BACKED | Optional diagram name filter. When NULL, all diagrams matching @owner_id are returned. |
| 2 | @owner_id (IN) | INT | YES | NULL | CODE-BACKED | Optional owner (principal_id) filter. When NULL, diagrams for the current user are returned. |

### Output Columns

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Database | sysname | The database name where the diagram resides. |
| 2 | Name | sysname | The diagram name. |
| 3 | ID | INT | The diagram_id (identity) from dbo.sysdiagrams. |
| 4 | Owner | sysname | The database user name of the diagram owner. |
| 5 | OwnerID | INT | The principal_id of the diagram owner. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Type | Relationship |
|-------------------|------|-------------|
| dbo.sysdiagrams | Table | Reads diagram metadata for listing |

### 5.2 Referenced By (other objects point to this)

No database objects reference this procedure. Called internally by SQL Server Management Studio when browsing the database diagrams node.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.sp_helpdiagrams
  --> dbo.sysdiagrams (table, read)
```

### 6.1 Objects This Depends On

| Object | Type | Details |
|--------|------|---------|
| dbo.sysdiagrams | Table | Source table for diagram metadata; reads name, diagram_id, owner_id, and version columns |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Executes under EXECUTE AS 'dbo' security context.
- Read-only operation -- does not modify dbo.sysdiagrams.
- Returns an empty result set (not an error) when no diagrams match the filter criteria.
- Both parameters are optional, allowing flexible listing and filtering.

---

## 8. Sample Queries

### 8.1 List all diagrams for current user (called by SSMS internally)
```sql
EXEC dbo.sp_helpdiagrams
```

### 8.2 List a specific diagram by name
```sql
EXEC dbo.sp_helpdiagrams
    @diagramname = N'WalletERD',
    @owner_id = NULL
```

### 8.3 List all diagrams for a specific owner
```sql
EXEC dbo.sp_helpdiagrams
    @diagramname = NULL,
    @owner_id = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a standard SQL Server system procedure.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 6.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_helpdiagrams | Type: Stored Procedure | Source: WalletDB/dbo/Stored Procedures/dbo.sp_helpdiagrams.sql*
