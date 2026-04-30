# dbo.tblaff_Languages

> Language definitions used across the affiliate platform for localizing banners, landing pages, and affiliate communications.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | LanguageID (INT IDENTITY, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 nonclustered PK, 1 unique nonclustered on Code) |

---

## 1. Business Meaning

This table defines all languages supported by the affiliate platform. Each row represents a language/locale variant that can be assigned to banners, media groups, and affiliate communications. It serves as both a language lookup and a landing page URL directory.

Without this table, the affiliate platform could not localize marketing assets, route affiliates to locale-specific landing pages, or send communications in the affiliate's preferred language. It is referenced by tblaff_Banners, tblaff_Groups, and tblaff_Affiliates (via CommunicationLangID).

Languages are managed by admin users with Languages_* permissions. The IsCommunicationLanguage flag separates the 104 languages available for affiliate correspondence from the full set of 1,055 language/locale entries used for banner and landing page targeting. Each entry can specify a top-level domain URL and default/tier-two landing pages for affiliate tracking links.

---

## 2. Business Logic

### 2.1 Communication vs Non-Communication Languages

**What**: Languages are classified into two tiers - communication languages (for direct affiliate messaging) and non-communication languages (for banner/landing page targeting only).

**Columns/Parameters Involved**: `IsCommunicationLanguage`

**Rules**:
- IsCommunicationLanguage = 1 (104 entries): Available for affiliate email communication language preference (tblaff_Affiliates.CommunicationLangID)
- IsCommunicationLanguage = 0 (951 entries): Used only for banner/landing page localization and tracking URL routing
- The large number of non-communication entries suggests locale-specific landing page variants (e.g., different landing pages per country within a language)

### 2.2 Landing Page URL Routing

**What**: Each language entry provides URLs for routing affiliate traffic to the correct localized landing page.

**Columns/Parameters Involved**: `TLDURL`, `DefaultLandingPage`, `TierTwoLandingPage`, `Code`

**Rules**:
- TLDURL provides the base domain for the locale (e.g., etoro.com, etoro.it, etoro.fr)
- DefaultLandingPage overrides the base URL for specific campaign landing pages
- TierTwoLandingPage provides an alternate landing page for tier-2 (sub-affiliate) traffic
- Code follows BCP 47/IETF format (e.g., en-gb, es-es, zh-cn) for locale identification

---

## 3. Data Overview

| LanguageID | LanguageName | IsCommunicationLanguage | LanguageNaturalName | Code | Meaning |
|------------|-------------|------------------------|--------------------|----|---------|
| 1 | English | Yes | English | en-gb | Primary platform language - UK English locale. Default TLDURL points to main etoro.com domain. Used as fallback for unlocalized content. |
| 4 | Italian | Yes | Italiano | it-it | Italian locale with country-specific TLD (etoro.it). Communication-eligible for Italian-speaking affiliates. |
| 8 | Arabic | Yes | (Arabic script) | ar-ae | Arabic locale targeting UAE region (etoro.ae). Right-to-left language requiring special banner assets. |
| 9 | Chinese | Yes | Chinese | zh-cn | Simplified Chinese targeting mainland China (etoro.com.cn). Requires dedicated landing page infrastructure. |
| 10 | Japanese | No | (blank) | ja | Non-communication language - used for banner targeting only. No natural name suggests limited support. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LanguageID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing identifier for each language entry. Referenced by tblaff_Groups.LanguageID, tblaff_Banners.LanguageID, and tblaff_Affiliates.CommunicationLangID. |
| 2 | LanguageName | nvarchar(255) | YES | - | CODE-BACKED | English name of the language (e.g., "English", "Spanish", "German"). Used in admin UI dropdowns and reports. |
| 3 | IsCommunicationLanguage | bit | NO | 0 | CODE-BACKED | Whether this language is available for affiliate email communications. 1 = can be selected as an affiliate's communication preference (104 entries). 0 = used only for banner/landing page targeting (951 entries). |
| 4 | LanguageNaturalName | nvarchar(100) | YES | - | CODE-BACKED | Native-script name of the language (e.g., "Deutsch", "Francais", "Arabic script"). Displayed in locale selectors. NULL/blank for languages with limited support. |
| 5 | TLDURL | nvarchar(255) | YES | 'http://www.etoro.com/' | CODE-BACKED | Base top-level domain URL for this locale. Routes affiliate tracking links to the correct regional site (e.g., etoro.it for Italian, etoro.fr for French). Defaults to main etoro.com domain. |
| 6 | DefaultLandingPage | nvarchar(1024) | YES | - | NAME-INFERRED | Custom landing page URL for affiliate traffic in this language. When set, overrides the TLDURL for campaign-specific routing. |
| 7 | TierTwoLandingPage | nvarchar(1024) | YES | - | CODE-BACKED | Alternate landing page URL for tier-2 (sub-affiliate) traffic. Allows different conversion funnels for direct vs sub-affiliate traffic. |
| 8 | Code | nvarchar(10) | YES | - | CODE-BACKED | BCP 47/IETF language tag (e.g., "en-gb", "es-es", "zh-cn"). Used for locale matching in tracking URLs and API integrations. Unique constraint ensures no duplicate locale codes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Groups | LanguageID | Implicit FK | Banner group is assigned a target language for localization. |
| dbo.tblaff_Banners | LanguageID | Implicit FK | Banner asset is tagged with its target language. |
| dbo.tblaff_Affiliates | CommunicationLangID | Implicit FK | Affiliate's preferred language for email communications. Only IsCommunicationLanguage=1 entries are valid. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Groups | Table | LanguageID column references this table |
| dbo.tblaff_Banners | Table | LanguageID column references this table |
| dbo.tblaff_Affiliates | Table | CommunicationLangID references this table |
| dbo.GetLanguages | Stored Procedure | READER - retrieves all languages for admin dropdowns |
| dbo.GetLanguageByCode | Stored Procedure | READER - looks up language by Code for locale matching |
| dbo.GetBanners | Stored Procedure | READER - joins to resolve banner language |
| dbo.GetBannerById | Stored Procedure | READER - joins to resolve single banner language |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Languages_PK | NC PK | LanguageID | - | - | Active |
| UNQ_tblaff_Languages_Code | UNIQUE NC | Code | - | Code IS NOT NULL | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Languages_IsCommunicationLanguage | DEFAULT | IsCommunicationLanguage = 0 (new languages default to non-communication) |
| DF_tblaff_Languages_TLDURL | DEFAULT | TLDURL = 'http://www.etoro.com/' (default to main domain) |
| UNQ_tblaff_Languages_Code | UNIQUE | Code must be unique when not NULL - prevents duplicate locale tags |

---

## 8. Sample Queries

### 8.1 List all communication-eligible languages
```sql
SELECT LanguageID, LanguageName, LanguageNaturalName, Code
FROM dbo.tblaff_Languages WITH (NOLOCK)
WHERE IsCommunicationLanguage = 1
ORDER BY LanguageName
```

### 8.2 Find language by locale code
```sql
SELECT LanguageID, LanguageName, TLDURL, DefaultLandingPage, TierTwoLandingPage
FROM dbo.tblaff_Languages WITH (NOLOCK)
WHERE Code = 'en-gb'
```

### 8.3 List banners with their language names
```sql
SELECT b.BannerID, b.BannerName, l.LanguageName, l.Code
FROM dbo.tblaff_Banners b WITH (NOLOCK)
JOIN dbo.tblaff_Languages l WITH (NOLOCK) ON b.LanguageID = l.LanguageID
WHERE b.IsArchived = 0
ORDER BY l.LanguageName, b.BannerName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8.8/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Languages | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Languages.sql*
