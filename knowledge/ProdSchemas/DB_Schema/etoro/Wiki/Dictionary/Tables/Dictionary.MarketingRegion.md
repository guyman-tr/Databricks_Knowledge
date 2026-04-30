# Dictionary.MarketingRegion

> Lookup table defining the 21 geographic marketing segments used for customer acquisition, localization, and regional reporting.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MarketingRegionID (TINYINT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK clustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.MarketingRegion defines the geographic segments used by eToro's marketing and business intelligence teams to categorize customers, campaigns, and revenue by region. These regions are not strictly geographic — they blend geography, language, and business strategy (e.g., "French" and "German" are language-based regions, while "ROE" and "ROW" are catch-all categories for Rest of Europe and Rest of World).

Each country is mapped to a MarketingRegionID in `Dictionary.Country`, enabling customer segmentation by marketing region. This powers regional KPI dashboards, marketing spend allocation, localized content delivery, and sales team territory assignments.

The ID 99 ("eToro") is a special value representing the company itself, used for internal transactions, test accounts, or company-level aggregations.

---

## 2. Business Logic

### 2.1 Geographic Segmentation Strategy

**What**: Marketing regions group countries into business-meaningful segments that blend geography, language, and market strategy.

**Columns/Parameters Involved**: `MarketingRegionID`, `Name`

**Rules**:
- Regions are assigned at the country level (Dictionary.Country.MarketingRegionID), not per customer
- A customer's marketing region is derived from their registration country
- Region 0 ("Unknown") is the fallback when country-to-region mapping is missing
- Region 99 ("eToro") is reserved for internal/corporate use
- ID 19 is skipped in the sequence — the numbering has gaps from historical changes
- Regions can be language-based (French, German, Italian, Russian, Arabic) or geography-based (Australia, UK, USA, Israel)
- ROE (12) = Rest of Europe, ROW (13) = Rest of World — catch-all segments

---

## 3. Data Overview

| MarketingRegionID | Name | Meaning |
|---|---|---|
| 0 | Unknown | Fallback when the customer's country has no marketing region mapping. Should be minimal in production — indicates data quality issue. |
| 3 | Australia | Australian market — ASIC-regulated customers. Separate from Asia due to unique regulatory requirements and market size. |
| 12 | ROE | Rest of Europe — EU countries not covered by specific language-based regions (French, German, Italian, Spanish, North Europe). |
| 17 | UK | United Kingdom — FCA-regulated market. One of the largest customer segments. Separated from Europe due to distinct regulation and market significance. |
| 99 | eToro | Internal/corporate marker — used for company accounts, test environments, or aggregation of company-level metrics. Not a real geographic region. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MarketingRegionID | tinyint | NO | - | CODE-BACKED | Marketing region identifier (0-99). Referenced by Dictionary.Country.MarketingRegionID. Values: 0=Unknown, 1=Africa, 2=Arabic, 3=Australia, 4=Canada, 5=China, 6=French, 7=German, 8=Israel, 9=Italian, 10=North Europe, 11=Other Asia, 12=ROE, 13=ROW, 14=Russian, 15=South & Central America, 16=Spain, 17=UK, 18=USA, 20=Eastern Europe, 99=eToro. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Marketing region name. Unique constraint prevents duplicates. Used in BI dashboards, marketing reports, and sales territory assignments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Country | MarketingRegionID | Implicit | Each country is assigned to a marketing region for geographic segmentation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.MarketingRegion (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK-like reference via MarketingRegionID |
| BI/Reporting subsystem | Various | Regional KPI aggregation and dashboards |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DMR | CLUSTERED PK | MarketingRegionID | - | - | Active |
| UK_DMR_Name | NONCLUSTERED UNIQUE | Name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DMR | PRIMARY KEY | Unique marketing region, DICTIONARY filegroup |
| UK_DMR_Name | UNIQUE | Ensures no duplicate region names |

---

## 8. Sample Queries

### 8.1 List all marketing regions
```sql
SELECT  MarketingRegionID,
        Name
FROM    Dictionary.MarketingRegion WITH (NOLOCK)
ORDER BY MarketingRegionID;
```

### 8.2 Count countries per marketing region
```sql
SELECT  mr.Name             AS MarketingRegion,
        COUNT(*)            AS CountryCount
FROM    Dictionary.Country c WITH (NOLOCK)
JOIN    Dictionary.MarketingRegion mr WITH (NOLOCK)
        ON c.MarketingRegionID = mr.MarketingRegionID
GROUP BY mr.Name
ORDER BY COUNT(*) DESC;
```

### 8.3 List countries in a specific marketing region
```sql
SELECT  c.Name              AS Country,
        c.TwoLetterIsoCode,
        mr.Name             AS MarketingRegion
FROM    Dictionary.Country c WITH (NOLOCK)
JOIN    Dictionary.MarketingRegion mr WITH (NOLOCK)
        ON c.MarketingRegionID = mr.MarketingRegionID
WHERE   mr.Name = 'UK'
ORDER BY c.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MarketingRegion | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MarketingRegion.sql*
