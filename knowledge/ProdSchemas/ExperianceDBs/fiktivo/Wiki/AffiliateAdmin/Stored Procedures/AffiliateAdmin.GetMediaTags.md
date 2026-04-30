# AffiliateAdmin.GetMediaTags

> Returns media tags with optional filtering by specific tag ID or partial name search across the MediaTag table.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | TagID, TagName, TranslationKey |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetMediaTags retrieves media tag records from the `dbo.MediaTag` table. It supports three retrieval modes: all tags (no filter), search by partial name match, or lookup by specific tag ID. The result includes TagID, TagName, and TranslationKey for each tag.

**WHY:** Media tags are the classification mechanism for banners in the affiliate marketing platform. They enable flexible grouping and filtering of marketing materials beyond the traditional category hierarchy. The admin interface uses this procedure for tag management screens, tag search/autocomplete fields, and tag detail views. The three retrieval modes support different UI scenarios: browsing all tags, searching by name, and loading a specific tag for editing.

**HOW:** The procedure implements three execution branches based on parameter values. When both @TagID and @SearchBy are NULL, all tags are returned. When @SearchBy is provided, a LIKE filter is applied to TagName. When @TagID is provided, a single tag is returned by exact ID match. The result always includes TagID, TagName, and TranslationKey from `dbo.MediaTag`.

---

## 2. Business Logic

### 2.1 Three-Branch Retrieval Logic
The procedure uses conditional logic to determine the query behavior:

1. **No filter (both NULL):** Returns all media tags from the table. Used for full tag list display or tag management grids.
2. **Search by name (@SearchBy provided):** Applies a LIKE comparison against TagName, enabling partial name matching. Used for type-ahead search and autocomplete functionality.
3. **Lookup by ID (@TagID provided):** Returns a single tag by exact ID match. Used for loading tag details in edit forms.

### 2.2 TranslationKey Support
Each media tag includes a TranslationKey, which supports multilingual display of tag names in the admin interface. The application uses this key to look up localized tag names based on the administrator's language preference.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TagID | INT | Yes | NULL | CODE-BACKED | Optional specific tag ID for exact lookup; NULL to skip ID filter |
| 2 | @SearchBy | NVARCHAR(200) | Yes | NULL | CODE-BACKED | Optional partial name search filter; NULL to skip search filter |

**Result Set:** TagID (INT), TagName (NVARCHAR), TranslationKey (NVARCHAR) from `dbo.MediaTag` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.MediaTag` | Table | SELECT TagID, TagName, TranslationKey |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Media tag management screen | Application | Tag listing, search, and detail view |
| Tag autocomplete fields | Application | Type-ahead search for tag selection |
| Banner tag assignment | Application | Tag lookup during banner editing |

---

## 6. Dependencies

### 6.0 Chain
`GetMediaTags` -> `dbo.MediaTag`

### 6.1 Depends On
- `dbo.MediaTag` - Source table for media tag definitions

### 6.2 Depend On This
No known database dependencies. Called from application layer.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get all media tags (no filter)
EXEC AffiliateAdmin.GetMediaTags;
```

```sql
-- 2. Search media tags by partial name
EXEC AffiliateAdmin.GetMediaTags @SearchBy = N'forex';
```

```sql
-- 3. Get a specific tag by ID
EXEC AffiliateAdmin.GetMediaTags @TagID = 15;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4214.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetMediaTags | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetMediaTags.sql*
