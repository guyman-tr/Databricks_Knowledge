# AffiliateAdmin.GetAffiliateTierHierarchy

> Builds a recursive tier hierarchy tree for an affiliate, showing parent-child referral relationships up to a configurable depth.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns hierarchical tree: AffiliateID, Tier, ParentAffiliateID, Contact, DateCreated |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliateTierHierarchy is a recursive procedure that constructs the full referral tier tree for a given affiliate. In the affiliate program, affiliates can refer other affiliates (tier-2, tier-3, etc.), forming a multi-level hierarchy. This procedure traverses that hierarchy using a recursive Common Table Expression (CTE) to show all downstream affiliates and their depth levels.

This procedure exists because the admin portal needs to visualize and analyze the referral network of any affiliate. Understanding the tier structure is essential for commission calculations (where higher-tier affiliates earn overrides on their referrals' performance), fraud detection (identifying suspicious referral chains), and business development (measuring an affiliate's recruitment effectiveness).

Data flow: The procedure starts with the given @AffiliateID as the anchor and recursively joins dbo.tblaff_Tier2Members to discover child affiliates at each level. The recursion continues until either no more children are found or @MaxDepth is reached. At each level, the procedure joins dbo.tblaff_Affiliates to resolve affiliate contact information and creation dates, returning a flattened result set with a Tier column indicating each node's depth in the hierarchy.

---

## 2. Business Logic

### 2.1 Recursive CTE Traversal

The core logic uses a recursive CTE anchored on @AffiliateID. The anchor member selects the root affiliate at Tier 0, and the recursive member joins tblaff_Tier2Members to find all affiliates whose ParentAffiliateID matches a previously discovered affiliate. Each recursion increments the Tier counter.

### 2.2 Depth Limiting

The @MaxDepth parameter (default 5) caps the recursion depth to prevent runaway queries in deeply nested or circular referral chains. The recursive member includes a WHERE clause checking that the current Tier is less than @MaxDepth.

### 2.3 Affiliate Detail Enrichment

The recursive CTE output is joined with dbo.tblaff_Affiliates to attach human-readable Contact names and DateCreated timestamps to each node in the hierarchy, making the result set immediately useful for display in the admin UI.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int | NO | - | CODE-BACKED | Root affiliate ID from which to build the tier hierarchy tree. |
| 2 | @MaxDepth | int | NO | 5 | CODE-BACKED | Maximum recursion depth. Limits how many tier levels deep the hierarchy is traversed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_Tier2Members | Read | Recursive traversal of parent-child affiliate referral relationships |
| JOIN | dbo.tblaff_Affiliates | Read | Resolves AffiliateID to Contact name and DateCreated |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliateTierHierarchy (procedure)
+-- dbo.tblaff_Tier2Members (table, recursive CTE)
+-- dbo.tblaff_Affiliates (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Tier2Members | Table | Recursive CTE for parent-child tier traversal |
| dbo.tblaff_Affiliates | Table | JOIN for affiliate contact and date details |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get tier hierarchy for affiliate with default depth
```sql
EXEC AffiliateAdmin.GetAffiliateTierHierarchy @AffiliateID = 5001;
-- Returns: AffiliateID, Tier (0-5), ParentAffiliateID, Contact, DateCreated
-- Tier 0 = root affiliate, Tier 1 = direct referrals, etc.
```

### 8.2 Get shallow hierarchy (direct referrals only)
```sql
EXEC AffiliateAdmin.GetAffiliateTierHierarchy @AffiliateID = 5001, @MaxDepth = 1;
-- Returns only the root affiliate (Tier 0) and direct referrals (Tier 1)
```

### 8.3 Manually count referrals per tier level
```sql
;WITH Hierarchy AS (
    SELECT AffiliateID, 0 AS Tier
    FROM dbo.tblaff_Affiliates WITH (NOLOCK)
    WHERE AffiliateID = 5001
    UNION ALL
    SELECT t.AffiliateID, h.Tier + 1
    FROM dbo.tblaff_Tier2Members t WITH (NOLOCK)
    JOIN Hierarchy h ON h.AffiliateID = t.ParentAffiliateID
    WHERE h.Tier < 5
)
SELECT Tier, COUNT(*) AS AffiliateCount
FROM Hierarchy
GROUP BY Tier
ORDER BY Tier;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-5232.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliateTierHierarchy | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliateTierHierarchy.sql*
