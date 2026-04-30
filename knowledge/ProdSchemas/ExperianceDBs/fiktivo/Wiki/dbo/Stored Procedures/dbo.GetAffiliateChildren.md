# dbo.GetAffiliateChildren

> Recursively traverses the affiliate tier hierarchy downward from a given affiliate, returning all descendant affiliate relationships up to a specified tier depth.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateID (root of the hierarchy traversal) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure maps the downward affiliate network for a given parent affiliate, used by the Partners platform to display sub-affiliate trees and calculate tiered commissions. Starting from the given AffiliateID, it finds all directly recruited affiliates (Tier 2) and then recursively descends through their sub-affiliates until @MaxTier is reached. The result is used for commission calculations, hierarchy displays, and eligibility checks for tiered revenue sharing. Created by Ran Ovadia in July 2019 for the Partners portal.

---

## 2. Business Logic

- Uses a recursive CTE (cte_affiliations) anchored on tblaff_Tier2Members where AffiliateID = @AffiliateID (direct children, Tier = 2).
- Recursive member joins tblaff_Tier2Members back to the CTE on m2.AffiliateID = c.NewMemberID to descend one tier at a time.
- Recursion terminates when c.Tier >= @MaxTier (the WHERE clause checks c.Tier < @MaxTier before adding the next level).
- Both the anchor and recursive member use NOLOCK hint.
- Returns AffiliateID (parent), NewMemberID (child), SubAffiliateID, and Tier for every row in the hierarchy.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | IN | (required) | High | Root affiliate ID whose children will be enumerated |
| 2 | @MaxTier | INT | IN | (required) | High | Maximum tier depth to traverse (e.g., 5 returns tiers 2-5) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (recursive CTE) | dbo.tblaff_Tier2Members | Read | Source of parent-child affiliate relationships |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateChildren
  └── dbo.tblaff_Tier2Members   (READ - recursive CTE)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Tier2Members | Table | Stores parent-child affiliate relationships for tier traversal |

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
-- Get all direct children (Tier 2) of affiliate 1000
EXEC dbo.GetAffiliateChildren @AffiliateID = 1000, @MaxTier = 2;

-- Get full hierarchy up to 5 tiers deep
EXEC dbo.GetAffiliateChildren @AffiliateID = 1000, @MaxTier = 5;

-- Count descendants per tier for a specific affiliate
DECLARE @Children TABLE (AffiliateID INT, NewMemberID INT, SubAffiliateID INT, Tier INT);
INSERT INTO @Children
EXEC dbo.GetAffiliateChildren @AffiliateID = 1000, @MaxTier = 5;
SELECT Tier, COUNT(*) AS MemberCount FROM @Children GROUP BY Tier ORDER BY Tier;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.
*(Author note: Ran Ovadia, 17/7/2019 - Creating for Partners.)*

---

*Generated: 2026-04-12 | Quality: 8.2/10*
*Object: dbo.GetAffiliateChildren | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateChildren.sql*
