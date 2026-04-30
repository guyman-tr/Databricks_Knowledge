# Billing.GetHighRiskCountries

> Returns the full country record for all countries flagged as high-risk (IsHighRiskCountry=1) in Dictionary.Country - 14 countries requiring enhanced due diligence in the payment and compliance flows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns fixed set of 14 high-risk countries |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetHighRiskCountries` returns the complete country records for all countries designated as high-risk on the eToro platform. The set currently includes 14 countries: Albania, Cambodia, China, Cuba, Iran, Japan, Kuwait, Myanmar, Namibia, Nicaragua, North Korea, Palestinian Territory, Turkey, and Zimbabwe.

The procedure exists to give payment and compliance services a single call to retrieve the full high-risk country dataset. Rather than requiring consumers to know the `IsHighRiskCountry` column, they call this procedure to get all relevant country attributes - regulation, risk grouping, settlement restrictions, ISO codes - for high-risk country routing and compliance logic.

Data flows exclusively outward. The procedure has no known SQL-layer callers (not called from any other stored procedure), indicating it is consumed directly by application-layer services via EXECUTE permissions. The billing and compliance services use this list to trigger enhanced due diligence steps: additional document verification, manual review of first deposits, and reduced transaction monitoring thresholds.

---

## 2. Business Logic

### 2.1 High-Risk Country Filter for Enhanced Due Diligence

**What**: The 14 countries flagged with `IsHighRiskCountry=1` in Dictionary.Country trigger AML/KYC enhanced due diligence (EDD) flows for customers in those countries.

**Columns/Parameters Involved**: `IsHighRiskCountry`, `RiskGroupID`

**Rules**:
- `IsHighRiskCountry=1` flags countries where regulatory guidance or eToro risk policy requires enhanced screening
- `RiskGroupID` provides granular sub-classification for the high-risk set: 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit
- Triggers: additional document verification, manual review of first deposit, reduced transaction monitoring thresholds
- Source: Dictionary.Country.IsHighRiskCountry documentation (Section 2.1)

**Diagram**:
```
Dictionary.Country WHERE IsHighRiskCountry = 1
  -> 14 countries
  -> Used by compliance/payment services to:
       - Block or restrict deposits until EDD complete
       - Trigger manual review workflows
       - Apply lower transaction thresholds
```

### 2.2 Settlement Restriction Overlap

**What**: Some high-risk countries also have `IsSettlementRestricted=1`, meaning those customers face dual restrictions: both enhanced compliance scrutiny AND no access to real-asset positions.

**Columns/Parameters Involved**: `IsHighRiskCountry`, `IsSettlementRestricted`

**Rules**:
- Cuba, Iran, Myanmar, North Korea, Zimbabwe are both high-risk AND settlement-restricted
- Settlement restriction means users can only trade CFDs, cannot hold real stock/crypto positions
- This combination represents the highest-restriction tier: enhanced KYC AND no real assets
- Consumers of this procedure can use `IsSettlementRestricted` to identify this sub-tier without additional queries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has **no input parameters**. Output columns are all from `Dictionary.Country` (inherited from [Dictionary.Country documentation](../../Dictionary/Tables/Dictionary.Country.md)):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Primary key. Identifies the country. See Dictionary.Country for full country list. |
| 2 | RegionID | int | YES | - | CODE-BACKED | Geographic region grouping. FK to Dictionary.Region. Used for regional reporting and marketing segmentation. |
| 3 | DefaultCurrencyID | int | YES | - | CODE-BACKED | Default account currency for users from this country. FK to Dictionary.Currency. Determines base currency at registration. Cannot be changed post-registration. |
| 4 | LanguageID | int | YES | - | CODE-BACKED | Default UI language for users from this country. FK to Dictionary.Language. Can be changed by the user post-registration. |
| 5 | Abbreviation | varchar(2) | NO | - | CODE-BACKED | 2-letter ISO 3166-1 alpha-2 country code (e.g., US, GB, DE). Unique. Used in API responses and external integrations. |
| 6 | LongAbbreviation | varchar(3) | YES | - | CODE-BACKED | 3-letter ISO 3166-1 alpha-3 country code (e.g., USA, GBR, DEU). Used in regulatory reporting. |
| 7 | Name | nvarchar(100) | NO | - | CODE-BACKED | Full country name in English (e.g., "United States", "United Kingdom"). |
| 8 | PhonePrefix | varchar(10) | YES | - | CODE-BACKED | International dialing prefix (e.g., "+1", "+44"). Used for phone verification flows. |
| 9 | IsActive | bit | YES | - | CODE-BACKED | Whether this country is active on the platform. Inactive countries are blocked from registration. |
| 10 | IsHighRiskCountry | bit | YES | - | CODE-BACKED | Always 1 in this result set (the filter condition). Flags the country as high-risk requiring enhanced due diligence. All 14 returned rows have this = 1. |
| 11 | IsEligibleForRAFBonusCountry | bit | YES | - | CODE-BACKED | Whether users from this country can receive Refer-A-Friend bonuses. Many high-risk countries have this set to 0 (ineligible) due to regulatory restrictions. |
| 12 | MarketingRegionID | int | YES | - | CODE-BACKED | Marketing region segmentation. FK to a marketing region table. Used for campaign targeting. |
| 13 | RiskGroupID | int | YES | - | CODE-BACKED | Granular risk sub-classification: 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. Provides finer EDD routing within the high-risk set. |
| 14 | EconomicTypeID | int | YES | - | CODE-BACKED | Economic classification of the country (e.g., emerging market, developed). Used for economic reporting. |
| 15 | IsSettlementRestricted | bit | YES | - | CODE-BACKED | Whether users from this country are restricted from holding real-asset positions (stocks, crypto). 1=CFD only (cannot own underlying). Cuba, Iran, Myanmar, North Korea, Zimbabwe are both high-risk AND settlement-restricted. |
| 16 | IsoCode | varchar(5) | YES | - | CODE-BACKED | Additional ISO code field. Supplements Abbreviation/LongAbbreviation for regulatory reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| c (FROM) | Dictionary.Country | Direct Read | Reads all columns from country records where IsHighRiskCountry=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers identified. Consumed directly by application-layer compliance/payment services via EXECUTE permission. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetHighRiskCountries (procedure)
└── Dictionary.Country (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FROM - reads all columns WHERE IsHighRiskCountry=1 |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute to get all high-risk countries

```sql
EXEC Billing.GetHighRiskCountries
```

### 8.2 Equivalent ad-hoc with risk context

```sql
SELECT CountryID, Name, Abbreviation, IsHighRiskCountry,
       IsSettlementRestricted, RiskGroupID, IsEligibleForRAFBonusCountry
FROM Dictionary.Country WITH (NOLOCK)
WHERE IsHighRiskCountry = 1
ORDER BY Name
```

### 8.3 Find high-risk countries that are also settlement-restricted (highest restriction tier)

```sql
SELECT CountryID, Name, Abbreviation, RiskGroupID
FROM Dictionary.Country WITH (NOLOCK)
WHERE IsHighRiskCountry = 1
  AND IsSettlementRestricted = 1
ORDER BY Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.9/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetHighRiskCountries | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetHighRiskCountries.sql*
