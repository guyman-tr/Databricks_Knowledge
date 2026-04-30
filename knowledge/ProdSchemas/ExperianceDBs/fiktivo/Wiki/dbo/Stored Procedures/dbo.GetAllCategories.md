# dbo.GetAllCategories

> Returns all category ID and name pairs from the tblaff_Categories reference table.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CategoryID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a reference data lookup returning the complete list of affiliate categories used in the affiliate platform. Categories are used to classify affiliate types and commission plans (via the tblaff_AffiliateTypeCategories mapping table). The category list is used to populate dropdowns and filters in the admin portal. It was last updated as part of PART-2448 (CPA New Compensation Design, December 2023), though the original SP was created earlier to detect tracking date of registration for fraud prevention.

---

## 2. Business Logic

- Simple unconditional SELECT of CategoryID and CategoryName from tblaff_Categories with NOLOCK.
- No parameters, no filtering, no joins.
- Returns all rows in the reference table.
- SET NOCOUNT ON suppresses row-count messages.

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
| SELECT | dbo.tblaff_Categories | Read | Returns all category reference rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAllCategories
  └── dbo.tblaff_Categories   (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Categories | Table | Reference table for affiliate category definitions |

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
-- Retrieve all affiliate categories
EXEC dbo.GetAllCategories;

-- Use for dropdown population in admin UI
DECLARE @Cats TABLE (CategoryID INT, CategoryName NVARCHAR(200));
INSERT INTO @Cats EXEC dbo.GetAllCategories;
SELECT * FROM @Cats ORDER BY CategoryName;

-- Cross-reference with affiliate type mappings
DECLARE @C TABLE (CategoryID INT, CategoryName NVARCHAR(200));
INSERT INTO @C EXEC dbo.GetAllCategories;
SELECT c.CategoryName, atc.AffiliateTypeID
FROM @C c
JOIN dbo.tblaff_AffiliateTypeCategories atc WITH (NOLOCK) ON atc.CategoryID = c.CategoryID;
```

---

## 9. Atlassian Knowledge Sources

- PART-2448 - Gil Haba / Noga, 17/12/2023: CPA New Compensation Design.
- Comment (28/09/2022, Gil): NEW SP to fetch TrackingDate of Registration to avoid fraud.

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAllCategories | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAllCategories.sql*
