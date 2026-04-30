# dbo.GetCountryByCode

> Retrieves a single country record by its ISO abbreviation code using a case-insensitive match, returning segmentation attributes including affiliate type.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Ran Ovadia |
| **Created** | 2019-12-09 |

---

## 1. Business Meaning

Incoming data streams and API calls frequently supply country codes (e.g., "US", "us", "GB") as strings rather than integer IDs. This procedure maps an inbound country code to the full country record, including all segmentation attributes needed to route the affiliate to the correct group, region, and affiliate type.

Case-insensitive comparison (LOWER on both sides) ensures that codes submitted in mixed or lower case match correctly regardless of how they are stored in the database, avoiding incorrect "country not found" errors due to casing differences between client and database.

---

## 2. Business Logic

### 2.1 Case-Insensitive Code Lookup

**What**: Matches the supplied code against the Abbreviation column using LOWER() on both sides.

**Columns/Parameters Involved**: `@Code`, `Abbreviation`

**Rules**:
- LOWER(Abbreviation) = LOWER(@Code): the comparison is made case-insensitively; both values are lower-cased before comparison
- If no row matches, zero rows are returned (no error is raised)
- If multiple rows share the same abbreviation (data quality issue), multiple rows are returned; callers should expect at most one row
- The procedure returns the full set of segmentation columns, identical to dbo.GetCountries, making the result compatible with the same downstream processing

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @Code | IN | varchar(50) | (required) | The ISO country abbreviation code to look up. Matched case-insensitively against the Abbreviation column. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Country | SELECT | Filtered by case-insensitive abbreviation match |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| CountryID | tblaff_Country | Primary key |
| Code | tblaff_Country (Abbreviation aliased) | ISO abbreviation as stored |
| Name | tblaff_Country | Full country name |
| AffiliatesGroupsID | tblaff_Country | Affiliate group tier assignment |
| MarketingRegionID | tblaff_Country | Marketing region grouping |
| AffiliateTypeID | tblaff_Country | Default affiliate type for this country |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCountryByCode (stored procedure)
+-- dbo.tblaff_Country (table) [SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Country | Table | Sole data source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate registration / onboarding service | Application | Resolves a submitted country code to the full country record including affiliate type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON (via Set NoCount On) suppresses rowcount messages
- WITH (NOLOCK) applied; consistent with reference-table read pattern
- LOWER() applied to both the column and parameter prevents index seeks on Abbreviation; acceptable for a small reference table
- AffiliateTypeID was added by Ran Ovadia in December 2019, aligning with the same change in dbo.GetCountries

---

## 8. Sample Queries

### 8.1 Look up a country by its ISO code

```sql
EXEC dbo.GetCountryByCode @Code = 'US';
```

### 8.2 Test case-insensitive matching

```sql
EXEC dbo.GetCountryByCode @Code = 'gb';
EXEC dbo.GetCountryByCode @Code = 'GB';
-- Both should return the same row
```

### 8.3 Verify the affiliate type for a country code

```sql
SELECT AffiliateTypeID, Name
FROM dbo.tblaff_Country WITH (NOLOCK)
WHERE LOWER(Abbreviation) = LOWER('DE');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetCountryByCode | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetCountryByCode.sql*
