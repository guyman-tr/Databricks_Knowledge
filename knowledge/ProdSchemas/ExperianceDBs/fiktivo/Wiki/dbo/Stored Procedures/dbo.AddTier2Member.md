# dbo.AddTier2Member

> Creates a new tier 2 member relationship by inserting a child affiliate under a parent affiliate into tblaff_Tier2Members, enabling sub-affiliate (tier 2) commission tracking.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Ran Ovadia |
| **Created** | 2019-12-18 |

---

## 1. Business Meaning

This procedure establishes a tier 2 (sub-affiliate) relationship in the affiliate commission hierarchy. When an existing affiliate recruits another affiliate to join the platform, this procedure records the parent-child link so that the parent affiliate can receive tier 2 commission credit on the activity of the child (new) member.

The tier 2 model allows platform operators to incentivize top affiliates to grow the affiliate network itself. The @SubAffiliateId parameter carries a tracking tag that identifies the campaign or channel through which the new member was referred, enabling attribution reporting at the tier 2 level.

This is a lightweight, single-INSERT procedure with no transaction wrapper needed. It is called during the affiliate onboarding workflow when a referral relationship is detected.

---

## 2. Business Logic

### 2.1 Tier 2 Relationship Creation

**What**: Records a parent-child affiliate link for sub-affiliate commission attribution.

**Columns/Parameters Involved**: `@AffiliateId`, `@NewMemberId`, `@SubAffiliateId`

**Rules**:
- @AffiliateId is the existing (parent) affiliate who recruited the new member
- @NewMemberId is the newly registered affiliate being linked as a tier 2 member
- @SubAffiliateId is a free-text tracking tag (up to 1024 chars) identifying the referral source or campaign
- No duplicate-check logic is implemented in the procedure; the caller or a unique constraint on tblaff_Tier2Members is expected to prevent duplicate relationships
- The relationship is permanent once inserted; there is no corresponding archive or delete procedure at this level

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @AffiliateId | IN | int | (required) | The AffiliateID of the existing parent affiliate who recruited the new member. References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | @NewMemberId | IN | int | (required) | The AffiliateID of the newly registered affiliate being added as a tier 2 child member. References dbo.tblaff_Affiliates.AffiliateID. |
| 3 | @SubAffiliateId | IN | nvarchar(1024) | (required) | Tracking tag or campaign identifier associated with the referral. Stored alongside the relationship for attribution reporting. |

---

## 5. Relationships

### 5.1 Tables Written

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Tier2Members | INSERT | Inserts one row establishing the parent-child tier 2 affiliate relationship |

### 5.2 Tables Read

None.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddTier2Member (stored procedure)
+-- dbo.tblaff_Tier2Members (table) [INSERT]
    +-- dbo.tblaff_Affiliates (table) [implicit FK on AffiliateId and NewMemberId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Tier2Members | Table | Target of the INSERT statement |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate onboarding workflow | Application | Calls this procedure when a referred affiliate completes registration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- No explicit transaction; single-statement INSERT is atomic by default
- No SET NOCOUNT ON observed; caller should handle rowcount if needed
- No output parameters; no return value beyond implicit success/failure

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC dbo.AddTier2Member
    @AffiliateId    = 1001,
    @NewMemberId    = 2005,
    @SubAffiliateId = N'campaign_winter2020';
```

### 8.2 Verify the relationship was created

```sql
SELECT AffiliateId, NewMemberId, SubAffiliateId
FROM dbo.tblaff_Tier2Members WITH (NOLOCK)
WHERE AffiliateId = 1001
  AND NewMemberId = 2005;
```

### 8.3 List all tier 2 members under a parent affiliate

```sql
SELECT t.NewMemberId, t.SubAffiliateId, a.LoginName, a.DateCreated
FROM dbo.tblaff_Tier2Members t WITH (NOLOCK)
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON t.NewMemberId = a.AffiliateID
WHERE t.AffiliateId = 1001
ORDER BY a.DateCreated DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10*
*Object: dbo.AddTier2Member | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.AddTier2Member.sql*
