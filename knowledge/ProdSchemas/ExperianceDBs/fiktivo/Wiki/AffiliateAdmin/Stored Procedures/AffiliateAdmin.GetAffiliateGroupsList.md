# AffiliateAdmin.GetAffiliateGroupsList

> Returns a paginated, sortable, and searchable list of affiliate groups for the admin management grid.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns total count + paginated AffiliatesGroups rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliateGroupsList is the primary data provider for the affiliate groups management grid in the admin portal. It supports server-side pagination, dynamic column sorting, and text-based search filtering, enabling admins to efficiently browse and locate groups in a potentially large list.

This procedure exists because the affiliate groups management page needs a performant, flexible query that handles pagination and sorting at the database level rather than loading all groups into the application. The dual-result-set pattern (count + rows) allows the UI grid to display total record counts alongside the current page of data.

Data flow: The procedure accepts pagination parameters (@PageID, @PageSize), sorting parameters (@SortColumn, @SortType), and a @SearchExpression for text filtering. When @GetAllAffiliateGroups is set to 1, it bypasses pagination entirely and returns all groups in a single result set. Otherwise, it returns two result sets: the first with the total matching row count, and the second with the paginated rows for the requested page.

---

## 2. Business Logic

### 2.1 Search Filtering

When @SearchExpression is provided, the procedure filters AffiliatesGroupsName using a LIKE pattern match, enabling admins to quickly narrow results by typing partial group names.

### 2.2 Dynamic Sorting

The @SortColumn and @SortType parameters allow the UI to request any supported column ordering. Default sort is by AffiliatesGroupsName descending, ensuring the most recently named or alphabetically last groups appear first.

### 2.3 Get All Mode

When @GetAllAffiliateGroups = 1, the procedure skips pagination logic and returns all matching groups. This mode is used for export scenarios or when the calling code needs the full dataset (e.g., for client-side processing).

### 2.4 Pagination

Standard OFFSET/FETCH or ROW_NUMBER()-based pagination using @PageID and @PageSize to return only the requested slice of data, reducing network transfer and improving UI responsiveness.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SearchExpression | nvarchar | YES | - | CODE-BACKED | Text filter applied to AffiliatesGroupsName via LIKE pattern matching. |
| 2 | @PageID | int | NO | - | CODE-BACKED | Current page number for pagination (1-based). |
| 3 | @PageSize | int | NO | - | CODE-BACKED | Number of rows per page. |
| 4 | @SortColumn | nvarchar | NO | 'AffiliatesGroupsName' | CODE-BACKED | Column name to sort by. Defaults to group name. |
| 5 | @SortType | nvarchar | NO | 'DESC' | CODE-BACKED | Sort direction: ASC or DESC. |
| 6 | @GetAllAffiliateGroups | bit | NO | 0 | CODE-BACKED | When 1, returns all groups without pagination. When 0, returns paginated result sets. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | AffiliateAdmin.AffiliatesGroups | Read | Reads group list with filtering, sorting, and pagination |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliateGroupsList (procedure)
+-- AffiliateAdmin.AffiliatesGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.AffiliatesGroups | Table | SELECT with pagination, sorting, and search filtering |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get first page of groups with default sorting
```sql
EXEC AffiliateAdmin.GetAffiliateGroupsList
    @SearchExpression = NULL,
    @PageID = 1,
    @PageSize = 25,
    @SortColumn = 'AffiliatesGroupsName',
    @SortType = 'DESC',
    @GetAllAffiliateGroups = 0;
-- Result 1: Total count of matching groups
-- Result 2: First 25 groups sorted by name descending
```

### 8.2 Search for groups containing 'Premium'
```sql
EXEC AffiliateAdmin.GetAffiliateGroupsList
    @SearchExpression = 'Premium',
    @PageID = 1,
    @PageSize = 10,
    @SortColumn = 'AffiliatesGroupsName',
    @SortType = 'ASC',
    @GetAllAffiliateGroups = 0;
```

### 8.3 Export all groups (no pagination)
```sql
EXEC AffiliateAdmin.GetAffiliateGroupsList
    @SearchExpression = NULL,
    @PageID = 1,
    @PageSize = 100,
    @SortColumn = 'AffiliatesGroupsName',
    @SortType = 'ASC',
    @GetAllAffiliateGroups = 1;
-- Returns all groups in a single result set
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4500.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 6.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliateGroupsList | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliateGroupsList.sql*
