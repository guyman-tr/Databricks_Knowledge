# AffiliateAdmin.GetAllBanners

> Returns all banners along with their associated media tags in two separate result sets.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | All banner records + media tag mappings |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetAllBanners retrieves the complete list of banners from the affiliate banner repository along with their media tag associations. It produces two result sets: the first contains all columns from the banners table, and the second contains the media tag-to-banner mapping relationships.

**WHY:** The affiliate marketing platform requires a comprehensive view of all available banners and their tag classifications for administrative management. Media tags allow banners to be categorized and filtered by marketing teams, and returning both datasets in a single call reduces round-trips when populating administrative interfaces that display banners with their tag assignments.

**HOW:** The procedure executes two SELECT statements. The first retrieves all columns from `tblaff_Banners` without any filtering. The second performs a JOIN between `MediaTag` and `MediaTagBanner` to return TagID and BannerID pairs, providing the complete tag mapping for all banners in the system.

---

## 2. Business Logic

No complex business logic. This is a straightforward data retrieval procedure that returns two unfiltered result sets.

### 2.1 Result Set 1 - Banners
Returns all columns from `tblaff_Banners` including banner metadata, dimensions, URLs, and status information.

### 2.2 Result Set 2 - Media Tag Mappings
Returns the TagID and BannerID pairs by joining `MediaTag` with `MediaTagBanner`, providing the many-to-many relationship between banners and their assigned media tags.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set 1:** All columns from `tblaff_Banners` (CODE-BACKED)
**Result Set 2:** TagID (INT), BannerID (INT) from MediaTag/MediaTagBanner join (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Banners` | Table | SELECT all columns |
| `dbo.MediaTag` | Table | JOIN for tag names |
| `dbo.MediaTagBanner` | Table | JOIN for banner-tag mapping |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Banner management UI | Application | Loads all banners for admin display |

---

## 6. Dependencies

### 6.0 Chain
`GetAllBanners` -> `tblaff_Banners`, `MediaTag`, `MediaTagBanner`

### 6.1 Depends On
- `dbo.tblaff_Banners` - Source table for banner data
- `dbo.MediaTag` - Source table for tag definitions
- `dbo.MediaTagBanner` - Junction table for banner-tag relationships

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
-- 1. Execute the procedure to get all banners and their tags
EXEC AffiliateAdmin.GetAllBanners;
```

```sql
-- 2. Get all banners and process first result set only
EXEC AffiliateAdmin.GetAllBanners;
-- Application reads first result set for banner listing grid
```

```sql
-- 3. Verify banner-tag associations are intact
-- Execute and compare result set 2 counts with direct query
EXEC AffiliateAdmin.GetAllBanners;
-- Then verify: SELECT COUNT(*) FROM dbo.MediaTagBanner;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-5153.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAllBanners | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAllBanners.sql*
