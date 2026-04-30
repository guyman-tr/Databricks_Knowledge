# dbo.GetAllMediaTagsBanners

> Returns media tag records joined to their associated banner IDs, optionally filtered to a single banner when @BannerID is supplied.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Gil Haba |
| **Created** | 2021-12 (reviewed by Noga Rozen) |

---

## 1. Business Meaning

Media tags are categorisation labels applied to banners in the affiliate platform. This procedure provides a full or filtered view of those tag-to-banner associations, enabling banner management screens and APIs to resolve which tags are assigned to which banners.

When @BannerID is NULL, the procedure returns all tag-banner relationships across the entire catalog, supporting bulk data loads (e.g., page initialisation that must display tag chips on every banner). When @BannerID is provided, only the tags attached to that specific banner are returned, supporting detail-view and edit-form scenarios.

Both branches join dbo.MediaTag to dbo.MediaTagBanner on TagID, selecting TagName and TranslationKey alongside the IDs needed for front-end rendering and localisation.

---

## 2. Business Logic

### 2.1 Optional Banner Filter

**What**: The presence or absence of @BannerID controls whether all tag-banner links or only those for a specific banner are returned.

**Columns/Parameters Involved**: `@BannerID`, `tb.BannerID`, `m.TagID`

**Rules**:
- @BannerID = NULL: no WHERE clause is applied; all rows from the INNER JOIN are returned
- @BannerID IS NOT NULL: the result set is filtered to rows where tb.BannerID = @BannerID
- The INNER JOIN means only tags that have at least one banner assignment are returned; orphan tags in dbo.MediaTag with no rows in dbo.MediaTagBanner are excluded
- TranslationKey is included to support front-end i18n (the tag display name may differ per locale)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @BannerID | IN | int | NULL | When provided, restricts results to tag-banner associations for this specific banner. When NULL, all associations are returned. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.MediaTag | SELECT (INNER JOIN) | Source of tag metadata: TagID, TagName, TranslationKey |
| dbo.MediaTagBanner | SELECT (INNER JOIN) | Join table linking tags to banners; also source of BannerID in results |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| TagID | dbo.MediaTag | Primary key of the media tag |
| TagName | dbo.MediaTag | Display name of the tag |
| TranslationKey | dbo.MediaTag | Localisation key used by the front-end to render the tag in the user's language |
| BannerID | dbo.MediaTagBanner | The banner to which this tag is assigned |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAllMediaTagsBanners (stored procedure)
+-- dbo.MediaTag (table) [INNER JOIN]
+-- dbo.MediaTagBanner (table) [INNER JOIN]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.MediaTag | Table | Source of tag name and translation key |
| dbo.MediaTagBanner | Table | Join table providing the tag-to-banner mapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Banner management UI | Application | Calls this procedure to display tag chips on banners |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- Both branches of the IF use identical column lists and join structure; they differ only in the presence of the WHERE clause
- WITH (NOLOCK) hints are applied to both joined tables, accepting dirty reads in favour of reduced locking on the banner catalog
- No SET NOCOUNT ON; callers should handle the rowcount if needed
- No explicit transaction; the procedure is read-only

---

## 8. Sample Queries

### 8.1 Return all media tag-banner associations

```sql
EXEC dbo.GetAllMediaTagsBanners;
```

### 8.2 Return tags for a specific banner

```sql
EXEC dbo.GetAllMediaTagsBanners @BannerID = 42;
```

### 8.3 Find banners that share a given tag

```sql
SELECT BannerID
FROM dbo.MediaTagBanner WITH (NOLOCK)
WHERE TagID = (
    SELECT TagID FROM dbo.MediaTag WITH (NOLOCK) WHERE TagName = 'Crypto'
);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetAllMediaTagsBanners | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAllMediaTagsBanners.sql*
