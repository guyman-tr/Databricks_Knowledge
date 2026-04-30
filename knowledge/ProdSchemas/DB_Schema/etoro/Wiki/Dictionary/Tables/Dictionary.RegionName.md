# Dictionary.RegionName

> Reference table mapping country subdivisions (states/provinces/territories) to their full names — covering Australia, Canada, and other countries with regulatory region requirements. Page-compressed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Composite PK (CountryID, ShortName) |
| **Partition** | PRIMARY filegroup (PAGE compressed) |
| **Indexes** | 1 active (PK clustered, page-compressed) |

---

## 1. Business Meaning

Dictionary.RegionName provides human-readable names for country subdivisions identified by their short codes (e.g., "NSW" → "New South Wales", "QLD" → "Queensland"). This enables the platform to display proper region names for regulatory compliance, registration forms, and reporting.

The table is used by BackOffice.GetRegistrationReport and referenced by the StaticResourcesAPI for populating region dropdowns. Also used in regulatory views (dbo.V_Regulation_JunkNoga240325).

---

## 2. Business Logic

### 2.1 Region Code Resolution

**What**: Each row maps a country-specific short code to a full region name.

**Columns/Parameters Involved**: `CountryID`, `ShortName`, `Name`

**Rules**:
- Composite PK on (CountryID, ShortName) ensures uniqueness per country.
- Short codes are country-specific: "NSW" means New South Wales in Australia (12) but would mean something different in another country.
- Covers all major subdivisions for countries where region-level regulatory data is required.
- Example: Australia (12) has 8 entries (ACT, NSW, NT, QLD, SA, TAS, VIC, WA); Canada (38) has provinces (AB, BC, etc.).
- Page-compressed for storage efficiency.

---

## 3. Data Overview

| CountryID | ShortName | Name | Meaning |
|---|---|---|---|
| 12 | ACT | Australian Capital Territory | Canberra region, Australia |
| 12 | NSW | New South Wales | Largest state by population, Australia |
| 12 | QLD | Queensland | Northeastern state, Australia |
| 38 | AB | Alberta | Western province, Canada |
| 38 | BC | British Columbia | Pacific coast province, Canada |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Part of composite PK. References Dictionary.Country (implicit). Identifies which country this region belongs to. |
| 2 | ShortName | varchar(100) | NO | - | VERIFIED | Part of composite PK. ISO or country-specific short code for the region (e.g., "NSW", "AB", "CA"). |
| 3 | Name | varchar(100) | YES | - | VERIFIED | Full human-readable name of the region (e.g., "New South Wales", "Alberta"). Displayed in registration forms and reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | Relationship Type | Description |
|-------------------|---------|-------------------|-------------|
| Dictionary.Country | CountryID | Implicit | Parent country |

### 5.2 Referenced By (other objects point to this)

No direct FK consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object references Dictionary.Country implicitly.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Implicit — parent country |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetRegistrationReport | Stored Procedure | Reader — region names in registration reports |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_RegionName | CLUSTERED PK | CountryID ASC, ShortName ASC | - | - | Active (FF=90, PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_RegionName | PRIMARY KEY | Unique country+region code combination |

---

## 8. Sample Queries

### 8.1 List regions for a specific country
```sql
SELECT  ShortName,
        Name
FROM    [Dictionary].[RegionName] WITH (NOLOCK)
WHERE   CountryID = 12
ORDER BY ShortName;
```

### 8.2 Count regions per country
```sql
SELECT  c.Name AS CountryName,
        COUNT(*) AS RegionCount
FROM    [Dictionary].[RegionName] rn WITH (NOLOCK)
JOIN    [Dictionary].[Country] c WITH (NOLOCK) ON rn.CountryID = c.CountryID
GROUP BY c.Name
ORDER BY RegionCount DESC;
```

### 8.3 Resolve a region short code
```sql
SELECT  Name
FROM    [Dictionary].[RegionName] WITH (NOLOCK)
WHERE   CountryID = 38 AND ShortName = 'BC';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RegionName | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RegionName.sql*
