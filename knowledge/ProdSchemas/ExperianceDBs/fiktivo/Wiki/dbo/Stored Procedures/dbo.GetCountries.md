# dbo.GetCountries

> Returns all countries that have a non-blank ISO abbreviation code, including affiliate group, marketing region, and affiliate type assignments.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Ran Ovadia |
| **Created** | 2019-12-09 |

---

## 1. Business Meaning

The affiliate platform uses countries as a key dimension for commission routing, affiliate type assignment, and marketing region segmentation. This procedure provides the canonical country reference list used throughout the platform: it returns all countries that have been properly configured with a valid ISO abbreviation code (excluding placeholder or incomplete rows).

Callers use this list to populate country dropdowns in the affiliate sign-up form, to resolve commission plan tiers by country, and to validate incoming country codes from external sources. The AffiliateTypeID column added by Ran Ovadia in December 2019 allows the platform to map countries directly to affiliate types, supporting per-country programme rules.

---

## 2. Business Logic

### 2.1 Valid Country Filter

**What**: Excludes countries with NULL or blank Abbreviation codes.

**Columns/Parameters Involved**: `Abbreviation`

**Rules**:
- Abbreviation IS NOT NULL: rows with no ISO code are excluded
- RTRIM(Abbreviation) != '': rows containing only whitespace are also excluded
- This ensures only properly configured country records are exposed to the platform

### 2.2 Country Segmentation Attributes

**What**: Returns group, region, and affiliate-type assignments per country.

**Columns/Parameters Involved**: `AffiliatesGroupsID`, `MarketingRegionID`, `AffiliateTypeID`

**Rules**:
- AffiliatesGroupsID links the country to an affiliate group tier for commission purposes
- MarketingRegionID groups countries into geographic marketing regions
- AffiliateTypeID (added December 2019) maps the country to a default affiliate type, enabling per-country programme assignment

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure accepts no parameters.

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| - | (none) | - | - | - | No parameters; returns all valid countries. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Country | SELECT | Sole source; filtered to rows with non-blank Abbreviation |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| CountryID | tblaff_Country | Primary key |
| Code | tblaff_Country (Abbreviation aliased) | ISO country abbreviation code |
| Name | tblaff_Country | Full country name |
| AffiliatesGroupsID | tblaff_Country | Affiliate group assignment for this country |
| MarketingRegionID | tblaff_Country | Marketing region grouping |
| AffiliateTypeID | tblaff_Country | Default affiliate type for this country |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCountries (stored procedure)
+-- dbo.tblaff_Country (table) [SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Country | Table | Sole data source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate registration form | Application | Calls this procedure to populate the country selection dropdown |
| Commission routing logic | Application | Uses country-to-affiliate-type and country-to-group mapping |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON (via Set NoCount On) suppresses rowcount messages
- WITH (NOLOCK) applied; suitable for a stable reference table
- Abbreviation column is aliased as Code in the result set for consistency with the rest of the platform
- AffiliateTypeID was added in December 2019 by Ran Ovadia

---

## 8. Sample Queries

### 8.1 Return all valid countries

```sql
EXEC dbo.GetCountries;
```

### 8.2 Find countries assigned to a specific affiliate type

```sql
SELECT CountryID, Abbreviation AS Code, [Name], AffiliateTypeID
FROM dbo.tblaff_Country WITH (NOLOCK)
WHERE AffiliateTypeID = 2
  AND Abbreviation IS NOT NULL
  AND RTRIM(Abbreviation) <> '';
```

### 8.3 Count countries per marketing region

```sql
SELECT MarketingRegionID, COUNT(*) AS CountryCount
FROM dbo.tblaff_Country WITH (NOLOCK)
WHERE Abbreviation IS NOT NULL
  AND RTRIM(Abbreviation) <> ''
GROUP BY MarketingRegionID
ORDER BY MarketingRegionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetCountries | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetCountries.sql*
