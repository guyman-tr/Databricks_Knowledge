# AffiliateAdmin.CreateMediaTagBanner

> Assigns or replaces the set of media tags linked to a specific banner, with full audit logging of tag list changes.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Operates on dbo.MediaTagBanner junction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.CreateMediaTagBanner manages the many-to-many relationship between marketing banners and media tags. When an admin edits a banner's tag assignments in the portal, this procedure replaces the entire tag set for that banner atomically - it deletes all existing tag associations and inserts the new ones, all within a single transaction.

This procedure exists because banners need to be categorized by multiple tags simultaneously (e.g., a banner might be tagged "Crypto", "Holiday", and "English"), and the admin UI presents tags as a multi-select that submits the full list on save. Without this atomic replace pattern, partial updates could leave banners in inconsistent states.

Data flow: The admin portal collects the selected tag IDs into a `dbo.IDTableType` table-valued parameter and calls this procedure. It compares the old tag list (STRING_AGG of existing TagIDs) with the new list. If they differ, it deletes all existing MediaTagBanner rows for the banner and inserts the new set. Each change (deletion and insertion) is logged to AuditLog with ChangedSectionID=10 (MediaTag) and ActionID=1 (Insert).

---

## 2. Business Logic

### 2.1 Atomic Tag Set Replacement with Change Detection

**What**: The procedure compares old and new tag lists before making changes, avoiding unnecessary writes when the tag set hasn't changed.

**Columns/Parameters Involved**: `@BannerID`, `@IdTable`, `@OldTagList`, `@NewTagsList`

**Rules**:
- Old tag list is computed via STRING_AGG(TagID, ',') WITHIN GROUP (ORDER BY TagID) from existing MediaTagBanner rows
- New tag list is computed identically from @IdTable parameter
- Only if ISNULL(@OldTagList,'') <> ISNULL(@NewTagsList,'') does the procedure proceed with DELETE/INSERT
- This avoids unnecessary audit log entries when no actual change occurred

### 2.2 Dual Audit Log Entries

**What**: Both the removal of old tags and the addition of new tags are logged as separate audit entries.

**Columns/Parameters Involved**: `@UserEmail`, `@ReasonOfChange`, `@BannerID`

**Rules**:
- First AuditLog entry records the deletion (OldFieldValue = old tag list, NewFieldValue = NULL)
- Second AuditLog entry records the insertion (OldFieldValue = old tag list, NewFieldValue = new tag list)
- Both use ChangedSectionID=10 (MediaTag) and ActionID=1 (Insert)
- ReferencedChangedID = @BannerID to link the audit trail to the specific banner

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BannerID | int | NO | - | CODE-BACKED | ID of the banner whose tag associations are being updated. References dbo.tblaff_Banners.BannerID. |
| 2 | @UserEmail | nvarchar(250) | NO | - | CODE-BACKED | Email of the admin user making the change. Written to AuditLog.UserEmail for accountability. |
| 3 | @ReasonOfChange | nvarchar(1000) | NO | - | CODE-BACKED | User-provided reason for the tag change. Written to AuditLog.ReasonOfChange. |
| 4 | @IdTable | dbo.IDTableType | READONLY | - | CODE-BACKED | Table-valued parameter containing the new set of TagIDs to associate with the banner. Each row has an ID column representing a TagID from dbo.MediaTag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE/INSERT | dbo.MediaTagBanner | Write | Replaces all tag-banner associations for the given BannerID |
| INSERT INTO | dbo.AuditLog | Write | Logs tag list changes with SectionID=10 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.CreateMediaTagBanner (procedure)
+-- dbo.MediaTagBanner (table)
+-- dbo.AuditLog (table)
+-- dbo.IDTableType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.MediaTagBanner | Table | SELECT, DELETE, INSERT for tag-banner junction management |
| dbo.AuditLog | Table | INSERT for audit trail |
| dbo.IDTableType | UDT | Parameter type for receiving tag ID list |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Assign tags to a banner
```sql
DECLARE @Tags dbo.IDTableType;
INSERT INTO @Tags (ID) VALUES (1), (3), (5);

EXEC AffiliateAdmin.CreateMediaTagBanner
    @BannerID = 42,
    @UserEmail = 'admin@company.com',
    @ReasonOfChange = 'Updated tags for Q2 campaign',
    @IdTable = @Tags;
```

### 8.2 Check current tags for a banner
```sql
SELECT mt.TagID, mt.TagName
FROM dbo.MediaTagBanner mtb WITH (NOLOCK)
JOIN dbo.MediaTag mt WITH (NOLOCK) ON mt.TagID = mtb.TagID
WHERE mtb.BannerID = 42;
```

### 8.3 View tag change history for a banner
```sql
SELECT AuditID, ChangedOnDate, UserEmail, OldFieldValue, NewFieldValue, ReasonOfChange
FROM dbo.AuditLog WITH (NOLOCK)
WHERE ChangedSectionID = 10 AND ReferencedChangedID = 42
ORDER BY ChangedOnDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. DDL comments reference PART-4472 (Gil, 11/06/25) and PART-5085 (Gil, 21/12/25).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.CreateMediaTagBanner | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.CreateMediaTagBanner.sql*
