# Dictionary.MarketingRegion

> Lookup table defining geographic and linguistic marketing regions used for segmenting affiliate operations, reporting, and regional commission structures.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MarketingRegionID (tinyint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + unique on Name) |

---

## 1. Business Meaning

Dictionary.MarketingRegion segments the global market into 16 geographic and linguistic regions. Each country in dbo.tblaff_Country is assigned to a marketing region, which drives affiliate commission rate structures, reporting aggregation, and regional business strategy. Regions are defined by a mix of geography (Australia, Canada, India, South Africa, UK, USA) and language (Arabic, French, German, Italian, Spanish & Portuguese).

This table is fundamental to affiliate reporting. All commission summary reports aggregate data by marketing region, allowing business stakeholders to evaluate performance across geographic segments. Regional commission plans may offer different rates per region based on market maturity and customer value.

MarketingRegion is referenced by the country mapping table (dbo.tblaff_Country), multiple reporting procedures, and admin tools. The UNIQUE constraint on Name ensures no duplicate region names exist.

---

## 2. Business Logic

### 2.1 Regional Market Segmentation

**What**: Sixteen regions combining geographic territories and linguistic markets into a unified segmentation framework.

**Columns/Parameters Involved**: `MarketingRegionID`, `Name`

**Rules**:
- ID=0 (Unknown) is the fallback for countries not yet assigned to a region
- Geographic regions: Australia (3), Canada (4), India (7), South Africa (12), UK (14), USA (15)
- Linguistic regions: Arabic (1), French (5), German (6), Italian (8), Spanish & Portuguese (13)
- Catch-all regions: Asia (2), North Europe (9), ROE/Rest of Europe (10), ROW/Rest of World (11)
- Each country maps to exactly one marketing region via dbo.tblaff_Country.MarketingRegionID

---

## 3. Data Overview

| MarketingRegionID | Name | Meaning |
|---|---|---|
| 0 | Unknown | Region not determined or country not yet mapped. Used as a default when a country's marketing region assignment is pending |
| 1 | Arabic | Arabic-speaking markets spanning the Middle East and North Africa (MENA). High-value market with specific regulatory requirements around financial promotions |
| 6 | German | German-speaking markets covering the DACH region (Germany, Austria, Switzerland). Strict financial advertising regulations and high customer value |
| 14 | UK | United Kingdom market. Subject to FCA regulations with specific affiliate marketing compliance requirements |
| 15 | USA | United States market. Subject to SEC/FINRA regulations with the most restrictive affiliate marketing rules |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MarketingRegionID | tinyint | NO | - | VERIFIED | Primary key identifying the marketing region. Values: 0=Unknown, 1=Arabic, 2=Asia, 3=Australia, 4=Canada, 5=French, 6=German, 7=India, 8=Italian, 9=North Europe, 10=ROE, 11=ROW, 12=South Africa, 13=Spanish & Portuguese, 14=UK, 15=USA. See [Marketing Region](../../_glossary.md#marketing-region) for full definitions. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable region label. Subject to UNIQUE constraint (UK_DMR_Name) ensuring no duplicate names. Used in reporting displays, admin filters, and commission plan configuration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Country | MarketingRegionID | Implicit FK | Maps each country to its marketing region |
| AffiliateAdmin.GetMarketingRegion | JOIN | Lookup | Returns marketing regions for admin UI |
| AffiliateReport.ReportSummaryByAffiliate | GROUP BY | Aggregation | Commission reports aggregate by marketing region |
| AffiliateReport.ReportSummaryByAffiliate_RAN | GROUP BY | Aggregation | RAN-variant reports by marketing region |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Country | Table | Country-to-region mapping |
| AffiliateAdmin.GetMarketingRegion | Stored Procedure | READER - returns region list |
| AffiliateReport.ReportSummaryByAffiliate | Stored Procedure | READER - aggregates by region |
| dbo.GetCountryByCode | Stored Procedure | READER - returns country with region |
| dbo.GetCountries | Stored Procedure | READER - returns all countries with regions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DMR | CLUSTERED PK | MarketingRegionID ASC | - | - | Active |
| UK_DMR_Name | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UK_DMR_Name | UNIQUE | Ensures no duplicate marketing region names exist |

---

## 8. Sample Queries

### 8.1 Get all marketing regions
```sql
SELECT MarketingRegionID, Name
FROM Dictionary.MarketingRegion WITH (NOLOCK)
ORDER BY MarketingRegionID
```

### 8.2 Show countries with their marketing region
```sql
SELECT c.CountryCode, c.CountryName, mr.Name AS RegionName
FROM dbo.tblaff_Country c WITH (NOLOCK)
JOIN Dictionary.MarketingRegion mr WITH (NOLOCK) ON c.MarketingRegionID = mr.MarketingRegionID
ORDER BY mr.Name, c.CountryName
```

### 8.3 Count countries per region
```sql
SELECT mr.MarketingRegionID, mr.Name, COUNT(*) AS CountryCount
FROM dbo.tblaff_Country c WITH (NOLOCK)
JOIN Dictionary.MarketingRegion mr WITH (NOLOCK) ON c.MarketingRegionID = mr.MarketingRegionID
GROUP BY mr.MarketingRegionID, mr.Name
ORDER BY CountryCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MarketingRegion | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.MarketingRegion.sql*
