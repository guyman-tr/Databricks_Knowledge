# dbo.GetBannerById

> Retrieves a single banner with its type, language, and optional affiliate-type category details by banner ID, joining four tables to assemble the complete banner record.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

Banners are the core creative assets distributed through the affiliate platform. A fully resolved banner record requires not just the image and targeting metadata from tblaff_Banners but also the human-readable banner-type name, the full language record (including landing page URLs), and the optional affiliate-type category that scopes the banner to a specific programme segment.

This procedure assembles that complete view for a single banner. It is the canonical read path for the banner detail page and for any API endpoint that must return a fully hydrated banner object by ID, including all attributes needed to render the creative and configure the affiliate's tracking link.

---

## 2. Business Logic

### 2.1 Full Banner Record Assembly

**What**: Joins banner, type, language, and category tables to return all attributes of one banner.

**Columns/Parameters Involved**: `@Id`, `Banners.BannerID`, `BannerTypes.BannerTypeID`, `Languages.LanguageID`, `AffiliateTypeCategories.CategoryID`

**Rules**:
- The INNER JOINs to tblaff_BannerTypes and tblaff_Languages are mandatory; a banner without a valid Type or LanguageID would not be returned (data integrity expectation)
- The LEFT JOIN to tblaff_AffiliateTypeCategories means banners that are not linked to any affiliate-type category still appear in results with NULL category columns
- IsArchived is included in the output but not used as a filter; archived banners are returned if they exist for the requested ID
- If no banner exists with the given @Id, zero rows are returned

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @Id | IN | int | (required) | The BannerID primary key of the banner to retrieve. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Banners | SELECT | Primary source of banner attributes |
| dbo.tblaff_BannerTypes | SELECT (INNER JOIN) | Resolves banner type name from the type ID |
| dbo.tblaff_Languages | SELECT (INNER JOIN) | Resolves full language record including landing page URLs |
| dbo.tblaff_AffiliateTypeCategories | SELECT (LEFT JOIN) | Provides optional affiliate-type category linkage |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| BannerID | tblaff_Banners | Primary key |
| Type | tblaff_Banners | Banner type foreign key |
| BannerName | tblaff_Banners | Display name of the banner |
| ImageURL | tblaff_Banners | URL of the banner image asset |
| TargetURL | tblaff_Banners | Destination URL when the banner is clicked |
| AltText | tblaff_Banners | Accessibility alt text |
| Width / Height | tblaff_Banners | Pixel dimensions |
| PerSale / PerLead / PerClick | tblaff_Banners | Commission rates by event type |
| NotesToAffiliate | tblaff_Banners | Free-text notes displayed to the affiliate |
| AdvancedBanner | tblaff_Banners | Flag: 1 = HTML/JS creative, 0 = simple image |
| AdCode | tblaff_Banners | Raw HTML/JS ad code for advanced banners |
| TargetWindow | tblaff_Banners | Link target attribute (_blank, _self, etc.) |
| BrandID | tblaff_Banners | Brand association |
| Priority | tblaff_Banners | Display priority ordering |
| IsArchived | tblaff_Banners | Whether the banner has been archived |
| BannerTypeID / BannerTypeName | tblaff_BannerTypes | Type ID and human-readable type name |
| LanguageID / LanguageName / ... | tblaff_Languages | Full language record including TLDURL and landing pages |
| CategoryID / AffiliateTypeID | tblaff_AffiliateTypeCategories | Category and affiliate-type scope (NULL if uncategorised) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetBannerById (stored procedure)
+-- dbo.tblaff_Banners (table) [SELECT]
    +-- dbo.tblaff_BannerTypes (table) [INNER JOIN on Type]
    +-- dbo.tblaff_Languages (table) [INNER JOIN on LanguageID]
    +-- dbo.tblaff_AffiliateTypeCategories (table) [LEFT JOIN on CategoryID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Banners | Table | Primary source of banner data |
| dbo.tblaff_BannerTypes | Table | Resolves banner type name |
| dbo.tblaff_Languages | Table | Resolves language and landing page data |
| dbo.tblaff_AffiliateTypeCategories | Table | Provides optional affiliate-type category scope |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Banner detail/edit UI | Application | Calls this procedure to load a fully hydrated banner for display or editing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- All four tables use WITH (NOLOCK); accepts dirty reads consistent with the banner catalog pattern
- No IsArchived filter; archived banners are returned if requested by ID -- callers must handle this if needed
- CategoryID in tblaff_Banners links to tblaff_AffiliateTypeCategories.CategoryID, not directly to tblaff_AffiliateTypes

---

## 8. Sample Queries

### 8.1 Retrieve a banner by ID

```sql
EXEC dbo.GetBannerById @Id = 101;
```

### 8.2 Verify banner type and language for a banner

```sql
SELECT b.BannerID, bt.BannerTypeName, l.LanguageName
FROM dbo.tblaff_Banners b WITH (NOLOCK)
JOIN dbo.tblaff_BannerTypes bt WITH (NOLOCK) ON b.Type = bt.BannerTypeID
JOIN dbo.tblaff_Languages l  WITH (NOLOCK) ON b.LanguageID = l.LanguageID
WHERE b.BannerID = 101;
```

### 8.3 List archived banners

```sql
SELECT BannerID, BannerName, IsArchived
FROM dbo.tblaff_Banners WITH (NOLOCK)
WHERE IsArchived = 1
ORDER BY BannerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10*
*Object: dbo.GetBannerById | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetBannerById.sql*
