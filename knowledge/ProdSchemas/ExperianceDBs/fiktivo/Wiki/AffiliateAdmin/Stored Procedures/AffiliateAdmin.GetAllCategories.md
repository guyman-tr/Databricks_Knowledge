# AffiliateAdmin.GetAllCategories

> Returns all affiliate categories ordered alphabetically by name for use in dropdown selections.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CategoryID, CategoryName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetAllCategories retrieves the complete list of affiliate categories from the system, returning each category's identifier and display name. The results are sorted alphabetically by category name for consistent presentation in user interfaces.

**WHY:** Categories are a fundamental classification mechanism for organizing affiliates and banners within the affiliate marketing platform. Administrative screens frequently need a full category list for dropdown menus, filter panels, and assignment dialogs. Providing a dedicated procedure for this common lookup ensures consistent ordering and a single point of maintenance.

**HOW:** The procedure executes a simple SELECT of CategoryID and CategoryName from `tblaff_Categories`, ordered by CategoryName in ascending order. No filtering, pagination, or joins are applied.

---

## 2. Business Logic

No complex business logic. This is a simple lookup that returns all categories sorted alphabetically. No filtering or conditional logic is present.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set:** CategoryID (INT), CategoryName (NVARCHAR) from `tblaff_Categories` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Categories` | Table | SELECT CategoryID, CategoryName |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Category dropdown components | Application | Populates category selection lists |
| Banner filter panels | Application | Provides category filter options |

---

## 6. Dependencies

### 6.0 Chain
`GetAllCategories` -> `tblaff_Categories`

### 6.1 Depends On
- `dbo.tblaff_Categories` - Source table for category data

### 6.2 Depend On This
No known database dependencies. Called from application layer for UI population.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get all categories for dropdown population
EXEC AffiliateAdmin.GetAllCategories;
```

```sql
-- 2. Verify category count
EXEC AffiliateAdmin.GetAllCategories;
-- Compare with: SELECT COUNT(*) FROM dbo.tblaff_Categories;
```

```sql
-- 3. Use in application context for category assignment
-- Step 1: Load categories
EXEC AffiliateAdmin.GetAllCategories;
-- Step 2: Use returned CategoryID values for subsequent operations
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-4222, PART-2448.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAllCategories | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAllCategories.sql*
