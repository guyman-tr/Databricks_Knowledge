# Dictionary.Language

> Reference table of platform-supported languages with ISO codes and culture codes for UI localization and user communication.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LanguageID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + unique on Name) |

---

## 1. Business Meaning

Dictionary.Language defines the 28 languages supported by the eToro platform for UI localization, email communication, and content delivery. Each language entry includes ISO 639-1 codes for international standardization and .NET culture codes for proper locale-specific formatting of dates, numbers, and currencies.

This table is essential for eToro's global operation across 100+ countries. A user's language setting determines the platform UI language, email templates, customer support routing, and content variants. Proper culture codes ensure that date/number formatting matches user expectations (e.g., DD/MM/YYYY for European users vs MM/DD/YYYY for US users).

Language is selected during registration and can be changed in user settings. It is stored on the user profile and drives all localized content delivery. The unique index on Name prevents duplicate language entries.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| LanguageID | Name | IsoCode | CultureCode | Meaning |
|---|---|---|---|---|
| 1 | English | en | en-GB | Default platform language, British English locale formatting |
| 6 | Spanish | es | es-ES | Spanish language with Spain locale formatting |
| 10 | Portuguese | pt | pt-BR | Portuguese with Brazilian locale (largest Portuguese-speaking user base) |
| 25 | EnglishUS | en | en-US | US English variant with US date/number formatting |
| 3 | Arabic | ar | ar-AE | Arabic language with UAE locale, requires RTL layout |

*5 of 28 rows shown - selected to represent locale variety.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LanguageID | int | NO | - | CODE-BACKED | Primary key. Language identifier used across user profiles, content systems, and email templates. See [Language](_glossary.md#language). |
| 2 | Name | char(50) | NO | - | CODE-BACKED | Full language name in English. Uniquely indexed - no duplicate language entries allowed. Padded char(50) type. |
| 3 | IsoCode | nchar(10) | YES | - | CODE-BACKED | ISO 639-1 two-letter language code (e.g., "en", "de", "ar"). Note: same ISO code can appear for regional variants (en for both English and EnglishUS). |
| 4 | CultureCode | nchar(10) | YES | - | CODE-BACKED | .NET culture code for locale-specific formatting (e.g., "en-GB", "en-US", "pt-BR"). Determines date, number, and currency display formats. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user tables | LanguageID | Lookup | Stores user's preferred platform language |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Language | CLUSTERED PK | LanguageID | - | - | Active |
| uix_Language_Name | NONCLUSTERED UNIQUE | Name | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all supported languages
```sql
SELECT LanguageID, RTRIM(Name) AS Name, RTRIM(IsoCode) AS IsoCode, RTRIM(CultureCode) AS CultureCode
FROM Dictionary.Language WITH (NOLOCK)
ORDER BY Name
```

### 8.2 Find users by language
```sql
SELECT RTRIM(l.Name) AS Language, COUNT(*) AS UserCount
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.Language l WITH (NOLOCK) ON u.LanguageID = l.LanguageID
GROUP BY l.Name
ORDER BY UserCount DESC
```

### 8.3 Get language details for a user
```sql
SELECT u.CustomerID, RTRIM(l.Name) AS Language, RTRIM(l.CultureCode) AS CultureCode
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.Language l WITH (NOLOCK) ON u.LanguageID = l.LanguageID
WHERE u.CustomerID = @CustomerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Language | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.Language.sql*
