# dbo.sp_helpdiagrams

> Stored procedure that lists database diagrams with optional filtering by name and owner, enforcing ownership-based access control.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.sp_helpdiagrams is a SQL Server system-generated stored procedure that retrieves a list of database diagrams stored in dbo.sysdiagrams. It supports optional filtering by diagram name and owner ID. This is not a business object -- it supports the SSMS visual diagram feature by providing diagram metadata to the diagramming UI.

The procedure enforces security: members of the db_owner role can see all diagrams, while other users can only see diagrams they own. This ensures diagram privacy in shared database environments.

---

## 2. Business Logic

### 2.1 Diagram Listing with Access Control

**What**: Retrieves diagram metadata from sysdiagrams with permission-based filtering.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`

**Rules**:
- Executes WITH EXECUTE AS 'dbo' for the main body, then uses EXECUTE AS CALLER to check the actual caller's permissions
- Members of db_owner role see all diagrams regardless of ownership
- Non-db_owner users see only diagrams where principal_id matches their database principal ID
- If @diagramname is provided, results are filtered by exact name match
- If @owner_id is provided, results are filtered by that owner; if NULL, defaults to the caller's principal ID for non-db_owner users
- Returns columns: Database (DB_NAME), Name, ID (diagram_id), Owner (USER_NAME), OwnerID (principal_id)

### 2.2 Permission Model

| Role | Visibility |
|------|-----------|
| db_owner | All diagrams in the database |
| Other users | Only diagrams owned by the calling user |

---

## 3. Data Overview

N/A for system procedure. This procedure reads from dbo.sysdiagrams.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | YES | NULL | VERIFIED | Optional filter: exact diagram name to search for. |
| 2 | @owner_id | int | YES | NULL | VERIFIED | Optional filter: principal_id of the diagram owner. NULL defaults to caller for non-db_owner. |

### Result Set

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Database | sysname | Database name (DB_NAME()) |
| 2 | Name | sysname | Diagram name |
| 3 | ID | int | Diagram identifier (diagram_id) |
| 4 | Owner | sysname | Owner display name (USER_NAME of principal_id) |
| 5 | OwnerID | int | Owner principal_id |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.sysdiagrams | Table | Reads diagram metadata from this table |

### 5.2 Referenced By (other objects point to this)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.fn_diagramobjects | Function | Checks for existence of this procedure (bit 4) |

Called by SSMS to populate the diagram browser/list.

---

## 6. Dependencies

### 6.0 Dependency Chain

dbo.sp_helpdiagrams -> dbo.sysdiagrams

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.sysdiagrams | Table | Source of diagram metadata |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

- **Execution Context**: WITH EXECUTE AS 'dbo'; uses EXECUTE AS CALLER internally for permission checks
- **Transaction Handling**: Read-only, no transactions
- **Side Effects**: None (SELECT only)
- **Security**: IS_MEMBER('db_owner') determines visibility scope

---

## 8. Sample Queries

### 8.1 List all diagrams (requires db_owner)
```sql
EXEC dbo.sp_helpdiagrams
```

### 8.2 Find a specific diagram by name
```sql
EXEC dbo.sp_helpdiagrams @diagramname = N'ERD_Main'
```

### 8.3 List diagrams for a specific owner
```sql
EXEC dbo.sp_helpdiagrams @owner_id = 1
```

### 8.4 Find diagram by name and owner
```sql
EXEC dbo.sp_helpdiagrams @diagramname = N'ERD_Main', @owner_id = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Standard SQL Server system procedure.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: dbo.sp_helpdiagrams | Type: Stored Procedure | Source: RecurringInvestment/dbo/Stored Procedures/dbo.sp_helpdiagrams.sql*
