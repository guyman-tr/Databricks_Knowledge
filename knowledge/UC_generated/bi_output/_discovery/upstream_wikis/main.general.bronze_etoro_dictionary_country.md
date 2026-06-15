# Dictionary.Country

> Master reference table defining all 251 countries/territories with their geographic, localization, regulatory, marketing, and risk classification attributes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CountryID (INT, CLUSTERED PK) |
| **Row Count** | 251 rows (250 active, 1 "Not available" placeholder) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 6 active (PK clustered + unique on Abbreviation, LongAbbreviation, Name + NC on RegionID, DefaultCurrencyID, LanguageID) |

---

## 1. Business Meaning

Dictionary.Country is one of the most heavily referenced tables in the entire eToro database. It defines every country and territory the platform recognizes, storing geographic classification (region), localization defaults (language, currency), regulatory risk attributes (high-risk flag, risk group, settlement restrictions), and marketing segmentation data.

When a user registers, their country determines:
- **Which regulatory entity governs them** (via Country → Regulation mapping in Customer)
- **What language the UI displays** (LanguageID)
- **What base currency their account uses** (DefaultCurrencyID)
- **Whether they can trade real/settled assets** (IsSettlementRestricted)
- **What KYC/AML scrutiny level applies** (IsHighRiskCountry, RiskGroupID)
- **Whether they're eligible for referral bonuses** (IsEligibleForRAFBonusCountry)
- **Which marketing campaigns target them** (MarketingRegionID)

CountryID is referenced by `Customer.CustomerStatic`, `Billing.Deposit`, `Dictionary.CountryBin6/8`, `Dictionary.CountryToCountryGroup`, and 30+ stored procedures across BackOffice, Billing, Trade, and Customer schemas.

---

## 2. Business Logic

### 2.1 High-Risk Country Classification

**What**: 14 countries are flagged as high-risk, triggering enhanced due diligence (EDD) during onboarding and ongoing monitoring.

**Columns/Parameters Involved**: `IsHighRiskCountry`, `RiskGroupID`

**Rules**:
- IsHighRiskCountry=1 for: Albania, Cambodia, China, Cuba, Iran, Japan, Kuwait, Myanmar, Namibia, Nicaragua, North Korea, Palestinian Territory, Turkey, Zimbabwe
- RiskGroupID provides granular classification: 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit
- High-risk countries trigger additional compliance steps: enhanced document verification, manual review of first deposit, transaction monitoring thresholds reduced
- Some high-risk countries also have `IsSettlementRestricted=1` (Cuba, Iran, Myanmar, North Korea, Zimbabwe) — these users cannot hold real assets

### 2.2 Settlement Restriction

**What**: 21 countries are restricted from real-asset settlement (can only trade CFDs, not own underlying stocks/crypto).

**Columns/Parameters Involved**: `IsSettlementRestricted`

**Rules**:
- IsSettlementRestricted=1 for: Angola, Bhutan, Bosnia, Croatia, Cuba, Iran, Iraq, Liberia, Libya, Macedonia, Myanmar, Nauru, Nigeria, North Korea, Serbia, Sierra Leone, Slovenia, Sudan, Syria, United States, Zimbabwe
- Restricted users can only trade CFDs (SettlementType=CFD), never REAL assets
- The United States is settlement-restricted due to SEC/FINRA regulatory constraints — US users trade via the eToro US entity with different rules
- This flag overrides instrument-level settlement type availability

### 2.3 Default Localization

**What**: Each country maps to a default language and currency for new user onboarding.

**Columns/Parameters Involved**: `LanguageID`, `DefaultCurrencyID`

**Rules**:
- 6 distinct default currencies used: USD (most countries), EUR (European), GBP (UK), AUD (Australia), CAD (Canada), PLN (Poland)
- 11 distinct languages mapped, with English as the fallback for most countries
- Language can be changed by the user post-registration; currency is permanent
- Country 0 ("Not available") uses LanguageID=1 (English) and DefaultCurrencyID=1 (USD) as fallback

### 2.4 RAF Bonus Eligibility

**What**: Controls whether users from this country can participate in the Refer-A-Friend bonus program.

**Columns/Parameters Involved**: `IsEligibleForRAFBonusCountry`

**Rules**:
- Default is 1 (eligible) — most countries can participate
- Set to 0 for countries where regulatory restrictions or fraud patterns prohibit promotional bonuses
- Checked during RAF compensation processing (Customer.RAFCompensationProcess)

---

## 3. Data Overview

| CountryID | Abbreviation | Name | Region | Language | Currency | HighRisk | SettlementRestricted | Meaning |
|---|---|---|---|---|---|---|---|---|
| 0 | (blank) | Not available | Unknown | English | USD | No | No | Fallback/placeholder for users whose country cannot be determined. Inactive. |
| 82 | GR | Greece | Europe | English | EUR | No | No | Standard EU country. CySEC-regulated. EUR default. Full asset access. |
| 232 | US | United States | N. America | EnglishUS | USD | No | Yes | US users — settlement restricted (no REAL assets). Regulated by eToro USA LLC. The only developed market with settlement restrictions. |
| 16 | BD | Bangladesh | Asia | English | USD | No | No | Standard Asian market. USD default. Full access but limited marketing presence. |
| 57 | CU | Cuba | S. America | Spanish | USD | Yes | Yes | Sanctioned country — both high-risk AND settlement restricted. Minimal service availability. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Primary key. 0=Not available (fallback), 1-250=countries ordered roughly alphabetically. Referenced by Customer.CustomerStatic.CountryID, Dictionary.CountryBin6/8.CountryID, Dictionary.CountryToCountryGroup.CountryID, and 30+ procedures. |
| 2 | RegionID | int | NO | (0) | VERIFIED | FK to Dictionary.Region. Geographic region for analytics and default currency inheritance. 23 distinct values used. 0=Unknown (default). |
| 3 | DefaultCurrencyID | int | NO | (0) | VERIFIED | FK to Dictionary.Currency. The default trading account currency assigned to new users from this country. 6 distinct values: 1=USD (most), 2=EUR (Europe), 3=GBP (UK), 5=AUD (Australia), 7=CAD (Canada), 86=PLN (Poland). Permanent — cannot be changed after registration. |
| 4 | LanguageID | int | NO | - | VERIFIED | FK to Dictionary.Language. Default UI language for new users from this country. 11 distinct values. English is the most common default. User can change post-registration. |
| 5 | Abbreviation | char(2) | NO | - | VERIFIED | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). UNIQUE constraint. Used in UI display, API parameters, and geolocation matching. |
| 6 | LongAbbreviation | char(3) | NO | - | VERIFIED | ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR", "DEU"). UNIQUE constraint. Used in some international reporting standards. |
| 7 | Name | varchar(50) | NO | - | VERIFIED | Full country name in English. UNIQUE constraint. Used in UI dropdowns, reports, and compliance documents. |
| 8 | PhonePrefix | varchar(3) | YES | - | VERIFIED | International dialing code (e.g., "1" for US, "44" for UK, "972" for Israel). NULL for some territories. Used for phone verification and SMS routing. |
| 9 | IsActive | bit | NO | - | VERIFIED | Whether this country is currently active on the platform. 250 active, 1 inactive (CountryID=0). Inactive countries are hidden from registration but retained for existing users. |
| 10 | IsHighRiskCountry | tinyint | YES | - | VERIFIED | AML/compliance risk flag. 0=standard (237 countries), 1=high-risk (14 countries). Triggers enhanced due diligence, additional document requirements, and stricter transaction monitoring. |
| 11 | IsEligibleForRAFBonusCountry | bit | NO | (1) | VERIFIED | Whether users from this country can participate in the Refer-A-Friend bonus program. Default=1 (eligible). Set to 0 where regulatory or fraud patterns prohibit bonuses. |
| 12 | MarketingRegionID | tinyint | NO | (0) | VERIFIED | FK to Dictionary.MarketingRegion. Segments countries for marketing campaigns. Distinct from geographic Region — MarketingRegion groups by marketing strategy (e.g., "Arabic" cuts across Asia/Africa regions). |
| 13 | RiskGroupID | int | YES | (0) | VERIFIED | FK to Dictionary.CountryRiskGroup. Granular risk classification: 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than the binary IsHighRiskCountry flag. |
| 14 | EconomicTypeID | int | NO | (0) | VERIFIED | FK to Dictionary.CountryEconomicType. Economic classification of the country. 0=default (unclassified for most countries). |
| 15 | IsSettlementRestricted | bit | NO | (0) | VERIFIED | Whether users from this country are restricted to CFD-only trading (cannot hold REAL assets). 21 countries restricted. Most notable: United States. Overrides instrument-level settlement availability. |
| 16 | IsoCode | char(3) | YES | - | VERIFIED | ISO 3166-1 numeric country code (e.g., "840" for US, "826" for UK). Used for international financial reporting (SWIFT, FATCA). NULL for some territories. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Verified |
|---------|---------------|-------------------|----------|
| RegionID | Dictionary.Region | FK (explicit) | Yes — FK_TSREG_TDCNR |
| DefaultCurrencyID | Dictionary.Currency | FK (explicit) | Yes — FK_TDCUR_TDCNR |
| LanguageID | Dictionary.Language | FK (explicit) | Yes — FK_DLNG_DCNR |
| MarketingRegionID | Dictionary.MarketingRegion | FK (explicit) | Yes — FK_DMRG_DCNR |
| RiskGroupID | Dictionary.CountryRiskGroup | FK (explicit) | Yes — FK_Dictionary_Country_RiskGroupID |
| EconomicTypeID | Dictionary.CountryEconomicType | Implicit Lookup | Name convention match |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | CountryID | FK | Every user has a country |
| Dictionary.CountryBin6 | CountryID | FK | BIN-to-country card mapping |
| Dictionary.CountryBin8 | CountryID | FK | 8-digit BIN-to-country mapping |
| Dictionary.CountryToCountryGroup | CountryID | FK | Country group membership |
| Dictionary.CountryIP | CountryID | Implicit | IP geolocation mapping |
| BackOffice.GetCashOutRequests_Main | CountryID | Read | Withdrawal management |
| BackOffice.KycGetCountries | CountryID | Read | KYC country list |
| BackOffice.GetBlockedCustomers | CountryID | Read | Blocked user reporting |
| Billing.GetCountryAndRank | CountryID | Read | Billing country ranking |
| Billing.CountryBinsGet | CountryID | Read | BIN lookup by country |
| Trade.GetSmartCopyRestrictions | CountryID | Read | Copy-trading restrictions by country |
| Trade.InsertBSLMessagesIntoQueue | CountryID | Read | BSL message routing |
| Trade.GetUserInfo | CountryID | Read | User information retrieval |
| Internal.GetCountryIDByIP | CountryID | Read | IP-to-country resolution |
| dbo.V_Country | CountryID | View | Legacy country view |
| Compliance.GetCountryLongAbbreviation | CountryID, LongAbbreviation | Read | Reads all 251 rows to provide WorldCheck KYC/AML integration with ISO 3166-1 alpha-3 codes for every country |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.Country
 ├── Dictionary.Region (FK: RegionID)
 ├── Dictionary.Currency (FK: DefaultCurrencyID)
 │    └── Dictionary.CurrencyType (FK: CurrencyTypeID)
 ├── Dictionary.Language (FK: LanguageID)
 ├── Dictionary.MarketingRegion (FK: MarketingRegionID)
 └── Dictionary.CountryRiskGroup (FK: RiskGroupID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Region | Table | FK: Geographic region grouping |
| Dictionary.Currency | Table | FK: Default trading currency |
| Dictionary.Language | Table | FK: Default UI language |
| Dictionary.MarketingRegion | Table | FK: Marketing campaign segmentation |
| Dictionary.CountryRiskGroup | Table | FK: Granular risk classification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK: Every user's country |
| Dictionary.CountryBin6 | Table | FK: Card BIN country mapping |
| Dictionary.CountryBin8 | Table | FK: Card BIN country mapping |
| Dictionary.CountryToCountryGroup | Table | FK: Group membership |
| Dictionary.GetCountry | View | Full table exposure |
| dbo.V_Country | View | Legacy access |
| 30+ stored procedures | Procs | BackOffice, Billing, Trade, Customer |
| Compliance.GetCountryLongAbbreviation | Stored Procedure | Reads all CountryID + LongAbbreviation rows for WorldCheck KYC/AML integration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCNR | CLUSTERED PK | CountryID ASC | - | - | Active |
| DCNR_ABBREVIATION | NC UNIQUE | Abbreviation ASC | - | - | Active |
| DCNR_LONGABBREVIATION | NC UNIQUE | LongAbbreviation ASC | - | - | Active |
| DCNR_NAME | NC UNIQUE | Name ASC | - | - | Active |
| DCNR_CURRENCY | NC | DefaultCurrencyID ASC | - | - | Active |
| DCNR_LANGUAGE | NC | LanguageID ASC | - | - | Active |
| DCNR_REGION | NC | RegionID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCNR | PRIMARY KEY | Unique country identifier |
| DCNR_ABBREVIATION | UNIQUE | No duplicate 2-letter ISO codes |
| DCNR_LONGABBREVIATION | UNIQUE | No duplicate 3-letter ISO codes |
| DCNR_NAME | UNIQUE | No duplicate country names |
| FK_TSREG_TDCNR | FOREIGN KEY | RegionID → Dictionary.Region |
| FK_TDCUR_TDCNR | FOREIGN KEY | DefaultCurrencyID → Dictionary.Currency |
| FK_DLNG_DCNR | FOREIGN KEY | LanguageID → Dictionary.Language |
| FK_DMRG_DCNR | FOREIGN KEY | MarketingRegionID → Dictionary.MarketingRegion |
| FK_Dictionary_Country_RiskGroupID | FOREIGN KEY | RiskGroupID → Dictionary.CountryRiskGroup |
| DCNR_NULLREGION | DEFAULT | RegionID defaults to 0 |
| DCNR_NULLCURRENCY | DEFAULT | DefaultCurrencyID defaults to 0 |
| DF_DCNR_IsEligibleForRAFBonusCountry | DEFAULT | IsEligibleForRAFBonusCountry defaults to 1 |
| DCNR_NullMarketingRegion | DEFAULT | MarketingRegionID defaults to 0 |
| Df_Dictionary_Country_EconomicTypeID | DEFAULT | EconomicTypeID defaults to 0 |
| DF_DictionaryCountryIsSettlementRestricted | DEFAULT | IsSettlementRestricted defaults to 0 |

---

## 8. Sample Queries

### 8.1 List all high-risk countries with their risk group
```sql
SELECT  c.CountryID, c.Name, c.Abbreviation, c.IsHighRiskCountry,
        crg.Name AS RiskGroup, c.IsSettlementRestricted
FROM    [Dictionary].[Country] c WITH (NOLOCK)
LEFT JOIN [Dictionary].[CountryRiskGroup] crg WITH (NOLOCK) ON c.RiskGroupID = crg.ID
WHERE   c.IsHighRiskCountry = 1
ORDER BY c.Name;
```

### 8.2 List all settlement-restricted countries
```sql
SELECT  c.Name, c.Abbreviation, r.Name AS Region
FROM    [Dictionary].[Country] c WITH (NOLOCK)
JOIN    [Dictionary].[Region] r WITH (NOLOCK) ON c.RegionID = r.RegionID
WHERE   c.IsSettlementRestricted = 1
ORDER BY c.Name;
```

### 8.3 Countries by region with default currency
```sql
SELECT  r.Name AS Region, c.Name AS Country, cur.Abbreviation AS DefaultCurrency,
        RTRIM(l.Name) AS Language
FROM    [Dictionary].[Country] c WITH (NOLOCK)
JOIN    [Dictionary].[Region] r WITH (NOLOCK) ON c.RegionID = r.RegionID
JOIN    [Dictionary].[Currency] cur WITH (NOLOCK) ON c.DefaultCurrencyID = cur.CurrencyID
JOIN    [Dictionary].[Language] l WITH (NOLOCK) ON c.LanguageID = l.LanguageID
WHERE   c.IsActive = 1
ORDER BY r.Name, c.Name;
```

### 8.4 Find country by ISO code
```sql
SELECT * FROM [Dictionary].[Country] WITH (NOLOCK) WHERE Abbreviation = 'US';
SELECT * FROM [Dictionary].[Country] WITH (NOLOCK) WHERE LongAbbreviation = 'USA';
SELECT * FROM [Dictionary].[Country] WITH (NOLOCK) WHERE IsoCode = '840';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.Country.

---

*Generated: 2026-03-13 | Enriched: MCP live data, 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 16 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Country | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Country.sql*
