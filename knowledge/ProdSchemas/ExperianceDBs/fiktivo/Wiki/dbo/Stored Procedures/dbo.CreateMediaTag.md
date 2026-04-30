# dbo.CreateMediaTag

> Creates a new media tag if the supplied name does not already exist, then logs the creation to AuditLog. Idempotent: if a tag with the same name already exists, the existing TagID is returned and no duplicate is created.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Authors** | Gil Haba and Noga Rozen |
| **Created** | December 2021 |

---

## 1. Business Meaning

Media tags are classification labels attached to banners and other creative assets. They enable filtering and segmentation of banner inventory (for example, tagging banners by campaign theme, season, or product focus). This procedure is the single authoritative way to create a new media tag.

The procedure is idempotent by design: if a tag with the same name already exists, the existing TagID is returned rather than creating a duplicate. This makes it safe to call from application code that does not pre-check for existence. When a new tag is genuinely created, the procedure records the event in AuditLog using ChangedSectionID=10 (the media tag section) and ActionID=1 (create), providing a full audit trail of tag creation activity.

The @TranslationKey parameter stores a localization identifier that allows the tag name to be displayed in multiple languages in the affiliate portal.

---

## 2. Business Logic

### 2.1 Idempotent Tag Creation

**What**: The procedure first checks whether a tag with the supplied @Name already exists before inserting.

**Columns/Parameters Involved**: `@Name`, `MediaTag.Name`, `@TagID`

**Rules**:
- A SELECT on MediaTag checks for a matching Name (case-insensitive per database collation)
- If a matching tag is found, @TagID is set to the existing TagID and no INSERT is performed
- If no matching tag is found, a new row is inserted into MediaTag and @TagID is set from SCOPE_IDENTITY()
- The procedure returns @TagID in all cases; the caller cannot distinguish create vs. return-existing from the return value alone

### 2.2 Audit Logging

**What**: On successful new tag creation, an audit record is written to AuditLog.

**Columns/Parameters Involved**: `@ChangedByUserID`, `@TagID`, `AuditLog.ChangedSectionID`, `AuditLog.ActionID`

**Rules**:
- AuditLog is only written when a new tag is created; idempotent returns (tag already exists) do not generate an audit record
- ChangedSectionID = 10 identifies the media tag management section of the application
- ActionID = 1 represents a CREATE action in the audit log action vocabulary
- @ChangedByUserID is stored in the audit record to identify which admin user initiated the creation

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @ChangedByUserID | IN | int | (required) | ID of the admin user creating the media tag. Written to AuditLog when a new tag is inserted. References dbo.tblaff_User or equivalent user table. |
| 2 | @Name | IN | nvarchar(500) | (required) | The display name for the new media tag. If a tag with this name already exists, the existing TagID is returned and no INSERT is performed. Case-insensitive comparison per database collation. |
| 3 | @TranslationKey | IN | varchar(128) | (required) | Localization key for the tag name. Allows the tag to be displayed in multiple languages in the affiliate portal. |

### Output / Return Value

| Parameter / Column | Direction | Type | Description |
|-------------------|-----------|------|-------------|
| @TagID | OUT (result set or OUTPUT) | int | The TagID of the created or pre-existing media tag. Always populated on return. |

---

## 5. Relationships

### 5.1 Tables Written

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.MediaTag | SELECT then INSERT (conditional) | SELECT to check existence by Name; INSERT only if no matching name found |
| dbo.AuditLog | INSERT (conditional) | Audit record written only when a new tag is created; not written for idempotent returns |

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.MediaTag | SELECT | Existence check by Name before deciding whether to insert |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CreateMediaTag (stored procedure)
+-- dbo.MediaTag (table) [SELECT + conditional INSERT]
+-- dbo.AuditLog (table) [conditional INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.MediaTag | Table | Checked for existence by Name; target of INSERT when tag is new |
| dbo.AuditLog | Table | Receives the audit record for new tag creation (ChangedSectionID=10, ActionID=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.CreateBanner | Stored Procedure | May call CreateMediaTag indirectly when setting up new media tags before banner creation |
| Admin media tag management UI | Application | Calls this procedure when an admin creates a new tag from the media tag management panel |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- The idempotent pattern (check-then-insert) is not protected by a transaction or serializable isolation; a race condition between two simultaneous calls with the same name could result in a duplicate insert. The MediaTag table likely has a unique constraint on Name to prevent this at the storage level.
- AuditLog constants: ChangedSectionID=10 (media tags), ActionID=1 (create). These are application-defined lookup values.
- @TranslationKey uses varchar (not nvarchar), meaning it is limited to ASCII characters; localization keys are typically ASCII identifiers by convention.
- No explicit transaction wrapper is shown in the specification; the two INSERTs (MediaTag + AuditLog) may not be atomic if the procedure does not wrap them. A failure between the two INSERTs would create a tag with no audit record.

---

## 8. Sample Queries

### 8.1 Create a new media tag

```sql
EXEC dbo.CreateMediaTag
    @ChangedByUserID = 99,
    @Name            = N'Winter Campaign 2026',
    @TranslationKey  = 'media_tag_winter_2026';
-- Returns: @TagID = <new ID>
```

### 8.2 Idempotent call - returns existing tag

```sql
-- First call creates the tag:
EXEC dbo.CreateMediaTag
    @ChangedByUserID = 99,
    @Name            = N'Crypto Promo',
    @TranslationKey  = 'media_tag_crypto_promo';

-- Second call with same name returns existing TagID without inserting:
EXEC dbo.CreateMediaTag
    @ChangedByUserID = 99,
    @Name            = N'Crypto Promo',
    @TranslationKey  = 'media_tag_crypto_promo';
```

### 8.3 Verify the created tag and its audit record

```sql
-- Check the MediaTag row:
SELECT TagID, Name, TranslationKey
FROM dbo.MediaTag WITH (NOLOCK)
WHERE Name = N'Winter Campaign 2026';

-- Check the AuditLog entry:
SELECT *
FROM dbo.AuditLog WITH (NOLOCK)
WHERE ChangedSectionID = 10
  AND ActionID         = 1
ORDER BY LogDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10*
*Object: dbo.CreateMediaTag | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.CreateMediaTag.sql*
