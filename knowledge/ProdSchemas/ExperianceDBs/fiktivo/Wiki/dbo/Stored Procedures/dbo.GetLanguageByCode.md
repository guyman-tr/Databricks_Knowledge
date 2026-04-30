# dbo.GetLanguageByCode

> Retrieves a single language record by its code using a case-insensitive match, returning all language attributes including landing page URLs and TLD configuration.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

The affiliate platform supports multiple languages, each with its own landing page URLs, TLD, and communication settings. This procedure resolves a language code string (e.g., "en", "ES", "De") to the full language record, enabling services that receive language codes from external sources to obtain the complete configuration needed for link generation and localisation.

Case-insensitive comparison (LOWER on both sides) ensures that language codes supplied in any casing will match, preventing lookup failures due to casing inconsistencies between callers and the database.

---

## 2. Business Logic

### 2.1 Case-Insensitive Language Code Lookup

**What**: Matches the supplied @LanguageCode against the Code column using LOWER() on both sides.

**Columns/Parameters Involved**: `@LanguageCode`, `Code`

**Rules**:
- LOWER(Code) = LOWER(@LanguageCode): comparison is case-insensitive
- If no row matches, zero rows are returned with no error
- If multiple rows share the same Code (data quality issue), multiple rows are returned
- All language configuration columns are returned, providing a complete language record

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @LanguageCode | IN | varchar(50) | (required) | The language code to look up (e.g., "en", "ES"). Matched case-insensitively against the Code column in tblaff_Languages. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Languages | SELECT | Filtered by case-insensitive code match |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| LanguageID | tblaff_Languages | Primary key |
| LanguageName | tblaff_Languages | Internal name of the language |
| IsCommunicationLanguage | tblaff_Languages | Flag indicating whether this language is used for affiliate communications |
| LanguageNaturalName | tblaff_Languages | Display name in the language's own script |
| TLDURL | tblaff_Languages | Top-level domain URL associated with this language |
| DefaultLandingPage | tblaff_Languages | Default landing page URL for this language |
| TierTwoLandingPage | tblaff_Languages | Tier 2 (sub-affiliate) landing page URL |
| Code | tblaff_Languages | The language code as stored |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetLanguageByCode (stored procedure)
+-- dbo.tblaff_Languages (table) [SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Languages | Table | Sole data source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Link generation service | Application | Resolves a language code to landing page URLs for affiliate tracking links |
| Localisation middleware | Application | Looks up the full language record for content delivery |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- WITH (NOLOCK) applied; consistent with the reference-table read pattern
- LOWER() on both column and parameter prevents index seeks on Code; acceptable for a small reference table
- Analogous to dbo.GetCountryByCode in pattern and purpose

---

## 8. Sample Queries

### 8.1 Look up a language by code

```sql
EXEC dbo.GetLanguageByCode @LanguageCode = 'en';
```

### 8.2 Test case-insensitive matching

```sql
EXEC dbo.GetLanguageByCode @LanguageCode = 'ES';
EXEC dbo.GetLanguageByCode @LanguageCode = 'es';
-- Both should return the same row
```

### 8.3 Find all language codes in the table

```sql
SELECT LanguageID, Code, LanguageName
FROM dbo.tblaff_Languages WITH (NOLOCK)
WHERE RTRIM(ISNULL(Code, '')) <> ''
ORDER BY Code;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetLanguageByCode | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetLanguageByCode.sql*
