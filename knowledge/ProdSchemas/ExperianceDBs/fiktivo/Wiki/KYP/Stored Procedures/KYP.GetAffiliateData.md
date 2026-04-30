# KYP.GetAffiliateData

> Comprehensive reader procedure that returns the full KYP affiliate profile across 6 result sets: main profile (KYP + tblaff_Affiliates JOINed), countries of operation, marketing methods, corporate members, uploaded documents, and payment details.

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateID (input), returns 6 result sets |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYP.GetAffiliateData is the comprehensive data retrieval procedure for the KYP verification form. It returns everything needed to render the full KYP profile UI - the main affiliate data (JOINed from KYP.Affiliate and dbo.tblaff_Affiliates), plus all child collections (countries, marketing methods, corporate members, documents) and payment details. The 6 result sets map directly to the KYP form sections.

This is the most-consumed procedure in the KYP schema. It is also called at the end of `KYP.UpdateAffiliateData` to return the refreshed state after an update (read-after-write pattern). The procedure reads from 7 different tables/views across 3 schemas (KYP, dbo, Affiliate).

Created by Ran Ovadia (11/08/2020). Updated (07/10/2021) for payment details support. Updated (11/09/2023, PART-2028) by Noga to use Affiliate.tblaff_AffiliateURLs for website URLs instead of inline field.

---

## 2. Business Logic

### 2.1 Six Result Sets

**What**: Returns the complete KYP profile as 6 separate result sets that map to form sections.

**Rules**:
- **RS1**: Main profile - KYP.Affiliate INNER JOIN dbo.tblaff_Affiliates. Maps KYP compliance fields + affiliate basic info (name, company, contact). WebSiteURL aggregated from Affiliate.tblaff_AffiliateURLs using STRING_AGG with pipe delimiter.
- **RS2**: Countries of operation - SELECT CountryID FROM KYP.AffiliateCountriesOfOperation
- **RS3**: Marketing methods - SELECT MarketingMethodID FROM KYP.AffiliateKYPMarketingMethods
- **RS4**: Corporate members - SELECT Index, FullName, Position FROM KYP.AffiliateCorporateMembers ORDER BY Index
- **RS5**: KYP documents - SELECT DocID, DocName, DocTypeID FROM KYP.AffiliateKYPDocs
- **RS6**: Payment details - SELECT payment fields FROM dbo.tblaff_PaymentDetails (looked up via tblaff_Affiliates.PaymentDetails2ID)

### 2.2 Column Name Mapping (tblaff_Affiliates to KYP Form)

**What**: Legacy tblaff_Affiliates columns are aliased to business-meaningful names for the KYP UI.

**Rules**:
- Contact -> FirstName
- AffiliateCustom1 -> LastName
- BirthDayDate -> Birthday
- EntityName -> CompanyName
- CompanyAddress -> StreetAddress
- AffiliateCustom2 -> SkypeName

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | The affiliate ID to retrieve the full KYP profile for. Used across all 6 result set queries. |

Output consists of 6 result sets (see Section 2.1 for details).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYP.Affiliate | SELECT (READER) | Main KYP profile data |
| - | dbo.tblaff_Affiliates | INNER JOIN | Affiliate basic info (name, contact, company) |
| - | KYP.AffiliateCountriesOfOperation | SELECT (READER) | Countries of operation list |
| - | KYP.AffiliateKYPMarketingMethods | SELECT (READER) | Marketing methods list |
| - | KYP.AffiliateCorporateMembers | SELECT (READER) | Corporate members list |
| - | KYP.AffiliateKYPDocs | SELECT (READER) | Document metadata list |
| - | dbo.tblaff_PaymentDetails | SELECT (READER) | Payment details (via PaymentDetails2ID) |
| - | Affiliate.tblaff_AffiliateURLs | SELECT (READER) | Website URLs (STRING_AGG aggregation) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.UpdateAffiliateData | @AffiliateID | EXEC call | Called after update to return refreshed state |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYP.GetAffiliateData (procedure)
├── KYP.Affiliate (table)
├── KYP.AffiliateCountriesOfOperation (table)
├── KYP.AffiliateKYPMarketingMethods (table)
├── KYP.AffiliateCorporateMembers (table)
├── KYP.AffiliateKYPDocs (table)
├── dbo.tblaff_Affiliates (table, cross-schema)
├── dbo.tblaff_PaymentDetails (table, cross-schema)
└── Affiliate.tblaff_AffiliateURLs (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | INNER JOIN for KYP profile |
| KYP.AffiliateCountriesOfOperation | Table | SELECT countries |
| KYP.AffiliateKYPMarketingMethods | Table | SELECT marketing methods |
| KYP.AffiliateCorporateMembers | Table | SELECT corporate members |
| KYP.AffiliateKYPDocs | Table | SELECT documents |
| dbo.tblaff_Affiliates | Table (cross-schema) | INNER JOIN for basic affiliate info |
| dbo.tblaff_PaymentDetails | Table (cross-schema) | SELECT payment details |
| Affiliate.tblaff_AffiliateURLs | Table (cross-schema) | STRING_AGG for website URLs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.UpdateAffiliateData | SP | EXEC after update (read-after-write) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get full KYP profile
```sql
EXEC KYP.GetAffiliateData @AffiliateID = 60062
```

### 8.2 Get just the main profile data
```sql
SELECT kyp.AffiliateID, kyp.KYPStatusID, kyp.Progress, aff.EntityName AS CompanyName
FROM KYP.Affiliate kyp WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates aff WITH (NOLOCK) ON kyp.AffiliateID = aff.AffiliateID
WHERE kyp.AffiliateID = 60062
```

### 8.3 Get affiliate with all child counts
```sql
SELECT a.AffiliateID, a.KYPStatusID, a.Progress,
       (SELECT COUNT(*) FROM KYP.AffiliateCountriesOfOperation c WITH (NOLOCK) WHERE c.AffiliateID = a.AffiliateID) AS Countries,
       (SELECT COUNT(*) FROM KYP.AffiliateCorporateMembers m WITH (NOLOCK) WHERE m.AffiliateID = a.AffiliateID) AS Members,
       (SELECT COUNT(*) FROM KYP.AffiliateKYPDocs d WITH (NOLOCK) WHERE d.AffiliateID = a.AffiliateID) AS Docs
FROM KYP.Affiliate a WITH (NOLOCK)
WHERE a.AffiliateID = 60062
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.GetAffiliateData | Type: Stored Procedure | Source: fiktivo/KYP/Stored Procedures/KYP.GetAffiliateData.sql*
