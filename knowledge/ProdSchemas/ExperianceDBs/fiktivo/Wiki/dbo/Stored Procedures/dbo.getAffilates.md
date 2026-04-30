# dbo.getAffilates

> Dynamic SQL search procedure for affiliates, supporting keyword search across 14+ fields or exact ID lookup, with configurable sort order. Note: procedure name has a typo ("Affiliates" -> "Affiliates").

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns affiliate search results |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.getAffilates is the primary affiliate search procedure used by the admin interface. It builds a dynamic SQL query that searches across 14+ affiliate fields (Contact, LoginName, Email, CompanyName, Address, URLs, etc.) or performs an exact ID lookup when @filterOnlyById > 0. Results include affiliate group name via LEFT JOIN.

Updated 2023-09-11 (PART-2028) to search Affiliate URLs from the dedicated Affiliate.tblaff_AffiliateURLs table. Note: The procedure name contains a typo ("getAffilates" instead of "getAffiliates").

WARNING: The dynamic SQL concatenates @serachWord directly into the query string without parameterization, creating a SQL injection vulnerability.

---

## 2. Business Logic

### 2.1 Dual Search Mode

**What**: Exact ID lookup vs full-text keyword search.

**Columns/Parameters Involved**: `@serachWord`, `@filterOnlyById`, `@sortExpression`

**Rules**:
- @filterOnlyById > 0: WHERE AffiliateID = @serachWord (exact match)
- @filterOnlyById = 0: LIKE '%search%' across 14 fields (Contact, LoginName, LoginPassword, Email, CompanyName, CompanyAddress, Country, City, State, Zip, Telephone, Fax, WebSiteURL, WebSiteTitle, Comments)
- Results sorted by @sortExpression (dynamic column name)
- Dynamic SQL executed via EXECUTE(@command)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @serachWord | nvarchar(50) | IN | NULL | VERIFIED | Search keyword or affiliate ID. NULL returns all affiliates. Typo in name ("serach" not "search"). |
| 2 | @sortExpression | varchar(100) | IN | - | VERIFIED | Column name for ORDER BY. Injected directly into dynamic SQL. |
| 3 | @filterOnlyById | int | IN | - | VERIFIED | Search mode: > 0 = exact ID match, 0 = keyword search across all fields. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_Affiliates | SELECT | Main affiliate data |
| LEFT JOIN | dbo.tblaff_AffiliatesGroups | JOIN | Group name resolution |
| LEFT JOIN | Affiliate.tblaff_AffiliateURLs | JOIN | Website URL search (cross-schema) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the affiliate admin search interface.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.getAffilates (procedure)
  +-- dbo.tblaff_Affiliates (table)
  +-- dbo.tblaff_AffiliatesGroups (table)
  +-- Affiliate.tblaff_AffiliateURLs (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | Main search target |
| dbo.tblaff_AffiliatesGroups | Table | LEFT JOIN for group name |
| Affiliate.tblaff_AffiliateURLs | Table | LEFT JOIN for URL search |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Search by keyword
```sql
EXEC dbo.getAffilates @serachWord = 'etoro', @sortExpression = 'AffiliateID', @filterOnlyById = 0
```

### 8.2 Exact ID lookup
```sql
EXEC dbo.getAffilates @serachWord = '12345', @sortExpression = 'AffiliateID', @filterOnlyById = 1
```

### 8.3 Get all affiliates
```sql
EXEC dbo.getAffilates @serachWord = NULL, @sortExpression = 'DateCreated DESC', @filterOnlyById = 0
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2028](https://etoro-jira.atlassian.net/browse/PART-2028) | Jira | Search Affiliate URLs from dedicated table (2023-09-11) |

---

*Generated: 2026-04-12 | Quality: 8.2/10*
*Object: dbo.getAffilates | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.getAffilates.sql*
