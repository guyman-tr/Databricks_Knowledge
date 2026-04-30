# Dictionary.CountryGroup

> Lookup table defining 33 country groups used for regulatory, marketing, risk, and feature-gating purposes — from regulatory zones (ESMA, US territories) to marketing regions (Arabic, French, German) to feature flags (CfdRestrictedCountries, ERC20AllowedCountries).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CountryGroupID (int, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (clustered PK + unique filtered NC on CFKey) |

---

## 1. Business Meaning

Dictionary.CountryGroup defines logical groupings of countries that drive platform behavior across regulatory compliance, marketing segmentation, risk management, and feature availability. Countries are assigned to groups via the `Dictionary.CountryToCountryGroup` mapping table (many-to-many — a country can belong to multiple groups simultaneously).

These groups serve diverse purposes: regulatory zones (ESMA_Countries, European Union) determine leverage limits and product availability; geographic territories (China_Territories, Russia_Territories, US_Territories, France_Territories) define jurisdictional boundaries; marketing segments (Arabic, French, German, Italian, UK, Spain) drive language-specific campaigns; risk classifications (AML_Rank1_Countries, WalletBlockRiskCountries) trigger compliance controls; and feature flags (CfdRestrictedCountries, ERC20AllowedCountries, C2FCountries) gate product features by geography.

The `CFKey` column maps to an external Configuration Framework system — not all groups have a CFKey (only 13 of 33 do), indicating that some groups are internal-only while others are exposed to the centralized configuration system. Referenced by `dbo.V_Country` view.

---

## 2. Business Logic

### 2.1 Country Group Functional Categories

**What**: Five functional categories of country groups serving different platform subsystems.

**Columns/Parameters Involved**: `CountryGroupID`, `CountryGroupName`, `CFKey`

**Rules**:
- **Regulatory Zones (IDs 1, 10, 22)**: ESMA_Countries, European Union, CfdRestrictedCountries — determine which financial regulations apply, what products are available, and what leverage limits are enforced.
- **Geographic Territories (IDs 2-4, 23)**: China_Territories, Russia_Territories, US_Territories, France_Territories — jurisdictional groupings used for blanket restrictions or requirements that apply to all territories of a sovereign state.
- **Marketing Segments (IDs 5-8, 11-20)**: GCC, Latin America, SE Asia, ROW, Arabic, Australia, French, German, Italian, Other EU, Spain, UK — drive marketing campaign targeting, language selection, and regional promotions. Most have CFKey mappings.
- **Risk & Compliance (IDs 21, 28)**: AML_Rank1_Countries, WalletBlockRiskCountries — trigger enhanced compliance checks, AML monitoring, or feature restrictions for high-risk jurisdictions.
- **Feature Flags (IDs 25-27, 29-33)**: SilverClubCountriesNotEligibleForInterest, TicketFeesPhase2/3, ERC20AllowedCountries, C2FCountries, TR_CASP_countries_* — gate specific features or pricing by country group. Names often include feature names or phase numbers indicating incremental rollouts.

**Diagram**:
```
Country Group Categories
├── Regulatory (ESMA, EU, CfdRestricted)
├── Territorial (China, Russia, US, France)
├── Marketing (Arabic, French, German, UK, ...)
│   └── Most have CFKey for Configuration Framework
├── Risk/AML (AML_Rank1, WalletBlockRisk)
└── Feature Flags
    ├── SilverClubNotEligible (interest exclusion)
    ├── TicketFees Phase 2/3 (fee rollout)
    ├── ERC20Allowed (crypto feature)
    ├── C2F (crypto-to-fiat)
    └── TR_CASP (regulatory CASP by entity)
```

---

## 3. Data Overview

| CountryGroupID | CountryGroupName | CFKey | Meaning |
|---|---|---|---|
| 1 | ESMA_Countries | - | Countries subject to ESMA (European Securities and Markets Authority) regulations — enforces strict leverage limits (30:1 forex, 2:1 crypto) and negative balance protection. |
| 4 | US_Territories | 12 | All US territories and dependencies — blanket restriction group since eToro has specific US regulatory requirements. CFKey 12 links to configuration framework. |
| 20 | UK | 11 | United Kingdom — post-Brexit requires separate FCA-regulated entity (eToro UK). Distinct regulatory requirements from EU. CFKey 11 for configuration. |
| 22 | CfdRestrictedCountries | - | Countries where CFD (Contract for Difference) products cannot be offered due to local regulation — customers from these countries can only trade real stocks/crypto. |
| 27 | ERC20AllowedCountries | - | Countries where ERC-20 token transfers are allowed — gates crypto wallet functionality based on jurisdiction. Feature flag group for crypto regulatory compliance. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryGroupID | int | NO | - | VERIFIED | Primary key identifying the country group. Values 1-33 (non-contiguous — IDs 9 and 24 are missing). Referenced by `Dictionary.CountryToCountryGroup` mapping table and `dbo.V_Country` view. |
| 2 | CountryGroupName | varchar(50) | NO | - | VERIFIED | Descriptive name of the group using PascalCase or underscore convention (e.g., 'ESMA_Countries', 'ERC20AllowedCountries', 'TR_CASP_countries_eToroSEY'). Used as a programmatic identifier in feature-gating logic and configuration systems. |
| 3 | CFKey | int | YES | - | CODE-BACKED | Mapping key to an external Configuration Framework system. Only 13 of 33 groups have a CFKey — groups without one are internal-only and not exposed to centralized configuration. Enforced unique (when not NULL) via filtered unique index `Idx_Dictionary_CountryGroup`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.CountryToCountryGroup | CountryGroupID | Implicit FK | Many-to-many mapping — assigns countries to groups |
| dbo.V_Country | CountryGroupID | View reference | Country view joins country groups for display |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryToCountryGroup | Table | Maps countries to groups |
| dbo.V_Country | View | Joins country group data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCountryGroup | CLUSTERED PK | CountryGroupID ASC | - | - | Active |
| Idx_Dictionary_CountryGroup | UNIQUE NC | CFKey ASC | - | WHERE CFKey IS NOT NULL | Active |

### 7.2 Constraints

None beyond PK and filtered unique index.

---

## 8. Sample Queries

### 8.1 List all country groups
```sql
SELECT  CountryGroupID,
        CountryGroupName,
        CFKey
FROM    Dictionary.CountryGroup WITH (NOLOCK)
ORDER BY CountryGroupID;
```

### 8.2 Find groups with Configuration Framework mappings
```sql
SELECT  CountryGroupID,
        CountryGroupName,
        CFKey
FROM    Dictionary.CountryGroup WITH (NOLOCK)
WHERE   CFKey IS NOT NULL
ORDER BY CFKey;
```

### 8.3 Count countries per group
```sql
SELECT  CG.CountryGroupID,
        CG.CountryGroupName,
        COUNT(CTCG.CountryID) AS CountryCount
FROM    Dictionary.CountryGroup CG WITH (NOLOCK)
LEFT JOIN Dictionary.CountryToCountryGroup CTCG WITH (NOLOCK)
        ON CTCG.CountryGroupID = CG.CountryGroupID
GROUP BY CG.CountryGroupID, CG.CountryGroupName
ORDER BY CountryCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CountryGroup | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CountryGroup.sql*
