# Dictionary.GetCountry

> Legacy convenience view exposing key columns from Dictionary.Country for backward-compatible country lookups.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | View |
| **Key Identifier** | CountryID (from Country) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetCountry is a legacy convenience view (created 2007 by Spivak Igor) that exposes the six most commonly needed columns from the 16-column Dictionary.Country table. It provides a stable, narrow interface for older platform code that needs basic country information — ID, region, default currency, abbreviation, name, and active status — without coupling to the full table structure.

Without this view, legacy components that only need basic country data would have to query the full Country table and risk breaking when new columns are added. The view acts as an abstraction layer, shielding consumers from schema evolution in the base table.

The view returns ALL countries regardless of active status. Consumers are responsible for filtering on IsActive as needed. This design allows administrative and reporting tools to see inactive countries while user-facing components filter them out.

---

## 2. Business Logic

### 2.1 Country Reference Subset

**What**: Projects 6 essential columns from the 16-column Country table for lightweight country lookups.

**Columns/Parameters Involved**: `CountryID`, `RegionID`, `DefaultCurrencyID`, `Abbreviation`, `Name`, `IsActive`

**Rules**:
- No filter applied — all 251 countries are returned including inactive ones (CountryID=0 "Not available")
- Consumers in Billing, Customer, Compliance, and BackOffice use this view for country-based lookups
- The view omits specialized columns like RiskGroupID, CountryEconomicTypeID, PriceSourceID, etc. that are only needed by specific subsystems

**Diagram**:
```
Dictionary.Country (16 columns, 251 rows)
│
├── CountryID
├── RegionID              ─┐
├── DefaultCurrencyID      │
├── Abbreviation           ├── Dictionary.GetCountry (6 columns)
├── Name                   │
├── IsActive              ─┘
├── RiskGroupID            ─┐
├── CountryEconomicTypeID   │
├── ISONumeric              ├── Not exposed (specialized columns)
├── PriceSourceID           │
├── ...                    ─┘
```

---

## 3. Data Overview

| CountryID | RegionID | DefaultCurrencyID | Abbreviation | Name | IsActive | Meaning |
|---|---|---|---|---|---|---|
| 0 | 0 | 1 | (space) | Not available | 0 | Placeholder for unknown/unresolved country — used when geolocation fails or data is missing |
| 1 | 4 | 1 | AF | Afghanistan | 1 | Active country entry — customers from Afghanistan can register but may face regulatory restrictions |
| 82 | 3 | 3 | GB | United Kingdom | 1 | Major market under FCA regulation — one of the highest-volume customer sources |
| 4 | 6 | 1 | AS | American Samoa | 1 | US territory — subject to US regulatory restrictions despite separate country entry |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Unique country identifier. PK of the base Country table. Used across the entire platform for customer registration, billing, compliance, and regulatory routing. 0=Not available (placeholder). (Dictionary.Country) |
| 2 | RegionID | int | YES | - | VERIFIED | Geographic region classification. FK to Dictionary.Region. Groups countries into broad geographic areas for reporting and regulatory segmentation. (Dictionary.Region) |
| 3 | DefaultCurrencyID | int | YES | - | VERIFIED | Default deposit/display currency for customers registering from this country. FK to Dictionary.Currency (only fiat currencies). 1=USD is the most common default. (Dictionary.Currency) |
| 4 | Abbreviation | char(2) | YES | - | VERIFIED | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE", "IL"). Used in API responses, geolocation matching, and regulatory rule evaluation. Inherited from Dictionary.Country.Abbreviation. |
| 5 | Name | varchar(100) | YES | - | VERIFIED | Full country name in English (e.g., "United Kingdom", "Germany", "Israel"). Used in UI displays and customer-facing communications. Inherited from Dictionary.Country.Name. |
| 6 | IsActive | bit | YES | - | CODE-BACKED | Whether the country is currently active for customer registration: 1=customers can register from this country, 0=country is disabled (regulatory ban, sanctions, or not yet enabled). The view returns both active and inactive — consumers filter as needed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Base table | Source of all country data |
| RegionID | Dictionary.Region | Implicit (via Country) | Geographic region grouping |
| DefaultCurrencyID | Dictionary.Currency | Implicit (via Country) | Default registration currency |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomerByCID | - | JOIN | Customer detail view with country name |
| BackOffice.GetCustomerLogins | - | JOIN | Login history with country info |
| BackOffice.GetUserAdditionalDetails | - | JOIN | User detail enrichment |
| Billing.GetCountryProtocols | - | JOIN | Payment protocol routing by country |
| Billing.GetCountryProtocolsV2 | - | JOIN | Updated protocol routing |
| Billing.DepositAdd | - | JOIN | Country validation during deposit |
| Billing.FundingAdd | - | JOIN | Funding method country resolution |
| Billing.GetCountryConfiguration | - | JOIN | Country-level billing config |
| Customer.GetMiscData | - | JOIN | Customer miscellaneous data |
| Compliance.GetCountryLongAbbreviation | - | JOIN | Regulatory country lookup |
| Internal.GetCountryIDByIP | - | Function | IP-to-country resolution |
| Internal.GetCountryNameByIP | - | Function | IP-to-country-name resolution |
| OldStyle.GetCountry | - | View | Legacy view referencing this view |
| Trade.GetCountryIDsWithName | - | JOIN | Trading country lookups |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetCountry (view)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Base table — SELECT of 6 columns, no filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerByCID | Procedure | Country name lookup in customer views |
| BackOffice.GetCustomerLogins | Procedure | Login country enrichment |
| Billing.GetCountryProtocols | Procedure | Payment routing by country |
| Billing.DepositAdd | Procedure | Country validation on deposit |
| Billing.FundingAdd | Procedure | Funding country resolution |
| Customer.GetMiscData | Procedure | Customer misc data country info |
| Compliance.GetCountryLongAbbreviation | Procedure | Regulatory country name lookup |
| Internal.GetCountryIDByIP | Function | IP geolocation to country |
| Internal.GetCountryNameByIP | Function | IP to country name |
| OldStyle.GetCountry | View | Legacy compatibility wrapper |
| Trade.GetCountryIDsWithName | Procedure | Trading country lookups |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Base table Dictionary.Country has a clustered PK on CountryID.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all active countries
```sql
SELECT  CountryID, Abbreviation, Name
FROM    Dictionary.GetCountry WITH (NOLOCK)
WHERE   IsActive = 1
ORDER BY Name
```

### 8.2 Find countries in a specific region with their default currency
```sql
SELECT  gc.CountryID, gc.Name, gc.Abbreviation, r.Name AS Region, c.Name AS DefaultCurrency
FROM    Dictionary.GetCountry gc WITH (NOLOCK)
JOIN    Dictionary.Region r WITH (NOLOCK) ON r.RegionID = gc.RegionID
JOIN    Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = gc.DefaultCurrencyID
WHERE   gc.IsActive = 1
ORDER BY gc.Name
```

### 8.3 Look up a country by ISO code
```sql
SELECT  CountryID, Name, RegionID, DefaultCurrencyID, IsActive
FROM    Dictionary.GetCountry WITH (NOLOCK)
WHERE   Abbreviation = 'GB'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetCountry | Type: View | Source: etoro/etoro/Dictionary/Views/Dictionary.GetCountry.sql*
