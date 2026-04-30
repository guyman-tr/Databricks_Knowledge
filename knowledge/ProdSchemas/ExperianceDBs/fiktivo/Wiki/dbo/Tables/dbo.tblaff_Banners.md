# dbo.tblaff_Banners

> Individual marketing banner/creative assets that affiliates embed on their websites, with targeting by category, language, brand, and type.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | BannerID (INT IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 nonclustered PK, 1 covering Banners_Covered, 1 on Type+LanguageID+BrandID) |

---

## 1. Business Meaning

This table stores every marketing creative asset (banner, text link, widget, video, landing page link) available to affiliates. Each banner has dimensions, a target URL with tracking, alternative text, and is tagged by category, type, language, and brand. Affiliates select banners from the portal to generate tracking code for their websites.

Without this table, the affiliate program would have no marketing collateral to offer partners. Currently 4,632 banners. System-versioned with temporal history in History.tblaff_Banners for tracking creative changes. Managed by admin users with Banners_* permissions.

---

## 2. Business Logic

### 2.1 Banner Classification System

**What**: Each banner is classified along four dimensions for filtering and targeting.

**Columns/Parameters Involved**: `CategoryID`, `Type`, `LanguageID`, `BrandID`, `IsArchived`

**Rules**:
- CategoryID references [tblaff_Categories](dbo.tblaff_Categories.md) for content grouping (e.g., "Landing Pages", "Widgets")
- Type references [tblaff_BannerTypes](dbo.tblaff_BannerTypes.md).BannerTypeID for format (1=GIF, 2=Flash, 3=Text, etc.)
- LanguageID references [tblaff_Languages](dbo.tblaff_Languages.md) for locale targeting
- BrandID references [tblaff_Brands](dbo.tblaff_Brands.md) for entity/jurisdiction separation
- IsArchived=1 hides the banner from affiliate selection without deleting it
- Affiliates can only see banners in categories mapped to their affiliate type (via tblaff_AffiliateTypeCategories)

### 2.2 Commission Model Flags

**What**: Banners indicate which commission events they are optimized for.

**Columns/Parameters Involved**: `PerSale`, `PerLead`, `PerClick`

**Rules**:
- PerSale=1: banner is optimized for sale/deposit conversions
- PerLead=1: banner is optimized for lead generation
- PerClick=1: banner is optimized for click volume
- An affiliate's commission plan determines which model applies, but the banner flags help affiliates choose assets aligned with their plan

---

## 3. Data Overview

N/A - Banner configurations are operational. See element descriptions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BannerID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Referenced by tblaff_GroupBanners, tblaff_MediaTagBanner, and commission event tables (tblaff_Sales.BannerID, etc.) for conversion attribution. |
| 2 | CategoryID | int | YES | 0 | CODE-BACKED | References [dbo.tblaff_Categories](dbo.tblaff_Categories.md).CategoryID. Content category of the banner. |
| 3 | Type | int | YES | 0 | CODE-BACKED | References [dbo.tblaff_BannerTypes](dbo.tblaff_BannerTypes.md).BannerTypeID. Media format: 1=GIF, 2=Flash, 3=Text, 4=Rotating, 5=Links, 6=Widgets, 7=Videos, 8=Articles, 9=White Labels, 10=Mailers, 11=Education, 12=Logos. |
| 4 | BannerName | nvarchar(255) | YES | - | CODE-BACKED | Display name of the banner asset for admin and affiliate portal listing. |
| 5 | ImageURL | nvarchar(255) | YES | - | CODE-BACKED | URL to the banner image/asset file. For GIF/Flash banners, points to the creative file. |
| 6 | TargetURL | nvarchar(255) | YES | - | CODE-BACKED | Click-through URL. Where users are directed when they click the banner. Typically includes tracking parameters. |
| 7 | AltText | nvarchar(255) | YES | - | CODE-BACKED | HTML alt text for the banner image. Used for accessibility and SEO. |
| 8 | Width | int | YES | 0 | CODE-BACKED | Banner width in pixels. Standard IAB sizes (728, 300, 160, etc.). 0 = variable/responsive. |
| 9 | Height | int | YES | 0 | CODE-BACKED | Banner height in pixels. 0 = variable/responsive. |
| 10 | PerSale | bit | NO | 0 | CODE-BACKED | Banner optimized for sale/deposit conversion tracking. |
| 11 | PerLead | bit | NO | 0 | CODE-BACKED | Banner optimized for lead generation tracking. |
| 12 | PerClick | bit | NO | 0 | CODE-BACKED | Banner optimized for click-based tracking. |
| 13 | NotesToAffiliate | nvarchar(1000) | YES | - | CODE-BACKED | Instructions or notes for affiliates about how to best use this banner. |
| 14 | AdvancedBanner | bit | NO | 0 | CODE-BACKED | Whether this banner uses advanced/custom HTML instead of a standard image. 1 = custom AdCode content. |
| 15 | AdCode | ntext | YES | - | CODE-BACKED | Custom HTML/JavaScript ad code for advanced banners (AdvancedBanner=1). Affiliates paste this code directly into their sites. |
| 16 | TargetWindow | nvarchar(50) | YES | - | CODE-BACKED | HTML target window for the click-through link (e.g., "_blank", "_self", "_top"). |
| 17 | LanguageID | int | YES | 1 | CODE-BACKED | References [dbo.tblaff_Languages](dbo.tblaff_Languages.md).LanguageID. Locale of the banner content. Default 1 (English). |
| 18 | BrandID | int | YES | - | CODE-BACKED | References [dbo.tblaff_Brands](dbo.tblaff_Brands.md).BrandID. Brand/entity for regulatory targeting. |
| 19 | Priority | int | YES | - | NAME-INFERRED | Display priority/sort order for banners within the same category. Lower values may appear first. |
| 20 | IsArchived | bit | NO | 0 | CODE-BACKED | Archive flag. 1 = hidden from affiliate selection. 0 = active. |
| 21 | Trace | computed | NO | - | CODE-BACKED | Computed audit column. JSON with session metadata. |
| 22 | ValidFrom | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning period start. Hidden. |
| 23 | ValidTo | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | System-versioning period end. Hidden. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CategoryID | [dbo.tblaff_Categories](dbo.tblaff_Categories.md) | Implicit FK | Content category. |
| Type | [dbo.tblaff_BannerTypes](dbo.tblaff_BannerTypes.md) | Implicit FK | Media format type. |
| LanguageID | [dbo.tblaff_Languages](dbo.tblaff_Languages.md) | Implicit FK | Target language. |
| BrandID | [dbo.tblaff_Brands](dbo.tblaff_Brands.md) | Implicit FK | Brand/entity. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_GroupBanners | BannerID | Implicit FK | Links banner to display groups. Cascade-deleted via trigger. |
| dbo.tblaff_MediaTagBanner | BannerID | Implicit FK | Links banner to tracking tags. |
| dbo.tblaff_Sales | BannerID | Implicit FK | Attribution - which banner led to the sale. |
| dbo.tblaff_Leads | BannerID | Implicit FK | Attribution - which banner led to the lead. |
| dbo.tblaff_CPA | BannerID | Implicit FK | Attribution - which banner led to the CPA event. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no hard dependencies (all FKs are implicit).

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_GroupBanners | Table | BannerID referenced |
| dbo.tblaff_MediaTagBanner | Table | BannerID referenced |
| dbo.GetBanners | Stored Procedure | READER |
| dbo.GetBannerById | Stored Procedure | READER |
| dbo.CreateBanner | Stored Procedure | WRITER |
| dbo.UpdateBanner | Stored Procedure | MODIFIER |
| dbo.ArchiveBanner | Stored Procedure | MODIFIER - sets IsArchived=1 |
| dbo.BannerSearch | Stored Procedure | READER - search/filter banners |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Banners_PK | NC PK | BannerID | - | - | Active |
| Banners_Covered | NC | BannerID, CategoryID, Type, Width, Height | - | - | Active |
| IX_tblaff_Banners_Incl1 | NC | Type, LanguageID, BrandID | BannerID, CategoryID, BannerName, Width, Height, AdvancedBanner | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SYSTEM_VERSIONING | Temporal | History table: History.tblaff_Banners |
| tblaff_Banners_DTrig | TRIGGER (DELETE) | Cascade-deletes GroupBanners rows |
| tblaff_Banners_UTrig | TRIGGER (UPDATE) | Prevents BannerID update if GroupBanners exist |

---

## 8. Sample Queries

### 8.1 List active banners by type and language
```sql
SELECT b.BannerID, b.BannerName, bt.BannerTypeName, l.LanguageName, b.Width, b.Height
FROM dbo.tblaff_Banners b WITH (NOLOCK)
JOIN dbo.tblaff_BannerTypes bt WITH (NOLOCK) ON b.Type = bt.BannerTypeID
JOIN dbo.tblaff_Languages l WITH (NOLOCK) ON b.LanguageID = l.LanguageID
WHERE b.IsArchived = 0
ORDER BY bt.BannerTypeName, l.LanguageName, b.BannerName
```

### 8.2 Find banners by dimensions
```sql
SELECT BannerID, BannerName, TargetURL
FROM dbo.tblaff_Banners WITH (NOLOCK)
WHERE Width = 300 AND Height = 250 AND IsArchived = 0
ORDER BY BannerName
```

### 8.3 Banner conversion attribution
```sql
SELECT b.BannerID, b.BannerName, COUNT(s.SalesID) AS SaleCount
FROM dbo.tblaff_Banners b WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Sales s WITH (NOLOCK) ON b.BannerID = s.BannerID
WHERE b.IsArchived = 0
GROUP BY b.BannerID, b.BannerName
HAVING COUNT(s.SalesID) > 0
ORDER BY SaleCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 9.1/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Banners | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Banners.sql*
