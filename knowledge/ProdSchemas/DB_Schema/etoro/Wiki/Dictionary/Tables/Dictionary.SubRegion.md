# Dictionary.SubRegion

> Maps provinces/sub-regions within countries to their parent region for granular geographic classification of customers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SubRegionID (int, IDENTITY, PK) |
| **Row Count** | 107 |
| **Indexes** | 2 (clustered PK + unique nonclustered) |
| **Foreign Keys** | 2 (Country, RegionByIP) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.SubRegion is a geographic lookup table that maps provinces or sub-regions within a country to their parent region. Currently populated exclusively with Italian provinces (107 rows), it provides granular geographic classification below the country/region level.

### Why It Exists
For regulatory compliance (particularly Italian CONSOB requirements) and customer demographic accuracy, the platform needs to classify users at the province level, not just by country or IP-derived region. This table maps each province abbreviation (e.g., "MI" for Milan) to both the country (Italy) and the broader IP-based region, enabling precise address classification during registration and profile updates.

### How It Works
The `SubRegionID` is stored in `Customer.Address`, `Customer.CustomerStatic`, and `History.Customer` tables. During user registration and address updates, procedures like `Customer.UpdateContactUserInfo` and `Customer.DemographyEdit` write the sub-region ID. The unique index on `(CountryID, RegionID, ShortName)` ensures no duplicate province entries per country-region combination.

---

## 2. Business Logic

### Geographic Hierarchy
```
Dictionary.Country (CountryID)
  └── Dictionary.RegionByIP (RegionByIP_ID)
        └── Dictionary.SubRegion (SubRegionID)
              ├── ShortName: Province code (e.g., "MI")
              └── Name: Province name (e.g., "Milan")
```

### Current Coverage
All 107 rows are Italian provinces (CountryID=102). Italian provinces are mapped to ~18 distinct RegionByIP regions, providing complete coverage of Italy's administrative divisions.

### Sample Values (5 of 107)

| SubRegionID | CountryID | RegionID | ShortName | Name |
|-------------|-----------|----------|-----------|------|
| 1 | 102 (Italy) | 1421 | AG | Agrigento |
| 6 | 102 (Italy) | 2885 | MI | Milan |
| 7 | 102 (Italy) | 3624 | RM | Rome |
| 14 | 102 (Italy) | 3934 | FI | Florence |
| 105 | 102 (Italy) | 924 | TO | Torino |

---

## 3. Data Overview

| SubRegionID | ShortName | Name | Region (by ID) | Scenario |
|-------------|-----------|------|----------------|----------|
| 6 | MI | Milan | 2885 (Lombardy) | Italian user from Milan registers and selects province |
| 7 | RM | Rome | 3624 (Lazio) | Customer address shows province of Rome |
| 14 | FI | Florence | 3934 (Tuscany) | BackOffice views Florence-based customer demographics |
| 94 | TS | Trieste | 1613 (Friuli) | Customer updates address to Trieste province |
| 105 | TO | Torino | 924 (Piedmont) | Registration flow captures Torino sub-region |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SubRegionID | int | NO | IDENTITY(1,1) | HIGH | Auto-incrementing primary key identifying the sub-region/province. Referenced by Customer.Address, Customer.CustomerStatic, History.Customer. |
| 2 | CountryID | int | NO | — | HIGH | FK to `Dictionary.Country.CountryID`. Currently all rows = 102 (Italy). Determines which country this sub-region belongs to. |
| 3 | RegionID | int | NO | — | HIGH | FK to `Dictionary.RegionByIP.RegionByIP_ID`. Maps province to its parent IP-based region. Multiple provinces share the same region (e.g., all Sicilian provinces → RegionID 1421). |
| 4 | ShortName | nvarchar(100) | NO | — | HIGH | Province abbreviation code (e.g., "MI" for Milan, "RM" for Rome). Part of unique index with CountryID and RegionID. Standard Italian province codes. |
| 5 | Name | nvarchar(255) | YES | — | HIGH | Full province name (e.g., "Milan", "Rome", "Florence"). Nullable but populated for all current rows. Unicode-enabled for international names. |

---

## 5. Relationships

### Depends On (Explicit FKs)

| Referenced Table | FK Name | Column | Referenced Column |
|-----------------|---------|--------|-------------------|
| Dictionary.Country | FK_DICT_Country | CountryID | CountryID |
| Dictionary.RegionByIP | FK_DICT_Region | RegionID | RegionByIP_ID |

### Referenced By (Implicit)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| Customer.Address | SubRegionID | Implicit FK | Column in address table, written by update procedures |
| Customer.CustomerStatic | SubRegionID | Implicit FK | Customer profile static data |
| History.Customer | SubRegionID | Implicit FK | Historical customer snapshots |

### View Consumers

| View | Purpose |
|------|---------|
| Customer.Customer | Main customer view exposing SubRegionID |
| Customer.CustomerSafty | Schema-bound customer view with SubRegionID |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Customer.UpdateContactUserInfo | UPDATE | Updates customer sub-region during profile edit |
| Customer.UpdateContactUserInfoRemote | UPDATE | Remote version of profile update |
| Customer.PostUpdateContactUserInfo | UPDATE | Post-processing after contact info update |
| Customer.DemographyEdit | UPDATE | Demographics editing flow |
| Customer.P_UpdateCustomer | UPDATE | General customer update |
| Internal.FixRegistrationAsyncFailedSteps | INSERT | Fixes failed registration steps including sub-region |

---

## 6. Dependencies

### Depends On
- `Dictionary.Country` — FK on CountryID (currently all Italy = 102)
- `Dictionary.RegionByIP` — FK on RegionID (parent region grouping)

### Depended On By
- `Customer.Address` — stores SubRegionID per customer address
- `Customer.CustomerStatic` — stores SubRegionID in static customer profile
- `History.Customer` — historical customer records
- 6+ procedures for customer registration and profile updates

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_Dictionary_SubRegion | CLUSTERED PK | SubRegionID ASC | FILLFACTOR 90 |
| IX_SubRegion | UNIQUE NONCLUSTERED | CountryID ASC, RegionID ASC, ShortName ASC | FILLFACTOR 95 — prevents duplicate province codes per country-region |

| Property | Value |
|----------|-------|
| Filegroup | DICTIONARY |
| Identity | SubRegionID IDENTITY(1,1) |
| Foreign Keys | FK_DICT_Country → Dictionary.Country, FK_DICT_Region → Dictionary.RegionByIP |

---

## 8. Sample Queries

```sql
-- Get all sub-regions with country and region names
SELECT  sr.SubRegionID,
        c.CountryName,
        sr.ShortName AS ProvinceCode,
        sr.Name AS ProvinceName
FROM    Dictionary.SubRegion sr WITH (NOLOCK)
JOIN    Dictionary.Country c WITH (NOLOCK)
        ON sr.CountryID = c.CountryID
ORDER BY sr.ShortName;

-- Count customers by Italian province
SELECT  sr.ShortName AS Province,
        sr.Name AS ProvinceName,
        COUNT(*) AS CustomerCount
FROM    Customer.Address a WITH (NOLOCK)
JOIN    Dictionary.SubRegion sr WITH (NOLOCK)
        ON a.SubRegionID = sr.SubRegionID
GROUP BY sr.ShortName, sr.Name
ORDER BY CustomerCount DESC;

-- Find provinces in a specific region
SELECT  sr.ShortName,
        sr.Name
FROM    Dictionary.SubRegion sr WITH (NOLOCK)
WHERE   sr.RegionID = 2885
ORDER BY sr.Name;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `SubRegion`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.SubRegion | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.SubRegion.sql*
