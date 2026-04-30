# Dictionary.NatureOfBusiness

> Lookup table defining the industry sector classifications for corporate affiliate entities, collected during KYP onboarding for compliance and risk assessment.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | NatureOfBusinessID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.NatureOfBusiness classifies the industry sector of corporate affiliates. During KYP onboarding, companies declare their primary business activity, which helps the compliance team assess risk and apply appropriate due diligence. Certain industries (e.g., Marketing, which directly relates to affiliate advertising) may require different oversight than others.

Without this classification, compliance could not perform industry-based risk profiling. Marketing companies promoting financial services face different regulatory scrutiny than construction firms acting as affiliates.

This is static reference data used by the KYP subsystem. The KYP.Affiliate table stores NatureOfBusinessID for each corporate affiliate.

---

## 2. Business Logic

### 2.1 Industry Sector Classification

**What**: Eight industry sectors for corporate affiliate risk assessment.

**Columns/Parameters Involved**: `NatureOfBusinessID`, `NatureOfBusinessName`

**Rules**:
- ID=1 (Other) is the catch-all for industries not in the standard categories
- ID=3 (Marketing) is particularly relevant as marketing companies are the most common type of corporate affiliate
- ID=6 (Medical) and ID=7 (Education) may have specific advertising restrictions in financial services

---

## 3. Data Overview

| NatureOfBusinessID | NatureOfBusinessName | Meaning |
|---|---|---|
| 1 | Other | Industry not covered by standard categories. Triggers additional review to understand the company's business model and its relevance to financial services marketing |
| 3 | Marketing | Digital marketing, advertising, or media services. The most common industry for corporate affiliates as marketing is their core business. Highest compliance attention due to direct involvement in financial promotions |
| 5 | Art | Fine art, design studios, or creative industries. Less common for affiliates but may operate creative marketing agencies |
| 6 | Medical | Healthcare, pharmaceutical, or medical services. Unusual for financial affiliates, may trigger additional scrutiny about the relationship to financial services |
| 7 | Education | Educational institutions or training services. May include financial education platforms that refer students to trading accounts |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NatureOfBusinessID | int | NO | - | VERIFIED | Primary key identifying the industry sector. Values: 1=Other, 2=Real Estate, 3=Marketing, 4=Construction, 5=Art, 6=Medical, 7=Education, 8=Design. See [Nature Of Business](../../_glossary.md#nature-of-business) for full definitions. |
| 2 | NatureOfBusinessName | nvarchar(25) | NO | - | VERIFIED | Human-readable label for the industry sector. Displayed in KYP admin screens and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.Affiliate | NatureOfBusinessID | Implicit FK | Stores industry classification for each corporate affiliate |
| History.KYPAffiliate | NatureOfBusinessID | Implicit FK | Historical industry classification records |
| KYP.GetAffiliateData | JOIN | Lookup | Returns industry classification in KYP data |
| KYP.UpdateAffiliateData | Parameter | Lookup | Updates industry classification during KYP review |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | Stores NatureOfBusinessID |
| History.KYPAffiliate | Table | Historical records |
| KYP.GetAffiliateData | Stored Procedure | READER |
| KYP.UpdateAffiliateData | Stored Procedure | MODIFIER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryNatureOfBusiness | CLUSTERED PK | NatureOfBusinessID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all industry sectors
```sql
SELECT NatureOfBusinessID, NatureOfBusinessName
FROM Dictionary.NatureOfBusiness WITH (NOLOCK)
ORDER BY NatureOfBusinessID
```

### 8.2 Count corporate affiliates by industry
```sql
SELECT nb.NatureOfBusinessID, nb.NatureOfBusinessName, COUNT(*) AS AffiliateCount
FROM KYP.Affiliate a WITH (NOLOCK)
JOIN Dictionary.NatureOfBusiness nb WITH (NOLOCK) ON a.NatureOfBusinessID = nb.NatureOfBusinessID
GROUP BY nb.NatureOfBusinessID, nb.NatureOfBusinessName
ORDER BY AffiliateCount DESC
```

### 8.3 Find marketing company affiliates (highest compliance relevance)
```sql
SELECT a.*
FROM KYP.Affiliate a WITH (NOLOCK)
WHERE a.NatureOfBusinessID = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.NatureOfBusiness | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.NatureOfBusiness.sql*
