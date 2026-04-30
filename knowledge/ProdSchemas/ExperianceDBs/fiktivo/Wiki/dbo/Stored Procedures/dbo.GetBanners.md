# dbo.GetBanners

> Returns all active (non-archived, non-placeholder) banners with their type, language, and category name by joining four tables; added CategoryName in June 2024 to support the Partners Portal.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown (Gile Haba added CategoryName, 2024-06-17) |
| **Created** | Unknown |

---

## 1. Business Meaning

The affiliate and partners portal must present a catalog of available, usable banners to affiliates and administrators. This procedure is the primary bulk read for that catalog: it returns every banner that is not archived and whose name is not the developer placeholder "!!! DO NOT USE !!!".

Each banner row is enriched with its type name, language metadata (including landing page URLs needed for link generation), and the category name added in June 2024 to support Partners Portal filtering and display. The procedure has no parameters and always returns the full active catalog, making it suitable for page-load cache population.

---

## 2. Business Logic

### 2.1 Active Banner Filter

**What**: Excludes archived banners and internal developer placeholders.

**Columns/Parameters Involved**: `Banners.IsArchived`, `Banners.BannerName`

**Rules**:
- IsArchived = 0 is required; archived banners are hidden from the catalog
- BannerName != '!!! DO NOT USE !!!' excludes developer/test placeholder rows that should never be exposed to affiliates
- No language or type filter; all active banners across all languages and types are returned

### 2.2 Category Name Enrichment (PART-3001)

**What**: Joins tblaff_Categories to include CategoryName in the result set.

**Columns/Parameters Involved**: `bctg.CategoryName`, `Banners.CategoryID`

**Rules**:
- Added on 2024-06-17 to support banner category display in the Partners Portal
- The join to tblaff_Categories is a regular INNER JOIN (not LEFT JOIN); a banner with no matching CategoryID would be excluded -- callers should be aware that all active banners are expected to have a valid CategoryID
- Jira reference: PART-3001

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure accepts no parameters.

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| - | (none) | - | - | - | No parameters; always returns the full active banner catalog. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Banners | SELECT | Primary source of banner records |
| dbo.tblaff_BannerTypes | SELECT (INNER JOIN) | Provides BannerTypeName |
| dbo.tblaff_Languages | SELECT (INNER JOIN) | Provides language and landing page metadata |
| dbo.tblaff_Categories | SELECT (INNER JOIN) | Provides CategoryName (added PART-3001, June 2024) |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| BannerID | tblaff_Banners | Primary key |
| CategoryID | tblaff_Banners | Foreign key to tblaff_Categories |
| Type | tblaff_Banners | Banner type foreign key |
| BannerName | tblaff_Banners | Display name |
| ImageURL | tblaff_Banners | Banner image asset URL |
| TargetURL | tblaff_Banners | Click-through destination URL |
| AltText | tblaff_Banners | Accessibility alt text |
| Width / Height | tblaff_Banners | Pixel dimensions |
| PerSale / PerLead / PerClick | tblaff_Banners | Commission rates |
| NotesToAffiliate | tblaff_Banners | Affiliate-facing notes |
| AdvancedBanner | tblaff_Banners | 1 = HTML/JS creative, 0 = image |
| AdCode | tblaff_Banners | Raw HTML/JS for advanced banners |
| TargetWindow | tblaff_Banners | Link target attribute |
| BrandID | tblaff_Banners | Brand association |
| Priority | tblaff_Banners | Display ordering priority |
| IsArchived | tblaff_Banners | Always 0 for rows returned by this procedure |
| BannerTypeID / BannerTypeName | tblaff_BannerTypes | Type ID and name |
| LanguageID / LanguageName / ... | tblaff_Languages | Language record including TLDURL and landing pages |
| CategoryName | tblaff_Categories | Human-readable category name |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetBanners (stored procedure)
+-- dbo.tblaff_Banners (table) [SELECT]
    +-- dbo.tblaff_BannerTypes (table) [INNER JOIN on Type]
    +-- dbo.tblaff_Languages (table) [INNER JOIN on LanguageID]
    +-- dbo.tblaff_Categories (table) [INNER JOIN on CategoryID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Banners | Table | Primary banner catalog source |
| dbo.tblaff_BannerTypes | Table | Resolves banner type name |
| dbo.tblaff_Languages | Table | Resolves language and landing page data |
| dbo.tblaff_Categories | Table | Provides category name for Partners Portal display |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate portal banner catalog | Application | Calls this procedure to populate the full active banner list |
| Partners Portal | Application | Uses CategoryName column (added PART-3001) for category-based filtering |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- WITH (NOLOCK) applied to all joined tables
- The join to tblaff_Categories is an unaliased INNER JOIN (not LEFT); banners without a valid CategoryID are excluded
- The placeholder filter (BannerName != '!!! DO NOT USE !!!') is a developer-convention guard; the excluded rows are test/template entries
- Jira: PART-3001 (2024-06-17) added CategoryName and the tblaff_Categories join

---

## 8. Sample Queries

### 8.1 Return the full active banner catalog

```sql
EXEC dbo.GetBanners;
```

### 8.2 Count active banners by language

```sql
SELECT l.LanguageName, COUNT(*) AS BannerCount
FROM dbo.tblaff_Banners b WITH (NOLOCK)
JOIN dbo.tblaff_Languages l WITH (NOLOCK) ON b.LanguageID = l.LanguageID
WHERE b.IsArchived = 0
  AND b.BannerName <> '!!! DO NOT USE !!!'
GROUP BY l.LanguageName
ORDER BY BannerCount DESC;
```

### 8.3 Find banners in a specific category

```sql
SELECT b.BannerID, b.BannerName, c.CategoryName
FROM dbo.tblaff_Banners b WITH (NOLOCK)
JOIN dbo.tblaff_Categories c WITH (NOLOCK) ON c.CategoryID = b.CategoryID
WHERE b.IsArchived = 0
  AND c.CategoryName = 'Stocks';
```

---

## 9. Atlassian Knowledge Sources

- PART-3001 (2024-06-17, Gile Haba): Added CategoryName column and tblaff_Categories join to support banner data display in the Partners Portal.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10*
*Object: dbo.GetBanners | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetBanners.sql*
