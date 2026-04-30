# dbo.sp_creatediagram

> Stored procedure that creates a new database diagram by inserting a name, version, and binary layout definition into the sysdiagrams table.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.sp_creatediagram is a SQL Server system-generated stored procedure that creates a new database diagram entry in dbo.sysdiagrams. It is automatically created when database diagramming is first used in SSMS. This is not a business object -- it supports the SSMS visual diagram feature.

When a user creates a new diagram in SSMS and saves it, this procedure is called to persist the diagram's name, owner, format version, and the binary blob representing the visual layout (table positions, relationship lines, annotations).

---

## 2. Business Logic

### 2.1 Diagram Creation

**What**: Inserts a new diagram record into dbo.sysdiagrams after validation.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`, `@version`, `@definition`

**Rules**:
- Executes WITH EXECUTE AS 'dbo'
- If @owner_id is NULL, defaults to the caller's database principal_id
- Validates that no diagram with the same name already exists for the same owner
- If a duplicate name is found for the owner, raises an error and does not insert
- On success, inserts the row and returns the new diagram_id via @@IDENTITY
- The definition parameter contains the serialized SSMS diagram binary data

### 2.2 Validation Rules

| Check | Action on Failure |
|-------|-------------------|
| Duplicate name for same owner | Raises error, aborts insert |
| Missing owner_id | Defaults to caller's principal_id |

---

## 3. Data Overview

N/A for system procedure. This procedure writes to dbo.sysdiagrams.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | NO | - | VERIFIED | Name for the new diagram. Must be unique per owner. |
| 2 | @owner_id | int | YES | NULL | VERIFIED | Principal_id of the diagram owner. NULL defaults to caller's principal_id. |
| 3 | @version | int | NO | - | VERIFIED | Diagram format version number. |
| 4 | @definition | varbinary(max) | NO | - | VERIFIED | Binary blob containing the serialized SSMS diagram layout. |

### Output

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | diagram_id | int | The identity value of the newly created diagram (via @@IDENTITY) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.sysdiagrams | Table | Inserts new diagram records |

### 5.2 Referenced By (other objects point to this)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.fn_diagramobjects | Function | Checks for existence of this procedure (bit 16) |

Called by SSMS when a user saves a newly created diagram.

---

## 6. Dependencies

### 6.0 Dependency Chain

dbo.sp_creatediagram -> dbo.sysdiagrams

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.sysdiagrams | Table | Target for INSERT operations |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

- **Execution Context**: WITH EXECUTE AS 'dbo'
- **Transaction Handling**: Single INSERT statement; implicit transaction
- **Side Effects**: Inserts one row into dbo.sysdiagrams
- **Identity Return**: Uses @@IDENTITY to return the generated diagram_id
- **Concurrency**: Name uniqueness per owner is checked before insert (potential race condition under high concurrency, but diagrams are rarely created concurrently)

---

## 8. Sample Queries

### 8.1 Create a new diagram
```sql
EXEC dbo.sp_creatediagram
    @diagramname = N'ERD_Orders',
    @owner_id = NULL,
    @version = 1,
    @definition = 0x
```

### 8.2 Create a diagram with explicit owner
```sql
DECLARE @new_id INT
EXEC dbo.sp_creatediagram
    @diagramname = N'ERD_Products',
    @owner_id = 1,
    @version = 1,
    @definition = 0x
SET @new_id = @@IDENTITY
PRINT 'Created diagram with ID: ' + CAST(@new_id AS VARCHAR(10))
```

### 8.3 Verify diagram was created
```sql
EXEC dbo.sp_creatediagram
    @diagramname = N'ERD_Test',
    @owner_id = NULL,
    @version = 1,
    @definition = 0x

EXEC dbo.sp_helpdiagrams @diagramname = N'ERD_Test'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Standard SQL Server system procedure.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: dbo.sp_creatediagram | Type: Stored Procedure | Source: RecurringInvestment/dbo/Stored Procedures/dbo.sp_creatediagram.sql*
