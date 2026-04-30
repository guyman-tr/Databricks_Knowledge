# AffiliateCommission.GetReferralsAffiliates

> Walks the multi-tier affiliate referral chain using a recursive CTE, returning all downstream affiliates (tiers 2-5) with their commission rates for a given tier-1 affiliate.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns affiliate chain with tier levels and commission rates |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetReferralsAffiliates resolves the full multi-tier referral chain for a given top-level (tier 1) affiliate. In a multi-level affiliate program, a tier-1 affiliate can refer other affiliates, who can in turn refer more. This procedure uses a recursive CTE to walk the referral tree up to 5 levels deep, returning each downstream affiliate with their tier level and commission rates.

This procedure exists because the commission engine needs to identify all affiliates in a referral chain when calculating multi-tier commissions. When a customer referred by a tier-1 affiliate generates commission, upstream affiliates in the chain may also earn a percentage. This procedure provides the chain structure needed for that calculation.

The referral links are stored in dbo.tblaff_Tier2Members (the naming reflects that tier-2 is the first sub-affiliate level). The recursive CTE follows the NewMemberID -> AffiliateID chain until it reaches tier 5 or exhausts the tree.

---

## 2. Business Logic

### 2.1 Recursive Referral Chain Walk

**What**: Builds the complete affiliate referral tree from tier 2 to tier 5 using a recursive CTE.

**Columns/Parameters Involved**: `@Tier1AffiliateID`, `AffiliateID`, `NewMemberID`, `Tier`

**Rules**:
- Anchor: All entries in tblaff_Tier2Members where NewMemberID = @Tier1AffiliateID (direct sub-affiliates, tier 2)
- Recursion: For each found affiliate, find their sub-affiliates in tblaff_Tier2Members (Tier + 1)
- Max depth: Tier < 5 (supports up to 5-level deep chains)
- Result enrichment: Joins to tblaff_Affiliates and tblaff_AffiliateTypes to get commission rates
- Returns: AffiliateID, Tier, PerSale, PerDeposit, PerPNL, AffiliateTypeID

**Diagram**:
```
Tier 1: @Tier1AffiliateID (input)
  |
  +-- Tier 2: Direct sub-affiliates (tblaff_Tier2Members.NewMemberID = Tier1)
  |     |
  |     +-- Tier 3: Sub-sub-affiliates
  |           |
  |           +-- Tier 4: ...
  |                 |
  |                 +-- Tier 5: Maximum depth
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Tier1AffiliateID | int (IN) | NO | - | CODE-BACKED | The top-level (tier 1) affiliate whose referral chain is being queried. Matched against tblaff_Tier2Members.NewMemberID as the anchor. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | AffiliateID | int | - | - | CODE-BACKED | The downstream affiliate in the referral chain. |
| 3 | Tier | int | - | - | CODE-BACKED | The tier level (2-5) of this affiliate in the chain relative to the input tier-1 affiliate. |
| 4 | PerSale | money | - | - | CODE-BACKED | The affiliate's per-sale commission rate from their AffiliateType configuration. |
| 5 | PerDeposit | money | - | - | CODE-BACKED | The affiliate's per-deposit commission rate. |
| 6 | PerPNL | money | - | - | CODE-BACKED | The affiliate's per-PnL commission rate. |
| 7 | AffiliateTypeID | int | - | - | CODE-BACKED | The affiliate's compensation plan type. Links to the full rate card. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Tier1AffiliateID | dbo.tblaff_Tier2Members | READ (recursive CTE) | Walks the referral chain via NewMemberID -> AffiliateID links |
| AffiliateID | dbo.tblaff_Affiliates | READ (JOIN) | Resolves AffiliateTypeID for commission rates |
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | READ (JOIN) | Gets PerSale, PerDeposit, PerPNL rates |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission engine for multi-tier calculations.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetReferralsAffiliates (procedure)
+-- dbo.tblaff_Tier2Members (table, external)
+-- dbo.tblaff_Affiliates (table, external)
+-- dbo.tblaff_AffiliateTypes (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Tier2Members | Table (external) | Recursive CTE anchor and recursion source for referral chain |
| dbo.tblaff_Affiliates | Table (external) | JOIN to resolve AffiliateTypeID |
| dbo.tblaff_AffiliateTypes | Table (external) | JOIN to get commission rates (PerSale, PerDeposit, PerPNL) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission engine) | External | Resolves multi-tier referral chains for commission splitting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get referral chain for affiliate 3
```sql
EXEC [AffiliateCommission].[GetReferralsAffiliates] @Tier1AffiliateID = 3
```

### 8.2 Check direct sub-affiliates (tier 2 only)
```sql
SELECT m.AffiliateID, m.NewMemberID, m.SubAffiliateID
FROM [dbo].[tblaff_Tier2Members] AS m WITH (NOLOCK)
WHERE m.NewMemberID = 3
```

### 8.3 Find affiliates with the deepest referral chains
```sql
;WITH cte AS (
    SELECT m.AffiliateID, m.NewMemberID, 2 AS Tier
    FROM [dbo].[tblaff_Tier2Members] AS m WITH (NOLOCK)
    UNION ALL
    SELECT m2.AffiliateID, m2.NewMemberID, c.Tier + 1
    FROM [dbo].[tblaff_Tier2Members] AS m2 WITH (NOLOCK)
    INNER JOIN cte AS c ON m2.NewMemberID = c.AffiliateID
    WHERE c.Tier < 5
)
SELECT NewMemberID AS Tier1AffiliateID, MAX(Tier) AS MaxDepth, COUNT(*) AS ChainSize
FROM cte
GROUP BY NewMemberID
ORDER BY MaxDepth DESC, ChainSize DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetReferralsAffiliates | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetReferralsAffiliates.sql*
