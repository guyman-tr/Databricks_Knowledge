# dbo.tblaff_BannerTypes

> Lookup table classifying marketing banner assets by their media format or content type (GIF, Flash, Text, Video, Widget, etc.).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | BannerTypeID (INT IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (nonclustered PK) |

---

## 1. Business Meaning

This table defines the types of marketing assets available to affiliates. Each type represents a distinct media format or content category - from traditional GIF/Flash banners to text links, landing pages, widgets, videos, and educational tools. The classification drives the affiliate banner selection UI, allowing affiliates to filter by asset type.

Without this table, affiliates could not filter the banner library by format, and the admin team could not categorize new creative assets. BannerTypeID is referenced by tblaff_Banners.Type to classify each individual banner asset.

The table is a stable reference set of 12 types that rarely changes. New rows would only be added when the platform supports an entirely new media format. Managed by admin users with Banners_* permissions.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| BannerTypeID | BannerTypeName | Meaning |
|-------------|---------------|---------|
| 1 | GIF Banners | Static or animated GIF image banners - standard display advertising format for affiliate websites |
| 2 | Flash Banners | Adobe Flash-based animated banners - legacy format, likely deprecated as browsers dropped Flash support |
| 3 | Text Banners | Text-only banner content for embedding in articles, emails, or sites where images are impractical |
| 5 | Links & Landing Pages | Tracking URLs that direct to specific landing pages - the core affiliate conversion tool |
| 6 | Widgets | Embeddable interactive trading tools (price tickers, charts) that affiliates place on their sites |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BannerTypeID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing identifier. Referenced by tblaff_Banners.Type to classify each banner by its media format. Values: 1=GIF Banners, 2=Flash Banners, 3=Text Banners, 4=Rotating Banners, 5=Links & Landing Pages, 6=Widgets, 7=Videos & Tutorials, 8=Articles & Reviews, 9=White Labels, 10=Mailers, 11=Education Tools, 12=Logos. |
| 2 | BannerTypeName | nvarchar(255) | YES | - | CODE-BACKED | Display name for the banner type. Shown in admin UI and affiliate banner selection filters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Banners | Type | Implicit FK | Banner's Type column maps to BannerTypeID to classify the asset's media format. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Banners | Table | Type column references BannerTypeID |
| dbo.GetAllBannerTypes | Stored Procedure | READER - retrieves all banner types for UI dropdowns |
| dbo.GetBanners | Stored Procedure | READER - joins to resolve banner type display name |
| dbo.GetBannerById | Stored Procedure | READER - joins to resolve single banner type name |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_BannerTypes_PK | NC PK | BannerTypeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all banner types
```sql
SELECT BannerTypeID, BannerTypeName
FROM dbo.tblaff_BannerTypes WITH (NOLOCK)
ORDER BY BannerTypeID
```

### 8.2 Count banners per type
```sql
SELECT bt.BannerTypeID, bt.BannerTypeName, COUNT(b.BannerID) as BannerCount
FROM dbo.tblaff_BannerTypes bt WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Banners b WITH (NOLOCK) ON bt.BannerTypeID = b.Type
GROUP BY bt.BannerTypeID, bt.BannerTypeName
ORDER BY BannerCount DESC
```

### 8.3 Find active banners of a specific type
```sql
SELECT b.BannerID, b.BannerName, bt.BannerTypeName
FROM dbo.tblaff_Banners b WITH (NOLOCK)
JOIN dbo.tblaff_BannerTypes bt WITH (NOLOCK) ON b.Type = bt.BannerTypeID
WHERE b.IsArchived = 0
  AND bt.BannerTypeName = 'GIF Banners'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_BannerTypes | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_BannerTypes.sql*
