# dbo.BannerSearch

> Searches banners by name using exact or partial (LIKE) matching, filtered by affiliate type category and brand, using dynamic SQL executed via sp_executesql for flexible predicate construction.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Amir Moualem |
| **Created** | 2011-10-18 |

---

## 1. Business Meaning

Affiliates and administrators need to locate banners from a potentially large catalog when building campaigns. A banner must match a specific affiliate type (via its category) and brand before it is eligible for use by a given affiliate. This procedure provides that filtered, case-insensitive banner lookup, supporting both quick exact-name lookup and broader partial-match searches.

The procedure uses dynamic SQL (sp_executesql) to construct the WHERE clause at runtime: the search predicate switches between an exact equality match and a LIKE wildcard match based on the @MatchExactName flag. This pattern was common in older SQL Server code and allows the same procedure body to handle two distinct search modes without branching on static SQL.

Results are used by the admin and affiliate portal banner picker components. The procedure has been in service since 2011 and represents core banner catalog search functionality.

---

## 2. Business Logic

### 2.1 Exact vs. Partial Name Match

**What**: The @MatchExactName flag controls whether the search uses equality or a LIKE pattern.

**Columns/Parameters Involved**: `@MatchExactName`, `@Search`

**Rules**:
- @MatchExactName = 0: the search term is wrapped in wildcards (LIKE N'%@Search%'), enabling substring matching across all banners whose names contain the search string
- @MatchExactName = 1: the search term must match BannerName exactly (case-insensitive due to database collation)
- @Search = NULL or empty string will typically return all banners within the type/brand filter (LIKE '%' matches everything)

### 2.2 Affiliate Type and Brand Filtering

**What**: Results are scoped to banners that belong to the requested affiliate type category and brand.

**Columns/Parameters Involved**: `@AffiliateTypeID`, `@BrandID`

**Rules**:
- tblaff_AffiliateTypeCategories links affiliate types to banner categories; only banners in categories accessible to the specified affiliate type are returned
- @BrandID restricts results to banners created for a specific brand/label; 0 or NULL may return cross-brand results depending on join logic
- The JOIN between tblaff_AffiliateTypeCategories and tblaff_Banners ensures affiliates only see banners intended for their program type

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @MatchExactName | IN | bit | (required) | Search mode flag: 0=partial match using LIKE wildcard, 1=exact name match using equality. Controls the dynamic WHERE clause. |
| 2 | @AffiliateTypeID | IN | int | (required) | Filters results to banners associated with the affiliate type category that maps to this affiliate type ID. References dbo.tblaff_AffiliateTypes. |
| 3 | @BrandID | IN | int | (required) | Restricts results to banners belonging to the specified brand. References the BrandId column in tblaff_Banners. |
| 4 | @Search | IN | nvarchar(255) | (required) | The banner name search term. Used as-is for exact match or wrapped in % wildcards for partial match. Case-insensitive per database collation. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_AffiliateTypeCategories | SELECT (JOIN) | Filters banners by affiliate type category association |
| dbo.tblaff_Banners | SELECT (JOIN) | Primary source of banner records to search and return |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| BannerID | tblaff_Banners | Primary key of the matching banner |
| BannerName | tblaff_Banners | Display name of the banner |
| AdvancedBanner | tblaff_Banners | Flag indicating whether this is an advanced (HTML/JS) banner vs. a simple image banner |
| Width | tblaff_Banners | Banner width in pixels |
| Height | tblaff_Banners | Banner height in pixels |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.BannerSearch (stored procedure)
+-- dbo.tblaff_AffiliateTypeCategories (table) [JOIN]
+-- dbo.tblaff_Banners (table) [JOIN]
    +-- dbo.tblaff_AffiliateTypes (table) [implicit via category]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypeCategories | Table | Joined to link affiliate types to banner categories |
| dbo.tblaff_Banners | Table | Source table for banner search results |
| sys.sp_executesql | System procedure | Executes the dynamically constructed SQL string |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Banner picker UI (admin/affiliate portal) | Application | Calls this procedure to populate banner search results |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- Uses dynamic SQL via sp_executesql; the @Search parameter is passed as a parameter to sp_executesql, preventing SQL injection
- Case-insensitive matching is provided by the database default collation, not explicit COLLATE clauses
- No WITH (NOLOCK) hints mentioned in the specification; read consistency depends on default isolation level
- Authored in 2011; the dynamic SQL pattern predates filtered index or full-text search adoption

---

## 8. Sample Queries

### 8.1 Partial name search for a brand

```sql
EXEC dbo.BannerSearch
    @MatchExactName  = 0,
    @AffiliateTypeID = 3,
    @BrandID         = 1,
    @Search          = N'summer';
```

### 8.2 Exact name lookup

```sql
EXEC dbo.BannerSearch
    @MatchExactName  = 1,
    @AffiliateTypeID = 3,
    @BrandID         = 1,
    @Search          = N'Summer Promo 300x250';
```

### 8.3 Return all banners for a type and brand (empty search)

```sql
EXEC dbo.BannerSearch
    @MatchExactName  = 0,
    @AffiliateTypeID = 3,
    @BrandID         = 1,
    @Search          = N'';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10*
*Object: dbo.BannerSearch | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.BannerSearch.sql*
