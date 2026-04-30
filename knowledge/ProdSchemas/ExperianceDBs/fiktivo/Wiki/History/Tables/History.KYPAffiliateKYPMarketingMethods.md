# History.KYPAffiliateKYPMarketingMethods

> SQL Server temporal history table storing all historical versions of marketing methods used by KYP-verified affiliates.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateID + MarketingMethodID (composite - maps one affiliate to one marketing method across versions) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.KYPAffiliateKYPMarketingMethods is the system-versioned temporal history table for KYP.AffiliateKYPMarketingMethods. It captures every historical version of the marketing methods declared by KYP-verified affiliates. Each row represents one affiliate-marketing method pair at a specific point in time, recording which marketing channels the affiliate declared they use to generate leads and traffic.

This table supports compliance and partner management by preserving a historical record of how affiliates represent their marketing activities. When an affiliate changes their declared marketing methods - for example, switching from PPC to SEO, or adding Social Media to their declared channels - the prior state is preserved here. This is important for compliance reviews that need to understand what an affiliate claimed they were doing at a specific time versus what was actually observed.

Data flows in automatically via SQL Server's temporal mechanism. With only 5 historical rows, marketing method changes are very rare, suggesting affiliates seldom update their declared methods after initial KYP submission.

---

## 2. Business Logic

### 2.1 Marketing Method Declaration Tracking

**What**: Tracks changes to the marketing methods declared by KYP-verified affiliates over time.

**Columns/Parameters Involved**: `AffiliateID`, `MarketingMethodID`, `ValidFrom`, `ValidTo`

**Rules**:
- AffiliateID + MarketingMethodID together identify a specific affiliate-marketing method relationship
- MarketingMethodID references Dictionary.KYPMarketingMethod: 1=PPC, 2=SEO, 3=Social Media, 4=Email Marketing, 5=Media Buying
- See [KYP Marketing Method](../../Dictionary/Tables/Dictionary.KYPMarketingMethod.md) for the full marketing method dictionary
- An affiliate can declare multiple marketing methods simultaneously
- Only 5 historical rows exist, indicating marketing method declarations are rarely changed after initial setup

---

## 3. Data Overview

The table contains only 5 historical rows, making it the smallest History table in the KYP domain. This indicates that affiliates very rarely modify their declared marketing methods after the initial KYP verification process.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | The affiliate whose marketing method is recorded. References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | MarketingMethodID | int | NO | - | CODE-BACKED | The declared marketing method. See [KYP Marketing Method](../../Dictionary/Tables/Dictionary.KYPMarketingMethod.md): 1=PPC, 2=SEO, 3=Social Media, 4=Email Marketing, 5=Media Buying. |
| 3 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. |
| 4 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this version became active. |
| 5 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | KYP.AffiliateKYPMarketingMethods | Temporal History | Stores historical versions of the base table |
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | The affiliate whose marketing method is recorded |
| MarketingMethodID | Dictionary.KYPMarketingMethod | Implicit FK | The declared marketing method |

### 5.2 Referenced By (other objects point to this)

Accessed implicitly via temporal queries on KYP.AffiliateKYPMarketingMethods.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.KYPAffiliateKYPMarketingMethods (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.AffiliateKYPMarketingMethods | Table | SYSTEM_VERSIONING |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_KYPAffiliateKYPMarketingMethods | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View full marketing method history for an affiliate
```sql
SELECT AffiliateID, MarketingMethodID, ValidFrom, ValidTo
FROM KYP.AffiliateKYPMarketingMethods FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY MarketingMethodID, ValidFrom
```

### 8.2 Check which marketing methods an affiliate declared at a specific date
```sql
SELECT AffiliateID, MarketingMethodID
FROM KYP.AffiliateKYPMarketingMethods FOR SYSTEM_TIME AS OF '2025-06-01' WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY MarketingMethodID
```

### 8.3 Find all historical marketing method changes
```sql
SELECT AffiliateID, MarketingMethodID, ValidFrom, ValidTo
FROM History.KYPAffiliateKYPMarketingMethods WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.KYPAffiliateKYPMarketingMethods | Type: Table | Source: fiktivo/History/Tables/History.KYPAffiliateKYPMarketingMethods.sql*
