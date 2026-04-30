# dbo.UpdateInsertBrand

## 1. Overview

Upserts a brand record in `tblaff_Brands`: inserts a new brand when `@BrandID = 0`, or updates an existing brand's name otherwise. For updates, an audit log entry is written only when the brand name has actually changed. The ID of the inserted or updated brand is returned via an OUTPUT parameter.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Brands |
| Secondary Tables | dbo.AuditLog |
| Operation | INSERT or UPDATE, INSERT (audit) |
| Transaction | No |

## 3. Return / Result Set

No result set is returned. The ID of the inserted or updated brand is returned via `@OutputBrandID OUTPUT`.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @ChangedByUserID | IN | INT | required | UserID of the user performing the operation. |
| @BrandID | IN | INT | 0 | 0 to insert a new brand; existing BrandID to update. |
| @ReasonOfChange | IN | nvarchar(1000) | NULL | Free-text reason written to audit log rows on update. |
| @ReferencedChangedID | IN | int | NULL | Referenced entity ID for audit rows. |
| @BrandName | IN | varchar(150) | required | The brand name to insert or update. |
| @OutputBrandID | OUT | int | NULL | OUTPUT: ID of the inserted or updated brand. |
| @ActionID | IN | int | NULL | Audit action ID; overridden to 2 for updates. |

## 5. Business Logic

**Insert path (`@BrandID = 0`):**
1. INSERTs a new row into `tblaff_Brands` with the supplied `@BrandName`.
2. Retrieves the new `BrandID` by selecting TOP 1 ordered by `BrandID DESC` where `BrandName` matches.
3. Sets `@OutputBrandID` to the new ID.
4. INSERTs an audit row with `ActionID = 1`, `ChangedSectionID = 7`, and reason `'Add new Brand with ID: <ID>'`. `OldFieldValue` and `NewFieldValue` are NULL; `ReferencedChangedID` is the string cast of the new ID.

**Update path (`@BrandID != 0`):**
1. Forces `@ActionID = 2`.
2. Reads the current `BrandName` from `tblaff_Brands` for the given `@BrandID`.
3. If the name has changed, INSERTs an audit row with `ChangedSectionID = 7`, old and new name values, and field name `'Brand'`.
4. UPDATEs `tblaff_Brands` setting `BrandName = @BrandName` for the given `@BrandID` unconditionally (even when the name is unchanged).

**Notes:**
- The new-ID retrieval after INSERT uses `SELECT TOP 1 ... ORDER BY BrandID DESC` which carries a concurrency risk; `SCOPE_IDENTITY()` would be safer.
- No explicit transaction wraps the insert/update and the audit insert.
- `SET NOCOUNT ON` suppresses row-count messages.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Brands | Table | dbo | Stores brand definitions |
| dbo.AuditLog | Table | dbo | Field-level audit trail |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- High-volume concurrent inserts may produce duplicate or incorrect `@OutputBrandID` due to the TOP 1 / ORDER BY DESC pattern.
- The UPDATE runs unconditionally even when only the name comparison for audit differs; this is harmless but a minor inefficiency.

## 8. Usage Examples

```sql
-- Insert a new brand
DECLARE @newBrandID INT;
EXEC dbo.UpdateInsertBrand
    @ChangedByUserID = 99,
    @BrandID         = 0,
    @BrandName       = 'Acme Trading',
    @OutputBrandID   = @newBrandID OUTPUT;
SELECT @newBrandID AS NewBrandID;

-- Update an existing brand name
EXEC dbo.UpdateInsertBrand
    @ChangedByUserID     = 99,
    @BrandID             = 7,
    @ReasonOfChange      = N'Rebranding initiative',
    @ReferencedChangedID = 7,
    @BrandName           = 'Acme Markets';
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.UpdateInsertBrand | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateInsertBrand.sql*
