# Dictionary.Country

> Master lookup table of all countries recognized by the eToro platform, used across registration, regulation assignment, KYC, and geo-targeting.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CountryID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.Country is the master list of 251 countries recognized by the eToro platform. It is one of the most widely referenced lookup tables in UserApiDB, used for user registration (country of residence), regulatory assignment (which regulation applies based on country), KYC requirements (which documents are needed), IP-based geo-location, and state/region hierarchies.

This table is foundational to the platform's multi-regulatory architecture. A user's country determines their regulatory jurisdiction (CySEC, FCA, ASIC, etc.), which in turn controls available products, leverage limits, KYC requirements, and compliance workflows. Without this table, the platform could not route users to the correct regulatory framework.

Country is set during user registration based on self-declaration and IP-based detection. It drives cascading lookups: Country -> Regulation (via configuration tables), Country -> State (Dictionary.State), Country -> Region (Dictionary.RegionByIP), Country -> KYC requirements (via ExtendedUserField configurations).

---

## 2. Business Logic

### 2.1 Country-Driven Regulatory Routing

**What**: Country determines the regulatory jurisdiction and all downstream compliance requirements.

**Columns/Parameters Involved**: `CountryID`, `Name`

**Rules**:
- Each country maps to exactly one primary regulation (e.g., UK -> FCA, Australia -> ASIC, EU countries -> CySEC)
- Country determines KYC field requirements (which ExtendedUserFields are mandatory)
- Country determines available payment methods and currency options
- Some countries are blocked entirely from registration

---

## 3. Data Overview

| CountryID | Name | Meaning |
|---|---|---|
| 1 | United States | US-regulated users under FinCEN/FINRA - separate product set, crypto-only initially |
| 44 | United Kingdom | FCA-regulated users - UK-specific compliance and negative balance protection |
| 49 | Germany | CySEC-regulated (via eToro EU) - MiFID II categorization applies |
| 61 | Australia | ASIC-regulated users - ASIC classification (Retail/Sophisticated/Wholesale) |
| 972 | Israel | eToro's home market - CySEC regulation typically applies |

*5 of 251 rows shown - selected to represent major regulatory jurisdictions.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Primary key. Country identifier, typically based on international dialing codes (e.g., 1=US, 44=UK, 61=Australia). Referenced by CountryIP, RegionByIP, State, SubRegion, and numerous Customer schema tables. See [Country](_glossary.md#country). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Full country name in English. Used in UI display, reports, and compliance documents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.CountryIP | CountryID | Implicit FK | Maps IP ranges to countries |
| Dictionary.RegionByIP | CountryID | Implicit FK | Regions belong to countries |
| Dictionary.RegionByIP_ISOCode | CountryID | Implicit FK | ISO region codes linked to countries |
| Dictionary.State | CountryID | Explicit FK | States/provinces within a country |
| Dictionary.SubRegion | CountryID | Explicit FK | Sub-regions within a country |
| Customer.InsertRealCustomer | CountryID | Lookup | Sets user's country during registration |
| Customer.InsertNewCustomer | CountryID | Lookup | Sets user's country during registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryIP | Table | References CountryID |
| Dictionary.RegionByIP | Table | References CountryID |
| Dictionary.RegionByIP_ISOCode | Table | References CountryID |
| Dictionary.State | Table | FK to CountryID |
| Dictionary.SubRegion | Table | FK to CountryID |
| Customer.InsertRealCustomer | Stored Procedure | Reads country data |
| Customer.InsertNewCustomer | Stored Procedure | Reads country data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Country | CLUSTERED PK | CountryID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all countries
```sql
SELECT CountryID, Name
FROM Dictionary.Country WITH (NOLOCK)
ORDER BY Name
```

### 8.2 Find a user's country
```sql
SELECT u.CustomerID, c.Name AS Country
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON u.CountryID = c.CountryID
WHERE u.CustomerID = @CustomerID
```

### 8.3 User count by country (top 10)
```sql
SELECT TOP 10 c.Name, COUNT(*) AS UserCount
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON u.CountryID = c.CountryID
GROUP BY c.Name
ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Country | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.Country.sql*
