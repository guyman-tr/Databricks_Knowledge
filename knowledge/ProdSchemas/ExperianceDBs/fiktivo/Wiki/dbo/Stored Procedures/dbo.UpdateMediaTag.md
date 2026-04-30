# dbo.UpdateMediaTag

## 1. Overview

Updates an existing media tag record in the `MediaTag` table. The procedure compares the incoming `@Name` and `@TranslationKey` values against the stored values; if either field has changed, the row is updated. Separate audit log entries are written for each changed field. If neither field has changed, no write operations are performed. Created by Gil Haba and reviewed by Noga Rozen, December 2021.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.MediaTag |
| Secondary Tables | dbo.AuditLog |
| Operation | UPDATE, INSERT (audit) |
| Transaction | No |

## 3. Return / Result Set

No result set and no OUTPUT parameters. The procedure performs in-place updates only.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @ChangedByUserID | IN | INT | required | UserID of the user performing the update. |
| @ReferencedChangedID | IN | INT | NULL | Referenced entity ID written to audit log rows. |
| @ReasonOfChange | IN | NVARCHAR(1000) | required | Free-text reason written to audit log rows. |
| @ID | IN | INT | required | TagID of the MediaTag row to update. |
| @Name | IN | NVARCHAR(500) | required | New tag name value. |
| @TranslationKey | IN | VARCHAR(128) | required | New translation key value. |

## 5. Business Logic

1. Reads the current `TagName` and `TranslationKey` from `MediaTag WITH (NOLOCK)` for the given `@ID` into local variables `@Name_old` and `@TranslationKey_old`.
2. If either `@Name_old <> @Name` OR `@TranslationKey_old <> @TranslationKey`:
   - UPDATEs `dbo.MediaTag` setting `TagName = @Name` and `TranslationKey = @TranslationKey` where `TagID = @ID`.
3. If `@Name_old <> @Name`:
   - INSERTs an audit row with `ChangedSectionID = 10`, `ActionID = 2`, `ChangedFieldName = 'Update Media Tag Name'`, timestamp from `GETUTCDATE()`.
4. If `@TranslationKey_old <> @TranslationKey`:
   - INSERTs an audit row with `ChangedSectionID = 10`, `ActionID = 2`, `ChangedFieldName = 'Update Media Tag Translation key'`, timestamp from `GETUTCDATE()`.

**Notes:**
- Uses `GETUTCDATE()` for audit timestamps (unlike many other procedures in this schema that use `GETDATE()`), so all audit rows for media tag changes are in UTC.
- The `WITH (NOLOCK)` hint on the initial SELECT means a dirty read is possible in high-concurrency scenarios.
- No insert path exists; this procedure only updates existing tags. Use `dbo.CreateMediaTag` to insert new ones.
- `SET NOCOUNT ON` suppresses row-count messages.
- No explicit transaction; the UPDATE and each audit INSERT are separate implicit transactions.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.MediaTag | Table | dbo | Stores media tag definitions (TagID, TagName, TranslationKey) |
| dbo.AuditLog | Table | dbo | Field-level audit trail |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- A covering index on `MediaTag(TagID)` including `TagName` and `TranslationKey` would make the initial read efficient; this likely already exists via the primary key.
- The NOLOCK hint on the read avoids blocking but can produce stale comparisons in concurrent scenarios.

## 8. Usage Examples

```sql
-- Update a media tag name and translation key
EXEC dbo.UpdateMediaTag
    @ChangedByUserID     = 99,
    @ReferencedChangedID = 15,
    @ReasonOfChange      = N'Corrected display name per localization team',
    @ID                  = 15,
    @Name                = N'Sports Banner',
    @TranslationKey      = 'media_tag_sports_banner';

-- Update only the translation key (name unchanged)
EXEC dbo.UpdateMediaTag
    @ChangedByUserID     = 99,
    @ReferencedChangedID = 22,
    @ReasonOfChange      = N'Translation key renamed in i18n system',
    @ID                  = 22,
    @Name                = N'Forex Widget',
    @TranslationKey      = 'media_tag_forex_widget_v2';
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Dec 2021 | Gil Haba (reviewed by Noga Rozen) | N/A | Initial creation |

---
*Object: dbo.UpdateMediaTag | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateMediaTag.sql*
