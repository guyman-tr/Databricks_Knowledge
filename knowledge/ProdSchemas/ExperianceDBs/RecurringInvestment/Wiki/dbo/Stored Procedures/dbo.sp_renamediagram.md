# dbo.sp_renamediagram

> Stored procedure that renames an existing database diagram after verifying ownership permissions and ensuring the new name is unique for the owner.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.sp_renamediagram is a SQL Server system-generated stored procedure that renames an existing database diagram stored in dbo.sysdiagrams. It is automatically created when database diagramming is first used in SSMS. This is not a business object -- it supports the SSMS visual diagram feature.

The procedure enforces ownership-based access control: only the diagram owner or a db_owner member can rename a diagram. It also validates that the new name does not conflict with an existing diagram owned by the same user.

---

## 2. Business Logic

### 2.1 Diagram Rename with Validation

**What**: Updates the name column in dbo.sysdiagrams for a specific diagram.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`, `@new_diagramname`

**Rules**:
- Executes WITH EXECUTE AS 'dbo'
- If @owner_id is NULL, defaults to the caller's database principal_id
- Verifies the source diagram exists for the specified owner
- Checks that the new name does not already exist for the same owner
- db_owner members can rename any diagram; other users can only rename their own
- On validation failure, raises an appropriate error message
- On success, updates the name column in sysdiagrams

### 2.2 Validation Rules

| Check | Action on Failure |
|-------|-------------------|
| Source diagram not found | Raises error |
| New name already exists for same owner | Raises error (duplicate name) |
| User does not own diagram (and is not db_owner) | Raises permission error |

---

## 3. Data Overview

N/A for system procedure. This procedure updates dbo.sysdiagrams.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | NO | - | VERIFIED | Current name of the diagram to rename. |
| 2 | @owner_id | int | YES | NULL | VERIFIED | Principal_id of the diagram owner. NULL defaults to caller's principal_id. |
| 3 | @new_diagramname | sysname | NO | - | VERIFIED | New name for the diagram. Must be unique for the owner. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.sysdiagrams | Table | Updates name column for the target diagram |

### 5.2 Referenced By (other objects point to this)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.fn_diagramobjects | Function | Checks for existence of this procedure (bit 32) |

Called by SSMS when a user renames a diagram.

---

## 6. Dependencies

### 6.0 Dependency Chain

dbo.sp_renamediagram -> dbo.sysdiagrams

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
- **Side Effects**: Updates the name column for one row in dbo.sysdiagrams
- **Security**: Ownership check via principal_id comparison; IS_MEMBER('db_owner') bypass
- **Idempotent**: No -- renaming to the same name would either succeed (no-op) or fail if validation logic checks for "different" name

---

## 8. Sample Queries

### 8.1 Rename a diagram
```sql
EXEC dbo.sp_renamediagram
    @diagramname = N'ERD_Old',
    @owner_id = NULL,
    @new_diagramname = N'ERD_Current'
```

### 8.2 Rename a diagram with explicit owner
```sql
EXEC dbo.sp_renamediagram
    @diagramname = N'ERD_Draft',
    @owner_id = 1,
    @new_diagramname = N'ERD_Final'
```

### 8.3 Verify rename succeeded
```sql
EXEC dbo.sp_renamediagram
    @diagramname = N'ERD_Old',
    @owner_id = NULL,
    @new_diagramname = N'ERD_New'

-- Confirm old name no longer exists
EXEC dbo.sp_helpdiagrams @diagramname = N'ERD_Old'
-- Confirm new name exists
EXEC dbo.sp_helpdiagrams @diagramname = N'ERD_New'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Standard SQL Server system procedure.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: dbo.sp_renamediagram | Type: Stored Procedure | Source: RecurringInvestment/dbo/Stored Procedures/dbo.sp_renamediagram.sql*
