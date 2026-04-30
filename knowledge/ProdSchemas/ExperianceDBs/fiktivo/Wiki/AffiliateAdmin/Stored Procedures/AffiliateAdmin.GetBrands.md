# AffiliateAdmin.GetBrands

> Returns all brands with optional search word filtering from the affiliate brands table.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | BrandID, BrandName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetBrands retrieves the list of brands from `tblaff_Brands`, returning each brand's identifier and display name. An optional search word parameter allows filtering the results by brand name.

**WHY:** Brands are a key organizational dimension in the affiliate marketing platform, used to associate banners, campaigns, and affiliate relationships with specific company brands. Administrative interfaces need brand lists for dropdown menus and autocomplete fields. The optional search filter supports type-ahead search scenarios where administrators can narrow the brand list by typing partial names.

**HOW:** The procedure selects BrandID and BrandName from `tblaff_Brands`. When @SearchWord is provided, a LIKE filter is applied to BrandName. When @SearchWord is NULL, all brands are returned. The results provide a clean brand lookup suitable for UI consumption.

---

## 2. Business Logic

### 2.1 Optional Search Filtering
When @SearchWord is provided (non-NULL), the procedure filters brands by applying a LIKE comparison against BrandName. This supports partial matching for type-ahead search functionality. When @SearchWord is NULL, no filtering is applied and all brands are returned.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SearchWord | VARCHAR(100) | Yes | NULL | CODE-BACKED | Optional partial name filter for brand search; NULL returns all brands |

**Result Set:** BrandID (INT), BrandName (NVARCHAR) from `tblaff_Brands` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Brands` | Table | SELECT BrandID, BrandName with optional filter |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Brand dropdown/autocomplete | Application | Populates brand selection with type-ahead support |
| Banner filter panel | Application | Provides brand filter options |

---

## 6. Dependencies

### 6.0 Chain
`GetBrands` -> `tblaff_Brands`

### 6.1 Depends On
- `dbo.tblaff_Brands` - Source table for brand data

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
-- 1. Get all brands without filtering
EXEC AffiliateAdmin.GetBrands;
```

```sql
-- 2. Search brands by partial name
EXEC AffiliateAdmin.GetBrands @SearchWord = 'Trading';
```

```sql
-- 3. Type-ahead brand search
EXEC AffiliateAdmin.GetBrands @SearchWord = 'Inv';
-- Returns brands whose name contains 'Inv'
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4218.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetBrands | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetBrands.sql*
