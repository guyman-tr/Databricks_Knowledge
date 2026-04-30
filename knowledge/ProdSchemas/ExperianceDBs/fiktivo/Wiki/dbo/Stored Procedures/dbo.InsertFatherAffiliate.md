# dbo.InsertFatherAffiliate

## 1. Overview

Sets the `FatherAffiliateTypeID` column on an existing affiliate type record, establishing a parent-child hierarchy between affiliate types. Despite the "Insert" prefix in its name, this procedure performs an UPDATE; its purpose is to assign or replace the parent (father) affiliate type for a given affiliate type.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_AffiliateTypes |
| Secondary Tables | None |
| Operation | UPDATE |
| Transaction | Implicit (single statement) |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned. No OUTPUT parameters.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @AffiliateTypeID | IN | INTEGER | required | ID of the affiliate type to update. |
| @FatherAffiliateTypeID | IN | INTEGER | required | ID of the parent affiliate type to assign as the father. |

## 5. Business Logic

1. Updates `tblaff_AffiliateTypes` setting `FatherAffiliateTypeID = @FatherAffiliateTypeID` where `AffiliateTypeID = @AffiliateTypeID`.
2. No audit logging is performed within this procedure.
3. No validation is performed to confirm that `@FatherAffiliateTypeID` exists or that circular references are avoided; such logic must be enforced at the application layer.
4. No `SET NOCOUNT ON`; the row-count message is returned to the caller.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| tblaff_AffiliateTypes | Table | dbo | Stores affiliate type definitions including the FatherAffiliateTypeID hierarchy column |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Single-row UPDATE on the primary key; minimal performance impact.
- No transaction block; the implicit single-statement transaction provides atomicity.

## 8. Usage Examples

```sql
-- Set AffiliateType 25 as the parent of AffiliateType 30
EXEC dbo.InsertFatherAffiliate
    @AffiliateTypeID       = 30,
    @FatherAffiliateTypeID = 25;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Created: add a father affiliate type ID to an affiliate type (per inline comment) |

---
*Object: dbo.InsertFatherAffiliate | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.InsertFatherAffiliate.sql*
