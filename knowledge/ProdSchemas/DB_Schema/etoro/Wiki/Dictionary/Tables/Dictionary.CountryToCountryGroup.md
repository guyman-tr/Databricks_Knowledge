# Dictionary.CountryToCountryGroup

> Many-to-many mapping table that assigns countries to named country groups used for regulatory gating, feature eligibility, risk classification, and marketing segmentation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CountryGroupID + CountryID (composite PK) |
| **Partition** | No — stored on DICTIONARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table implements a many-to-many relationship between countries and country groups. A single country can belong to multiple groups simultaneously (e.g., France belongs to ESMA_Countries, European Union, French, Other EU, and ROW), and each group contains multiple countries. The groups represent regulatory jurisdictions, geopolitical territories, language regions, risk tiers, feature rollout cohorts, and marketing segments.

Without this table, the platform would have no way to apply group-based rules to countries. Regulatory restrictions (e.g., CFD restrictions for CfdRestrictedCountries), US territory detection (US_Territories group 4), crypto wallet access gating (ERC20AllowedCountries), interest eligibility (SilverClubCountriesNotEligibleForInterest), and fee phase rollouts (TicketFeesPhase2/3) all depend on country group membership defined here.

Data is maintained by operations/compliance teams through BackOffice tools. The table is read by trading functions (`Trade.IsUsUser`), BSL equity protection views (`Trade.BslView`), dividend snapshot procedures, SettingsDB resolvers (guru status, geographic registration, promotions), and SSRS reporting. Replication to SettingsDB and tradonomi databases is handled via merge replication stored procedures.

---

## 2. Business Logic

### 2.1 Multi-Group Country Membership

**What**: Countries belong to multiple overlapping groups serving different business purposes.

**Columns/Parameters Involved**: `CountryGroupID`, `CountryID`

**Rules**:
- A country can appear in many groups — France (ID 74) belongs to groups 1, 10, 14, 17, 18 simultaneously
- Groups are NOT mutually exclusive — they serve different dimensions (regulatory, geographic, feature, risk)
- Group 17 (ROW = Rest of World) is the largest with 101 countries, acting as a catch-all

**Diagram**:
```
Country (France, ID=74)
├── Group 1: ESMA_Countries (regulatory)
├── Group 10: European Union (political)
├── Group 14: French (language)
├── Group 17: ROW (catch-all)
└── Group 18: Other EU (marketing)
```

### 2.2 US Territory Detection Pattern

**What**: Group 4 (US_Territories) is used by trading logic to determine if a user is from a US territory, which triggers special regulatory handling.

**Columns/Parameters Involved**: `CountryGroupID` (= 4), `CountryID`

**Rules**:
- `Trade.IsUsUser(@CID)` checks if a customer's CountryID is in group 4 AND their regulation is US-based
- `Trade.GetUsTerritoriesCountryIds` returns all CountryIDs in group 4 for batch operations
- US territory membership affects BSL (Balance Stop Loss) calculations, dividend processing, and crypto eligibility

---

## 3. Data Overview

| CountryGroupID | CountryGroupName | CountryID | CountryName | Meaning |
|---|---|---|---|---|
| 1 | ESMA_Countries | 74 | France | ESMA regulatory scope — triggers EU leverage limits, negative balance protection, and marketing restrictions mandated by European Securities and Markets Authority |
| 4 | US_Territories | 237 | United States | US territory detection — triggers special regulatory handling including crypto restrictions, dividend withholding rules, and BSL equity protection exclusions |
| 22 | CfdRestrictedCountries | 13 | Austria | CFD trading restriction — countries where CFD products are restricted or require additional disclosure due to local regulations |
| 25 | SilverClubCountriesNotEligibleForInterest | 74 | France | Interest eligibility exclusion — 244 countries where Silver-tier eToro Club members do not receive interest on uninvested cash |
| 27 | ERC20AllowedCountries | 237 | United States | Crypto wallet feature gate — countries where users are allowed to transfer ERC-20 tokens to/from their eToro Money crypto wallet |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryGroupID | int | NO | - | VERIFIED | The country group this mapping belongs to. FK to Dictionary.CountryGroup. Key groups: 1=ESMA_Countries (34 countries), 4=US_Territories (7 countries), 10=European Union (28), 17=ROW (101), 22=CfdRestrictedCountries (28), 25=SilverClubCountriesNotEligibleForInterest (244), 27=ERC20AllowedCountries (79). See [Country Group](Dictionary.CountryGroup.md). |
| 2 | CountryID | int | NO | - | VERIFIED | The country assigned to this group. FK to Dictionary.Country. A country can appear in multiple groups simultaneously. See [Country](Dictionary.Country.md). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryGroupID | Dictionary.CountryGroup | FK | Links to the group definition containing the group name and purpose |
| CountryID | Dictionary.Country | FK | Links to the country being assigned to the group |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.IsUsUser | CountryGroupID | JOIN | Checks if a customer's country is in US_Territories (group 4) to determine US user status |
| Trade.GetUsTerritoriesCountryIds | CountryGroupID | JOIN | Returns all US territory country IDs for batch regulatory processing |
| Trade.BslView | CountryGroupID | JOIN | BSL equity protection view filters by country group for US territory exclusion |
| Trade.InsertBSLMessagesIntoQueue | CountryGroupID | JOIN | BSL message queue procedure uses country group for territory-based filtering |
| dbo.V_Country | CountryGroupID | JOIN | Country view enriches country data with group memberships |
| Trade.UsUsersCryptoStat | CountryGroupID | JOIN | Crypto statistics procedure filters by US territory group |
| Trade.SP_SavePositionsSnapshotForDividends | CountryGroupID | JOIN | Dividend snapshot procedure uses country groups for eligibility |
| SettingsDB.Customer.CountryGroupAndPlayerLevelResolver | CountryGroupID | JOIN | SettingsDB resolver for country-group-based settings |
| SettingsDB.Customer.GuruStatusResolver | CountryGroupID | JOIN | Popular Investor status resolver uses country groups for eligibility rules |
| SettingsDB.Wallet.PromotionEligibleResolver | CountryGroupID | JOIN | Promotion eligibility resolver checks country group membership |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CountryToCountryGroup (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryGroup | Table | FK target — provides group definitions |
| Dictionary.Country | Table | FK target — provides country definitions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.IsUsUser | Function | Reads — checks US territory group membership |
| Trade.GetUsTerritoriesCountryIds | Procedure | Reads — returns US territory country IDs |
| Trade.BslView | View | Reads — BSL equity protection filtering |
| Trade.InsertBSLMessagesIntoQueue | Procedure | Reads — BSL message filtering |
| dbo.V_Country | View | Reads — country enrichment |
| Trade.UsUsersCryptoStat | Procedure | Reads — crypto stat filtering |
| dbo.SSRS_LIST_AUTOMATION | Procedure | Reads — SSRS reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCountryToCountryGroup | CLUSTERED | CountryGroupID, CountryID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_DictionaryCountryGroup_DictionaryCountryToCountryGroup | FK | CountryGroupID → Dictionary.CountryGroup.CountryGroupID |
| FK_DictionaryCountry_DictionaryCountryToCountryGroup | FK | CountryID → Dictionary.Country.CountryID |

---

## 8. Sample Queries

### 8.1 List all countries in a specific group
```sql
SELECT  cg.CountryGroupName,
        c.Name AS CountryName,
        c.Abbreviation
FROM    Dictionary.CountryToCountryGroup ctg WITH (NOLOCK)
        JOIN Dictionary.CountryGroup cg WITH (NOLOCK) ON ctg.CountryGroupID = cg.CountryGroupID
        JOIN Dictionary.Country c WITH (NOLOCK) ON ctg.CountryID = c.CountryID
WHERE   cg.CountryGroupName = 'ESMA_Countries'
ORDER BY c.Name
```

### 8.2 Find all groups a specific country belongs to
```sql
SELECT  c.Name AS CountryName,
        cg.CountryGroupID,
        cg.CountryGroupName
FROM    Dictionary.CountryToCountryGroup ctg WITH (NOLOCK)
        JOIN Dictionary.CountryGroup cg WITH (NOLOCK) ON ctg.CountryGroupID = cg.CountryGroupID
        JOIN Dictionary.Country c WITH (NOLOCK) ON ctg.CountryID = c.CountryID
WHERE   c.Name = 'France'
ORDER BY cg.CountryGroupID
```

### 8.3 Count countries per group
```sql
SELECT  cg.CountryGroupID,
        cg.CountryGroupName,
        COUNT(*) AS CountryCount
FROM    Dictionary.CountryToCountryGroup ctg WITH (NOLOCK)
        JOIN Dictionary.CountryGroup cg WITH (NOLOCK) ON ctg.CountryGroupID = cg.CountryGroupID
GROUP BY cg.CountryGroupID, cg.CountryGroupName
ORDER BY CountryCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Compliance API - Regular Deployment Checklist](https://etoro.atlassian.net/wiki/spaces/COMP/pages/2030239765) | Confluence | Country group configurations are part of compliance deployment checklists |
| [ASIC Flow](https://etoro.atlassian.net/wiki/spaces/COMP/pages/1167458463) | Confluence | Country groups used in ASIC regulatory flow for Australian user classification |

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CountryToCountryGroup | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CountryToCountryGroup.sql*
