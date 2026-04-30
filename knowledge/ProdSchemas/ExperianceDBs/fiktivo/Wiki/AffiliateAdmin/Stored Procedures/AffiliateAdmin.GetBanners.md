# AffiliateAdmin.GetBanners

> Returns a paginated, sortable, multi-filtered listing of banners with support for type, brand, language, category, media tag, and archive status filtering.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Paginated banner list with total count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetBanners provides a comprehensive paginated listing of banners from the affiliate marketing platform. It supports extensive filtering by banner type, archived status, brand, language, category, media tag, and free-text search. The procedure returns two result sets: the total count of matching records and the paginated rows for the requested page.

**WHY:** The banner management screen is a central hub for marketing administrators who manage potentially hundreds or thousands of banner creatives. This procedure supports efficient browsing with multiple filter dimensions, allowing administrators to quickly locate specific banners by any combination of their classification attributes. The pagination and sorting capabilities ensure the interface remains responsive regardless of the total banner count.

**HOW:** The procedure builds a filtered query against `tblaff_Banners`. It applies optional filters for @Type (banner type), @ShowArchived (archive status), @BrandID, @LanguageID, @CategoryID, and @MediaTagID. The media tag filter uses an EXISTS subquery against `MediaTagBanner`. The @SearchExpression provides free-text search. Results are paginated via @PageID and @PageSize, with dynamic sorting via @SortColumn and @SortType.

---

## 2. Business Logic

### 2.1 Multi-Dimensional Filtering
- **@Type (INT, nullable):** Filters by banner type (e.g., image, flash, HTML5). When NULL, all types are returned.
- **@ShowArchived (BIT, default 0):** Controls whether archived banners appear. Default is 0 (hide archived), set to 1 to include archived banners.
- **@BrandID (INT, nullable):** Filters banners by their associated brand.
- **@LanguageID (INT, nullable):** Filters banners by their target language.
- **@CategoryID (INT, nullable):** Filters banners by their assigned category.
- **@MediaTagID (INT, nullable):** Filters banners that have a specific media tag assignment. Uses an EXISTS subquery against `MediaTagBanner` to check tag association.
- **@SearchExpression (NVARCHAR, nullable):** Free-text search across banner fields.

### 2.2 Archive Status Logic
By default, archived banners are hidden (@ShowArchived = 0). This ensures that day-to-day banner management only shows active materials. Administrators can explicitly include archived banners by setting @ShowArchived = 1, which is useful for historical review or reactivation workflows.

### 2.3 Media Tag Filtering via EXISTS
When @MediaTagID is provided, the procedure uses an EXISTS subquery against the `MediaTagBanner` junction table to filter banners that have the specified tag. This approach is efficient as it avoids duplicating banner rows that have multiple tags.

### 2.4 Pagination and Sorting
Server-side pagination uses @PageID (zero-based) and @PageSize (default 10). Dynamic sorting defaults to BannerID ascending. The first result set returns the total count for pagination controls.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PageID | INT | No | 0 | CODE-BACKED | Zero-based page index for pagination |
| 2 | @PageSize | INT | No | 10 | CODE-BACKED | Number of rows per page |
| 3 | @Type | INT | Yes | NULL | CODE-BACKED | Filter by banner type; NULL returns all types |
| 4 | @ShowArchived | BIT | No | 0 | CODE-BACKED | Include archived banners (0=hide, 1=show) |
| 5 | @BrandID | INT | Yes | NULL | CODE-BACKED | Filter by brand; NULL returns all brands |
| 6 | @LanguageID | INT | Yes | NULL | CODE-BACKED | Filter by language; NULL returns all languages |
| 7 | @CategoryID | INT | Yes | NULL | CODE-BACKED | Filter by category; NULL returns all categories |
| 8 | @MediaTagID | INT | Yes | NULL | CODE-BACKED | Filter by media tag via EXISTS; NULL returns all |
| 9 | @SearchExpression | NVARCHAR | Yes | NULL | CODE-BACKED | Free-text search filter across banner fields |
| 10 | @SortColumn | NVARCHAR | No | 'BannerID' | CODE-BACKED | Column name to sort results by |
| 11 | @SortType | NVARCHAR | No | 'ASC' | CODE-BACKED | Sort direction: ASC or DESC |

**Result Set 1:** Total count of matching banner records (INT) (CODE-BACKED)
**Result Set 2:** Paginated banner rows with banner details (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Banners` | Table | Primary data source for banners |
| `dbo.MediaTagBanner` | Table | EXISTS subquery for media tag filtering |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Banner listing grid | Application | Main banner management screen |
| Banner search/filter panel | Application | Multi-filter banner search |

---

## 6. Dependencies

### 6.0 Chain
`GetBanners` -> `tblaff_Banners` + `MediaTagBanner`

### 6.1 Depends On
- `dbo.tblaff_Banners` - Primary banner data source
- `dbo.MediaTagBanner` - Media tag filtering via EXISTS subquery

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
-- 1. Get first page of active banners with default sorting
EXEC AffiliateAdmin.GetBanners
    @PageID = 0,
    @PageSize = 20,
    @ShowArchived = 0;
```

```sql
-- 2. Filter banners by brand, category, and media tag
EXEC AffiliateAdmin.GetBanners
    @PageID = 0,
    @PageSize = 10,
    @BrandID = 5,
    @CategoryID = 12,
    @MediaTagID = 3,
    @ShowArchived = 0,
    @SortColumn = 'BannerID',
    @SortType = 'DESC';
```

```sql
-- 3. Search banners including archived, sorted by name
EXEC AffiliateAdmin.GetBanners
    @PageID = 0,
    @PageSize = 50,
    @ShowArchived = 1,
    @SearchExpression = N'holiday promo',
    @SortColumn = 'BannerID',
    @SortType = 'ASC';
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-4472, PART-5349.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetBanners | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetBanners.sql*
