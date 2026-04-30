# AffiliateAdmin.UpdateMediaTag

> Updates a media tag's name and translation key with separate audit log entries for each changed field using SectionID=10.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updated MediaTag record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateMediaTag updates the Name and TranslationKey fields of an existing media tag record in `dbo.MediaTag`. The procedure creates separate audit log entries for each changed field using SectionID=10 (MediaTags), enabling independent tracking of name changes and translation key changes.

**WHY:** Media tags are used to categorize and label banners for filtering and organization in the affiliate portal. Each tag has a display name and a translation key that enables localization of the tag label across different languages. When either field changes, it needs to be independently tracked in the audit log because name changes affect the admin interface while translation key changes affect the localized affiliate-facing display.

**HOW:** The procedure accepts the tag @ID, new @Name, and new @TranslationKey values. It retrieves the current values for both fields from `dbo.MediaTag`. It compares the current Name to @Name and, if different, creates an audit log entry for the name change with SectionID=10. It separately compares the current TranslationKey to @TranslationKey and, if different, creates another audit log entry for the key change. Finally, it performs the UPDATE on the `dbo.MediaTag` record.

---

## 2. Business Logic

### 2.1 Independent Field Comparison
Each field (Name and TranslationKey) is compared independently against its current value. This allows the procedure to create targeted audit entries that distinguish between name changes and translation key changes, even when both change simultaneously.

### 2.2 Name Audit Entry
When the Name field changes, an audit log entry is created with:
- SectionID=10 (MediaTags)
- The old name value
- The new name value
- The performing user and reason

### 2.3 Translation Key Audit Entry
When the TranslationKey field changes, a separate audit log entry is created with:
- SectionID=10 (MediaTags)
- The old translation key value
- The new translation key value
- The performing user and reason

### 2.4 Section ID Reference
SectionID=10 corresponds to MediaTags in the audit log section classification. See Changed Sections glossary for full reference.

### 2.5 Update-Only Operation
Unlike many other procedures in the AffiliateAdmin schema, UpdateMediaTag only supports UPDATE operations. New media tags are created through the separate `CreateMediaTag` procedure.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 2 | @ReferencedChangedID | INT | Yes | NULL | CODE-BACKED | Referenced entity ID for audit context |
| 3 | @ReasonOfChange | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Reason for the change (audit context) |
| 4 | @ID | INT | No | - | CODE-BACKED | The media tag ID to update |
| 5 | @Name | NVARCHAR(500) | Yes | NULL | CODE-BACKED | New display name for the media tag |
| 6 | @TranslationKey | VARCHAR(128) | Yes | NULL | CODE-BACKED | New translation key for localization |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.MediaTag` | Table | UPDATE name and translation key |
| `dbo.AuditLog` | Table | INSERT separate audit entries for name and key changes (SectionID=10) |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Media tag management screen | Application | Edit tag name or translation key |
| Localization administration | Application | Update translation keys for media tags |

---

## 6. Dependencies

### 6.0 Chain
`UpdateMediaTag` -> SELECT current values from `MediaTag` -> compare Name (if changed -> `AuditLog` INSERT) -> compare TranslationKey (if changed -> `AuditLog` INSERT) -> UPDATE `MediaTag`

### 6.1 Depends On
- `dbo.MediaTag` - Target table for media tag updates
- `dbo.AuditLog` - Audit trail storage (SectionID=10)

### 6.2 Depend On This
No known database dependencies. Called from application layer.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Update media tag name
EXEC AffiliateAdmin.UpdateMediaTag
    @UserEmail = N'admin@company.com',
    @ReferencedChangedID = 25,
    @ReasonOfChange = N'Corrected tag name spelling',
    @ID = 25,
    @Name = N'Premium Display Ads',
    @TranslationKey = 'media_tag_premium_display';
```

```sql
-- 2. Update only the translation key
EXEC AffiliateAdmin.UpdateMediaTag
    @UserEmail = N'localization@company.com',
    @ReferencedChangedID = 10,
    @ReasonOfChange = N'Standardized translation key format',
    @ID = 10,
    @Name = N'Social Media Banners',  -- unchanged, no audit entry
    @TranslationKey = 'banner_tag_social_media';
```

```sql
-- 3. Update both name and translation key
EXEC AffiliateAdmin.UpdateMediaTag
    @UserEmail = N'admin@company.com',
    @ReferencedChangedID = 30,
    @ReasonOfChange = N'Renamed category and updated key',
    @ID = 30,
    @Name = N'Video Content',
    @TranslationKey = 'media_tag_video_content';
-- This creates TWO audit log entries: one for name, one for key
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4214.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateMediaTag | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateMediaTag.sql*
