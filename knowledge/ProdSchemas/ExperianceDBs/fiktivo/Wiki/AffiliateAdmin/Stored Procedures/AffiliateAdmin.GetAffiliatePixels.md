# AffiliateAdmin.GetAffiliatePixels

> Returns a paginated, sortable, and filtered list of affiliate tracking pixels with pixel type and affiliate details.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns total count + paginated pixel rows with joined metadata |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliatePixels is the primary data provider for the tracking pixel management grid in the affiliate admin portal. It supports server-side pagination, dynamic column sorting, multi-criteria filtering (by pixel type, affiliate, and generic pixel flag), and text search, enabling administrators to efficiently manage the potentially large volume of tracking pixels across all affiliates.

This procedure exists because tracking pixel management is a critical operational function. Affiliates use pixels to track conversions, and the admin team needs to review, audit, and troubleshoot these pixels. The procedure consolidates data from multiple tables (pixels, pixel types, affiliates, affiliate URLs) into a single grid-ready result set.

Data flow: The procedure joins dbo.tblaff_AffiliatePixels with Dictionary.PixelTypes for type descriptions, dbo.tblaff_Affiliates for affiliate contact info, and Affiliate.tblaff_AffiliateURLs for URL context. The @Method parameter controls the filtering mode, @PixelType and @AffiliateID narrow by specific type or affiliate, and @GetGenericPixels controls whether non-affiliate-specific pixels are included. Results are returned as two result sets: total count and paginated rows.

---

## 2. Business Logic

### 2.1 Method-Based Filtering

The @Method parameter (default 0) controls the query's filtering behavior. Different integer values activate different filter combinations, allowing the UI to switch between views (e.g., all pixels, affiliate-specific pixels, type-specific pixels) using a single procedure.

### 2.2 Generic Pixel Toggle

The @GetGenericPixels flag (default 1) determines whether pixels not assigned to a specific affiliate are included in results. Generic pixels are shared tracking snippets used across multiple affiliates, and toggling this flag allows admins to focus on affiliate-specific or shared pixels.

### 2.3 Multi-Table Join

The procedure enriches pixel data by joining across four tables: the pixel definition, its type classification from the Dictionary schema, the owning affiliate's details, and the affiliate's URL configuration. This provides a comprehensive view without requiring multiple API calls.

### 2.4 Dynamic Sort and Pagination

Standard server-side pagination with dynamic column sorting via @SortColumn and @SortType, defaulting to PixelID descending (newest first).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Method | int | NO | 0 | CODE-BACKED | Controls filtering mode. Different values activate different filter combinations. |
| 2 | @PixelType | int | YES | NULL | CODE-BACKED | Filters by PixelTypeID from Dictionary.PixelTypes. NULL returns all types. |
| 3 | @AffiliateID | int | YES | NULL | CODE-BACKED | Filters by specific affiliate. NULL returns pixels for all affiliates. |
| 4 | @GetGenericPixels | bit | NO | 1 | CODE-BACKED | When 1, includes pixels not assigned to a specific affiliate (generic/shared pixels). |
| 5 | @SearchExpression | nvarchar | YES | - | CODE-BACKED | Text filter applied to pixel or affiliate fields via LIKE pattern matching. |
| 6 | @PageID | int | NO | - | CODE-BACKED | Current page number for pagination (1-based). |
| 7 | @PageSize | int | NO | - | CODE-BACKED | Number of rows per page. |
| 8 | @SortColumn | nvarchar | NO | 'PixelID' | CODE-BACKED | Column name to sort results by. Defaults to PixelID. |
| 9 | @SortType | nvarchar | NO | 'DESC' | CODE-BACKED | Sort direction: ASC or DESC. Defaults to newest first. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_AffiliatePixels | Read | Main pixel data (PixelID, AffiliateID, PixelTypeID, Code, IsPost) |
| JOIN | Dictionary.PixelTypes | Read | Resolves PixelTypeID to human-readable type descriptions |
| JOIN | dbo.tblaff_Affiliates | Read | Resolves AffiliateID to affiliate contact and account info |
| JOIN | Affiliate.tblaff_AffiliateURLs | Read | Provides affiliate URL context for pixel association |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliatePixels (procedure)
+-- dbo.tblaff_AffiliatePixels (table)
+-- Dictionary.PixelTypes (table)
+-- dbo.tblaff_Affiliates (table)
+-- Affiliate.tblaff_AffiliateURLs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliatePixels | Table | Main SELECT for pixel records |
| Dictionary.PixelTypes | Table | JOIN for pixel type description |
| dbo.tblaff_Affiliates | Table | JOIN for affiliate details |
| Affiliate.tblaff_AffiliateURLs | Table | JOIN for affiliate URL context |

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

### 8.1 Get first page of all pixels
```sql
EXEC AffiliateAdmin.GetAffiliatePixels
    @Method = 0,
    @PixelType = NULL,
    @AffiliateID = NULL,
    @GetGenericPixels = 1,
    @SearchExpression = NULL,
    @PageID = 1,
    @PageSize = 25,
    @SortColumn = 'PixelID',
    @SortType = 'DESC';
-- Result 1: Total pixel count
-- Result 2: First 25 pixels sorted by ID descending
```

### 8.2 Get pixels for a specific affiliate, excluding generic
```sql
EXEC AffiliateAdmin.GetAffiliatePixels
    @Method = 0,
    @PixelType = NULL,
    @AffiliateID = 1001,
    @GetGenericPixels = 0,
    @SearchExpression = NULL,
    @PageID = 1,
    @PageSize = 50,
    @SortColumn = 'PixelID',
    @SortType = 'ASC';
```

### 8.3 Manually query pixels with type and affiliate info
```sql
SELECT p.PixelID, p.AffiliateID, a.Contact, pt.Description AS PixelType,
       p.Code, p.IsPost
FROM dbo.tblaff_AffiliatePixels p WITH (NOLOCK)
JOIN Dictionary.PixelTypes pt WITH (NOLOCK) ON pt.PixelTypeID = p.PixelTypeID
LEFT JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateID = p.AffiliateID
ORDER BY p.PixelID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4266.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliatePixels | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliatePixels.sql*
