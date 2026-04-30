# AffiliateAdmin.GetAllMediaTagsByAffiliateId

> Returns all media tags available to a specific affiliate based on their affiliate type's category-banner associations, excluding archived banners.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Media tags filtered by affiliate's type categories |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetAllMediaTagsByAffiliateId retrieves the media tags that are available to a specific affiliate. Availability is determined by the affiliate's type, which maps to categories, which in turn map to banners, which carry media tag assignments. The procedure traverses this chain to return only the tags relevant to the given affiliate.

**WHY:** Affiliates are only permitted to use banners and marketing materials that match their affiliate type's category permissions. When an affiliate accesses their marketing toolkit, the system must filter available media tags to show only those associated with banners in their permitted categories. This procedure enforces this business rule at the data layer, preventing affiliates from seeing or using unauthorized marketing assets.

**HOW:** The procedure performs a complex 4-way JOIN chain: starting from `tblaff_Affiliates` to look up the affiliate's AffiliateTypeID, then joining `tblaff_AffiliateTypeCategories` to find the categories permitted for that type, then `tblaff_Banners` (filtered to non-archived) to find banners in those categories, then `MediaTagBanner` and `MediaTag` to resolve the final tag list. The result is filtered by the input @AffiliateID parameter.

---

## 2. Business Logic

### 2.1 Affiliate Type Resolution
The affiliate's type is resolved by looking up the AffiliateTypeID from `tblaff_Affiliates` where AffiliateID matches the input parameter. This type determines which categories the affiliate has access to.

### 2.2 Category-Based Banner Filtering
The `tblaff_AffiliateTypeCategories` table provides the many-to-many mapping between affiliate types and categories. Only banners belonging to categories assigned to the affiliate's type are included.

### 2.3 Archived Banner Exclusion
Banners that are marked as archived in `tblaff_Banners` are excluded from the results, ensuring affiliates only see active marketing materials.

### 2.4 Tag Aggregation
The final result aggregates all distinct media tags from the filtered banner set through the `MediaTagBanner` junction table and `MediaTag` definition table.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | No | - | CODE-BACKED | The unique identifier of the affiliate whose available media tags are being retrieved |

**Result Set:** TagID (INT), TagName (NVARCHAR), TranslationKey (NVARCHAR) from MediaTag (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Affiliates` | Table | Lookup AffiliateTypeID by AffiliateID |
| `dbo.tblaff_AffiliateTypeCategories` | Table | Category permissions for affiliate type |
| `dbo.tblaff_Banners` | Table | Banners in permitted categories, non-archived |
| `dbo.MediaTagBanner` | Table | Banner-to-tag junction mapping |
| `dbo.MediaTag` | Table | Tag definitions (TagID, TagName) |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate marketing portal | Application | Loads available media tags for affiliate's marketing toolkit |

---

## 6. Dependencies

### 6.0 Chain
`GetAllMediaTagsByAffiliateId` -> `tblaff_Affiliates` -> `tblaff_AffiliateTypeCategories` -> `tblaff_Banners` -> `MediaTagBanner` -> `MediaTag`

### 6.1 Depends On
- `dbo.tblaff_Affiliates` - Resolves affiliate type
- `dbo.tblaff_AffiliateTypeCategories` - Maps type to categories
- `dbo.tblaff_Banners` - Banner data with archive status
- `dbo.MediaTagBanner` - Banner-tag junction table
- `dbo.MediaTag` - Tag definitions

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
-- 1. Get all media tags available to affiliate ID 1001
EXEC AffiliateAdmin.GetAllMediaTagsByAffiliateId @AffiliateID = 1001;
```

```sql
-- 2. Compare tags available to two different affiliates
EXEC AffiliateAdmin.GetAllMediaTagsByAffiliateId @AffiliateID = 1001;
EXEC AffiliateAdmin.GetAllMediaTagsByAffiliateId @AffiliateID = 2005;
```

```sql
-- 3. Verify tag availability after changing an affiliate's type
-- Before type change
EXEC AffiliateAdmin.GetAllMediaTagsByAffiliateId @AffiliateID = 1001;
-- After type change, re-execute to confirm new tag set
EXEC AffiliateAdmin.GetAllMediaTagsByAffiliateId @AffiliateID = 1001;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4214.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAllMediaTagsByAffiliateId | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAllMediaTagsByAffiliateId.sql*
