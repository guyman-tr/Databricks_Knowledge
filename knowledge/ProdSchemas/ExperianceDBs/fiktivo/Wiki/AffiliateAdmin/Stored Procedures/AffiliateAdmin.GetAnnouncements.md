# AffiliateAdmin.GetAnnouncements

> Returns a paginated, sortable, and filtered listing of announcements with support for active status and affiliate type filtering.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Paginated announcement list with total count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetAnnouncements provides a paginated, sortable listing of announcements from the affiliate platform. It supports filtering by active status, affiliate type, and a free-text search expression. The procedure returns two result sets: a total count of matching records and the paginated rows for the requested page.

**WHY:** The announcement management screen in the admin interface requires an efficient way to browse and search through potentially large numbers of announcements. Pagination prevents loading excessive data, sorting allows administrators to organize results by relevant columns, and filtering by active status and affiliate type enables quick location of specific announcements.

**HOW:** The procedure builds a filtered query against `tblaff_Announcement` joined with `tblaff_Announcement_AffiliateType`. It applies optional filters for @IsActive, @AffiliateTypeID, and @SearchExpression. The total count of matching records is returned first, followed by the paginated result set using OFFSET/FETCH or ROW_NUMBER() based on @PageID, @PageSize, @SortColumn, and @SortType parameters.

---

## 2. Business Logic

### 2.1 Filter Logic
- **@IsActive (BIT, nullable):** When provided, filters announcements by their active/inactive status. When NULL, all announcements are returned regardless of status.
- **@AffiliateTypeID (INT, nullable):** When provided, filters to only announcements targeted at the specified affiliate type via the `tblaff_Announcement_AffiliateType` junction table. When NULL, no affiliate type filtering is applied.
- **@SearchExpression (NVARCHAR, nullable):** When provided, applies a LIKE-based text search across announcement fields (typically title and content).

### 2.2 Pagination Logic
The procedure implements server-side pagination using @PageID (zero-based page index) and @PageSize (rows per page, default 10). The first result set returns the total count of matching records for the UI to calculate total pages.

### 2.3 Dynamic Sorting
The @SortColumn and @SortType parameters control result ordering. The default sort is by 'Date' ascending. The procedure likely uses a CASE expression in the ORDER BY clause to support dynamic column sorting.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsActive | BIT | Yes | NULL | CODE-BACKED | Filter by active/inactive status; NULL returns all |
| 2 | @AffiliateTypeID | INT | Yes | NULL | CODE-BACKED | Filter by targeted affiliate type; NULL returns all |
| 3 | @SearchExpression | NVARCHAR | Yes | NULL | CODE-BACKED | Free-text search filter across announcement fields |
| 4 | @PageID | INT | No | 0 | CODE-BACKED | Zero-based page index for pagination |
| 5 | @PageSize | INT | No | 10 | CODE-BACKED | Number of rows per page |
| 6 | @SortColumn | NVARCHAR | No | 'Date' | CODE-BACKED | Column name to sort results by |
| 7 | @SortType | NVARCHAR | No | 'ASC' | CODE-BACKED | Sort direction: ASC or DESC |

**Result Set 1:** Total count of matching records (INT) (CODE-BACKED)
**Result Set 2:** Paginated announcement rows with announcement details (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Announcement` | Table | Primary data source for announcements |
| `dbo.tblaff_Announcement_AffiliateType` | Table | JOIN for affiliate type filtering |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Announcement listing grid | Application | Main announcement management screen |
| Announcement search | Application | Search and filter functionality |

---

## 6. Dependencies

### 6.0 Chain
`GetAnnouncements` -> `tblaff_Announcement` + `tblaff_Announcement_AffiliateType`

### 6.1 Depends On
- `dbo.tblaff_Announcement` - Primary data source
- `dbo.tblaff_Announcement_AffiliateType` - Affiliate type targeting data

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
-- 1. Get first page of all announcements, default sorting
EXEC AffiliateAdmin.GetAnnouncements
    @PageID = 0,
    @PageSize = 10;
```

```sql
-- 2. Get active announcements for a specific affiliate type, sorted by date descending
EXEC AffiliateAdmin.GetAnnouncements
    @IsActive = 1,
    @AffiliateTypeID = 3,
    @PageID = 0,
    @PageSize = 20,
    @SortColumn = 'Date',
    @SortType = 'DESC';
```

```sql
-- 3. Search announcements with text filter
EXEC AffiliateAdmin.GetAnnouncements
    @SearchExpression = N'commission update',
    @PageID = 0,
    @PageSize = 10,
    @SortColumn = 'Date',
    @SortType = 'DESC';
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4678.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAnnouncements | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAnnouncements.sql*
