# dbo.UserAPI_IsoCurrencyInfo

> Staging table holding country-level configuration data imported from the UserAPI, including currency defaults, risk classifications, and regional settings.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | CountryID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

UserAPI_IsoCurrencyInfo is a staging table that caches country-level configuration from the UserAPI system. Despite its name suggesting currency information, it primarily stores country attributes: default currency, region, language, risk classification, and various eligibility flags. This data supports the fiat platform's country-based eligibility rules and regulatory compliance.

This table exists to provide the fiat DWH with UserAPI country configuration data for eligibility processing and reporting. The name "IsoCurrencyInfo" is a misnomer inherited from the source system - the table is really a country configuration table that includes currency as one of many attributes.

Data is populated via ETL from the UserAPI and refreshed periodically.

---

## 2. Business Logic

### 2.1 Country Risk and Eligibility Classification

**What**: Each country has risk, eligibility, and settlement restriction flags that affect fiat operations.

**Columns/Parameters Involved**: `IsHighRiskCountry`, `IsEligibleForRAFBonusCountry`, `IsSettlementRestricted`, `RiskGroupID`

**Rules**:
- IsHighRiskCountry flags countries with elevated compliance requirements
- IsSettlementRestricted determines if settlement operations are limited for the country
- These flags influence eligibility rule evaluation for sub-program assignment

---

## 3. Data Overview

N/A - staging table with country configuration data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Internal country identifier from the UserAPI system. Primary key. |
| 2 | RegionID | int | NO | - | NAME-INFERRED | Geographic region classification for the country. Used for regional grouping in reports. |
| 3 | DefaultCurrencyID | int | NO | - | NAME-INFERRED | Default currency assigned to accounts in this country. References the UserAPI currency system. |
| 4 | LanguageID | int | NO | - | NAME-INFERRED | Default language for customer communications in this country. |
| 5 | Abbreviation | char(2) | NO | - | CODE-BACKED | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). |
| 6 | LongAbbreviation | char(3) | NO | - | CODE-BACKED | ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR", "DEU"). |
| 7 | Name | varchar(50) | NO | - | CODE-BACKED | Country name in English. |
| 8 | PhonePrefix | varchar(3) | YES | - | CODE-BACKED | International dialing prefix for the country (e.g., "1" for US, "44" for UK). |
| 9 | IsActive | bit | NO | - | CODE-BACKED | Whether the country is currently active in the platform. 0=inactive (no new accounts), 1=active. |
| 10 | IsHighRiskCountry | tinyint | YES | - | CODE-BACKED | Risk classification flag. Non-null values indicate elevated risk requiring additional compliance checks. |
| 11 | IsEligibleForRAFBonusCountry | bit | NO | - | NAME-INFERRED | Whether customers in this country are eligible for Refer-a-Friend bonus programs. |
| 12 | MarketingRegionID | tinyint | NO | - | NAME-INFERRED | Marketing region grouping for the country. Used for marketing campaign targeting. |
| 13 | RiskGroupID | int | YES | - | NAME-INFERRED | Risk group classification for the country. Used in conjunction with IsHighRiskCountry for tiered risk assessment. |
| 14 | EconomicTypeID | int | NO | - | NAME-INFERRED | Economic classification of the country (e.g., developed, emerging market). |
| 15 | IsSettlementRestricted | bit | NO | - | CODE-BACKED | Whether settlement operations are restricted for this country. 1=restricted (limits on withdrawals/transfers). |
| 16 | IsoCode | char(3) | YES | - | CODE-BACKED | ISO 4217 default currency code for the country (e.g., "USD", "GBP"). Nullable for countries without a clear default. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No stored procedures in the dbo schema reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCNR | CLUSTERED | CountryID ASC | - | - | Active (FILLFACTOR=90) |

### 7.2 Constraints

None (beyond PK).

---

## 8. Sample Queries

### 8.1 Find active countries by region
```sql
SELECT CountryID, Name, Abbreviation, IsoCode, RegionID
FROM dbo.UserAPI_IsoCurrencyInfo WITH (NOLOCK)
WHERE IsActive = 1 ORDER BY RegionID, Name;
```

### 8.2 Find high-risk countries
```sql
SELECT CountryID, Name, Abbreviation, IsHighRiskCountry, RiskGroupID
FROM dbo.UserAPI_IsoCurrencyInfo WITH (NOLOCK)
WHERE IsHighRiskCountry IS NOT NULL AND IsHighRiskCountry > 0;
```

### 8.3 Find settlement-restricted countries
```sql
SELECT CountryID, Name, Abbreviation, IsSettlementRestricted
FROM dbo.UserAPI_IsoCurrencyInfo WITH (NOLOCK)
WHERE IsSettlementRestricted = 1 ORDER BY Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.6/10 (Elements: 7.5/10, Logic: 7/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.UserAPI_IsoCurrencyInfo | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.UserAPI_IsoCurrencyInfo.sql*
