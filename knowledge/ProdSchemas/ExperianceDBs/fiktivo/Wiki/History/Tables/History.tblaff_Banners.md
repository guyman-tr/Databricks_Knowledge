# History.tblaff_Banners

> SQL Server temporal history table storing all historical versions of marketing banner/creative definitions used by affiliates for customer acquisition campaigns.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | BannerID (int) - identifies the banner across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.tblaff_Banners is the system-versioned temporal history table for dbo.tblaff_Banners. It captures every historical version of banner/creative asset definitions whenever banners are updated, archived, or deleted. Banners are the marketing creatives (images, HTML snippets, links) that affiliates embed on their websites to drive traffic and customer acquisition.

This table preserves the complete change history of all banner configurations, enabling audit of what a banner looked like at any historical point. This is important for compliance verification (ensuring banners met regulatory requirements at the time they were active) and for investigating affiliate disputes about which creatives were available.

Data flows in automatically via SQL Server's temporal mechanism when dbo.tblaff_Banners is modified. The table contains 286 historical versions across all banners.

---

## 2. Business Logic

### 2.1 Banner Lifecycle Tracking

**What**: Tracks the full lifecycle of marketing banners from creation through archival, including all content and targeting changes.

**Columns/Parameters Involved**: `BannerID`, `BannerName`, `ImageURL`, `TargetURL`, `IsArchived`

**Rules**:
- Each banner version captures the complete state: creative content (ImageURL, AdCode), targeting (TargetURL, TargetWindow), dimensions (Width, Height), and categorization (CategoryID, LanguageID, BrandID)
- IsArchived = true indicates the banner was retired but not deleted
- Commission attribution flags (PerSale, PerLead, PerClick) control which commission events this banner can generate
- AdvancedBanner = true indicates the banner uses custom HTML (AdCode) rather than a simple image

---

## 3. Data Overview

| BannerID | BannerName | Width | Height | LanguageID | BrandID | IsArchived | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 4860 | Original Test Banner | 728 | 90 | 1 | 1 | false | 2026-02-18 07:38:19 | 2026-02-18 07:38:25 | Test leaderboard banner (728x90) - standard IAB ad size, updated within 6 seconds |
| 4858 | Test Banner IEJIHKHGHH | 728 | 90 | 1 | 1 | false | 2026-02-17 21:59:23 | 2026-02-17 21:59:25 | Automated test banner - random name pattern indicates QA test, short-lived |
| 4857 | Original Active Banner | 728 | 90 | 1 | 1 | false | 2026-02-17 21:59:20 | 2026-02-17 21:59:21 | Another test banner created and quickly superseded during automated testing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BannerID | int | NO | - | CODE-BACKED | Unique identifier for the banner. Matches dbo.tblaff_Banners.BannerID. Multiple rows share the same ID for version history. |
| 2 | CategoryID | int | YES | - | CODE-BACKED | Banner category for organizing creatives in the affiliate console. References a banner categories table. |
| 3 | Type | int | YES | - | CODE-BACKED | Banner type classification (e.g., 1 = standard image banner). |
| 4 | BannerName | nvarchar(255) | YES | - | CODE-BACKED | Display name of the banner shown in the affiliate console. |
| 5 | ImageURL | nvarchar(255) | YES | - | CODE-BACKED | URL of the banner image file. Used for standard (non-advanced) banners. |
| 6 | TargetURL | nvarchar(255) | YES | - | CODE-BACKED | Destination URL when a user clicks the banner. Typically includes affiliate tracking parameters. |
| 7 | AltText | nvarchar(255) | YES | - | CODE-BACKED | Alternative text for the banner image (accessibility and SEO). |
| 8 | Width | int | YES | - | CODE-BACKED | Banner width in pixels (e.g., 728 for leaderboard, 300 for medium rectangle). |
| 9 | Height | int | YES | - | CODE-BACKED | Banner height in pixels (e.g., 90 for leaderboard, 250 for medium rectangle). |
| 10 | PerSale | bit | NO | - | CODE-BACKED | Whether clicks on this banner can generate sale commissions for the affiliate. |
| 11 | PerLead | bit | NO | - | CODE-BACKED | Whether clicks on this banner can generate lead commissions. |
| 12 | PerClick | bit | NO | - | CODE-BACKED | Whether clicks on this banner generate click commissions. |
| 13 | NotesToAffiliate | nvarchar(1000) | YES | - | CODE-BACKED | Instructions or notes displayed to affiliates about how to use this banner. |
| 14 | AdvancedBanner | bit | NO | - | CODE-BACKED | Whether this banner uses custom HTML/JavaScript (AdCode) instead of a simple image. |
| 15 | AdCode | ntext | YES | - | CODE-BACKED | Custom HTML/JavaScript code for advanced banners. Rendered as-is on the affiliate's website. |
| 16 | TargetWindow | nvarchar(50) | YES | - | CODE-BACKED | Browser window target for click navigation (e.g., "_blank" for new tab, "_self" for same window). |
| 17 | LanguageID | int | YES | - | CODE-BACKED | Language of the banner content. Controls which affiliates see it based on their locale settings. |
| 18 | BrandID | int | YES | - | CODE-BACKED | Brand identity for the banner (e.g., eToro brand variants for different markets). |
| 19 | Priority | int | YES | - | CODE-BACKED | Display priority for ordering banners in the affiliate console. Higher values appear first. |
| 20 | IsArchived | bit | NO | - | CODE-BACKED | Whether the banner has been archived/retired. Archived banners are hidden from the affiliate console but retained for historical reference. |
| 21 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context captured when this version was created. Contains HostName, AppName, SUserName, SPID, DBName, ObjectName. |
| 22 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version became active. Set by SQL Server temporal mechanism. |
| 23 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version was superseded. Set by SQL Server temporal mechanism. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BannerID | dbo.tblaff_Banners | Temporal History | Stores historical versions of the base table |

### 5.2 Referenced By (other objects point to this)

This table is accessed implicitly via temporal queries (FOR SYSTEM_TIME) on dbo.tblaff_Banners.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.tblaff_Banners (table)
```

This table has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Banners | Table | SYSTEM_VERSIONING - SQL Server automatically moves superseded row versions here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_tblaff_Banners | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View banner change history
```sql
SELECT BannerID, BannerName, ImageURL, TargetURL, IsArchived, ValidFrom, ValidTo
FROM dbo.tblaff_Banners FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE BannerID = 4860
ORDER BY ValidFrom
```

### 8.2 Find banners that existed at a point in time
```sql
SELECT BannerID, BannerName, Width, Height, IsArchived
FROM dbo.tblaff_Banners FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00' WITH (NOLOCK)
WHERE IsArchived = 0
ORDER BY Priority DESC
```

### 8.3 Audit recently changed banners
```sql
SELECT BannerID, BannerName,
       JSON_VALUE(Trace, '$.ObjectName') AS ChangedBy,
       ValidFrom, ValidTo
FROM History.tblaff_Banners WITH (NOLOCK)
WHERE ValidTo > DATEADD(DAY, -30, GETUTCDATE())
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.tblaff_Banners | Type: Table | Source: fiktivo/History/Tables/History.tblaff_Banners.sql*
