# Dictionary.Region

> Lookup table defining geographic regions for country grouping, regulatory bucketing, marketing segmentation, and default currency assignment.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RegionID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK clustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.Region groups countries into geographic regions for marketing segmentation, regulatory bucketing, and default currency assignment. Each region defines which currency new users from that area see as their default trading currency.

This table supports eToro's global expansion strategy. Marketing campaigns, onboarding flows, and default settings are configured per region rather than per individual country. The DefaultCurrency column links to Dictionary.Currency, ensuring users in Europe see EUR, UK users see GBP, and most other regions default to USD.

RegionID is referenced by Dictionary.Country (every country belongs to a region) and is used in marketing, analytics, and user segmentation across BackOffice and DWH procedures.

---

## 2. Business Logic

### 2.1 Region Granularity

**What**: Regions range from continents to individual countries, reflecting marketing needs.

**Columns/Parameters Involved**: `RegionID`, `Name`, `DefaultCurrency`

**Rules**:
- **Continent-level** (0-6): Unknown, N. America, S. America, Europe, Asia, Africa, Oceania
- **Country-level** (7+): Canada, UK, Netherlands, Italy, Spain, Indonesia, Brazil, etc. — individual countries elevated to region status for targeted marketing
- DefaultCurrency maps to Dictionary.Currency: 1=USD (most regions), 2=EUR (Europe), 3=GBP (UK), 5=AUD (Australia), 7=CAD (Canada)

---

## 3. Data Overview

| RegionID | Name | DefaultCurrency | Meaning |
|---|---|---|---|
| 0 | Unknown | 0 | Fallback region for users whose country couldn't be mapped. DefaultCurrency 0 = no default (system will prompt). |
| 3 | Europe | 2 | Continental Europe — most EU users. Default currency EUR. The largest user region by volume for CySEC-regulated users. |
| 8 | UK | 3 | United Kingdom — elevated to its own region post-Brexit for FCA-specific marketing and GBP default. |
| 16 | Israel | 1 | eToro's home market — separate region for local marketing. Default currency USD (Israeli users trade in USD). |
| 24 | Australia | 5 | Australia — ASIC-regulated users with AUD default currency and region-specific compliance rules. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegionID | int | NO | - | CODE-BACKED | Primary key identifying the geographic region. 0=Unknown, 1=N. America, 2=S. America, 3=Europe, 4=Asia, 5=Africa, 6=Oceania, 7=Canada, 8=UK, 9-25=country-specific regions. Referenced by Dictionary.Country.RegionID. See [Region](_glossary.md#region). (Dictionary.Region) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable region name. UNIQUE constraint. Used in marketing dashboards, analytics, and user segmentation. |
| 3 | DefaultCurrency | int | YES | - | CODE-BACKED | FK to Dictionary.Currency — the default trading currency for new users in this region. 1=USD, 2=EUR, 3=GBP, 5=AUD, 7=CAD. Applied during registration to set the user's account base currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DefaultCurrency | Dictionary.Currency | Implicit Lookup | Default trading currency for the region |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Country | RegionID | FK | Every country belongs to a region |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK: RegionID groups countries into regions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DREG | CLUSTERED PK | RegionID ASC | - | - | Active |
| DREG_NAME | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DREG | PRIMARY KEY | Unique region identifier |
| DREG_NAME | UNIQUE | No duplicate region names |

---

## 8. Sample Queries

### 8.1 List all regions with default currencies
```sql
SELECT  r.RegionID, r.Name, c.Abbreviation AS DefaultCurrency
FROM    [Dictionary].[Region] r WITH (NOLOCK)
LEFT JOIN [Dictionary].[Currency] c WITH (NOLOCK) ON r.DefaultCurrency = c.CurrencyID
ORDER BY r.RegionID;
```

### 8.2 Count countries per region
```sql
SELECT  r.Name AS Region, COUNT(*) AS CountryCount
FROM    [Dictionary].[Country] co WITH (NOLOCK)
JOIN    [Dictionary].[Region] r WITH (NOLOCK) ON co.RegionID = r.RegionID
GROUP BY r.Name ORDER BY CountryCount DESC;
```

### 8.3 Find all countries in Europe
```sql
SELECT  co.CountryID, co.Name, co.Abbreviation
FROM    [Dictionary].[Country] co WITH (NOLOCK)
JOIN    [Dictionary].[Region] r WITH (NOLOCK) ON co.RegionID = r.RegionID
WHERE   r.RegionID = 3 ORDER BY co.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.Region.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Region | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Region.sql*
