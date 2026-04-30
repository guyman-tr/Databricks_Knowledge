# AffiliateAdmin.UpdateInsertAnnouncement

> Upserts an announcement with affiliate type targeting using MERGE on the type association table, with full field-level audit logging.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OutputAnnouncementID (inserted or updated AnnouncementID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertAnnouncement upserts an announcement record in `tblaff_Announcement` and manages affiliate type targeting through `tblaff_Announcement_AffiliateType`. It handles announcement content (headline, image, body content), expiration dates, promotion flags, and the set of affiliate types that should see the announcement. The MERGE pattern on the type association table efficiently handles adding, removing, and retaining type assignments.

**WHY:** Announcements are used to communicate important information to affiliates -- promotions, policy changes, new features, or time-sensitive offers. Different announcements may target different affiliate types (e.g., premium partners see different promotions than standard affiliates). The combined announcement + type targeting upsert ensures that content and targeting are always saved together, and the field-level audit trail supports content governance and compliance review.

**HOW:** The procedure checks @ID to determine INSERT or UPDATE mode. For inserts, it creates a new `tblaff_Announcement` row with all content fields. For updates, it compares each field and logs changes. In both cases, it then uses a MERGE statement on `tblaff_Announcement_AffiliateType` to synchronize the type targeting: new types are inserted, removed types are deleted, and existing matches are left unchanged. The @OutputAnnouncementID returns the announcement ID.

---

## 2. Business Logic

### 2.1 Insert vs. Update Detection
- **@ID = 0 or NULL:** INSERT a new announcement
- **@ID > 0:** UPDATE the existing announcement

### 2.2 Announcement Content Fields
- **Headline:** Short title text for the announcement
- **Image:** URL or reference to an announcement image
- **Content:** Full body content of the announcement (rich text/HTML)
- **ExpirationDate:** When the announcement should stop being displayed
- **IsTypePromotions:** Flag indicating if this is a promotional announcement

### 2.3 Affiliate Type Targeting via MERGE
The @AffiliateTypeIDs TVP contains the set of affiliate types that should see this announcement. The MERGE statement on `tblaff_Announcement_AffiliateType`:
- **WHEN NOT MATCHED BY TARGET:** INSERT new type associations
- **WHEN NOT MATCHED BY SOURCE:** DELETE removed type associations
- **WHEN MATCHED:** No action needed (association already exists)

### 2.4 Field-Level Audit Logging
On UPDATE, each content field is compared against its current value. Individual audit entries are created for changed fields including: Headline, Image, Content, ExpirationDate, IsTypePromotions, and the type association list.

### 2.5 Output Parameter
@OutputAnnouncementID returns the announcement ID to the caller for both INSERT and UPDATE operations.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | INT | No | - | CODE-BACKED | 0 for INSERT, >0 for UPDATE of existing announcement |
| 2 | @ExpirationDate | DATETIME | Yes | NULL | CODE-BACKED | When the announcement expires |
| 3 | @Headline | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Announcement title/headline |
| 4 | @Image | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Image URL for the announcement |
| 5 | @Content | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Full body content (rich text/HTML) |
| 6 | @IsTypePromotions | BIT | Yes | NULL | CODE-BACKED | Flag for promotional announcements |
| 7 | @AffiliateTypeIDs | dbo.IDTableType READONLY | No | - | CODE-BACKED | TVP containing affiliate type IDs that should see this announcement |
| 8 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 9 | @ReasonOfChange | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Reason for the change (audit context) |
| 10 | @OutputAnnouncementID | INT | No | OUTPUT | CODE-BACKED | Returns the AnnouncementID (new or existing) |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Announcement` | Table | INSERT or UPDATE announcement record |
| `dbo.tblaff_Announcement_AffiliateType` | Table | MERGE type targeting associations |
| `dbo.AuditLog` | Table | INSERT field-level audit entries |
| `dbo.IDTableType` | User-Defined Table Type | Input type for affiliate type ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Announcement management screen | Application | Create or edit announcements |
| Promotion campaign tool | Application | Create promotional announcements with targeting |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertAnnouncement` -> check @ID -> INSERT or UPDATE `tblaff_Announcement` -> MERGE `tblaff_Announcement_AffiliateType` -> `AuditLog` (INSERT per changed field)

### 6.1 Depends On
- `dbo.tblaff_Announcement` - Announcement record storage
- `dbo.tblaff_Announcement_AffiliateType` - Type targeting junction table
- `dbo.AuditLog` - Audit trail storage
- `dbo.IDTableType` - User-defined table type for ID list input

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
-- 1. Create a new announcement targeted at specific affiliate types
DECLARE @Types dbo.IDTableType;
INSERT INTO @Types (ID) VALUES (1), (3), (5);
DECLARE @NewID INT;
EXEC AffiliateAdmin.UpdateInsertAnnouncement
    @ID = 0,
    @ExpirationDate = '2026-06-30',
    @Headline = N'Summer Promotion - Increased Commissions',
    @Image = N'/images/announcements/summer2026.png',
    @Content = N'<p>Commission rates increased by 20% for all summer registrations.</p>',
    @IsTypePromotions = 1,
    @AffiliateTypeIDs = @Types,
    @UserEmail = N'marketing@company.com',
    @ReasonOfChange = N'Q3 summer promotion launch',
    @OutputAnnouncementID = @NewID OUTPUT;
SELECT @NewID AS AnnouncementID;
```

```sql
-- 2. Update announcement content and retarget
DECLARE @Types dbo.IDTableType;
INSERT INTO @Types (ID) VALUES (1), (2), (3), (4), (5);
DECLARE @AnnID INT = 42;
EXEC AffiliateAdmin.UpdateInsertAnnouncement
    @ID = @AnnID,
    @Headline = N'Summer Promotion Extended!',
    @ExpirationDate = '2026-07-31',
    @Content = N'<p>Due to popular demand, summer promotion extended through July.</p>',
    @IsTypePromotions = 1,
    @AffiliateTypeIDs = @Types,
    @UserEmail = N'marketing@company.com',
    @ReasonOfChange = N'Extended promotion and broadened targeting',
    @OutputAnnouncementID = @AnnID OUTPUT;
```

```sql
-- 3. Create a non-promotional system announcement for all types
DECLARE @AllTypes dbo.IDTableType;
INSERT INTO @AllTypes (ID) SELECT AffiliateTypeID FROM dbo.tblaff_AffiliateTypes;
DECLARE @NewID INT;
EXEC AffiliateAdmin.UpdateInsertAnnouncement
    @ID = 0,
    @ExpirationDate = '2026-05-01',
    @Headline = N'System Maintenance Notice',
    @Content = N'<p>Scheduled maintenance window: April 15, 2AM-4AM UTC.</p>',
    @IsTypePromotions = 0,
    @AffiliateTypeIDs = @AllTypes,
    @UserEmail = N'admin@company.com',
    @ReasonOfChange = N'Maintenance notification',
    @OutputAnnouncementID = @NewID OUTPUT;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4678.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertAnnouncement | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAnnouncement.sql*
