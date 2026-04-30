# AffiliateAdmin.GetGeneralBannerResource

> Returns the maximum banner priority value and all available banner types in two result sets for banner creation/editing forms.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | MAX(Priority) + banner type list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetGeneralBannerResource provides two pieces of reference data needed when creating or editing banners: (1) the current maximum Priority value from existing banners, and (2) the complete list of banner types from `tblaff_BannerTypes`. These are returned as two separate result sets.

**WHY:** When creating a new banner, the admin interface needs to suggest the next priority value (typically MAX + 1) and display the available banner types for selection. This procedure consolidates both lookups into a single call, reducing database round-trips when initializing the banner creation form. The max priority helps administrators understand the current priority range and set appropriate priority levels for new banners.

**HOW:** The procedure executes two SELECT statements. The first retrieves MAX(Priority) from `tblaff_Banners` to determine the highest current priority value. The second retrieves all rows from `tblaff_BannerTypes` to provide the available banner type options for the type dropdown.

---

## 2. Business Logic

### 2.1 Maximum Priority Calculation
The first result set returns the MAX(Priority) value from `tblaff_Banners`. This value is used by the application to suggest a default priority for new banners (typically MAX + 1). If no banners exist, MAX returns NULL.

### 2.2 Banner Types Lookup
The second result set returns all banner types from `tblaff_BannerTypes`. Banner types categorize the format or medium of the banner (e.g., image banner, flash banner, HTML5 banner, text link).

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set 1:** MAX(Priority) (INT, nullable) from `tblaff_Banners` (CODE-BACKED)
**Result Set 2:** Banner type columns from `tblaff_BannerTypes` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Banners` | Table | SELECT MAX(Priority) |
| `dbo.tblaff_BannerTypes` | Table | SELECT all banner types |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Banner creation form | Application | Provides default priority and type options |
| Banner edit form | Application | Provides type dropdown options |

---

## 6. Dependencies

### 6.0 Chain
`GetGeneralBannerResource` -> `tblaff_Banners`, `tblaff_BannerTypes`

### 6.1 Depends On
- `dbo.tblaff_Banners` - Source for MAX(Priority) calculation
- `dbo.tblaff_BannerTypes` - Banner type reference data

### 6.2 Depend On This
No known database dependencies. Called from application layer for form initialization.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get banner resource data for form initialization
EXEC AffiliateAdmin.GetGeneralBannerResource;
```

```sql
-- 2. Determine next available priority for new banner
EXEC AffiliateAdmin.GetGeneralBannerResource;
-- Application reads first result set, adds 1 to get suggested priority
```

```sql
-- 3. Verify banner types are available
EXEC AffiliateAdmin.GetGeneralBannerResource;
-- Check second result set for expected banner type options
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-4670, PART-4472.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetGeneralBannerResource | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetGeneralBannerResource.sql*
