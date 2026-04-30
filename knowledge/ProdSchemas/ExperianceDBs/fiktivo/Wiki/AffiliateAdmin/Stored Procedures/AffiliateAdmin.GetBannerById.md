# AffiliateAdmin.GetBannerById

> Retrieves a single banner by ID along with its associated media tag identifiers in two result sets.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Banner details + associated TagIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetBannerById retrieves a single banner record and its associated media tags. The first result set contains the full banner details from `tblaff_Banners`, and the second result set returns the TagIDs from the `MediaTag` and `MediaTagBanner` junction, providing the complete tag assignment for the banner.

**WHY:** When an administrator opens a banner for viewing or editing in the admin interface, the system needs both the banner's properties (dimensions, URL, type, category, priority, etc.) and its media tag assignments. Returning both datasets in a single procedure call reduces database round-trips and ensures atomic data retrieval for the edit form.

**HOW:** The procedure accepts a @BannerID parameter, then executes two SELECT statements. The first retrieves all banner details from `tblaff_Banners` filtered by the given ID. The second performs a JOIN between `MediaTag` and `MediaTagBanner` filtered by the same BannerID to return the associated TagIDs.

---

## 2. Business Logic

### 2.1 Banner Detail Retrieval
The first result set fetches the complete banner record by primary key lookup from `tblaff_Banners`. This includes all banner metadata such as name, URL, dimensions, type, category, priority, brand, language, and archive status.

### 2.2 Media Tag Association
The second result set returns TagIDs by joining `MediaTag` with `MediaTagBanner` where BannerID matches the input parameter. These tags represent the marketing classifications assigned to the banner, used for filtering and organization.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BannerID | INT | No | - | CODE-BACKED | The unique identifier of the banner to retrieve |

**Result Set 1:** All columns from `tblaff_Banners` for the specified BannerID (CODE-BACKED)
**Result Set 2:** TagID (INT) from MediaTag/MediaTagBanner join (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Banners` | Table | SELECT banner details by BannerID |
| `dbo.MediaTag` | Table | JOIN for tag resolution |
| `dbo.MediaTagBanner` | Table | JOIN for banner-tag mapping |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Banner edit screen | Application | Loads banner data and tags for editing |
| Banner detail view | Application | Displays banner properties and tag assignments |

---

## 6. Dependencies

### 6.0 Chain
`GetBannerById` -> `tblaff_Banners`, `MediaTag`, `MediaTagBanner`

### 6.1 Depends On
- `dbo.tblaff_Banners` - Source table for banner data
- `dbo.MediaTag` - Tag definitions
- `dbo.MediaTagBanner` - Banner-tag junction table

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
-- 1. Get banner ID 500 with its tags
EXEC AffiliateAdmin.GetBannerById @BannerID = 500;
```

```sql
-- 2. Load banner for edit form population
EXEC AffiliateAdmin.GetBannerById @BannerID = 123;
-- First result set populates banner property fields
-- Second result set populates tag multi-select
```

```sql
-- 3. Verify banner tag associations after update
EXEC AffiliateAdmin.GetBannerById @BannerID = 500;
-- Check second result set for expected TagIDs
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4472.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetBannerById | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetBannerById.sql*
