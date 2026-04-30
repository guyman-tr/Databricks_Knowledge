# AffiliateAdmin.UpdateInsertBanners

> Upserts a banner record with media tag associations, validating category, language, and brand references, with full field-level audit logging.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OutputBannerID (inserted or updated BannerID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateInsertBanners upserts a banner record in `tblaff_Banners` along with its media tag associations. The procedure handles all banner attributes including creative content (image URL, ad code, alt text), display properties (width, height, priority, target window), organizational metadata (category, type, language, brand), and the list of associated media tags. It validates that the referenced CategoryID, LanguageID, and BrandID exist before proceeding.

**WHY:** Banners are the primary creative assets that affiliates use to promote the platform. Each banner contains the visual content, targeting configuration, and organizational metadata needed for proper display and tracking. The upsert with validation ensures that banners always reference valid categories, languages, and brands, preventing broken banner configurations. Media tag associations enable flexible categorization and filtering of banners for affiliate selection.

**HOW:** The procedure first validates that @CategoryID, @LanguageId, and @BrandId reference existing records in their respective tables. It then checks @BannerID to determine INSERT or UPDATE mode. For inserts, a new banner row is created with all provided attributes. For updates, fields are compared and changes are audit-logged. After the banner record is saved, the media tag associations are managed through the @IdTable TVP -- existing tags are replaced with the provided set. The @OutputBannerID returns the banner ID.

---

## 2. Business Logic

### 2.1 Reference Validation
Before performing any data modification, the procedure validates:
- **CategoryID:** Must exist in `tblaff_Categories`
- **LanguageID:** Must exist in `tblaff_Languages`
- **BrandID:** Must exist in `tblaff_Brands`
If any validation fails, the procedure exits without making changes.

### 2.2 Insert vs. Update Detection
- **@BannerID = 0 or NULL:** INSERT a new banner record
- **@BannerID > 0:** UPDATE the existing banner record

### 2.3 Banner Content Fields
The banner record includes:
- **Creative:** ImageURL, AdCode (for advanced banners), AltText
- **Display:** Width, Height, Priority, TargetWindow, IsArchived
- **Organization:** CategoryID, TypeID, LanguageId, BrandId, BannerName
- **Content:** NotesToAffiliate, AdvancedBanner flag, TargetURL

### 2.4 Media Tag Association
The @IdTable TVP (dbo.IDTableType) contains the set of media tag IDs to associate with the banner. The procedure replaces the existing tag associations for the banner, similar to the DELETE-then-INSERT pattern used in other procedures.

### 2.5 Advanced Banner Support
The @AdvancedBanner bit flag indicates whether the banner uses custom ad code (@AdCode) instead of a simple image (@ImageURL). This affects how the banner is rendered in the affiliate portal.

### 2.6 Field-Level Audit Logging
On UPDATE, each field is individually compared and changes are logged with old and new values, the performing user, and the banner ID as the referenced entity.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BannerID | INT | No | - | CODE-BACKED | 0 for INSERT, >0 for UPDATE |
| 2 | @CategoryID | INT | No | - | CODE-BACKED | Banner category (validated against tblaff_Categories) |
| 3 | @TypeID | INT | No | - | CODE-BACKED | Banner type identifier |
| 4 | @BannerName | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Display name for the banner |
| 5 | @ImageURL | NVARCHAR(500) | Yes | NULL | CODE-BACKED | URL of the banner image |
| 6 | @TargetURL | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Click-through destination URL |
| 7 | @AltText | NVARCHAR(500) | Yes | NULL | CODE-BACKED | Alt text for image accessibility |
| 8 | @Width | INT | Yes | NULL | CODE-BACKED | Banner width in pixels |
| 9 | @Height | INT | Yes | NULL | CODE-BACKED | Banner height in pixels |
| 10 | @NotesToAffiliate | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Instructions/notes for affiliates using this banner |
| 11 | @AdvancedBanner | BIT | Yes | 0 | CODE-BACKED | Flag for custom ad code banners |
| 12 | @AdCode | NVARCHAR(MAX) | Yes | NULL | CODE-BACKED | Custom HTML/JS ad code (for advanced banners) |
| 13 | @TargetWindow | NVARCHAR(50) | Yes | NULL | CODE-BACKED | Link target (_blank, _self, etc.) |
| 14 | @LanguageId | INT | Yes | NULL | CODE-BACKED | Language (validated against tblaff_Languages) |
| 15 | @BrandId | INT | Yes | NULL | CODE-BACKED | Brand (validated against tblaff_Brands) |
| 16 | @Priority | INT | Yes | NULL | CODE-BACKED | Display priority/sort order |
| 17 | @IsArchived | BIT | Yes | 0 | CODE-BACKED | Archive status flag |
| 18 | @UserEmail | NVARCHAR(250) | No | - | CODE-BACKED | Admin user performing the change (for audit) |
| 19 | @IdTable | dbo.IDTableType READONLY | No | - | CODE-BACKED | TVP containing media tag IDs to associate |
| 20 | @OutputBannerID | INT | No | OUTPUT | CODE-BACKED | Returns the BannerID (new or existing) |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Banners` | Table | INSERT or UPDATE banner record |
| `dbo.tblaff_Categories` | Table | Validate CategoryID exists |
| `dbo.tblaff_Languages` | Table | Validate LanguageID exists |
| `dbo.tblaff_Brands` | Table | Validate BrandID exists |
| `dbo.MediaTagBanner` | Table | Replace media tag associations |
| `dbo.AuditLog` | Table | INSERT field-level audit entries |
| `dbo.IDTableType` | User-Defined Table Type | Input type for media tag ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Banner management screen | Application | Create or edit banners |
| Banner upload wizard | Application | Multi-step banner creation |
| Creative asset management | Application | Bulk banner operations |

---

## 6. Dependencies

### 6.0 Chain
`UpdateInsertBanners` -> validate Category + Language + Brand -> check @BannerID -> INSERT or UPDATE `tblaff_Banners` -> replace `MediaTagBanner` associations -> `AuditLog` (INSERT per changed field)

### 6.1 Depends On
- `dbo.tblaff_Banners` - Banner record storage
- `dbo.tblaff_Categories` - Category validation
- `dbo.tblaff_Languages` - Language validation
- `dbo.tblaff_Brands` - Brand validation
- `dbo.MediaTagBanner` - Media tag junction table
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
-- 1. Create a new image banner with media tags
DECLARE @Tags dbo.IDTableType;
INSERT INTO @Tags (ID) VALUES (1), (5), (8);
DECLARE @NewID INT;
EXEC AffiliateAdmin.UpdateInsertBanners
    @BannerID = 0,
    @CategoryID = 2,
    @TypeID = 1,
    @BannerName = N'Spring Campaign 300x250',
    @ImageURL = N'/banners/spring2026_300x250.png',
    @TargetURL = N'https://www.example.com/?aid={affiliate_id}',
    @AltText = N'Spring promotion - sign up today',
    @Width = 300,
    @Height = 250,
    @LanguageId = 1,
    @BrandId = 1,
    @Priority = 1,
    @IsArchived = 0,
    @UserEmail = N'creative@company.com',
    @IdTable = @Tags,
    @OutputBannerID = @NewID OUTPUT;
SELECT @NewID AS CreatedBannerID;
```

```sql
-- 2. Update banner image and target URL
DECLARE @Tags dbo.IDTableType;
INSERT INTO @Tags (ID) VALUES (1), (5), (8);
DECLARE @BID INT = 150;
EXEC AffiliateAdmin.UpdateInsertBanners
    @BannerID = @BID,
    @CategoryID = 2,
    @TypeID = 1,
    @BannerName = N'Spring Campaign 300x250 v2',
    @ImageURL = N'/banners/spring2026_300x250_v2.png',
    @TargetURL = N'https://www.example.com/spring/?aid={affiliate_id}',
    @AltText = N'Spring promotion v2',
    @Width = 300,
    @Height = 250,
    @LanguageId = 1,
    @BrandId = 1,
    @UserEmail = N'creative@company.com',
    @IdTable = @Tags,
    @OutputBannerID = @BID OUTPUT;
```

```sql
-- 3. Create an advanced banner with custom ad code
DECLARE @Tags dbo.IDTableType;
INSERT INTO @Tags (ID) VALUES (3);
DECLARE @NewID INT;
EXEC AffiliateAdmin.UpdateInsertBanners
    @BannerID = 0,
    @CategoryID = 5,
    @TypeID = 2,
    @BannerName = N'Interactive Widget',
    @AdvancedBanner = 1,
    @AdCode = N'<div class="widget" data-aid="{affiliate_id}"><script src="/widgets/interactive.js"></script></div>',
    @Width = 728,
    @Height = 90,
    @LanguageId = 1,
    @BrandId = 2,
    @UserEmail = N'creative@company.com',
    @IdTable = @Tags,
    @OutputBannerID = @NewID OUTPUT;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-4718, PART-4472, PART-5085.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateInsertBanners | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertBanners.sql*
