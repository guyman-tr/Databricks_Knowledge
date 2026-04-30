# dbo.CreateBanner

> Creates a new banner record and optionally associates it with one or more media tags in a single transaction. Returns the new BannerID. Calls dbo.CreateMediaTagBanner for each media tag supplied via the table-valued parameter.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Gil Haba |
| **Created** | PART-210 (2022-07-03) |

---

## 1. Business Meaning

Banners are the creative assets that affiliates embed in their websites, emails, and other promotional channels to refer customers to the trading platform. Each banner has a display type, dimensions, content (image URL or ad code), targeting configuration (brand, language, affiliate category), and optional media tag associations.

This procedure is the single point of entry for creating banners. By wrapping the operation in a transaction, it guarantees that a banner is never created without its media tag associations, or vice versa: either the full banner with all its tags is committed, or nothing is.

The @IdTable table-valued parameter (TVP) accepts a set of media tag IDs to associate with the new banner. When the TVP contains rows, the procedure calls dbo.CreateMediaTagBanner for each row to insert the junction records. When the TVP is empty, only the banner row is created.

This procedure is part of the PART-210 banner management initiative, which introduced the IsArchived lifecycle and the media tag association system.

---

## 2. Business Logic

### 2.1 Banner Creation

**What**: A new row is inserted into tblaff_Banners with all display, targeting, and configuration fields.

**Columns/Parameters Involved**: All banner-specific parameters

**Rules**:
- @BannerName must be unique within the brand/category combination (enforced by application; no DB unique constraint is mentioned)
- @IsArchived = 0 at creation time is the standard initial state
- @Priority controls display ordering in the affiliate portal banner picker
- @AdvancedBanner distinguishes rich HTML/JS banners (1) from simple image banners (0)
- @ChangedByUserID records which admin user created the banner for audit purposes

### 2.2 Media Tag Association

**What**: If @IdTable contains rows (media tag IDs), the procedure calls dbo.CreateMediaTagBanner once per row to insert a banner-tag association.

**Columns/Parameters Involved**: `@IdTable`, `@BannerID`

**Rules**:
- @IdTable is a READONLY TVP of type dbo.IDTableType; it carries a list of integer IDs (MediaTag IDs)
- The new @BannerID (captured from SCOPE_IDENTITY() after the banner INSERT) is passed to each dbo.CreateMediaTagBanner call
- If @IdTable is empty, no dbo.CreateMediaTagBanner calls are made
- If any dbo.CreateMediaTagBanner call fails, the transaction is rolled back and no banner or tags are persisted

### 2.3 Transaction Integrity

**What**: The entire operation runs within an explicit transaction.

**Rules**:
- BEGIN TRANSACTION wraps both the INSERT into tblaff_Banners and all calls to dbo.CreateMediaTagBanner
- On success, COMMIT is issued and @BannerID is returned
- On error, ROLLBACK ensures atomicity; partial states (banner without tags) are prevented

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @CategoryID | IN | int | (required) | Banner category, used to associate the banner with affiliate type categories. References tblaff_AffiliateTypeCategories. |
| 2 | @TypeID | IN | int | (required) | Banner display type (e.g., image, HTML, flash). References a banner type lookup. |
| 3 | @BannerName | IN | nvarchar | (required) | Display name for the banner. Shown in the admin and affiliate portal banner picker. |
| 4 | @ImageURL | IN | nvarchar | (required) | URL of the banner image asset. Used for image-type banners; may be NULL for advanced (ad-code) banners. |
| 5 | @TargetURL | IN | nvarchar | (required) | The destination URL when the banner is clicked by a site visitor. Usually contains the affiliate tracking token. |
| 6 | @AltText | IN | nvarchar | (required) | HTML alt text for the banner image, used for accessibility compliance. |
| 7 | @Width | IN | int | (required) | Banner width in pixels (e.g., 300, 728). |
| 8 | @Height | IN | int | (required) | Banner height in pixels (e.g., 250, 90). |
| 9 | @NotesToAffiliate | IN | nvarchar | (required) | Optional notes or usage instructions displayed to affiliates in the portal. |
| 10 | @AdvancedBanner | IN | bit | (required) | 1=rich HTML/JS banner (uses @AdCode), 0=standard image banner (uses @ImageURL). |
| 11 | @AdCode | IN | nvarchar | (required) | HTML or JavaScript ad code for advanced banners. Used when @AdvancedBanner = 1. |
| 12 | @TargetWindow | IN | nvarchar | (required) | HTML target attribute for the banner link: '_blank' (new tab), '_self' (same tab), etc. |
| 13 | @LanguageId | IN | int | (required) | Language of the banner creative. Enables language-targeted banner display. |
| 14 | @BrandId | IN | int | (required) | Brand or label this banner belongs to. Affiliates see only banners matching their brand assignment. |
| 15 | @Priority | IN | int | (required) | Display ordering priority in banner lists. Lower values appear first. |
| 16 | @IsArchived | IN | bit | (required) | Initial archive state; typically 0 (active) at creation time. |
| 17 | @ChangedByUserID | IN | int | (required) | ID of the admin user creating the banner. Stored for audit trail purposes. |
| 18 | @IdTable | IN | dbo.IDTableType READONLY | (required) | Table-valued parameter containing a list of MediaTag IDs to associate with the new banner. Pass an empty TVP if no media tags are needed. |

### Output / Return Value

| Parameter / Column | Direction | Type | Description |
|-------------------|-----------|------|-------------|
| @BannerID | OUT (result set or OUTPUT) | int | The IDENTITY value of the newly created banner row in tblaff_Banners. |

---

## 5. Relationships

### 5.1 Tables Written

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Banners | INSERT | Creates the banner master record |
| dbo.MediaTagBanner | INSERT (via dbo.CreateMediaTagBanner) | One row per media tag in @IdTable; links the new banner to each media tag |

### 5.2 Tables Read

None directly.

### 5.3 Procedures Called

| Procedure | When Called | Notes |
|-----------|-------------|-------|
| dbo.CreateMediaTagBanner | For each row in @IdTable | Creates a banner-media tag association record; called inside the transaction |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CreateBanner (stored procedure)
+-- dbo.tblaff_Banners (table) [INSERT]
+-- dbo.CreateMediaTagBanner (stored procedure) [called per tag row]
    +-- dbo.MediaTagBanner (table) [INSERT]
    +-- dbo.AuditLog (table) [INSERT, if logged by CreateMediaTagBanner]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Banners | Table | Target of the banner INSERT |
| dbo.CreateMediaTagBanner | Stored Procedure | Called to insert each banner-media tag association |
| dbo.IDTableType | User-Defined Table Type | Type of the @IdTable TVP parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Admin banner creation UI | Application | Primary caller; supplies all banner fields and the selected media tag IDs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- The explicit transaction ensures atomicity across the banner INSERT and all media tag association INSERTs
- dbo.IDTableType is a user-defined table type (TVP); the caller must declare and populate a variable of this type before calling the procedure
- @IdTable is READONLY, meaning the procedure cannot modify the TVP contents
- SCOPE_IDENTITY() is used to capture the new BannerID after the tblaff_Banners INSERT
- Introduced under PART-210 as part of the banner lifecycle and media tag management initiative

---

## 8. Sample Queries

### 8.1 Create a standard image banner with no media tags

```sql
DECLARE @tags dbo.IDTableType;

EXEC dbo.CreateBanner
    @CategoryID        = 5,
    @TypeID            = 1,
    @BannerName        = N'Summer Promo 300x250',
    @ImageURL          = N'https://cdn.example.com/banners/summer300x250.png',
    @TargetURL         = N'https://platform.example.com/register',
    @AltText           = N'Join us this summer',
    @Width             = 300,
    @Height            = 250,
    @NotesToAffiliate  = N'Use on sidebar placements',
    @AdvancedBanner    = 0,
    @AdCode            = NULL,
    @TargetWindow      = N'_blank',
    @LanguageId        = 1,
    @BrandId           = 1,
    @Priority          = 10,
    @IsArchived        = 0,
    @ChangedByUserID   = 99,
    @IdTable           = @tags;
```

### 8.2 Create an advanced banner and associate two media tags

```sql
DECLARE @tags dbo.IDTableType;
INSERT INTO @tags (ID) VALUES (7), (12);

EXEC dbo.CreateBanner
    @CategoryID        = 5,
    @TypeID            = 2,
    @BannerName        = N'HTML5 Leaderboard 728x90',
    @ImageURL          = NULL,
    @TargetURL         = N'https://platform.example.com/register',
    @AltText           = N'Trade with us',
    @Width             = 728,
    @Height            = 90,
    @NotesToAffiliate  = N'HTML5 animated banner',
    @AdvancedBanner    = 1,
    @AdCode            = N'<div class="banner">...</div>',
    @TargetWindow      = N'_blank',
    @LanguageId        = 1,
    @BrandId           = 1,
    @Priority          = 5,
    @IsArchived        = 0,
    @ChangedByUserID   = 99,
    @IdTable           = @tags;
```

### 8.3 Verify the created banner and its media tags

```sql
SELECT b.BannerID, b.BannerName, b.Width, b.Height, b.IsArchived,
       mt.Name AS MediaTagName
FROM dbo.tblaff_Banners b WITH (NOLOCK)
LEFT JOIN dbo.MediaTagBanner mtb WITH (NOLOCK) ON b.BannerID = mtb.BannerID
LEFT JOIN dbo.MediaTag mt WITH (NOLOCK) ON mtb.MediaTagID = mt.TagID
WHERE b.BannerName = N'HTML5 Leaderboard 728x90';
```

---

## 9. Atlassian Knowledge Sources

### Jira Issues

| Key | Summary | Relevance |
|-----|---------|-----------|
| PART-210 | Banner management: archive flag and media tag association system | This procedure was created as part of the PART-210 initiative (Gil Haba, 2022-07-03) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10*
*Object: dbo.CreateBanner | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.CreateBanner.sql*
