# dbo.GetAffiliateTypeCategories

> Returns all category-to-affiliate-type mapping rows from tblaff_AffiliateTypeCategories.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CategoryID + AffiliateTypeID (mapping table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the complete list of category assignments across all affiliate types. The tblaff_AffiliateTypeCategories table maps categories (e.g., geographic regions, product verticals, or traffic source types) to affiliate commission plans. The data returned is used by the admin portal to populate category filters, plan assignment UIs, and to enforce which categories are available for a given plan. It is a configuration reference table lookup with no filtering - it always returns the full mapping table.

---

## 2. Business Logic

- SELECT of CategoryID and AffiliateTypeID from tblaff_AffiliateTypeCategories with NOLOCK.
- No parameters, no filtering, no joins.
- Returns all rows in the mapping table.
- Set NoCount On suppresses row-count messages.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure takes no parameters |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_AffiliateTypeCategories | Read | Returns all category-to-plan mapping rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateTypeCategories
  └── dbo.tblaff_AffiliateTypeCategories   (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_AffiliateTypeCategories | Table | Category-to-AffiliateType mapping configuration table |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Retrieve all category-to-plan mappings
EXEC dbo.GetAffiliateTypeCategories;

-- Filter results in the application layer for a specific plan
DECLARE @Mappings TABLE (CategoryID INT, AffiliateTypeID INT);
INSERT INTO @Mappings EXEC dbo.GetAffiliateTypeCategories;
SELECT * FROM @Mappings WHERE AffiliateTypeID = 10;

-- Count categories per affiliate type
DECLARE @Map TABLE (CategoryID INT, AffiliateTypeID INT);
INSERT INTO @Map EXEC dbo.GetAffiliateTypeCategories;
SELECT AffiliateTypeID, COUNT(*) AS CategoryCount FROM @Map GROUP BY AffiliateTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAffiliateTypeCategories | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateTypeCategories.sql*
