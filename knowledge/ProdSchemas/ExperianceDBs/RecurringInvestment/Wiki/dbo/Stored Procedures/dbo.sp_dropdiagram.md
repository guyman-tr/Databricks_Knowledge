# dbo.sp_dropdiagram

> Stored procedure that deletes a database diagram from the sysdiagrams table after verifying ownership permissions.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.sp_dropdiagram is a SQL Server system-generated stored procedure that permanently deletes a database diagram from dbo.sysdiagrams. It is automatically created when database diagramming is first used in SSMS. This is not a business object -- it supports the SSMS visual diagram feature.

When a user deletes a diagram in SSMS, this procedure is called to remove the diagram's metadata and binary definition from the sysdiagrams table. The deletion is permanent and cannot be undone through the diagramming interface. The procedure enforces ownership-based access control to prevent unauthorized deletions.

---

## 2. Business Logic

### 2.1 Diagram Deletion with Permission Check

**What**: Deletes a diagram record from dbo.sysdiagrams by name and owner.

**Columns/Parameters Involved**: `@diagramname`, `@owner_id`

**Rules**:
- Executes WITH EXECUTE AS 'dbo'
- If @owner_id is NULL, defaults to the caller's database principal_id
- Verifies the target diagram exists for the specified owner
- db_owner members can delete any diagram; other users can only delete their own
- On validation failure (diagram not found or permission denied), raises an error
- On success, deletes the row from sysdiagrams
- Deletion is permanent -- no soft-delete or recycle bin

### 2.2 Permission Model

| Role | Access |
|------|--------|
| db_owner | Can delete any diagram |
| Diagram owner | Can delete their own diagrams |
| Other users | Access denied |

---

## 3. Data Overview

N/A for system procedure. This procedure deletes from dbo.sysdiagrams.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @diagramname | sysname | NO | - | VERIFIED | Name of the diagram to delete. Required parameter. |
| 2 | @owner_id | int | YES | NULL | VERIFIED | Principal_id of the diagram owner. NULL defaults to caller's principal_id. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.sysdiagrams | Table | Deletes diagram records from this table |

### 5.2 Referenced By (other objects point to this)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.fn_diagramobjects | Function | Checks for existence of this procedure (bit 128) |

Called by SSMS when a user deletes a diagram from the diagram browser.

---

## 6. Dependencies

### 6.0 Dependency Chain

dbo.sp_dropdiagram -> dbo.sysdiagrams

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.sysdiagrams | Table | Target for DELETE operations |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

- **Execution Context**: WITH EXECUTE AS 'dbo'
- **Transaction Handling**: Single DELETE statement; implicit transaction
- **Side Effects**: Permanently removes one row from dbo.sysdiagrams
- **Reversibility**: Deletion is permanent; diagram binary data cannot be recovered after commit
- **Security**: Ownership check via principal_id comparison; IS_MEMBER('db_owner') bypass
- **Cascading**: No cascading effects; sysdiagrams has no foreign key relationships to other tables

---

## 8. Sample Queries

### 8.1 Delete a diagram
```sql
EXEC dbo.sp_dropdiagram @diagramname = N'ERD_Old'
```

### 8.2 Delete a specific owner's diagram
```sql
EXEC dbo.sp_dropdiagram @diagramname = N'ERD_Draft', @owner_id = 1
```

### 8.3 Verify diagram was deleted
```sql
-- Check diagram exists before deletion
EXEC dbo.sp_helpdiagrams @diagramname = N'ERD_Temp'

-- Delete
EXEC dbo.sp_dropdiagram @diagramname = N'ERD_Temp'

-- Confirm deletion
EXEC dbo.sp_helpdiagrams @diagramname = N'ERD_Temp'
-- Should return empty result set
```

### 8.4 List remaining diagrams after cleanup
```sql
EXEC dbo.sp_dropdiagram @diagramname = N'ERD_Test'
EXEC dbo.sp_helpdiagrams
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Standard SQL Server system procedure.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: dbo.sp_dropdiagram | Type: Stored Procedure | Source: RecurringInvestment/dbo/Stored Procedures/dbo.sp_dropdiagram.sql*
