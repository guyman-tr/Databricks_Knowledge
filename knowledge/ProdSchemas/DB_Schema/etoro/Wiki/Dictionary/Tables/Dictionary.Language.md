# Dictionary.Language

> Lookup table defining the 28 supported UI and communication languages on the eToro platform, with ISO and culture codes for localization.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LanguageID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK clustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.Language defines every language supported by the eToro platform for UI rendering, email communications, legal documents, and customer support. Each language includes ISO 639 codes and .NET culture codes for programmatic localization.

This table is critical for eToro's global operation across 100+ countries. The correct language determines which T&C documents are shown, what email templates are sent, how numbers/dates are formatted, and what regulatory disclosures appear. A user's language is set at registration (based on browser locale or country) and stored in customer data.

LanguageID is referenced by Dictionary.Country (each country has a default language), Dictionary.PaymentStatusNotification (payment notifications per language), and various email/notification procedures.

---

## 2. Business Logic

### 2.1 Regional Language Variants

**What**: Some languages have multiple variants for different regions.

**Columns/Parameters Involved**: `LanguageID`, `IsoCode`, `CultureCode`

**Rules**:
- English has two variants: UK (1, en-GB) and US (25, en-US) — differ in regulatory text and spelling
- Portuguese has two: Brazilian (10, pt-BR) and European (20, pt-PT) — different markets
- Chinese has two: Simplified (4, zh-CN) and Traditional (18, zh-TW) — Mainland vs Taiwan
- IsoCode may be shared between variants; CultureCode provides the specific regional distinction

---

## 3. Data Overview

| LanguageID | Name | CultureCode | Meaning |
|---|---|---|---|
| 1 | English | en-GB | Default platform language. Used for UK, Australia, and most English-speaking markets. All legal documents start in this variant. |
| 6 | Spanish | es-ES | European Spanish — used across Spain and Latin American markets. One of the highest-volume non-English languages. |
| 25 | EnglishUS | en-US | US-specific English with FINRA/SEC-compliant disclosures. Distinct from en-GB for regulatory text (e.g., "securities" vs "shares"). |
| 10 | Portuguese | pt-BR | Brazilian Portuguese for the large Brazilian user base. Distinct from European Portuguese in vocabulary and formatting. |
| 4 | Chinese | zh-CN | Simplified Chinese for Mainland China / Singapore markets. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LanguageID | int | NO | - | CODE-BACKED | Primary key identifying the language. 1=English(UK), 2=German, 3=Arabic, 4=Chinese, 5=Russian, 6=Spanish, 7=French, 8=Italian, 9=Japanese, 10=Portuguese(BR), 11=Turkish, 12=Greek, 13=Korean, 14=Swedish, 15=Norwegian, 16=Hungarian, 17=Polish, 18=ChineseTraditional, 19=Dutch, 20=EuropeanPortuguese, 21=Czech, 22=Malay, 23=Danish, 24=Romanian, 25=EnglishUS, 26=Vietnamese, 27=Thai, 28=Finnish. Referenced by Dictionary.Country.LanguageID. See [Language](_glossary.md#language). (Dictionary.Language) |
| 2 | Name | char(50) | NO | - | CODE-BACKED | Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. |
| 3 | IsoCode | nchar(10) | YES | - | CODE-BACKED | ISO 639-1 two-letter language code (e.g., "en", "de", "ar"). Used for URL routing, API locale headers, and content management. May be shared between regional variants (e.g., both en-GB and en-US share "en"). |
| 4 | CultureCode | nchar(10) | YES | - | CODE-BACKED | .NET culture code for full locale specification (e.g., "en-GB", "de-DE", "zh-CN"). Used for number formatting (decimal separators), date formatting, and currency display. Provides the regional distinction that IsoCode alone cannot. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Country | LanguageID | FK | Default language for users from each country |
| Dictionary.PaymentStatusNotification | LanguageID | FK | Payment notification templates per language |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK: LanguageID sets default language per country |
| Dictionary.PaymentStatusNotification | Table | FK: notification templates per language |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DLNG | CLUSTERED PK | LanguageID ASC | - | - | Active |
| DLNG_NAME | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DLNG | PRIMARY KEY | Unique language identifier |
| DLNG_NAME | UNIQUE | No duplicate language names |

---

## 8. Sample Queries

### 8.1 List all languages with codes
```sql
SELECT LanguageID, RTRIM(Name) AS Name, RTRIM(IsoCode) AS IsoCode, RTRIM(CultureCode) AS CultureCode
FROM [Dictionary].[Language] WITH (NOLOCK) ORDER BY LanguageID;
```

### 8.2 Find countries using a specific language
```sql
SELECT co.Name AS Country, co.Abbreviation, RTRIM(l.Name) AS Language
FROM [Dictionary].[Country] co WITH (NOLOCK)
JOIN [Dictionary].[Language] l WITH (NOLOCK) ON co.LanguageID = l.LanguageID
WHERE l.LanguageID = 1 ORDER BY co.Name;
```

### 8.3 Count countries per language
```sql
SELECT RTRIM(l.Name) AS Language, COUNT(*) AS CountryCount
FROM [Dictionary].[Country] co WITH (NOLOCK)
JOIN [Dictionary].[Language] l WITH (NOLOCK) ON co.LanguageID = l.LanguageID
GROUP BY l.Name ORDER BY CountryCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.Language.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Language | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Language.sql*
