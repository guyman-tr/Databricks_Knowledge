# dbo.sp_helpdiagramdefinition

> Stored procedure that retrieves the binary definition and version of a specific database diagram, enabling SSMS to render the visual diagram layout.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.sp_helpdiagramdefinition is a SQL Server system-generated stored procedure that retrieves the full definition of a database diagram, including its version number and the binary blob that encodes the visual layout (table positions, relationships, annotations). This is not a business object -- it supports the SSMS visual diagram feature.

The binary definition contains the serialized SSMS diagram state, including which tables are displayed, their positions on the canvas, visible columns, and relationship lines. This data is opaque and consumed only by SSMS.

---

## 2. Business Logic

### 2.1 Diagram Definition Retrieval

**What**: Fetches the version and binary definition for a named diagram.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`

**Rules**:
- Executes WITH EXECUTE AS 'dbo' with EXECUTE AS CALLER for permission validation
- Looks up the diagram in dbo.sysdiagrams by name (and optionally owner_id)
- If @owner_id is NULL, defaults to the caller's principal_id for non-db_owner users
- db_owner members can retrieve any diagram; other users can only retrieve their own
- Returns the version (int) and definition (varbinary(max)) columns
- If the diagram is not found or the user lacks permission, returns an empty result set

### 2.2 Permission Model

| Role | Access |
|------|--------|
| db_owner | Can retrieve any diagram definition |
| Other users | Can only retrieve diagrams they own |

---

## 3. Data Overview

N/A for system procedure. This procedure reads from dbo.sysdiagrams.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | NO | - | VERIFIED | Name of the diagram to retrieve. Required parameter. |
| 2 | @owner_id | int | YES | NULL | VERIFIED | Principal_id of the diagram owner. NULL defaults to caller for non-db_owner users. |

### Result Set

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | version | int | Diagram format version number |
| 2 | definition | varbinary(max) | Binary blob containing the serialized SSMS diagram layout |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.sysdiagrams | Table | Reads version and definition columns |

### 5.2 Referenced By (other objects point to this)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.fn_diagramobjects | Function | Checks for existence of this procedure (bit 8) |

Called by SSMS when opening a diagram for viewing or editing.

---

## 6. Dependencies

### 6.0 Dependency Chain

dbo.sp_helpdiagramdefinition -> dbo.sysdiagrams

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.sysdiagrams | Table | Source of diagram definitions |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

- **Execution Context**: WITH EXECUTE AS 'dbo'; uses EXECUTE AS CALLER for permission checks
- **Transaction Handling**: Read-only, no transactions
- **Side Effects**: None (SELECT only)
- **Data Size**: The definition column can be large (megabytes) for diagrams with many tables
- **Security**: IS_MEMBER('db_owner') determines access scope

---

## 8. Sample Queries

### 8.1 Retrieve a diagram definition
```sql
EXEC dbo.sp_helpdiagramdefinition @diagramname = N'ERD_Main'
```

### 8.2 Retrieve a specific owner's diagram
```sql
EXEC dbo.sp_helpdiagramdefinition @diagramname = N'ERD_Main', @owner_id = 1
```

### 8.3 Check diagram version
```sql
DECLARE @ver TABLE (version int, definition varbinary(max))
INSERT INTO @ver
EXEC dbo.sp_helpdiagramdefinition @diagramname = N'ERD_Main'
SELECT version FROM @ver
```

### 8.4 Check definition size
```sql
DECLARE @def TABLE (version int, definition varbinary(max))
INSERT INTO @def
EXEC dbo.sp_helpdiagramdefinition @diagramname = N'ERD_Main'
SELECT version, DATALENGTH(definition) AS DefinitionSizeBytes FROM @def
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Standard SQL Server system procedure.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: dbo.sp_helpdiagramdefinition | Type: Stored Procedure | Source: RecurringInvestment/dbo/Stored Procedures/dbo.sp_helpdiagramdefinition.sql*
