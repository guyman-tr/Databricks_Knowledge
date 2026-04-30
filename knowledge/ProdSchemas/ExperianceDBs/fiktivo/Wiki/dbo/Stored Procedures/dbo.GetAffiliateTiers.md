# dbo.GetAffiliateTiers

> Returns the NewMemberID and tier number for all sub-affiliates beneath a given affiliate, traversing up to four levels deep using nested subquery unions (tiers 2 through 5), bounded by the @MaxTier limit.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateID + MaxTier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the flattened list of sub-affiliate member IDs and their tier depth for a given parent affiliate, up to Tier 5. It is used in the affiliate management platform to enumerate which affiliates earn which tier of sub-affiliate commissions. Unlike GetAffiliateChildren (which uses a recursive CTE), this SP uses explicit nested subquery unions for tiers 2 through 5. This makes the depth limit fixed in the SQL structure itself (max 4 levels below the root). It was designed for use cases that require a flat list of members at each tier rather than the full parent-child relationship rows.

---

## 2. Business Logic

- Four UNION branches query tblaff_Tier2Members at each level:
  - Tier 2: Direct children where AffiliateID = @AffiliateID.
  - Tier 3: Children of Tier 2 members (one level of nesting).
  - Tier 4: Children of Tier 3 members (two levels of nesting).
  - Tier 5: Children of Tier 4 members (three levels of nesting).
- Results are filtered by Tiers.Tier <= @MaxTier after the UNION, allowing callers to cap the depth.
- Uses UNION (not UNION ALL), which deduplicates - a member appearing in multiple paths via different parents counts once per tier.
- No NOLOCK hints on these reads.
- SET NOCOUNT ON suppresses extra result sets.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | IN | (required) | High | Root affiliate whose sub-affiliate tier members are listed |
| 2 | @MaxTier | INT | IN | (required) | High | Maximum tier depth to include (2-5; values above 5 return all tiers) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (nested UNION) | dbo.tblaff_Tier2Members | Read | Traversed at multiple levels of nesting to produce tier-annotated member list |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateTiers
  └── dbo.tblaff_Tier2Members   (READ, queried at 4 nesting depths)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Tier2Members | Table | Parent-child affiliate relationships; queried at Tier 2, 3, 4, and 5 |

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
-- Get all direct sub-affiliates (Tier 2 only) of affiliate 1000
EXEC dbo.GetAffiliateTiers @AffiliateID = 1000, @MaxTier = 2;

-- Get full hierarchy up to Tier 5
EXEC dbo.GetAffiliateTiers @AffiliateID = 1000, @MaxTier = 5;

-- Count members at each tier level
DECLARE @Tiers TABLE (NewMemberID INT, Tier INT);
INSERT INTO @Tiers
EXEC dbo.GetAffiliateTiers @AffiliateID = 1000, @MaxTier = 5;
SELECT Tier, COUNT(*) AS MemberCount FROM @Tiers GROUP BY Tier ORDER BY Tier;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 8.2/10*
*Object: dbo.GetAffiliateTiers | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateTiers.sql*
