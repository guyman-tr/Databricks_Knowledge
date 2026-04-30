# dbo.UpdateAffiliateGroup_NogaJunk0226

## 1. Overview

Updates an affiliate group record in `tblaff_AffiliatesGroups` and writes a field-level audit log entry for each field that has actually changed (group name, account manager name, and manager user ID). Only changed fields generate audit rows, avoiding audit noise for unchanged values.

> **Deprecated / Developer Backup:** The `NogaJunk0226` suffix indicates this is a developer backup snapshot created on 2026-02-26. It should not be used in production code. Use `dbo.UpdateInsertAffiliateGroup` for active affiliate group updates.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_AffiliatesGroups |
| Secondary Tables | dbo.AuditLog |
| Operation | UPDATE, INSERT (audit) |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @UserID | IN | INT | required | ID of the user performing the update; written to audit rows. |
| @AffiliatesGroupsID | IN | int | required | ID of the affiliate group to update. |
| @ChangedSectionID | IN | int | required | Section ID for the audit log. |
| @ReasonOfChange | IN | nvarchar(1000) | required | Reason description written to all audit rows. |
| @ReferencedChangedID | IN | int | required | Referenced entity ID for audit log. |
| @AccountManagerName | IN | nvarchar(50) | NULL | New account manager name. |
| @AffiliatesGroupsName | IN | nvarchar(50) | NULL | New group name. |
| @ManagerUserID | IN | int | NULL | New manager user ID. |

## 5. Business Logic

1. Reads current values of `AffiliatesGroupsName`, `AccountManagerName`, and `ManagerUserID` from `tblaff_AffiliatesGroups` for the target group ID.
2. Compares each field to its new value; if different, INSERTs an audit row into `AuditLog` recording the old and new values, section ID, reason, and referenced ID. Note: the audit row for `ManagerUserID` changes uses the label `'Affiliate Account Manager''s Name'` (same as the account manager name field) rather than an ID label; this appears to be a copy-paste bug in the original code.
3. UPDATEs `tblaff_AffiliatesGroups` setting all three fields unconditionally (the UPDATE runs regardless of whether any field changed).
4. `SET NOCOUNT ON` suppresses row-count messages.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_AffiliatesGroups | Table | dbo | Source and target for affiliate group data |
| dbo.AuditLog | Table | dbo | Field-level audit trail |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The UPDATE is unconditional; even if no fields changed the UPDATE statement executes and triggers will fire if present.
- The `ManagerUserID` audit label (`'Affiliate Account Manager''s Name'`) duplicates the label used for `AccountManagerName`; this is a known defect in this snapshot. The production procedure `UpdateInsertAffiliateGroup` correctly logs the manager user ID with a distinct label.

## 8. Usage Examples

```sql
EXEC dbo.UpdateAffiliateGroup_NogaJunk0226
    @UserID               = 99,
    @AffiliatesGroupsID   = 5,
    @ChangedSectionID     = 3,
    @ReasonOfChange       = N'Reassigned account manager',
    @ReferencedChangedID  = 5,
    @AccountManagerName   = N'Jane Smith',
    @AffiliatesGroupsName = N'APAC Partners',
    @ManagerUserID        = 44;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2026-02-26 | Noga | N/A | Developer backup snapshot created (NogaJunk0226). Do not use in production. |

---
*Object: dbo.UpdateAffiliateGroup_NogaJunk0226 | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateAffiliateGroup_NogaJunk0226.sql*
