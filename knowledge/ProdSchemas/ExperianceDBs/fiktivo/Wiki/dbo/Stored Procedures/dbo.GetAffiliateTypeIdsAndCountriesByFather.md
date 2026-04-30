# dbo.GetAffiliateTypeIdsAndCountriesByFather

> Returns all child affiliate type IDs and their associated CPA-eligible country IDs for plans that share a given parent (father) affiliate type.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | FatherAffiliateTypeID (parent plan ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports the CPA per-country configuration workflow in the affiliate admin portal. Affiliate commission plans (AffiliateTypes) can be organized into families where a parent plan (FatherAffiliateTypeID) has multiple child variants, each targeting different countries. This SP returns the full list of (AffiliateTypeID, CountryID) pairs for all child plans under the given parent, enabling the portal to display or validate which countries are covered by the plan family. It is used when setting up or reviewing CPA per-country rate structures. Created by Gonen Frim (Nov 2015).

---

## 2. Business Logic

- Joins tblaff_CPACountriesToAffiliateTypeID (country-to-plan mapping) to tblaff_AffiliateTypes on AffiliateTypeID.
- Filters to plans where FatherAffiliateTypeID = @FatherAffiliateTypeID.
- Both tables use NOLOCK hints.
- Returns AffiliateTypeID and CountryID for each country-plan pair.
- No NOCOUNT or error handling.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @FatherAffiliateTypeID | INT | IN | (required) | High | Parent plan ID whose child plan-country pairs are returned |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | dbo.tblaff_CPACountriesToAffiliateTypeID | Read | Country-to-plan CPA mapping rows |
| JOIN | dbo.tblaff_AffiliateTypes | Read | Filters plans by FatherAffiliateTypeID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateTypeIdsAndCountriesByFather
  ├── dbo.tblaff_CPACountriesToAffiliateTypeID  (READ)
  └── dbo.tblaff_AffiliateTypes                 (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_CPACountriesToAffiliateTypeID | Table | Maps countries to affiliate type plans for CPA eligibility |
| dbo.tblaff_AffiliateTypes | Table | Provides the FatherAffiliateTypeID filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Get all child plans and countries for parent plan 5
EXEC dbo.GetAffiliateTypeIdsAndCountriesByFather @FatherAffiliateTypeID = 5;

-- Verify country coverage for a specific plan family
DECLARE @Coverage TABLE (AffiliateTypeID INT, CountryID INT);
INSERT INTO @Coverage
EXEC dbo.GetAffiliateTypeIdsAndCountriesByFather @FatherAffiliateTypeID = 10;
SELECT AffiliateTypeID, COUNT(*) AS CountryCoverage
FROM @Coverage GROUP BY AffiliateTypeID;

-- Find all child plans under parent 1
EXEC dbo.GetAffiliateTypeIdsAndCountriesByFather @FatherAffiliateTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.
*(Author note: Gonen Frim, 30/11/2015.)*

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAffiliateTypeIdsAndCountriesByFather | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateTypeIdsAndCountriesByFather.sql*
