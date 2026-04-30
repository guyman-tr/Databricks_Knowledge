# dbo.UpdateInsertAffiliateGroup

## 1. Overview

Upserts an affiliate group record in `tblaff_AffiliatesGroups`: inserts a new group when `@AffiliatesGroupsID = 0`, or updates an existing group otherwise. For updates, generates field-level audit log entries only for fields that have actually changed, including a human-readable manager name lookup for the `ManagerUserID` change. Returns the ID of the affected group via an OUTPUT parameter.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_AffiliatesGroups |
| Secondary Tables | dbo.AuditLog, dbo.tblaff_User |
| Operation | INSERT or UPDATE, INSERT (audit) |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned. The ID of the inserted or updated group is returned via `@OutputAffiliatesGroupsID OUTPUT`.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @ChangedByUserID | IN | INT | required | UserID of the user performing the operation. |
| @AffiliatesGroupsID | IN | int | 0 | 0 to insert a new group; existing ID to update. |
| @ReasonOfChange | IN | nvarchar(1000) | NULL | Reason written to audit log rows. |
| @ReferencedChangedID | IN | int | NULL | Referenced entity ID for audit rows. |
| @AccountManagerName | IN | nvarchar(50) | NULL | Account manager display name. |
| @AffiliatesGroupsName | IN | nvarchar(50) | NULL | Group name. |
| @ManagerUserID | IN | int | NULL | UserID of the assigned manager. |
| @ActionID | IN | int | NULL | Audit action ID; overridden to 2 for updates. |
| @AccountManagerEmail | IN | nvarchar | NULL | Account manager email address. |
| @AccountManagerImagePath | IN | nvarchar | NULL | Path to account manager profile image. |
| @OutputAffiliatesGroupsID | OUT | int | NULL | OUTPUT: ID of the inserted or updated group. |

## 5. Business Logic

**Insert path (`@AffiliatesGroupsID = 0`):**
1. INSERTs a new row into `tblaff_AffiliatesGroups` with all supplied fields.
2. Retrieves the new `AffiliatesGroupsID` by selecting TOP 1 ordered by ID DESC where the name matches.
3. Sets `@OutputAffiliatesGroupsID` to the new ID.
4. INSERTs an audit row with action ID 1 and reason `'Add new affiliatesGroup with ID: <ID>'`.

**Update path (`@AffiliatesGroupsID != 0`):**
1. Forces `@ActionID = 2`.
2. Reads current `AffiliatesGroupsName`, `AccountManagerName`, and `ManagerUserID` from the existing row.
3. For each changed field, INSERTs an audit row:
   - Group name change: logs old/new name, field `'Affiliate Group Name'`.
   - Account manager name change: logs old/new name, field `'Affiliate Account Manager''s Name'`.
   - Manager user ID change: additionally looks up the old and new user names from `tblaff_User` to populate `OldFieldDescription`/`NewFieldDescription` in the audit row, field `'Affiliate Account Manager''s ID'`.
4. UPDATEs `tblaff_AffiliatesGroups` with the new values.
5. Does not update `@OutputAffiliatesGroupsID` in the update path (remains NULL unless the caller initializes it).

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_AffiliatesGroups | Table | dbo | Stores affiliate group definitions |
| dbo.AuditLog | Table | dbo | Field-level audit trail |
| dbo.tblaff_User | Table | dbo | User name lookup for manager change audit rows |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The new-ID retrieval after INSERT (`SELECT TOP 1 ... ORDER BY AffiliatesGroupsID DESC`) is a race-condition risk under high concurrency; `SCOPE_IDENTITY()` or `OUTPUT` clause would be safer.
- `@AccountManagerEmail` and `@AccountManagerImagePath` are declared as bare `nvarchar` (no length) which defaults to `nvarchar(1)` in parameter declarations; this may silently truncate longer values.
- No explicit transaction; the insert/update and audit insert are separate implicit transactions.

## 8. Usage Examples

```sql
-- Insert a new group
DECLARE @newID INT;
EXEC dbo.UpdateInsertAffiliateGroup
    @ChangedByUserID      = 99,
    @AffiliatesGroupsID   = 0,
    @AffiliatesGroupsName = N'EMEA Partners',
    @AccountManagerName   = N'John Doe',
    @ManagerUserID        = 44,
    @OutputAffiliatesGroupsID = @newID OUTPUT;
SELECT @newID AS NewGroupID;

-- Update an existing group
EXEC dbo.UpdateInsertAffiliateGroup
    @ChangedByUserID      = 99,
    @AffiliatesGroupsID   = 5,
    @ReasonOfChange       = N'Manager change',
    @ReferencedChangedID  = 5,
    @AffiliatesGroupsName = N'EMEA Partners',
    @AccountManagerName   = N'Jane Smith',
    @ManagerUserID        = 55;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Guy | N/A | Initial creation |

---
*Object: dbo.UpdateInsertAffiliateGroup | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateInsertAffiliateGroup.sql*
