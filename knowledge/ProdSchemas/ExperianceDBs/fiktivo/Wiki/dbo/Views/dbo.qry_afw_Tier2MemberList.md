# dbo.qry_afw_Tier2MemberList

> Comprehensive tier 2 member listing that combines recruited affiliate details (from qry_afw_Tier2MemberList1) with their parent/referring affiliate's contact information for side-by-side comparison.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base: dbo.qry_afw_Tier2MemberList1 + dbo.tblaff_Affiliates |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_afw_Tier2MemberList is the outer layer of a two-view pattern for the tier 2 member admin screen. It takes the child affiliate details from qry_afw_Tier2MemberList1 and JOINs back to tblaff_Affiliates to add the PARENT (referring) affiliate's contact details (RefContact, RefEmail, RefWebSiteURL, RefWebSiteTitle). This provides a complete side-by-side view of "who recruited whom" for the affiliate admin interface.

Updated 2023-09-11 (PART-2028) to use AffiliateURLs from the dedicated Affiliate.tblaff_AffiliateURLs table for parent affiliate URLs.

---

## 2. Business Logic

### 2.1 Parent-Child Side-by-Side View

**What**: Combines child affiliate profile with parent affiliate contact details.

**Columns/Parameters Involved**: Child columns from qry_afw_Tier2MemberList1, Ref* columns from tblaff_Affiliates

**Rules**:
- INNER JOIN: qry_afw_Tier2MemberList1 ON AffiliateID = parent's AffiliateID
- Child details: LoginName, Contact, Email, WebSiteURL, CompanyName, etc.
- Parent details: RefContact, RefEmail, RefWebSiteURL, RefWebSiteTitle
- Parent WebSiteURL also uses STRING_AGG from Affiliate.tblaff_AffiliateURLs

---

## 3. Data Overview

View combines parent and child affiliate data for all tier 2 relationships.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DateCreated | datetime | YES | - | VERIFIED | Child affiliate's registration date. From qry_afw_Tier2MemberList1. |
| 2 | AffiliateID | int | YES | - | VERIFIED | Parent affiliate ID. The recruiter. |
| 3 | NewMemberID | int | YES | - | VERIFIED | Child affiliate ID. The recruited affiliate. |
| 4 | LoginName | nvarchar(50) | YES | - | VERIFIED | Child's login name. |
| 5 | Contact | nvarchar(255) | YES | - | VERIFIED | Child's contact name. |
| 6 | Email | nvarchar(255) | YES | - | VERIFIED | Child's email. |
| 7 | WebSiteTitle | nvarchar(255) | YES | - | VERIFIED | Child's website title. |
| 8 | WebSiteURL | nvarchar(max) | YES | - | VERIFIED | Child's website URLs (pipe-delimited from AffiliateURLs). |
| 9 | RefContact | nvarchar(255) | YES | - | VERIFIED | PARENT affiliate's contact name. From tblaff_Affiliates (the recruiter). |
| 10 | RefEmail | nvarchar(255) | YES | - | VERIFIED | PARENT affiliate's email address. |
| 11 | RefWebSiteURL | nvarchar(max) | YES | - | VERIFIED | PARENT affiliate's website URLs. STRING_AGG from Affiliate.tblaff_AffiliateURLs. |
| 12 | RefWebSiteTitle | nvarchar(255) | YES | - | VERIFIED | PARENT affiliate's website title. |
| 13 | CompanyName | nvarchar(255) | YES | - | VERIFIED | Child's company name. |
| 14 | CompanyAddress | nvarchar(255) | YES | - | VERIFIED | Child's company address. |
| 15 | CountryID | int | NO | - | VERIFIED | Child's country. |
| 16 | City | nvarchar(100) | YES | - | VERIFIED | Child's city. |
| 17 | Telephone | nvarchar(50) | YES | - | VERIFIED | Child's phone. |
| 18 | SubAffiliateID | nvarchar(1024) | YES | - | VERIFIED | Tier 2 sub-affiliate tracking tag. |
| 19 | Description | nvarchar | YES | - | VERIFIED | Child's affiliate type description. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (child columns) | dbo.qry_afw_Tier2MemberList1 | INNER JOIN | Child affiliate details |
| (Ref* columns) | dbo.tblaff_Affiliates | INNER JOIN | Parent affiliate contact info |
| RefWebSiteURL | Affiliate.tblaff_AffiliateURLs | Correlated subquery | Parent's website URLs |

### 5.2 Referenced By (other objects point to this)

No dependents found in SSDT.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_afw_Tier2MemberList (view)
  +-- dbo.qry_afw_Tier2MemberList1 (view)
  |     +-- dbo.tblaff_Affiliates (table)
  |     +-- dbo.tblaff_Tier2Members (table)
  |     +-- dbo.tblaff_AffiliateTypes (table)
  |     +-- Affiliate.tblaff_AffiliateURLs (table, cross-schema)
  +-- dbo.tblaff_Affiliates (table)
  +-- Affiliate.tblaff_AffiliateURLs (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.qry_afw_Tier2MemberList1 | View | INNER JOIN for child details |
| dbo.tblaff_Affiliates | Table | INNER JOIN for parent details |
| Affiliate.tblaff_AffiliateURLs | Table | Correlated subquery for parent URLs |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 Full tier 2 member list for a parent
```sql
SELECT NewMemberID, LoginName, Contact, Email, RefContact, RefEmail
FROM dbo.qry_afw_Tier2MemberList WITH (NOLOCK)
WHERE AffiliateID = @ParentAffiliateID
```

### 8.2 Parent-child pairs with websites
```sql
SELECT AffiliateID AS Parent, NewMemberID AS Child,
       RefContact AS ParentName, Contact AS ChildName,
       RefWebSiteURL AS ParentSite, WebSiteURL AS ChildSite
FROM dbo.qry_afw_Tier2MemberList WITH (NOLOCK)
ORDER BY AffiliateID
```

### 8.3 Tier 2 members by affiliate type
```sql
SELECT Description, COUNT(*) AS MemberCount
FROM dbo.qry_afw_Tier2MemberList WITH (NOLOCK)
GROUP BY Description ORDER BY MemberCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2028](https://etoro-jira.atlassian.net/browse/PART-2028) | Jira | Use AffiliateURLs from dedicated table for both parent and child URL display (2023-09-11) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 19 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_afw_Tier2MemberList | Type: View | Source: fiktivo/dbo/Views/dbo.qry_afw_Tier2MemberList.sql*
