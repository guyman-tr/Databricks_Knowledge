# AffiliateAdmin.GetAffiliates

> Returns a paginated, sortable, and multi-filter affiliate listing for the main affiliate management grid in the admin portal.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns total count + paginated affiliate rows with tier, country, and URL details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliates is the primary data provider for the main affiliate management grid in the admin portal. It is the central listing procedure for the entire affiliate administration module, supporting server-side pagination, dynamic column sorting, and multi-dimensional filtering by IB level, account status, affiliate groups (via TVP), individual affiliate ID, affiliate type, and free-text search.

This procedure exists because the affiliate management page is the most frequently used screen in the admin portal, and it must handle a potentially very large dataset (thousands of affiliates) with fast response times. Server-side pagination, combined with flexible filtering and sorting, ensures that admins can efficiently locate and work with specific affiliates or groups of affiliates.

Data flow: The procedure joins dbo.tblaff_Affiliates with dbo.tblaff_Tier2Members (for IB/tier level), dbo.tblaff_Country (for country resolution), and Affiliate.tblaff_AffiliateURLs (for affiliate URL details). The @AffiliateGroupsID TVP enables multi-group filtering. Results are returned as two result sets: the first with the total matching row count for pagination controls, and the second with the paginated affiliate rows for the current page.

---

## 2. Business Logic

### 2.1 Multi-Dimensional Filtering

The procedure supports simultaneous filtering by multiple criteria: @AffiliateIBLevel for IB tier level, @AccountStatus for account state, @AffiliateGroupsID (TVP) for group membership, @AffiliateID for direct ID lookup, @AffiliateTypeID for type classification, and @TxtFilter for free-text search across affiliate fields. All filters are optional and combined with AND logic when provided.

### 2.2 Table-Valued Parameter for Groups

The @AffiliateGroupsID parameter uses dbo.IDTableType to accept multiple group IDs in a single call. When populated, only affiliates belonging to at least one of the specified groups are returned. When empty, the group filter is bypassed.

### 2.3 Tier/IB Level Join

The JOIN to dbo.tblaff_Tier2Members enriches each affiliate row with their tier membership information, indicating whether the affiliate is a direct partner or a referred sub-affiliate (IB level). The @AffiliateIBLevel parameter filters on this dimension.

### 2.4 Dynamic Sort and Pagination

Standard server-side pagination with dynamic column sorting via @SortColumn (default: DateCreated) and @SortType (default: DESC), ensuring newest affiliates appear first by default. The dual result set pattern provides both total count and paginated data.

### 2.5 Country and URL Enrichment

Joins to dbo.tblaff_Country and Affiliate.tblaff_AffiliateURLs provide country names and URL information alongside core affiliate data, giving the admin grid a complete view without secondary lookups.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PageID | int | NO | - | CODE-BACKED | Current page number for pagination (1-based). |
| 2 | @PageSize | int | NO | - | CODE-BACKED | Number of rows per page. |
| 3 | @SortColumn | nvarchar | NO | 'DateCreated' | CODE-BACKED | Column name to sort results by. Defaults to affiliate creation date. |
| 4 | @SortType | nvarchar | NO | 'DESC' | CODE-BACKED | Sort direction: ASC or DESC. Defaults to newest first. |
| 5 | @AffiliateIBLevel | int | YES | - | CODE-BACKED | Filter by IB (Introducing Broker) tier level from tblaff_Tier2Members. |
| 6 | @AccountStatus | int | YES | - | CODE-BACKED | Filter by affiliate account status (active, suspended, etc.). |
| 7 | @AffiliateGroupsID | dbo.IDTableType READONLY | NO | - | CODE-BACKED | Table-valued parameter containing group IDs to filter by. Empty = no group filter. |
| 8 | @AffiliateID | int | YES | - | CODE-BACKED | Filter by specific AffiliateID for direct lookup. |
| 9 | @AffiliateTypeID | int | YES | - | CODE-BACKED | Filter by affiliate type classification. |
| 10 | @TxtFilter | nvarchar | YES | - | CODE-BACKED | Free-text search filter applied across affiliate fields via LIKE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_Affiliates | Read | Main affiliate data source |
| JOIN | dbo.tblaff_Tier2Members | Read | Tier/IB level membership for hierarchy context |
| JOIN | dbo.tblaff_Country | Read | Country name resolution for affiliate's registered country |
| JOIN | Affiliate.tblaff_AffiliateURLs | Read | Affiliate URL details |
| JOIN | @AffiliateGroupsID (TVP) | Filter | Table-valued parameter for multi-group filtering |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliates (procedure)
+-- dbo.tblaff_Affiliates (table)
+-- dbo.tblaff_Tier2Members (table)
+-- dbo.tblaff_Country (table)
+-- Affiliate.tblaff_AffiliateURLs (table)
+-- dbo.IDTableType (user-defined table type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | Main SELECT for affiliate records |
| dbo.tblaff_Tier2Members | Table | JOIN for tier/IB level data |
| dbo.tblaff_Country | Table | JOIN for country name resolution |
| Affiliate.tblaff_AffiliateURLs | Table | JOIN for affiliate URL details |
| dbo.IDTableType | User-Defined Table Type | Parameter type for @AffiliateGroupsID |

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

### 8.1 Get first page of affiliates with default sorting
```sql
DECLARE @Groups dbo.IDTableType;

EXEC AffiliateAdmin.GetAffiliates
    @PageID = 1,
    @PageSize = 25,
    @SortColumn = 'DateCreated',
    @SortType = 'DESC',
    @AffiliateIBLevel = NULL,
    @AccountStatus = NULL,
    @AffiliateGroupsID = @Groups,
    @AffiliateID = NULL,
    @AffiliateTypeID = NULL,
    @TxtFilter = NULL;
-- Result 1: Total matching affiliate count
-- Result 2: First 25 affiliates sorted by creation date descending
```

### 8.2 Filter by specific groups and affiliate type
```sql
DECLARE @Groups dbo.IDTableType;
INSERT INTO @Groups (ID) VALUES (2), (5);

EXEC AffiliateAdmin.GetAffiliates
    @PageID = 1,
    @PageSize = 50,
    @SortColumn = 'Contact',
    @SortType = 'ASC',
    @AffiliateIBLevel = NULL,
    @AccountStatus = NULL,
    @AffiliateGroupsID = @Groups,
    @AffiliateID = NULL,
    @AffiliateTypeID = 3,
    @TxtFilter = NULL;
```

### 8.3 Search for a specific affiliate by text
```sql
DECLARE @Groups dbo.IDTableType;

EXEC AffiliateAdmin.GetAffiliates
    @PageID = 1,
    @PageSize = 10,
    @SortColumn = 'DateCreated',
    @SortType = 'DESC',
    @AffiliateIBLevel = NULL,
    @AccountStatus = NULL,
    @AffiliateGroupsID = @Groups,
    @AffiliateID = NULL,
    @AffiliateTypeID = NULL,
    @TxtFilter = 'john.doe';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4989, PART-3580, PART-3147, PART-2714.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliates | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliates.sql*
