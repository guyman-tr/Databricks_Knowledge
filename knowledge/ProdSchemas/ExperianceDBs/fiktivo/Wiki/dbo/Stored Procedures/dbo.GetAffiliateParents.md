# dbo.GetAffiliateParents

> Recursively traverses the affiliate tier hierarchy upward from a given affiliate, returning all ancestor affiliate relationships up to a specified tier depth.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateID (leaf node of the upward traversal) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the inverse of GetAffiliateChildren: it maps the upward affiliate network for a given sub-affiliate, returning the chain of parent affiliates who recruited it. It is used by the Partners platform to determine commission eligibility for parent affiliates (who earn tiered commissions when their recruited affiliates generate activity) and to display the hierarchy path from the current affiliate up to the top-level parent. Created by Ran Ovadia in July 2019 for the Partners portal.

---

## 2. Business Logic

- Uses a recursive CTE (cte_affiliations) anchored on tblaff_Tier2Members where NewMemberID = @AffiliateID (direct parent, Tier = 2).
- Recursive member joins tblaff_Tier2Members back to the CTE on m2.NewMemberID = c.AffiliateID to ascend one tier at a time.
- Recursion terminates when c.Tier >= @MaxTier.
- Both anchor and recursive member use NOLOCK hint.
- Returns AffiliateID (parent), NewMemberID (child), SubAffiliateID, and Tier for every row in the ancestor chain.
- The Tier column starts at 2 for the direct parent and increments with each generation upward.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | IN | (required) | High | Leaf affiliate ID whose parent chain will be enumerated |
| 2 | @MaxTier | INT | IN | (required) | High | Maximum number of tiers to traverse upward |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (recursive CTE) | dbo.tblaff_Tier2Members | Read | Source of parent-child relationships, traversed upward |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateParents
  └── dbo.tblaff_Tier2Members   (READ - recursive CTE)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Tier2Members | Table | Stores parent-child affiliate relationships for upward traversal |

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
-- Get the direct parent (Tier 2) of affiliate 5000
EXEC dbo.GetAffiliateParents @AffiliateID = 5000, @MaxTier = 2;

-- Walk up the full ancestry chain to 5 tiers
EXEC dbo.GetAffiliateParents @AffiliateID = 5000, @MaxTier = 5;

-- Store parent chain and check commission eligibility
DECLARE @Parents TABLE (AffiliateID INT, NewMemberID INT, SubAffiliateID INT, Tier INT);
INSERT INTO @Parents
EXEC dbo.GetAffiliateParents @AffiliateID = 5000, @MaxTier = 5;
SELECT AffiliateID AS ParentAffiliateID, Tier
FROM @Parents ORDER BY Tier;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.
*(Author note: Ran Ovadia, 17/7/2019 - Creating for Partners.)*

---

*Generated: 2026-04-12 | Quality: 8.2/10*
*Object: dbo.GetAffiliateParents | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateParents.sql*
