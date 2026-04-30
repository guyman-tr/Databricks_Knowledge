# dbo.tblaff_Country

> Country reference table mapping each country to its default affiliate group, marketing region, and affiliate type for geo-targeted affiliate configuration.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | CountryID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table defines the country-level configuration for the affiliate platform. Each row maps a country (identified by ISO 3166-1 numeric code and 2-letter abbreviation) to a default affiliate group, marketing region, and affiliate type. When a new affiliate registers from a specific country, the platform can auto-assign them to the correct group and commission plan.

Without this table, the platform could not implement geo-targeted affiliate management - different countries have different regulatory requirements, marketing strategies, and commission structures. The MarketingRegionID groups countries into broader marketing territories for regional reporting. Managed by admin users with Countries_* permissions.

---

## 2. Business Logic

### 2.1 Country-to-Channel Mapping

**What**: Each country has default routing for new affiliates - which group they join and which commission plan they receive.

**Columns/Parameters Involved**: `CountryID`, `AffiliatesGroupsID`, `AffiliateTypeID`, `MarketingRegionID`

**Rules**:
- AffiliatesGroupsID determines the default group for affiliates from this country (references [tblaff_AffiliatesGroups](dbo.tblaff_AffiliatesGroups.md))
- AffiliateTypeID (when set) overrides the group-level default commission plan for this country
- MarketingRegionID classifies the country into a broader marketing territory. See [Marketing Region](../../_glossary.md#marketing-region): 1=Arabic, 2=Asia, ..., 14=UK, 15=USA
- CountryID=0 with Abbreviation="  " is the "Not available" sentinel for unknown/unresolved countries

---

## 3. Data Overview

| CountryID | Abbreviation | Name | MarketingRegionID | AffiliatesGroupsID | Meaning |
|-----------|-------------|------|-------------------|-------------------|---------|
| 0 | (blank) | Not available | 11 (ROW) | NULL | Sentinel for unknown/unresolved country. Defaults to Rest of World region. |
| 1 | AF | Afghanistan | 11 (ROW) | 11 | Assigned to general affiliate group 11, Rest of World region. No country-specific plan. |
| 3 | DZ | Algeria | 1 (Arabic) | 159 | Assigned to Arabic marketing region with dedicated group 159 for Arabic-market affiliates. |
| 4 | AS | American Samoa | 11 (ROW) | 141 | US territory mapped to ROW region with separate group. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Primary key. ISO 3166-1 numeric country code. 0 = "Not available" sentinel. Referenced by tblaff_Affiliates.CountryID (explicit FK). |
| 2 | Abbreviation | char(2) | NO | - | CODE-BACKED | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Used for display and API integration. |
| 3 | Name | varchar(50) | NO | - | CODE-BACKED | Country display name (e.g., "United States", "United Kingdom"). MASKED (dynamic data masking). |
| 4 | AffiliatesGroupsID | int | YES | - | CODE-BACKED | Default affiliate group for this country. References [dbo.tblaff_AffiliatesGroups](dbo.tblaff_AffiliatesGroups.md). NULL = no country-level group default. |
| 5 | MarketingRegionID | tinyint | NO | 0 | CODE-BACKED | FK to Dictionary.MarketingRegion. Groups country into marketing territory. See [Marketing Region](../../_glossary.md#marketing-region): 0=Unknown, 1=Arabic, ..., 15=USA. Default 0 (Unknown). |
| 6 | AffiliateTypeID | int | YES | - | CODE-BACKED | Default commission plan for affiliates from this country. References [dbo.tblaff_AffiliateTypes](dbo.tblaff_AffiliateTypes.md). NULL = use group-level default plan. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MarketingRegionID | Dictionary.MarketingRegion | Explicit FK | Marketing territory classification. |
| AffiliatesGroupsID | [dbo.tblaff_AffiliatesGroups](dbo.tblaff_AffiliatesGroups.md) | Implicit FK | Default group for affiliates from this country. |
| AffiliateTypeID | [dbo.tblaff_AffiliateTypes](dbo.tblaff_AffiliateTypes.md) | Implicit FK | Default commission plan override for this country. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Affiliates | CountryID | Explicit FK | Affiliate's registered country. |
| dbo.tblaff_Lead2Country | CountryID | Implicit FK | Country-specific lead tracking. |
| dbo.tblaff_Registration2Country | CountryID | Implicit FK | Country-specific registration tracking. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.tblaff_Country (table)
+-- Dictionary.MarketingRegion (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MarketingRegion | Table | FK: MarketingRegionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | CountryID FK |
| dbo.GetCountries | Stored Procedure | READER |
| dbo.GetCountriesAndIDs | Stored Procedure | READER |
| dbo.GetCountryByCode | Stored Procedure | READER |
| dbo.UpdateInsertCountry | Stored Procedure | WRITER/MODIFIER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_Country | CLUSTERED PK | CountryID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DCNR_NullMarketingRegion | DEFAULT | MarketingRegionID = 0 (Unknown) |
| FK_DMRG_DCNR | FOREIGN KEY | MarketingRegionID -> Dictionary.MarketingRegion.MarketingRegionID |

---

## 8. Sample Queries

### 8.1 List countries by marketing region
```sql
SELECT c.CountryID, c.Abbreviation, c.Name, mr.Name AS Region
FROM dbo.tblaff_Country c WITH (NOLOCK)
JOIN Dictionary.MarketingRegion mr WITH (NOLOCK) ON c.MarketingRegionID = mr.MarketingRegionID
WHERE c.CountryID > 0
ORDER BY mr.Name, c.Name
```

### 8.2 Find countries with specific affiliate type overrides
```sql
SELECT c.CountryID, c.Name, at.Description AS AffiliateType
FROM dbo.tblaff_Country c WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON c.AffiliateTypeID = at.AffiliateTypeID
WHERE c.AffiliateTypeID IS NOT NULL
```

### 8.3 Count countries per marketing region
```sql
SELECT mr.Name AS Region, COUNT(*) AS CountryCount
FROM dbo.tblaff_Country c WITH (NOLOCK)
JOIN Dictionary.MarketingRegion mr WITH (NOLOCK) ON c.MarketingRegionID = mr.MarketingRegionID
WHERE c.CountryID > 0
GROUP BY mr.Name
ORDER BY CountryCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Country | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Country.sql*
