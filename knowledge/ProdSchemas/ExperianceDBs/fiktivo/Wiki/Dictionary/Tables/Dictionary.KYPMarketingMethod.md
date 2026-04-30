# Dictionary.KYPMarketingMethod

> Lookup table defining the primary marketing channels used by affiliates to drive traffic, collected during KYP onboarding for compliance and risk assessment.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MarketingMethodID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.KYPMarketingMethod captures the primary marketing channel an affiliate uses to acquire customers. This information is collected during KYP onboarding to help the compliance team understand the affiliate's business model and assess associated risks. Different marketing methods carry different regulatory implications - for example, PPC advertising in financial services is heavily regulated in some jurisdictions.

Without this classification, compliance could not perform risk-appropriate due diligence or enforce marketing method-specific restrictions. Some jurisdictions require different oversight levels based on how affiliates market financial products.

This is static reference data used by the KYP subsystem. The KYP.AffiliateKYPMarketingMethods table allows affiliates to declare one or more marketing methods.

---

## 2. Business Logic

### 2.1 Marketing Channel Classification

**What**: Five primary digital marketing channels that affiliates use for customer acquisition.

**Columns/Parameters Involved**: `MarketingMethodID`, `MarketingMethodName`

**Rules**:
- ID=1 (PPC) and ID=2 (SEO) are search-based channels with different regulatory implications - PPC involves paid financial promotions
- ID=3 (Social Media) covers all social platform-based marketing
- ID=4 (Email Marketing) covers newsletter and email campaign-based acquisition
- ID=5 (Media Buying) covers programmatic and direct display advertising purchases
- An affiliate may use multiple methods simultaneously (junction table KYP.AffiliateKYPMarketingMethods)

---

## 3. Data Overview

| MarketingMethodID | MarketingMethodName | Meaning |
|---|---|---|
| 1 | PPC | Pay-Per-Click advertising through Google Ads, Bing, etc. Highest regulatory scrutiny because ads promoting financial services must comply with advertising standards in each jurisdiction |
| 2 | SEO | Search Engine Optimization - organic search traffic. Lower compliance risk as content is editorial, but still subject to financial promotion rules |
| 3 | Social Media | Traffic driven through social media platforms (Facebook, Instagram, Twitter, TikTok, YouTube). Subject to platform-specific advertising policies for financial services |
| 4 | Email Marketing | Email campaigns and newsletter-based customer acquisition. Subject to anti-spam regulations (GDPR, CAN-SPAM) and financial promotion rules |
| 5 | Media Buying | Direct display and programmatic advertising purchases. Involves placing ads on third-party websites through ad networks or direct deals |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MarketingMethodID | int | NO | - | VERIFIED | Primary key identifying the marketing channel. Values: 1=PPC, 2=SEO, 3=Social Media, 4=Email Marketing, 5=Media Buying. See [KYP Marketing Method](../../_glossary.md#kyp-marketing-method) for full definitions. |
| 2 | MarketingMethodName | nvarchar(25) | NO | - | VERIFIED | Human-readable label for the marketing channel. Displayed in KYP forms and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.AffiliateKYPMarketingMethods | MarketingMethodID | Implicit FK | Junction table linking affiliates to their declared marketing methods |
| History.KYPAffiliateKYPMarketingMethods | MarketingMethodID | Implicit FK | Historical snapshot of affiliate marketing method declarations |
| KYP.GetAffiliateData | JOIN | Lookup | Returns affiliate marketing methods during KYP review |
| KYP.UpdateAffiliateData | Parameter | Lookup | Updates affiliate marketing method declarations |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.AffiliateKYPMarketingMethods | Table | Junction table for affiliate-to-method mapping |
| History.KYPAffiliateKYPMarketingMethods | Table | Historical marketing method records |
| KYP.GetAffiliateData | Stored Procedure | READER - returns marketing methods |
| KYP.UpdateAffiliateData | Stored Procedure | MODIFIER - updates marketing methods |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryKYPMarketingMethod | CLUSTERED PK | MarketingMethodID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all marketing methods
```sql
SELECT MarketingMethodID, MarketingMethodName
FROM Dictionary.KYPMarketingMethod WITH (NOLOCK)
ORDER BY MarketingMethodID
```

### 8.2 Find affiliates using PPC (highest regulatory scrutiny)
```sql
SELECT a.AffiliateID, mm.MarketingMethodName
FROM KYP.AffiliateKYPMarketingMethods amm WITH (NOLOCK)
JOIN KYP.Affiliate a WITH (NOLOCK) ON amm.AffiliateID = a.AffiliateID
JOIN Dictionary.KYPMarketingMethod mm WITH (NOLOCK) ON amm.MarketingMethodID = mm.MarketingMethodID
WHERE amm.MarketingMethodID = 1
```

### 8.3 Count affiliates by marketing method
```sql
SELECT mm.MarketingMethodID, mm.MarketingMethodName, COUNT(*) AS AffiliateCount
FROM KYP.AffiliateKYPMarketingMethods amm WITH (NOLOCK)
JOIN Dictionary.KYPMarketingMethod mm WITH (NOLOCK) ON amm.MarketingMethodID = mm.MarketingMethodID
GROUP BY mm.MarketingMethodID, mm.MarketingMethodName
ORDER BY AffiliateCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.KYPMarketingMethod | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.KYPMarketingMethod.sql*
