# dbo.UpdateAffiliatesWithAffiliateType

## 1. Overview

Bulk-reassigns a set of affiliates from one affiliate type to another and writes individual audit log entries for each moved affiliate in a single transaction. Designed for the affiliate administration UI to support mass category changes with full auditability and rollback safety.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Affiliates |
| Secondary Tables | dbo.tblaff_AffiliateTypes, dbo.AuditLog |
| Operation | UPDATE, INSERT (audit) |
| Transaction | Yes (explicit BEGIN/COMMIT with TRY/CATCH) |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @UserEmail | IN | nvarchar(250) | required | Email of the user making the change; written to audit rows. |
| @RemovedAffiliateTypeID | IN | int | required | The affiliate type being replaced (old type). |
| @AffiliateTypeID | IN | int | required | The new affiliate type to assign. |
| @Affiliates | IN | dbo.IDTableType READONLY | required | Table-valued parameter containing the affiliate IDs to reassign. |

## 5. Business Logic

1. Looks up `Description` from `tblaff_AffiliateTypes` for both `@RemovedAffiliateTypeID` and `@AffiliateTypeID` to supply human-readable descriptions in audit rows.
2. Begins an explicit transaction.
3. UPDATEs `tblaff_Affiliates.AffiliateTypeID` to `@AffiliateTypeID` for all affiliates in `@Affiliates` (set-based UPDATE via JOIN).
4. INSERTs one audit row per affiliate in `@Affiliates` into `AuditLog`, recording: UTC date, `@UserEmail`, section ID 1, old and new type IDs, reason "Update AffiliateTypeID", field name "Affiliate Type", the affiliate ID as the reference, action ID 2, and old/new type descriptions.
5. Commits the transaction.
6. TRY/CATCH handles errors: if this is the outermost transaction it rolls back; if nested it commits the savepoint. Always re-throws the original error via `THROW`.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Affiliates | Table | dbo | Target of the bulk affiliate type update |
| dbo.tblaff_AffiliateTypes | Table | dbo | Source of human-readable type descriptions for audit log |
| dbo.AuditLog | Table | dbo | Receives per-affiliate audit entries |
| dbo.IDTableType | User-Defined Table Type | dbo | Table type for @Affiliates parameter |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The set-based UPDATE and batch INSERT into `AuditLog` (via SELECT from @Affiliates) are efficient for large sets of affiliates.
- The TRY/CATCH/THROW pattern correctly propagates errors to the caller.
- `GetUTCDate()` is used for the audit timestamp (UTC), consistent with modern audit logging practices.
- `NOLOCK` hints on `tblaff_AffiliateTypes` lookups for descriptions are safe read-only lookups.

## 8. Usage Examples

```sql
DECLARE @affiliates dbo.IDTableType;
INSERT INTO @affiliates VALUES (101), (205), (340);

EXEC dbo.UpdateAffiliatesWithAffiliateType
    @UserEmail             = N'admin@company.com',
    @RemovedAffiliateTypeID= 3,
    @AffiliateTypeID       = 7,
    @Affiliates            = @affiliates;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2021-09-30 | Ran Ovadia | N/A | Created for Admin |
| 2024-09-29 | Gil H. | PART-3409 | Affiliate Admin - Rewrite Categories |

---
*Object: dbo.UpdateAffiliatesWithAffiliateType | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateAffiliatesWithAffiliateType.sql*
