# AffiliateAdmin.CreateMediaTag

> Creates a new media tag in the system if one with the same name does not already exist, with audit logging, and returns the tag ID.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns @TagID (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.CreateMediaTag provides the backend logic for creating new media tags in the affiliate marketing platform. Media tags are labels applied to banners and creative assets to categorize and filter them for affiliates. For example, tags might represent campaign themes, seasonal promotions, or content categories that help affiliates find relevant marketing materials.

This procedure exists because the affiliate admin portal needs a controlled way to create new tags while preventing duplicates. Without it, duplicate tag names could proliferate, making it difficult for affiliates to filter banners consistently. The idempotent design (returns existing TagID if name already exists) ensures safe retries.

Data flow: The admin portal calls this procedure when a user creates a new media tag. The procedure checks if a tag with the given name already exists in `dbo.MediaTag`. If not, it inserts the new tag within a transaction, logs the creation to `dbo.AuditLog` with ChangedSectionID=10 (MediaTag) and ActionID=1 (Insert), then returns the TagID. If the tag name already exists, it simply returns the existing TagID without modification.

---

## 2. Business Logic

### 2.1 Idempotent Tag Creation

**What**: The procedure is idempotent - calling it with an existing tag name returns the existing tag ID instead of creating a duplicate.

**Columns/Parameters Involved**: `@Name`, `@TagID`

**Rules**:
- First attempts to find an existing tag by exact name match: `SELECT @TagID = TagID FROM dbo.MediaTag WHERE TagName = @Name`
- If found (@TagID is not null), skips the INSERT entirely and returns the existing ID
- If not found, creates a new row and returns the SCOPE_IDENTITY()
- This prevents duplicate tags and makes the procedure safe for retry

**Diagram**:
```
@Name --> Lookup in dbo.MediaTag
           |
     +-----+-----+
     |             |
   Found       Not Found
     |             |
   Return      INSERT new tag
   existing      |
   TagID       AuditLog (Section=10, Action=1)
                 |
               Return new TagID
```

### 2.2 Transactional Audit Logging

**What**: Tag creation and its audit log entry are wrapped in a single transaction to ensure consistency.

**Columns/Parameters Involved**: `@UserEmail`, `@TagID`

**Rules**:
- The INSERT into MediaTag and the INSERT into AuditLog happen within the same BEGIN TRAN / COMMIT
- AuditLog entry records: ChangedSectionID=10 (MediaTag), ActionID=1 (Insert), ReasonOfChange includes the new TagID
- Error handling uses the standard pattern: ROLLBACK if last tran, COMMIT if nested, then THROW

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserEmail | nvarchar(250) | NO | - | CODE-BACKED | Email of the admin user performing the action. Logged to AuditLog.UserEmail for accountability. Matches the Azure AD email synced to AffiliateAdmin.Users. |
| 2 | @Name | nvarchar(500) | NO | - | CODE-BACKED | Display name for the new media tag. Checked for uniqueness against dbo.MediaTag.TagName before insertion. |
| 3 | @TranslationKey | varchar(128) | NO | - | CODE-BACKED | Internationalization key for the tag name. Stored in dbo.MediaTag.TranslationKey for localized display in the affiliate portal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT INTO | dbo.MediaTag | Write | Creates new media tag records |
| INSERT INTO | dbo.AuditLog | Write | Creates audit trail entry for tag creation with SectionID=10 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.CreateMediaTag (procedure)
+-- dbo.MediaTag (table)
+-- dbo.AuditLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.MediaTag | Table | SELECT to check existence, INSERT to create new tags |
| dbo.AuditLog | Table | INSERT to log creation audit entry |

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

### 8.1 Create a new media tag
```sql
EXEC AffiliateAdmin.CreateMediaTag
    @UserEmail = 'admin@company.com',
    @Name = 'Summer Campaign 2026',
    @TranslationKey = 'tag.summer_campaign_2026';
```

### 8.2 Verify tag was created
```sql
SELECT TagID, TagName, TranslationKey
FROM dbo.MediaTag WITH (NOLOCK)
WHERE TagName = 'Summer Campaign 2026';
```

### 8.3 Check audit log for tag creations
```sql
SELECT AuditID, ChangedOnDate, UserEmail, ReasonOfChange
FROM dbo.AuditLog WITH (NOLOCK)
WHERE ChangedSectionID = 10 AND ActionID = 1
ORDER BY ChangedOnDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Comment in DDL references PART-4214 (move from affwizard to affiliateadmin, Gil 31/3/2025).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.CreateMediaTag | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.CreateMediaTag.sql*
