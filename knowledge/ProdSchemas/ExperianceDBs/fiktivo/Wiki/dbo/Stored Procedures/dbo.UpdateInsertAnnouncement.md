# dbo.UpdateInsertAnnouncement

## 1. Overview

Upserts an announcement record in `tblaff_Announcement`: inserts a new announcement when `@AnnouncementID = 0`, or updates an existing announcement otherwise. For updates, generates field-level audit log entries only for fields that have actually changed (headline, expiration date, image, type, and body). Returns the ID of the created or updated announcement via an OUTPUT parameter.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Announcement |
| Secondary Tables | dbo.AuditLog |
| Operation | INSERT or UPDATE, INSERT (audit) |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned. The ID of the inserted or updated announcement is returned via `@OutputAnnouncementID OUTPUT`.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @ChangedByUserID | IN | INT | required | UserID of the user performing the operation. |
| @AnnouncementID | IN | INT | 0 | 0 to insert a new announcement; existing ID to update. |
| @ReasonOfChange | IN | nvarchar(1000) | NULL | Reason written to audit rows (update path). |
| @ReferencedChangedID | IN | int | NULL | Referenced entity ID for audit rows (update path). |
| @AnnouncementExpirationDate | IN | nvarchar(200) | required | Expiration date as a string in MM/DD/YYYY format (converted internally to DATETIME via style 101). |
| @AnnouncementHeadline | IN | nvarchar(1000) | required | Announcement headline text. |
| @AnnouncementImage | IN | nvarchar(1000) | NULL | Optional image URL or path. |
| @AnnouncementBody | IN | nvarchar(max) | required | Full announcement body/content. |
| @AnnouncementNews | IN | bit | required | 1 = News type; 0 = Promotions type. |
| @OutputAnnouncementID | OUT | int | NULL | OUTPUT: ID of the inserted or updated announcement. |
| @ActionID | IN | int | NULL | Audit action ID; overridden to 2 for updates. |

## 5. Business Logic

**Insert path (`@AnnouncementID = 0`):**
1. Converts `@AnnouncementExpirationDate` from nvarchar to DATETIME using style 101 (MM/DD/YYYY).
2. INSERTs a new row into `tblaff_Announcement`.
3. Retrieves the new `AnnouncementID` via `SELECT TOP 1 ... WHERE AnnouncementHeadline = @AnnouncementHeadline ORDER BY AnnouncementID DESC`.
4. Sets `@OutputAnnouncementID`.
5. INSERTs an audit row with action 1 and reason `'Add new Announcement with ID: <ID>'`, section ID 4.

**Update path (`@AnnouncementID != 0`):**
1. Forces `@ActionID = 2`.
2. Reads current `AnnouncementExpirationDate`, `AnnouncementHeadline`, `AnnouncementImage`, `AnnouncementNews`, and `AnnouncementBody` from the existing row.
3. For each changed field, INSERTs an audit row:
   - Headline change: field `'Announcement Headline'`.
   - Expiration date change: field `'Expiration Date'`.
   - Image change: field `'Announcement Image'`.
   - Type change (`AnnouncementNews`): resolves human-readable descriptions ("News"/"Promotions") noting that `AnnouncementNews = 1` maps to "Promotions" and `AnnouncementNews = 0` maps to "News" in the description fields (note: old value = 1 produces `OldDescription = 'Promitions'` - this is a typo in the source; should be "Promotions").
   - Body change: field `'Announcement Content'`.
4. UPDATEs all five fields on the existing announcement row.
5. `SET NOCOUNT ON` suppresses row-count messages.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Announcement | Table | dbo | Stores affiliate portal announcements |
| dbo.AuditLog | Table | dbo | Field-level change history |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- `@AnnouncementExpirationDate` is accepted as `nvarchar(200)` and converted to DATETIME using `CONVERT(..., 101)` (US date format MM/DD/YYYY); callers must format the date accordingly to avoid conversion errors.
- The new-ID retrieval uses `SELECT TOP 1 ... ORDER BY DESC` which risks returning the wrong ID under concurrent inserts; an `OUTPUT` clause on the INSERT would be safer.
- The audit description for `AnnouncementNews` has a known typo: `'Promitions'` should be `'Promotions'`.
- The mapping of `AnnouncementNews = 1` to the label "Promotions" (not "News") and `AnnouncementNews = 0` to "News" appears inverted relative to the field name; verify with the business before relying on the audit descriptions.

## 8. Usage Examples

```sql
-- Insert a new announcement
DECLARE @newID INT;
EXEC dbo.UpdateInsertAnnouncement
    @ChangedByUserID           = 99,
    @AnnouncementID            = 0,
    @AnnouncementExpirationDate= N'12/31/2024',
    @AnnouncementHeadline      = N'New Feature Release',
    @AnnouncementBody          = N'We are excited to announce...',
    @AnnouncementNews          = 0,
    @OutputAnnouncementID      = @newID OUTPUT;
SELECT @newID AS NewAnnouncementID;

-- Update an existing announcement
EXEC dbo.UpdateInsertAnnouncement
    @ChangedByUserID           = 99,
    @AnnouncementID            = 42,
    @ReasonOfChange            = N'Corrected expiry date',
    @ReferencedChangedID       = 42,
    @AnnouncementExpirationDate= N'01/31/2025',
    @AnnouncementHeadline      = N'New Feature Release',
    @AnnouncementBody          = N'We are excited to announce...',
    @AnnouncementNews          = 0;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.UpdateInsertAnnouncement | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateInsertAnnouncement.sql*
