# AffiliateAdmin.DeleteAnnouncements

> Hard-deletes one or more announcements and their affiliate type associations, with audit logging.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from dbo.tblaff_Announcement |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.DeleteAnnouncements removes announcements that are displayed to affiliates in the partner portal. Announcements are time-limited messages (promotions, news) targeted to specific affiliate types. This procedure performs a hard delete (unlike the soft-delete pattern used for affiliate types), removing both the announcement and its type targeting associations.

This procedure exists because announcements are ephemeral content - once expired or irrelevant, they should be fully removed rather than hidden. The procedure deletes child records first (tblaff_Announcement_AffiliateType) then parent records (tblaff_Announcement), maintaining referential integrity.

Data flow: Admin sends announcement IDs via `dbo.IDTableType`. The procedure resolves the 'Announcements' section ID from Dictionary.ChangedSections, deletes child rows from tblaff_Announcement_AffiliateType, then parent rows from tblaff_Announcement. If rows were deleted, audit entries are created with ActionID=3 (Delete).

---

## 2. Business Logic

### 2.1 Parent-Child Cascade Delete

**What**: Deletes child records (type associations) before parent records (announcements) to maintain referential integrity.

**Columns/Parameters Involved**: `@AnnouncementIDsToDelete`

**Rules**:
- DELETE FROM tblaff_Announcement_AffiliateType first (child)
- DELETE FROM tblaff_Announcement second (parent)
- Audit logging only occurs if parent rows were actually deleted (@@ROWCOUNT > 0)
- All operations are within a single transaction

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AnnouncementIDsToDelete | dbo.IDTableType | READONLY | - | CODE-BACKED | Table-valued parameter containing AnnouncementIDs to delete from dbo.tblaff_Announcement. |
| 2 | @UserEmail | nvarchar(250) | NO | - | CODE-BACKED | Email of the admin user. Written to AuditLog.UserEmail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | dbo.tblaff_Announcement_AffiliateType | Write | Removes type targeting associations |
| DELETE | dbo.tblaff_Announcement | Write | Removes the announcement records |
| SELECT | Dictionary.ChangedSections | Read | Resolves SectionID for 'Announcements'. See [Changed Sections](../../_glossary.md#changed-sections): ID=4. |
| INSERT INTO | dbo.AuditLog | Write | Logs deletions with ActionID=3 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.DeleteAnnouncements (procedure)
+-- dbo.tblaff_Announcement_AffiliateType (table)
+-- dbo.tblaff_Announcement (table)
+-- Dictionary.ChangedSections (table)
+-- dbo.AuditLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Announcement | Table | DELETE target |
| dbo.tblaff_Announcement_AffiliateType | Table | DELETE target (child records) |
| Dictionary.ChangedSections | Table | Lookup SectionID for 'Announcements' |
| dbo.AuditLog | Table | INSERT for audit trail |

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

### 8.1 Delete announcements
```sql
DECLARE @Ids dbo.IDTableType;
INSERT INTO @Ids (ID) VALUES (10), (11);
EXEC AffiliateAdmin.DeleteAnnouncements @AnnouncementIDsToDelete = @Ids, @UserEmail = 'admin@company.com';
```

### 8.2 Find expired announcements for cleanup
```sql
SELECT AnnouncementID, AnnouncementHeadline, AnnouncementExpirationDate
FROM dbo.tblaff_Announcement WITH (NOLOCK)
WHERE AnnouncementExpirationDate < GETUTCDATE()
ORDER BY AnnouncementExpirationDate;
```

### 8.3 Review announcement deletion audit trail
```sql
SELECT ChangedOnDate, UserEmail, ReasonOfChange, ReferencedChangedID
FROM dbo.AuditLog WITH (NOLOCK)
WHERE ChangedSectionID = (SELECT SectionID FROM Dictionary.ChangedSections WITH (NOLOCK) WHERE Name = 'Announcements')
  AND ActionID = 3
ORDER BY ChangedOnDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4678 (Gil, 10/08/25).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.DeleteAnnouncements | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.DeleteAnnouncements.sql*
