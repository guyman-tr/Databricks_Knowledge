# dbo.sp_alterdiagram

> Stored procedure that updates the definition (binary layout) and version of an existing database diagram in the sysdiagrams table.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.sp_alterdiagram is a SQL Server system-generated stored procedure that updates an existing database diagram's definition and version in dbo.sysdiagrams. It is automatically created when database diagramming is first used in SSMS. This is not a business object -- it supports the SSMS visual diagram feature.

When a user modifies a diagram in SSMS (adds/removes tables, repositions elements, changes visible columns) and saves, this procedure is called to persist the updated binary layout and version number. It enforces ownership-based access control to prevent unauthorized modifications.

---

## 2. Business Logic

### 2.1 Diagram Definition Update

**What**: Updates the version and definition columns in dbo.sysdiagrams for a named diagram.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`, `@version`, `@definition`

**Rules**:
- Executes WITH EXECUTE AS 'dbo'
- If @owner_id is NULL, defaults to the caller's database principal_id
- Verifies the target diagram exists for the specified owner
- db_owner members can alter any diagram; other users can only alter their own
- On validation failure, raises an appropriate error
- On success, updates both the version and definition columns in sysdiagrams
- The definition parameter contains the full serialized SSMS diagram binary (not a delta/patch)

### 2.2 Permission Model

| Role | Access |
|------|--------|
| db_owner | Can alter any diagram |
| Diagram owner | Can alter their own diagrams |
| Other users | Access denied |

---

## 3. Data Overview

N/A for system procedure. This procedure updates dbo.sysdiagrams.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | NO | - | VERIFIED | Name of the diagram to update. |
| 2 | @owner_id | int | YES | NULL | VERIFIED | Principal_id of the diagram owner. NULL defaults to caller's principal_id. |
| 3 | @version | int | NO | - | VERIFIED | New version number for the diagram. |
| 4 | @definition | varbinary(max) | NO | - | VERIFIED | New binary blob containing the updated serialized SSMS diagram layout. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.sysdiagrams | Table | Updates version and definition columns |

### 5.2 Referenced By (other objects point to this)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.fn_diagramobjects | Function | Checks for existence of this procedure (bit 64) |

Called by SSMS when a user saves changes to an existing diagram.

---

## 6. Dependencies

### 6.0 Dependency Chain

dbo.sp_alterdiagram -> dbo.sysdiagrams

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.sysdiagrams | Table | Target for UPDATE operations |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

- **Execution Context**: WITH EXECUTE AS 'dbo'
- **Transaction Handling**: Single UPDATE statement; implicit transaction
- **Side Effects**: Updates version and definition for one row in dbo.sysdiagrams
- **Data Size**: The @definition parameter can be large (megabytes) for diagrams with many tables; each save replaces the full blob
- **Security**: Ownership check via principal_id comparison; IS_MEMBER('db_owner') bypass
- **Concurrency**: If two users edit the same diagram simultaneously, last writer wins

---

## 8. Sample Queries

### 8.1 Update a diagram definition
```sql
EXEC dbo.sp_alterdiagram
    @diagramname = N'ERD_Main',
    @owner_id = NULL,
    @version = 2,
    @definition = 0x
```

### 8.2 Update with explicit owner
```sql
EXEC dbo.sp_alterdiagram
    @diagramname = N'ERD_Main',
    @owner_id = 1,
    @version = 3,
    @definition = 0x
```

### 8.3 Verify update was applied
```sql
-- Before
EXEC dbo.sp_helpdiagramdefinition @diagramname = N'ERD_Main'

-- Update
EXEC dbo.sp_alterdiagram
    @diagramname = N'ERD_Main',
    @owner_id = NULL,
    @version = 2,
    @definition = 0x

-- After
EXEC dbo.sp_helpdiagramdefinition @diagramname = N'ERD_Main'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Standard SQL Server system procedure.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: dbo.sp_alterdiagram | Type: Stored Procedure | Source: RecurringInvestment/dbo/Stored Procedures/dbo.sp_alterdiagram.sql*
