# dbo.RemoveMediaTag

## 1. Overview

Safely deletes a media tag from `dbo.MediaTag` provided the tag is not currently associated with any banner in `dbo.MediaTagBanner`. If the deletion succeeds (at least one row removed), an audit log entry is written recording the deletion. The safety check prevents orphan removal issues by ensuring the tag has no active banner associations before it is deleted.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.MediaTag |
| Secondary Tables | dbo.MediaTagBanner, dbo.AuditLog |
| Operation | DELETE, INSERT (audit) |
| Transaction | No (single-statement DELETE; audit INSERT is conditional) |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned. No OUTPUT parameters.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @ID | IN | INT | required | TagID of the media tag to delete. |
| @ChangedByUserID | IN | INT | required | UserID of the user requesting the deletion; written to audit log. |

## 5. Business Logic

1. Attempts to DELETE from `MediaTag` (aliased `M`) with a LEFT JOIN to `MediaTagBanner` (aliased `B`) on `TagID`. The WHERE clause requires `M.TagID = @ID AND B.TagID IS NULL`, meaning the DELETE only proceeds when no matching row exists in `MediaTagBanner` (the tag has no banner associations).
2. Checks `@@ROWCOUNT` after the DELETE. If at least one row was deleted:
   a. INSERTs a row into `AuditLog` with UTC date (`GETUTCDATE()`), `@ChangedByUserID`, `ChangedSectionID = 10`, NULL old/new field values, reason string `'Delete MedaiTag if exists: <ID>'` (note: "MedaiTag" is a typo in the source), `ActionID = 1`.
3. If no rows were deleted (tag has banner associations or does not exist), no action is taken and no error is raised.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.MediaTag | Table | dbo | Stores media tag definitions; target of the DELETE |
| dbo.MediaTagBanner | Table | dbo | Junction table linking tags to banners; used for the safety check |
| dbo.AuditLog | Table | dbo | Receives an audit entry when the deletion succeeds |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The LEFT JOIN / IS NULL pattern for the safety check is standard and efficient when `MediaTagBanner.TagID` is indexed.
- The procedure silently does nothing if the tag has banner associations; callers should check `@@ROWCOUNT` (or query the tag again) if they need to confirm deletion.
- "MedaiTag" in the audit `ReasonOfChange` string is a typo present in the source code; it should read "MediaTag".

## 8. Usage Examples

```sql
-- Attempt to delete media tag ID 55, logged as user 10
EXEC dbo.RemoveMediaTag
    @ID              = 55,
    @ChangedByUserID = 10;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2021-12 | Gil Haba, reviewed by Noga Rozen | N/A | Created |

---
*Object: dbo.RemoveMediaTag | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.RemoveMediaTag.sql*
