# AffiliateAdmin.GetCategoryById

> Retrieves a category's name and its associated affiliate type assignments by category ID.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Category details + associated AffiliateTypeIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetCategoryById retrieves a single category record along with its affiliate type associations. The procedure joins `tblaff_Categories` with `tblaff_AffiliateTypeCategories` to return both the category name and the list of affiliate types that have access to this category.

**WHY:** Categories in the affiliate platform control which banners and marketing materials are available to different affiliate types. When an administrator views or edits a category, the system needs to display both the category's name and which affiliate types are currently assigned to it. This combined retrieval supports the category management form in the admin interface.

**HOW:** The procedure accepts an @ID parameter and performs a LEFT JOIN between `tblaff_Categories` and `tblaff_AffiliateTypeCategories` on CategoryID. The LEFT JOIN ensures the category details are returned even if no affiliate types are assigned. The result includes the category name and associated AffiliateTypeID values.

---

## 2. Business Logic

### 2.1 Category-Affiliate Type Mapping
The procedure uses a LEFT JOIN to retrieve affiliate type associations. This design choice ensures that a category with no affiliate type assignments still returns the category name (with NULL affiliate type values), rather than returning an empty result set.

### 2.2 Affiliate Type Access Control
The `tblaff_AffiliateTypeCategories` junction table defines which affiliate types can access banners in a given category. This relationship is central to the permission model for marketing material distribution.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | INT | No | - | CODE-BACKED | The unique identifier of the category to retrieve |

**Result Set:** CategoryName (NVARCHAR), AffiliateTypeID (INT, nullable via LEFT JOIN) (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Categories` | Table | SELECT category name by ID |
| `dbo.tblaff_AffiliateTypeCategories` | Table | LEFT JOIN for affiliate type assignments |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Category edit screen | Application | Loads category data for editing |
| Category detail view | Application | Displays category and its type assignments |

---

## 6. Dependencies

### 6.0 Chain
`GetCategoryById` -> `tblaff_Categories` + `tblaff_AffiliateTypeCategories`

### 6.1 Depends On
- `dbo.tblaff_Categories` - Source table for category data
- `dbo.tblaff_AffiliateTypeCategories` - Junction table for category-to-affiliate-type mapping

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
-- 1. Get category ID 5 with its affiliate type assignments
EXEC AffiliateAdmin.GetCategoryById @ID = 5;
```

```sql
-- 2. Load category for edit form
EXEC AffiliateAdmin.GetCategoryById @ID = 12;
-- CategoryName populates the name field
-- AffiliateTypeIDs populate the type assignment checkboxes
```

```sql
-- 3. Verify category-type associations after update
EXEC AffiliateAdmin.GetCategoryById @ID = 5;
-- Check returned AffiliateTypeIDs match expected assignments
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4222.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetCategoryById | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetCategoryById.sql*
