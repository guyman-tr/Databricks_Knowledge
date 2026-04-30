# dbo.GetLanguages

> Returns distinct language records with optional filtering by LanguageID and/or BannerTypeID, joining tblaff_Languages to tblaff_Banners to support banner-type-scoped language queries.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown (modified by Gil H, 2024-05-29, PART-2849) |
| **Created** | Unknown |

---

## 1. Business Meaning

The affiliate platform must display languages in various contexts: a full language list for general settings, a per-language list filtered to a specific banner type when managing banner campaigns, or a single language record when editing a specific configuration item. This procedure covers all three scenarios through its two optional parameters.

The join to tblaff_Banners enables the @BannerTypeID filter -- when provided, only languages that have at least one banner of the requested type are returned. This avoids presenting language options that have no banners available for the chosen banner type, keeping UI dropdowns relevant.

The PART-2849 update (May 2024) added LanguageID to the WHERE clause to support the @ID filter path, aligning the procedure with the language management requirements of the SoftDeleteAffiliate feature (the commented-out code at the top of the file belongs to that same ticket).

---

## 2. Business Logic

### 2.1 Base Language Filter (Non-Blank Code)

**What**: Excludes languages without a valid Code value.

**Columns/Parameters Involved**: `l.Code`

**Rules**:
- RTRIM(ISNULL(Code, '')) != '': languages with NULL or whitespace-only Code are excluded
- This ensures only deployable language configurations are returned

### 2.2 Optional LanguageID Filter

**What**: When @ID is supplied, restricts results to that specific language.

**Columns/Parameters Involved**: `@ID`, `l.LanguageID`

**Rules**:
- l.LanguageID = ISNULL(@ID, l.LanguageID): the ISNULL idiom means "match if @ID is provided, otherwise always match"
- Defaults to NULL (returns all languages)

### 2.3 Optional BannerTypeID Filter

**What**: When @BannerTypeID is supplied, restricts results to languages that have at least one banner of that type.

**Columns/Parameters Involved**: `@BannerTypeID`, `b.Type`

**Rules**:
- The LEFT JOIN to tblaff_Banners is used; when @BannerTypeID IS NOT NULL, b.Type must equal @BannerTypeID
- The DISTINCT keyword prevents duplicate language rows when a language has multiple banners of the requested type
- When @BannerTypeID IS NULL, all languages with valid codes are returned regardless of banner associations

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @ID | IN | int | NULL | When supplied, returns only the language with this LanguageID. When NULL, all valid languages are returned. |
| 2 | @BannerTypeID | IN | int | NULL | When supplied, restricts results to languages that have at least one banner of this banner type. When NULL, no banner-type filter is applied. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Languages | SELECT (LEFT JOIN driver) | Source of language configuration records |
| dbo.tblaff_Banners | SELECT (LEFT JOIN) | Used to filter languages by banner type when @BannerTypeID is provided |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| LanguageID | tblaff_Languages | Primary key |
| LanguageName | tblaff_Languages | Internal language name |
| IsCommunicationLanguage | tblaff_Languages | Communication language flag |
| LanguageNaturalName | tblaff_Languages | Display name in native script |
| TLDURL | tblaff_Languages | TLD URL for this language |
| DefaultLandingPage | tblaff_Languages | Default landing page URL |
| TierTwoLandingPage | tblaff_Languages | Tier 2 landing page URL |
| Code | tblaff_Languages | ISO or platform language code |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetLanguages (stored procedure)
+-- dbo.tblaff_Languages (table) [SELECT]
+-- dbo.tblaff_Banners (table) [LEFT JOIN, optional banner-type filter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Languages | Table | Primary source of language records |
| dbo.tblaff_Banners | Table | Joined to support banner-type-scoped language filtering |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Banner management UI | Application | Calls with @BannerTypeID to populate language dropdown for a specific banner type |
| Language settings UI | Application | Calls without parameters to return all valid languages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- WITH (NOLOCK) applied to both tblaff_Languages and tblaff_Banners
- DISTINCT prevents duplicate rows when a language has multiple banners of the requested type
- The source file contains a commented-out SoftDeleteAffiliate procedure body from PART-2849; this is developer residue and does not affect execution
- PART-2849 (2024-05-29, Gil H): Added LanguageID to WHERE clause; comment "Add LanguageID to where clause. PART-2849"

---

## 8. Sample Queries

### 8.1 Return all valid languages

```sql
EXEC dbo.GetLanguages;
```

### 8.2 Return a specific language by ID

```sql
EXEC dbo.GetLanguages @ID = 3;
```

### 8.3 Return languages that have banners of a specific type

```sql
EXEC dbo.GetLanguages @BannerTypeID = 2;
```

### 8.4 Return a specific language filtered by banner type

```sql
EXEC dbo.GetLanguages @ID = 3, @BannerTypeID = 2;
```

---

## 9. Atlassian Knowledge Sources

- PART-2849 (2024-05-29, Gil H): Added LanguageID to WHERE clause to support language-specific filtering in the language management workflow.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10*
*Object: dbo.GetLanguages | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetLanguages.sql*
