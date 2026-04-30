# Dictionary.FormOfIncorporation

> Lookup table defining the legal structure classifications for corporate affiliate entities, used during KYP (Know Your Partner) onboarding.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FormOfIncorporationID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FormOfIncorporation classifies the legal structure of corporate affiliate entities. When a company (rather than an individual) registers as an affiliate, the KYP (Know Your Partner) onboarding process captures whether the entity is privately held, publicly traded, or has another legal structure. This classification drives compliance validation rules and risk assessment.

Without this table, the compliance team could not apply the correct due diligence requirements. Public companies have different documentation requirements than private companies, and "Other" structures may require additional verification steps.

This is static reference data used by the KYP subsystem. The KYP.Affiliate table stores FormOfIncorporationID for each corporate affiliate, populated during onboarding and updated if the entity's legal structure changes.

---

## 2. Business Logic

### 2.1 Corporate Structure Classification

**What**: Three legal structure types that determine KYP compliance requirements.

**Columns/Parameters Involved**: `FormOfIncorporationID`, `FormOfIncorporationName`

**Rules**:
- ID=1 (Other) is a catch-all for structures not fitting standard categories - may trigger additional manual review
- ID=2 (Private) indicates a privately held company - requires standard corporate documentation (articles of incorporation, beneficial ownership)
- ID=3 (Public) indicates a publicly listed company - may have lighter documentation requirements since public disclosures satisfy some KYP checks

---

## 3. Data Overview

| FormOfIncorporationID | FormOfIncorporationName | Meaning |
|---|---|---|
| 1 | Other | Legal structure not covered by standard categories. Includes partnerships, LLCs, sole proprietorships, trusts, or foreign entity types. May require additional manual compliance review |
| 2 | Private | Privately held company with shares not publicly traded. Standard KYP documentation required: certificate of incorporation, beneficial ownership declaration, director identification |
| 3 | Public | Publicly listed company with shares traded on a recognized exchange. Regulatory filings and public disclosures may satisfy some KYP documentation requirements |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FormOfIncorporationID | int | NO | - | VERIFIED | Primary key identifying the legal structure type. Values: 1=Other, 2=Private, 3=Public. See [Form Of Incorporation](../../_glossary.md#form-of-incorporation) for full business definitions. Referenced by KYP.Affiliate for corporate affiliate onboarding. |
| 2 | FormOfIncorporationName | nvarchar(25) | NO | - | VERIFIED | Human-readable label for the legal structure. Displayed in KYP admin screens and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.Affiliate | FormOfIncorporationID | Implicit FK | Stores legal structure for each corporate affiliate |
| History.KYPAffiliate | FormOfIncorporationID | Implicit FK | Historical snapshot preserves legal structure for audit |
| KYP.GetAffiliateData | JOIN | Lookup | Returns affiliate KYP data including legal structure |
| KYP.UpdateAffiliateData | Parameter | Lookup | Updates affiliate legal structure during KYP review |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | Stores FormOfIncorporationID |
| History.KYPAffiliate | Table | Historical KYP records |
| KYP.GetAffiliateData | Stored Procedure | READER - returns KYP affiliate data |
| KYP.UpdateAffiliateData | Stored Procedure | MODIFIER - updates KYP affiliate data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryFormOfIncorporation | CLUSTERED PK | FormOfIncorporationID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all incorporation forms
```sql
SELECT FormOfIncorporationID, FormOfIncorporationName
FROM Dictionary.FormOfIncorporation WITH (NOLOCK)
ORDER BY FormOfIncorporationID
```

### 8.2 Count corporate affiliates by legal structure
```sql
SELECT fi.FormOfIncorporationID, fi.FormOfIncorporationName, COUNT(*) AS AffiliateCount
FROM KYP.Affiliate a WITH (NOLOCK)
JOIN Dictionary.FormOfIncorporation fi WITH (NOLOCK) ON a.FormOfIncorporationID = fi.FormOfIncorporationID
GROUP BY fi.FormOfIncorporationID, fi.FormOfIncorporationName
```

### 8.3 Find affiliates with non-standard legal structures requiring review
```sql
SELECT a.*
FROM KYP.Affiliate a WITH (NOLOCK)
WHERE a.FormOfIncorporationID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FormOfIncorporation | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.FormOfIncorporation.sql*
